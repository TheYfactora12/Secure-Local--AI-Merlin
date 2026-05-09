"""Presence-only provider connector store for Wizard HQ Settings.

This module intentionally does not persist raw API keys. The first #117 backend
slice records connector metadata, explicit user allow state, and a secret
fingerprint so Wizard HQ can show presence-only status without enabling cloud
routing by default.
"""

from __future__ import annotations

import hashlib
import json
import os
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from pydantic import BaseModel

from merlin.config_loader import REPO_ROOT


DEFAULT_CONNECTOR_STORE = REPO_ROOT / "logs" / "provider-connectors.json"


class ProviderConnectorRecord(BaseModel):
    provider_id: str
    credential_present: bool
    credential_fingerprint: str
    user_allowed: bool
    enabled: bool
    approval_id: str
    updated_at: str
    storage_mode: str = "presence_marker_only"
    secret_persisted: bool = False


def connector_store_path() -> Path:
    override = os.environ.get("MERLIN_PROVIDER_CONNECTOR_STORE")
    return Path(override) if override else DEFAULT_CONNECTOR_STORE


def known_external_provider_ids() -> set[str]:
    from merlin.provider_registry import EXTERNAL_PROVIDER_CATALOG

    return {str(provider["provider_id"]) for provider in EXTERNAL_PROVIDER_CATALOG}


def _utc_now() -> str:
    return datetime.now(UTC).isoformat()


def _fingerprint(provider_id: str, secret_value: str) -> str:
    digest = hashlib.sha256(f"{provider_id}:{secret_value}".encode("utf-8")).hexdigest()
    return digest[:16]


def _load_store(path: Path | None = None) -> dict[str, Any]:
    store_path = path or connector_store_path()
    try:
        with store_path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return {"providers": {}}
    if not isinstance(data, dict):
        return {"providers": {}}
    providers = data.get("providers")
    if not isinstance(providers, dict):
        data["providers"] = {}
    return data


def _write_store(data: dict[str, Any], path: Path | None = None) -> None:
    store_path = path or connector_store_path()
    store_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = store_path.with_suffix(f"{store_path.suffix}.tmp")
    with tmp_path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, sort_keys=True)
        handle.write("\n")
    tmp_path.replace(store_path)


def get_provider_connector(provider_id: str, path: Path | None = None) -> ProviderConnectorRecord | None:
    data = _load_store(path)
    raw = data.get("providers", {}).get(provider_id)
    if not isinstance(raw, dict):
        return None
    try:
        return ProviderConnectorRecord.model_validate(raw)
    except ValueError:
        return None


def list_provider_connectors(path: Path | None = None) -> dict[str, ProviderConnectorRecord]:
    data = _load_store(path)
    records: dict[str, ProviderConnectorRecord] = {}
    for provider_id, raw in data.get("providers", {}).items():
        if not isinstance(provider_id, str) or not isinstance(raw, dict):
            continue
        try:
            records[provider_id] = ProviderConnectorRecord.model_validate(raw)
        except ValueError:
            continue
    return records


def upsert_provider_connector(
    *,
    provider_id: str,
    secret_value: str,
    user_allowed: bool,
    approval_id: str,
    path: Path | None = None,
) -> ProviderConnectorRecord:
    if provider_id not in known_external_provider_ids():
        raise ValueError(f"unknown provider_id: {provider_id}")
    if not approval_id.strip():
        raise ValueError("approval_id is required")
    if not secret_value.strip():
        raise ValueError("secret_value is required")

    record = ProviderConnectorRecord(
        provider_id=provider_id,
        credential_present=True,
        credential_fingerprint=_fingerprint(provider_id, secret_value.strip()),
        user_allowed=bool(user_allowed),
        enabled=bool(user_allowed),
        approval_id=approval_id.strip(),
        updated_at=_utc_now(),
    )
    data = _load_store(path)
    data.setdefault("providers", {})[provider_id] = record.model_dump()
    _write_store(data, path)
    return record


def disable_provider_connector(
    *,
    provider_id: str,
    approval_id: str,
    path: Path | None = None,
) -> ProviderConnectorRecord:
    existing = get_provider_connector(provider_id, path)
    if existing is None:
        raise ValueError(f"provider connector is not configured: {provider_id}")
    if not approval_id.strip():
        raise ValueError("approval_id is required")

    record = existing.model_copy(
        update={
            "user_allowed": False,
            "enabled": False,
            "approval_id": approval_id.strip(),
            "updated_at": _utc_now(),
        }
    )
    data = _load_store(path)
    data.setdefault("providers", {})[provider_id] = record.model_dump()
    _write_store(data, path)
    return record
