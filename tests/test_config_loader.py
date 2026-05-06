from __future__ import annotations

import copy
import shutil
from pathlib import Path

import pytest
import yaml

from merlin import config_loader
from merlin.config_loader import ConfigValidationError, DimensionMismatchError, MerlinConfig


def _copy_configs(tmp_path: Path) -> Path:
    target = tmp_path / "configs" / "merlin"
    target.mkdir(parents=True)
    for name in config_loader.CONFIG_SCHEMAS:
        shutil.copy(config_loader.CONFIG_DIR / name, target / name)
    return target


def _load_yaml(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    assert isinstance(data, dict)
    return data


def _write_yaml(path: Path, data: dict) -> None:
    with path.open("w", encoding="utf-8") as handle:
        yaml.safe_dump(data, handle, sort_keys=False)


def test_load_all_configs_happy_path() -> None:
    loaded = config_loader.load_all_configs()
    assert isinstance(loaded, MerlinConfig)
    assert loaded.persona.persona.name == "Merlin"
    assert loaded.memory.defaults.embedding_dimensions == 768


def test_missing_required_field_raises_config_validation_error(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config_dir = _copy_configs(tmp_path)
    persona_path = config_dir / "persona.yaml"
    data = _load_yaml(persona_path)
    data["persona"].pop("name")
    _write_yaml(persona_path, data)

    monkeypatch.setattr(config_loader, "CONFIG_DIR", config_dir)

    with pytest.raises(ConfigValidationError) as exc:
        config_loader.load_all_configs()

    assert "persona.yaml" in str(exc.value)
    assert "persona.name" in str(exc.value)


def test_wrong_type_raises_config_validation_error(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config_dir = _copy_configs(tmp_path)
    policy_path = config_dir / "policy.yaml"
    data = _load_yaml(policy_path)
    data["defaults"]["online_mode_enabled"] = "not-a-bool"
    _write_yaml(policy_path, data)

    monkeypatch.setattr(config_loader, "CONFIG_DIR", config_dir)

    with pytest.raises(ConfigValidationError) as exc:
        config_loader.load_all_configs()

    assert "policy.yaml" in str(exc.value)
    assert "defaults.online_mode_enabled" in str(exc.value)


def test_corrupt_yaml_raises_config_validation_error(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config_dir = _copy_configs(tmp_path)
    (config_dir / "routes.yaml").write_text("routes:\n  general: [unterminated\n", encoding="utf-8")

    monkeypatch.setattr(config_loader, "CONFIG_DIR", config_dir)

    with pytest.raises(ConfigValidationError) as exc:
        config_loader.load_all_configs()

    assert "routes.yaml" in str(exc.value)
    assert "corrupt YAML" in str(exc.value)


def test_dimension_mismatch_guard_raises_dimension_mismatch_error(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    config_dir = _copy_configs(tmp_path)
    memory_path = config_dir / "memory.yaml"
    data = _load_yaml(memory_path)
    data = copy.deepcopy(data)
    data["canonical"]["merlin_session"]["vector_size"] = 1536
    _write_yaml(memory_path, data)

    monkeypatch.setattr(config_loader, "CONFIG_DIR", config_dir)

    with pytest.raises(DimensionMismatchError) as exc:
        config_loader.load_all_configs()

    assert "memory.yaml" in str(exc.value)
    assert "vector_size" in str(exc.value)
