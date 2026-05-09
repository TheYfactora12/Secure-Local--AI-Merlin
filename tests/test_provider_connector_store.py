from __future__ import annotations

from merlin.provider_connector_store import (
    disable_provider_connector,
    list_provider_connectors,
    upsert_provider_connector,
)


def test_provider_connector_store_persists_presence_only(tmp_path) -> None:
    path = tmp_path / "connectors.json"
    secret_value = "provider-secret-value-that-must-not-persist"

    record = upsert_provider_connector(
        provider_id="openai",
        secret_value=secret_value,
        user_allowed=True,
        approval_id="approval-1",
        path=path,
    )
    raw_store = path.read_text(encoding="utf-8")

    assert record.provider_id == "openai"
    assert record.credential_present is True
    assert record.user_allowed is True
    assert record.enabled is True
    assert record.storage_mode == "presence_marker_only"
    assert record.secret_persisted is False
    assert secret_value not in raw_store


def test_provider_connector_store_rejects_unknown_provider(tmp_path) -> None:
    try:
        upsert_provider_connector(
            provider_id="unknown",
            secret_value="secret",
            user_allowed=True,
            approval_id="approval-1",
            path=tmp_path / "connectors.json",
        )
    except ValueError as exc:
        assert "unknown provider_id" in str(exc)
    else:
        raise AssertionError("unknown providers must be rejected")


def test_provider_connector_disable_preserves_presence_marker(tmp_path) -> None:
    path = tmp_path / "connectors.json"
    upsert_provider_connector(
        provider_id="anthropic",
        secret_value="provider-secret",
        user_allowed=True,
        approval_id="approval-1",
        path=path,
    )

    record = disable_provider_connector(provider_id="anthropic", approval_id="approval-2", path=path)
    records = list_provider_connectors(path)

    assert record.credential_present is True
    assert record.user_allowed is False
    assert record.enabled is False
    assert records["anthropic"].enabled is False
