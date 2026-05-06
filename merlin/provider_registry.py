"""Read-only Merlin provider registry.

The registry reports configured local and optional external providers without
calling them, reading secret values from disk, or enabling cloud behavior.
"""

from __future__ import annotations

import io
import os
from contextlib import redirect_stdout
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel

from merlin.config_loader import REPO_ROOT, MerlinConfig, load_all_configs


LITELLM_CONFIG_PATH = REPO_ROOT / "configs" / "litellm" / "config.yaml"


class ProviderStatus(BaseModel):
    provider_id: str
    provider_type: str
    enabled: bool
    configured: bool
    local: bool
    default: bool
    requires_approval: bool
    api_key_required: bool
    api_key_present: bool
    model_aliases: list[str]
    status: str
    notes: list[str]


class ProviderRegistry(BaseModel):
    mode: str
    local_first: bool
    cloud_enabled: bool
    external_providers_enabled: bool
    providers: list[ProviderStatus]


def _load_config_quietly() -> MerlinConfig:
    with redirect_stdout(io.StringIO()):
        return load_all_configs()


def _safe_yaml(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = yaml.safe_load(handle)
    except (OSError, yaml.YAMLError):
        return {}
    return data if isinstance(data, dict) else {}


def _litellm_aliases_by_provider() -> dict[str, list[str]]:
    data = _safe_yaml(LITELLM_CONFIG_PATH)
    aliases: dict[str, set[str]] = {}
    for entry in data.get("model_list", []) or []:
        if not isinstance(entry, dict):
            continue
        alias = entry.get("model_name")
        params = entry.get("litellm_params", {})
        model = params.get("model") if isinstance(params, dict) else None
        if not isinstance(alias, str) or not isinstance(model, str):
            continue
        provider = model.split("/", 1)[0] if "/" in model else "unknown"
        aliases.setdefault(provider, set()).add(alias)
    return {provider: sorted(values) for provider, values in aliases.items()}


def _env_present(key: str) -> bool:
    return bool(os.environ.get(key))


def _local_provider(config: MerlinConfig, litellm_aliases: dict[str, list[str]]) -> ProviderStatus:
    model_aliases = sorted(
        alias
        for alias, model in config.models.models.items()
        if model.provider == "ollama" and model.local
    )
    litellm_model_aliases = litellm_aliases.get("ollama", [])
    configured = bool(model_aliases) and bool(litellm_model_aliases)
    return ProviderStatus(
        provider_id="ollama",
        provider_type="local_model_runtime",
        enabled=True,
        configured=configured,
        local=True,
        default=True,
        requires_approval=False,
        api_key_required=False,
        api_key_present=False,
        model_aliases=model_aliases,
        status="available" if configured else "config_missing",
        notes=[
            "Local Ollama models are the default Merlin provider.",
            "No provider API key is required for local inference.",
        ],
    )


def _gateway_provider(litellm_aliases: dict[str, list[str]]) -> ProviderStatus:
    model_aliases = litellm_aliases.get("ollama", [])
    configured = bool(model_aliases)
    return ProviderStatus(
        provider_id="litellm",
        provider_type="local_gateway",
        enabled=True,
        configured=configured,
        local=True,
        default=True,
        requires_approval=False,
        api_key_required=True,
        api_key_present=_env_present("LITELLM_MASTER_KEY"),
        model_aliases=model_aliases,
        status="configured" if configured else "config_missing",
        notes=[
            "LiteLLM is the local gateway in front of Ollama aliases.",
            "API key presence is reported as a boolean only; values are never exposed.",
        ],
    )


def _external_provider(provider_id: str, env_key: str, config: MerlinConfig) -> ProviderStatus:
    api_key_present = _env_present(env_key)
    return ProviderStatus(
        provider_id=provider_id,
        provider_type="external_model_provider",
        enabled=False,
        configured=api_key_present,
        local=False,
        default=False,
        requires_approval=config.models.defaults.require_approval_for_cloud,
        api_key_required=True,
        api_key_present=api_key_present,
        model_aliases=[],
        status="disabled_key_present" if api_key_present else "disabled",
        notes=[
            "External providers are disabled by default.",
            "Using this provider requires explicit online/cloud approval.",
        ],
    )


def build_provider_registry() -> ProviderRegistry:
    """Build a read-only provider registry from local config and env presence."""

    config = _load_config_quietly()
    litellm_aliases = _litellm_aliases_by_provider()
    cloud_enabled = bool(config.models.defaults.cloud_by_default)
    providers = [
        _local_provider(config, litellm_aliases),
        _gateway_provider(litellm_aliases),
        _external_provider("openai", "OPENAI_API_KEY", config),
        _external_provider("anthropic", "ANTHROPIC_API_KEY", config),
        _external_provider("perplexity", "PERPLEXITY_API_KEY", config),
    ]
    return ProviderRegistry(
        mode="local_only" if not cloud_enabled else "online_optional",
        local_first=config.models.defaults.local_first,
        cloud_enabled=cloud_enabled,
        external_providers_enabled=False,
        providers=providers,
    )

