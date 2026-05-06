from __future__ import annotations

import shutil
from pathlib import Path
from types import SimpleNamespace

import pytest

from merlin import config_loader, policy_engine
from merlin.policy_engine import ApprovalRequiredError, PolicyLoadError


def _fake_config(action_name: str, requires_approval: bool = True):
    gates = {
        action_name: SimpleNamespace(
            requires_approval=requires_approval,
            reason=f"{action_name} requires explicit approval",
        )
    }
    return SimpleNamespace(policy=SimpleNamespace(approval_gates=gates))


def _copy_configs(tmp_path: Path) -> Path:
    target = tmp_path / "configs" / "merlin"
    target.mkdir(parents=True)
    for name in config_loader.CONFIG_SCHEMAS:
        shutil.copy(config_loader.CONFIG_DIR / name, target / name)
    return target


@pytest.mark.parametrize("gate", policy_engine.CONTROLLED_ACTION_GATES)
def test_each_controlled_gate_requires_approval(monkeypatch: pytest.MonkeyPatch, gate: str) -> None:
    monkeypatch.setattr(policy_engine.config_loader, "load_all_configs", lambda: _fake_config(gate))

    @policy_engine.requires_approval(gate)
    def controlled_action() -> str:
        return "executed"

    with pytest.raises(ApprovalRequiredError) as exc:
        controlled_action()

    assert exc.value.action_name == gate
    assert gate in exc.value.reason


def test_gate_with_approval_disabled_executes(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(
        policy_engine.config_loader,
        "load_all_configs",
        lambda: _fake_config("shell_command", requires_approval=False),
    )

    @policy_engine.requires_approval("shell_command")
    def controlled_action(value: str) -> str:
        return f"executed:{value}"

    assert controlled_action("ok") == "executed:ok"


def test_policy_file_missing_fails_closed(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config_dir = _copy_configs(tmp_path)
    (config_dir / "policy.yaml").unlink()
    monkeypatch.setattr(config_loader, "CONFIG_DIR", config_dir)

    @policy_engine.requires_approval("shell_command")
    def controlled_action() -> str:
        return "executed"

    with pytest.raises(PolicyLoadError):
        controlled_action()


def test_corrupt_policy_yaml_fails_closed(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config_dir = _copy_configs(tmp_path)
    (config_dir / "policy.yaml").write_text("approval_gates:\n  shell_command: [unterminated\n", encoding="utf-8")
    monkeypatch.setattr(config_loader, "CONFIG_DIR", config_dir)

    @policy_engine.requires_approval("shell_command")
    def controlled_action() -> str:
        return "executed"

    with pytest.raises(PolicyLoadError):
        controlled_action()
