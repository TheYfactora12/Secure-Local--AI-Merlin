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
    display_name: str
    api_family: str
    auth_scheme: str
    provider_type: str
    enabled: bool
    configured: bool
    local: bool
    default: bool
    requires_approval: bool
    user_allow_required: bool
    user_allowed: bool
    api_key_required: bool
    api_key_present: bool
    model_aliases: list[str]
    known_model_examples: list[str]
    capabilities: list[str]
    setup_state: str
    status: str
    connection_state: str
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
        display_name="Local Ollama",
        api_family="ollama_native",
        auth_scheme="none_localhost",
        provider_type="local_model_runtime",
        enabled=True,
        configured=configured,
        local=True,
        default=True,
        requires_approval=False,
        user_allow_required=False,
        user_allowed=True,
        api_key_required=False,
        api_key_present=False,
        model_aliases=model_aliases,
        known_model_examples=[config.models.models[alias].model for alias in model_aliases],
        capabilities=["chat", "embeddings", "local_inference"],
        setup_state="allowed",
        status="available" if configured else "config_missing",
        connection_state="allowed_local",
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
        display_name="LiteLLM Local Gateway",
        api_family="openai_compatible_gateway",
        auth_scheme="bearer_local_master_key",
        provider_type="local_gateway",
        enabled=True,
        configured=configured,
        local=True,
        default=True,
        requires_approval=False,
        user_allow_required=False,
        user_allowed=True,
        api_key_required=True,
        api_key_present=_env_present("LITELLM_MASTER_KEY"),
        model_aliases=model_aliases,
        known_model_examples=model_aliases,
        capabilities=["chat", "routing", "local_gateway"],
        setup_state="allowed",
        status="configured" if configured else "config_missing",
        connection_state="allowed_local",
        notes=[
            "LiteLLM is the local gateway in front of Ollama aliases.",
            "API key presence is reported as a boolean only; values are never exposed.",
        ],
    )


EXTERNAL_PROVIDER_CATALOG: tuple[dict[str, Any], ...] = (
    {
        "provider_id": "openai",
        "display_name": "ChatGPT / OpenAI",
        "api_family": "openai_responses",
        "auth_scheme": "bearer",
        "env_keys": ("OPENAI_API_KEY",),
        "known_model_examples": ["gpt-4.1", "gpt-4o", "o4-mini"],
        "capabilities": ["chat", "responses", "tools", "vision"],
    },
    {
        "provider_id": "anthropic",
        "display_name": "Claude / Anthropic",
        "api_family": "anthropic_messages",
        "auth_scheme": "x-api-key",
        "env_keys": ("ANTHROPIC_API_KEY",),
        "known_model_examples": ["claude-opus-4-5", "claude-sonnet-4-5"],
        "capabilities": ["chat", "messages", "vision"],
    },
    {
        "provider_id": "perplexity",
        "display_name": "Perplexity Sonar",
        "api_family": "perplexity_sonar",
        "auth_scheme": "bearer",
        "env_keys": ("PERPLEXITY_API_KEY",),
        "known_model_examples": ["sonar", "sonar-pro"],
        "capabilities": ["chat", "web_grounded_search", "citations"],
    },
    {
        "provider_id": "google",
        "display_name": "Gemini / Google AI",
        "api_family": "gemini_generate_content",
        "auth_scheme": "x-goog-api-key",
        "env_keys": ("GOOGLE_API_KEY", "GEMINI_API_KEY"),
        "known_model_examples": ["gemini-2.5-pro", "gemini-2.5-flash"],
        "capabilities": ["chat", "generate_content", "multimodal"],
    },
    {
        "provider_id": "mistral",
        "display_name": "Mistral AI",
        "api_family": "mistral_chat_completions",
        "auth_scheme": "bearer",
        "env_keys": ("MISTRAL_API_KEY",),
        "known_model_examples": ["mistral-large-latest", "codestral-latest"],
        "capabilities": ["chat", "tools", "structured_outputs"],
    },
    {
        "provider_id": "openrouter",
        "display_name": "OpenRouter",
        "api_family": "openai_compatible_router",
        "auth_scheme": "bearer",
        "env_keys": ("OPENROUTER_API_KEY",),
        "known_model_examples": ["openrouter/auto", "anthropic/claude-sonnet-4.5"],
        "capabilities": ["chat", "model_router", "model_discovery"],
    },
)


def _external_provider(provider: dict[str, Any], config: MerlinConfig) -> ProviderStatus:
    provider_id = str(provider["provider_id"])
    env_keys = tuple(str(key) for key in provider["env_keys"])
    api_key_present = any(_env_present(key) for key in env_keys)
    return ProviderStatus(
        provider_id=provider_id,
        display_name=str(provider["display_name"]),
        api_family=str(provider["api_family"]),
        auth_scheme=str(provider["auth_scheme"]),
        provider_type="external_model_provider",
        enabled=False,
        configured=api_key_present,
        local=False,
        default=False,
        requires_approval=config.models.defaults.require_approval_for_cloud,
        user_allow_required=True,
        user_allowed=False,
        api_key_required=True,
        api_key_present=api_key_present,
        model_aliases=[],
        known_model_examples=list(provider["known_model_examples"]),
        capabilities=list(provider["capabilities"]),
        setup_state="locked_until_policy_flow",
        status="disabled_key_present" if api_key_present else "disabled",
        connection_state="not_allowed",
        notes=[
            "External providers are not allowed by default.",
            "Using this provider requires user enablement and explicit online/cloud approval.",
            "Secret values are never returned by the provider registry.",
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
    ]
    providers.extend(_external_provider(provider, config) for provider in EXTERNAL_PROVIDER_CATALOG)
    return ProviderRegistry(
        mode="local_only" if not cloud_enabled else "online_optional",
        local_first=config.models.defaults.local_first,
        cloud_enabled=cloud_enabled,
        external_providers_enabled=False,
        providers=providers,
    )
