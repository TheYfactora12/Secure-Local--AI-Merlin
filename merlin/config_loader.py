"""Typed Merlin configuration loader.

The loader is intentionally read-only: it validates Merlin's declarative YAML
contract without starting services, downloading models, or touching secrets.
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any, Literal

import yaml
from pydantic import BaseModel, ConfigDict, Field, ValidationError, field_validator, model_validator


REPO_ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = REPO_ROOT / "configs" / "merlin"
EXPECTED_EMBEDDING_DIMS = 768


class ConfigValidationError(Exception):
    """Raised when a Merlin YAML config is missing, corrupt, or invalid."""

    def __init__(self, file_name: str, field_name: str, message: str) -> None:
        self.file_name = file_name
        self.field_name = field_name
        super().__init__(f"{file_name}: {field_name}: {message}")


class DimensionMismatchError(ConfigValidationError):
    """Raised when a Merlin memory collection uses an unsupported vector size."""


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class PersonaDefaults(StrictModel):
    local_first: bool
    cloud_by_default: bool
    memory_writes_require_approval: bool
    risky_actions_require_approval: bool
    prefer_small_reviewable_changes: bool
    protect_working_installer: bool


class PersonaBody(StrictModel):
    name: str
    role: str
    voice: list[str]
    mission: list[str]
    default_stance: PersonaDefaults
    guardian_ethos: dict[str, Any] | None = None
    team_modes: dict[str, Any] | None = None
    refusal_and_approval_rules: list[str] | None = None
    response_contract: list[str] | None = None

    @field_validator("name", "role")
    @classmethod
    def non_empty_text(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be empty")
        return value

    @field_validator("voice", "mission")
    @classmethod
    def non_empty_list(cls, value: list[str]) -> list[str]:
        if not value:
            raise ValueError("must contain at least one item")
        return value


class PersonaConfig(StrictModel):
    persona: PersonaBody


class PolicyDefaults(StrictModel):
    magic_mode_enabled: bool
    online_mode_enabled: bool
    cloud_fallback_enabled: bool
    local_network_only: bool
    memory_auto_write: bool
    shell_enabled_for_agents: bool
    file_write_enabled_for_agents: bool
    heavy_profiles_auto_start: bool


class ApprovalGate(StrictModel):
    risk: Literal["low", "medium", "high", "critical"]
    default: str
    requires_approval: bool
    reason: str
    audit_log: bool | None = None


class TaskRoutingRule(StrictModel):
    default_agent: str
    preferred_backend: str
    allowed_profiles: list[str] | None = None
    requires_profile: str | None = None
    requires_approval: bool | None = None


class PolicyAudit(StrictModel):
    log_route_decisions: bool
    log_policy_decisions: bool
    log_approvals: bool
    log_memory_writes: bool
    redact_secrets: bool


class PolicyConfig(StrictModel):
    version: int
    defaults: PolicyDefaults
    task_routing: dict[str, TaskRoutingRule]
    approval_gates: dict[str, ApprovalGate]
    allowed_scopes: dict[str, list[str]]
    audit: PolicyAudit
    low_memory_tier: dict[str, Any] | None = None

    @field_validator("version")
    @classmethod
    def supported_version(cls, value: int) -> int:
        if value < 1:
            raise ValueError("must be >= 1")
        return value


class RouteSpec(StrictModel):
    description: str
    agent: str
    task_types: list[str]
    required_profile: str
    model_class: str
    preferred_model_alias: str
    tools_allowed: list[str]
    approval_gates: list[str]
    default_risk: Literal["low", "medium", "high", "critical"]


class RouteTrace(StrictModel):
    required_fields: list[str]
    redact_fields: list[str]


class RouteFallback(StrictModel):
    action: str
    never_auto_start: bool | None = None
    disable_parallel_agents: bool | None = None
    default: str | None = None


class RoutesConfig(StrictModel):
    version: int
    defaults: dict[str, Any]
    routes: dict[str, RouteSpec]
    trace: RouteTrace
    fallbacks: dict[str, RouteFallback]

    @model_validator(mode="after")
    def validate_routes(self) -> "RoutesConfig":
        if not self.routes:
            raise ValueError("routes must contain at least one route")
        return self


class MemoryDefaults(StrictModel):
    qdrant_url: str
    distance: str
    embedding_model: str
    embedding_dimensions: int
    writes_require_user_approval: bool
    delete_requires_confirmation: bool
    audit_required: bool

    @field_validator("embedding_dimensions")
    @classmethod
    def expected_embedding_dimensions(cls, value: int) -> int:
        if value != EXPECTED_EMBEDDING_DIMS:
            raise ValueError(f"must be {EXPECTED_EMBEDDING_DIMS}")
        return value


class MemoryCollection(StrictModel):
    purpose: str
    vector_size: int
    payload_indexes: list[str]


class LegacyMemoryCollection(StrictModel):
    status: str
    owner: str
    vector_size: int
    migration_target: str


class MemoryBackup(StrictModel):
    default_collections: list[str]


class MemoryConfig(StrictModel):
    schema_version: int
    defaults: MemoryDefaults
    canonical: dict[str, MemoryCollection]
    legacy: dict[str, LegacyMemoryCollection]
    backup: MemoryBackup
    migration_policy: list[str]

    @model_validator(mode="after")
    def validate_dimensions(self) -> "MemoryConfig":
        for name, collection in self.canonical.items():
            if collection.vector_size != EXPECTED_EMBEDDING_DIMS:
                raise ValueError(
                    f"canonical.{name}.vector_size must be {EXPECTED_EMBEDDING_DIMS}, "
                    f"got {collection.vector_size}"
                )
        return self


class ModelSpec(StrictModel):
    provider: str
    model: str
    model_class: str
    local: bool
    enabled_by_default: bool
    context_window: int
    embedding_dimensions: int | None = None
    requires_api_key: bool = False

    @field_validator("context_window")
    @classmethod
    def positive_context_window(cls, value: int) -> int:
        if value <= 0:
            raise ValueError("must be > 0")
        return value

    @model_validator(mode="after")
    def validate_embedding_dims(self) -> "ModelSpec":
        if self.model_class == "embedding" and self.embedding_dimensions != EXPECTED_EMBEDDING_DIMS:
            raise ValueError(f"embedding_dimensions must be {EXPECTED_EMBEDDING_DIMS}")
        return self


class ModelsDefaults(StrictModel):
    local_first: bool
    cloud_by_default: bool
    require_approval_for_cloud: bool
    require_approval_for_downloads: bool
    default_chat_model: str
    default_embedding_model: str


class ModelsConfig(StrictModel):
    version: int
    defaults: ModelsDefaults
    models: dict[str, ModelSpec]

    @model_validator(mode="after")
    def validate_default_aliases(self) -> "ModelsConfig":
        missing = [
            alias
            for alias in (self.defaults.default_chat_model, self.defaults.default_embedding_model)
            if alias not in self.models
        ]
        if missing:
            raise ValueError(f"default model alias missing from models: {', '.join(missing)}")
        return self


class ToolSpec(StrictModel):
    description: str
    enabled_by_default: bool
    local_only: bool
    approval_gates: list[str]
    risk: Literal["low", "medium", "high", "critical"]


class ToolsDefaults(StrictModel):
    deny_external_network_by_default: bool
    require_approval_for_shell: bool
    require_approval_for_file_write: bool


class ToolsConfig(StrictModel):
    version: int
    defaults: ToolsDefaults
    tools: dict[str, ToolSpec]

    @field_validator("tools")
    @classmethod
    def require_tools(cls, value: dict[str, ToolSpec]) -> dict[str, ToolSpec]:
        if not value:
            raise ValueError("must contain at least one tool")
        return value


class AgentSpec(StrictModel):
    description: str
    enabled_by_default: bool
    allowed_tools: list[str]
    allowed_model_classes: list[str]
    approval_gates: list[str]
    can_write_memory: bool
    can_execute_shell: bool


class AgentsDefaults(StrictModel):
    planner: str
    require_approval_for_risky_agents: bool
    parallel_agents_by_default: bool


class AgentsConfig(StrictModel):
    version: int
    defaults: AgentsDefaults
    agents: dict[str, AgentSpec]

    @model_validator(mode="after")
    def validate_default_planner(self) -> "AgentsConfig":
        if self.defaults.planner not in self.agents:
            raise ValueError(f"default planner agent is missing: {self.defaults.planner}")
        return self


class MerlinConfig(StrictModel):
    persona: PersonaConfig
    policy: PolicyConfig
    routes: RoutesConfig
    memory: MemoryConfig
    models: ModelsConfig
    tools: ToolsConfig
    agents: AgentsConfig

    @model_validator(mode="after")
    def cross_validate(self) -> "MerlinConfig":
        gates = set(self.policy.approval_gates)
        models = set(self.models.models)
        tools = set(self.tools.tools)
        agents = set(self.agents.agents)

        for route_name, route in self.routes.routes.items():
            if route.agent not in agents:
                raise ValueError(f"routes.{route_name}.agent references unknown agent: {route.agent}")
            if route.preferred_model_alias not in models:
                raise ValueError(
                    f"routes.{route_name}.preferred_model_alias references unknown model: "
                    f"{route.preferred_model_alias}"
                )
            unknown_tools = sorted(set(route.tools_allowed) - tools)
            if unknown_tools:
                raise ValueError(f"routes.{route_name}.tools_allowed unknown tools: {', '.join(unknown_tools)}")
            unknown_gates = sorted(set(route.approval_gates) - gates)
            if unknown_gates:
                raise ValueError(f"routes.{route_name}.approval_gates unknown gates: {', '.join(unknown_gates)}")

        for agent_name, agent in self.agents.agents.items():
            unknown_tools = sorted(set(agent.allowed_tools) - tools)
            if unknown_tools:
                raise ValueError(f"agents.{agent_name}.allowed_tools unknown tools: {', '.join(unknown_tools)}")
            unknown_gates = sorted(set(agent.approval_gates) - gates)
            if unknown_gates:
                raise ValueError(f"agents.{agent_name}.approval_gates unknown gates: {', '.join(unknown_gates)}")

        return self


CONFIG_SCHEMAS: dict[str, tuple[str, type[BaseModel]]] = {
    "persona.yaml": ("persona", PersonaConfig),
    "policy.yaml": ("policy", PolicyConfig),
    "routes.yaml": ("routes", RoutesConfig),
    "memory.yaml": ("memory", MemoryConfig),
    "models.yaml": ("models", ModelsConfig),
    "tools.yaml": ("tools", ToolsConfig),
    "agents.yaml": ("agents", AgentsConfig),
}


def _read_yaml(file_path: Path) -> Any:
    try:
        with file_path.open("r", encoding="utf-8") as handle:
            data = yaml.safe_load(handle)
    except yaml.YAMLError as exc:
        mark = getattr(exc, "problem_mark", None)
        field_name = f"line {mark.line + 1}" if mark is not None else "$"
        raise ConfigValidationError(file_path.name, field_name, f"corrupt YAML: {exc}") from exc
    except OSError as exc:
        raise ConfigValidationError(file_path.name, "$", str(exc)) from exc

    if data is None:
        raise ConfigValidationError(file_path.name, "$", "file is empty")
    if not isinstance(data, dict):
        raise ConfigValidationError(file_path.name, "$", "top-level YAML value must be a mapping")
    return data


def _field_from_validation_error(error: dict[str, Any]) -> str:
    location = error.get("loc") or ("$",)
    return ".".join(str(part) for part in location)


def _is_dimension_error(error: dict[str, Any]) -> bool:
    field_name = _field_from_validation_error(error)
    message = str(error.get("msg", ""))
    return any(
        marker in f"{field_name} {message}"
        for marker in ("embedding_dimensions", "vector_size", f"must be {EXPECTED_EMBEDDING_DIMS}")
    )


def _validate_file(config_dir: Path, file_name: str, schema: type[BaseModel]) -> BaseModel:
    file_path = config_dir / file_name
    if not file_path.exists():
        raise ConfigValidationError(file_name, "$", "required config file is missing")

    data = _read_yaml(file_path)
    try:
        return schema.model_validate(data)
    except ValidationError as exc:
        first = exc.errors()[0]
        if file_name == "memory.yaml" and any(_is_dimension_error(error) for error in exc.errors()):
            raise DimensionMismatchError(file_name, _field_from_validation_error(first), first["msg"]) from exc
        raise ConfigValidationError(file_name, _field_from_validation_error(first), first["msg"]) from exc
    except ValueError as exc:
        if file_name == "memory.yaml":
            raise DimensionMismatchError(file_name, "$", str(exc)) from exc
        raise ConfigValidationError(file_name, "$", str(exc)) from exc


def load_all_configs() -> MerlinConfig:
    """Read and validate all Merlin YAML config files."""

    loaded: dict[str, BaseModel] = {}
    for file_name, (key, schema) in CONFIG_SCHEMAS.items():
        try:
            loaded[key] = _validate_file(CONFIG_DIR, file_name, schema)
        except ConfigValidationError:
            raise
        except Exception as exc:
            raise ConfigValidationError(file_name, "$", str(exc)) from exc

    try:
        config = MerlinConfig.model_validate(loaded)
    except ValidationError as exc:
        first = exc.errors()[0]
        raise ConfigValidationError("cross-config", _field_from_validation_error(first), first["msg"]) from exc
    except ValueError as exc:
        raise ConfigValidationError("cross-config", "$", str(exc)) from exc

    print("\033[32m\u2713 All configs valid\033[0m")
    return config


def main() -> int:
    try:
        load_all_configs()
    except ConfigValidationError as exc:
        print(f"Config validation failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
