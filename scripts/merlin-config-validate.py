#!/usr/bin/env python3
"""Validate Merlin config contracts without adding a YAML dependency.

This is the Phase 2A startup guard. It intentionally validates only the contract
shape Merlin runtime code depends on. CI still runs yamllint separately.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REQUIRED_FILES = {
    "hardware-tiers.yaml": {"tiers"},
    "memory.yaml": {"schema_version", "defaults", "canonical", "legacy", "backup"},
    "orchestration.yaml": {"version", "decision", "control_plane", "core_services", "runtime_phases"},
    "persona.yaml": {"persona"},
    "policy.yaml": {"version", "defaults", "task_routing", "approval_gates", "allowed_scopes", "audit"},
    "profiles.yaml": {"profiles"},
    "routes.yaml": {"version", "defaults", "routes", "trace", "fallbacks"},
    "trace.yaml": {"version", "storage", "route_decision_schema", "approval_status_values", "policy_decision_values", "redaction"},
}

REQUIRED_POLICY_GATES = {
    "shell_command",
    "file_read",
    "file_write",
    "file_delete",
    "git_operation",
    "external_network",
    "cloud_model_call",
    "api_key_use",
    "memory_write",
    "service_start",
    "service_stop",
    "model_download",
    "openhands_task",
}

REQUIRED_ROUTES = {"general", "search", "code", "automation", "memory"}
REQUIRED_PROFILES = {"core", "search", "automation", "coding", "security", "ops", "full"}
REQUIRED_TIERS = {"low", "base", "mid", "high"}
REQUIRED_TRACE_FIELDS = {
    "trace_id",
    "timestamp",
    "user_goal_hash",
    "route_id",
    "task_type",
    "selected_agent",
    "required_profile",
    "active_profile",
    "hardware_tier",
    "privacy_mode",
    "online_mode",
    "cloud_allowed",
    "selected_model_alias",
    "provider",
    "approval_gates",
    "approval_status",
    "policy_decision",
    "decision_reason",
    "redaction_applied",
}
CANONICAL_MEMORY_COLLECTIONS = {
    "merlin_session",
    "merlin_user",
    "merlin_documents",
    "merlin_tools",
    "merlin_audit",
}
LEGACY_MEMORY_COLLECTIONS = {
    "home_ai_memory",
    "swarm_memory",
    "documents",
    "openwebui",
    "perplexica",
    "n8n_memory",
    "conversations",
}


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def read_file(config_dir: Path, filename: str, errors: list[str]) -> str:
    path = config_dir / filename
    if not path.is_file():
        fail(errors, f"missing required config: {path}")
        return ""
    text = path.read_text(encoding="utf-8")
    if "\t" in text:
        fail(errors, f"{path}: tabs are not allowed in Merlin YAML")
    if not text.strip():
        fail(errors, f"{path}: file is empty")
    return text


def top_level_keys(text: str) -> set[str]:
    keys: set[str] = set()
    for line in text.splitlines():
        if not line or line.startswith("#") or line.startswith(" "):
            continue
        match = re.match(r"^([A-Za-z0-9_-]+):", line)
        if match:
            keys.add(match.group(1))
    return keys


def section_lines(text: str, section: str) -> list[str]:
    lines = text.splitlines()
    start = None
    for index, line in enumerate(lines):
        if line == f"{section}:":
            start = index + 1
            break
    if start is None:
        return []

    out: list[str] = []
    for line in lines[start:]:
        if line and not line.startswith(" ") and not line.startswith("#"):
            break
        out.append(line)
    return out


def subsection_keys(text: str, section: str) -> set[str]:
    keys: set[str] = set()
    for line in section_lines(text, section):
        match = re.match(r"^  ([A-Za-z0-9_-]+):", line)
        if match:
            keys.add(match.group(1))
    return keys


def list_values_under_key(text: str, key: str) -> list[str]:
    lines = text.splitlines()
    values: list[str] = []
    start = None
    key_pattern = re.compile(rf"^\s*{re.escape(key)}:\s*$")
    for index, line in enumerate(lines):
        if key_pattern.match(line):
            start = index + 1
            break
    if start is None:
        return values

    base_indent = len(lines[start - 1]) - len(lines[start - 1].lstrip())
    for line in lines[start:]:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        if indent <= base_indent and not stripped.startswith("- "):
            break
        if stripped.startswith("- "):
            values.append(stripped[2:].strip().strip('"').strip("'"))
    return values


def nested_mapping_block(text: str, parent: str, child: str) -> str:
    parent_block = section_lines(text, parent)
    start = None
    child_pattern = re.compile(rf"^  {re.escape(child)}:\s*$")
    for index, line in enumerate(parent_block):
        if child_pattern.match(line):
            start = index + 1
            break
    if start is None:
        return ""

    out: list[str] = []
    for line in parent_block[start:]:
        if re.match(r"^  [A-Za-z0-9_-]+:\s*$", line):
            break
        out.append(line)
    return "\n".join(out)


def list_values_in_block(block: str, key: str) -> list[str]:
    lines = block.splitlines()
    values: list[str] = []
    start = None
    key_pattern = re.compile(rf"^\s*{re.escape(key)}:\s*$")
    for index, line in enumerate(lines):
        if key_pattern.match(line):
            start = index + 1
            break
    if start is None:
        return values
    base_indent = len(lines[start - 1]) - len(lines[start - 1].lstrip())
    for line in lines[start:]:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        if indent <= base_indent and not stripped.startswith("- "):
            break
        if stripped.startswith("- "):
            values.append(stripped[2:].strip().strip('"').strip("'"))
    return values


def validate_required_files(config_dir: Path, errors: list[str]) -> dict[str, str]:
    texts: dict[str, str] = {}
    for filename, required_keys in REQUIRED_FILES.items():
        text = read_file(config_dir, filename, errors)
        texts[filename] = text
        if not text:
            continue
        keys = top_level_keys(text)
        missing = sorted(required_keys - keys)
        if missing:
            fail(errors, f"{filename}: missing top-level key(s): {', '.join(missing)}")
    return texts


def validate_policy(text: str, errors: list[str]) -> set[str]:
    gates = subsection_keys(text, "approval_gates")
    missing = sorted(REQUIRED_POLICY_GATES - gates)
    if missing:
        fail(errors, f"policy.yaml: missing approval gate(s): {', '.join(missing)}")
    if "cloud_fallback_enabled: false" not in text:
        fail(errors, "policy.yaml: cloud fallback must be disabled by default")
    if "memory_auto_write: false" not in text:
        fail(errors, "policy.yaml: memory auto-write must be disabled by default")
    if 'repo_write:' in text and "configs/merlin" not in text:
        fail(errors, "policy.yaml: repo_write scope must include configs/merlin")
    return gates


def validate_routes(text: str, policy_gates: set[str], errors: list[str]) -> None:
    routes = subsection_keys(text, "routes")
    missing = sorted(REQUIRED_ROUTES - routes)
    if missing:
        fail(errors, f"routes.yaml: missing route(s): {', '.join(missing)}")

    for route in REQUIRED_ROUTES & routes:
        block = nested_mapping_block(text, "routes", route)
        for required in ("agent:", "required_profile:", "preferred_model_alias:", "approval_gates:", "default_risk:"):
            if required not in block:
                fail(errors, f"routes.yaml: route '{route}' missing {required}")

    all_route_gates: set[str] = set()
    for route in routes:
        all_route_gates.update(list_values_in_block(nested_mapping_block(text, "routes", route), "approval_gates"))
    unknown_gates = sorted({gate for gate in all_route_gates if gate and gate not in policy_gates})
    if unknown_gates:
        fail(errors, f"routes.yaml: approval gate(s) not declared in policy.yaml: {', '.join(unknown_gates)}")

    if "cloud_allowed: false" not in text:
        fail(errors, "routes.yaml: cloud_allowed must be false by default")


def validate_profiles(text: str, errors: list[str]) -> None:
    profiles = subsection_keys(text, "profiles")
    missing = sorted(REQUIRED_PROFILES - profiles)
    if missing:
        fail(errors, f"profiles.yaml: missing profile(s): {', '.join(missing)}")
    if "core:" not in text or "starts_by_default: true" not in text:
        fail(errors, "profiles.yaml: core profile must start by default")
    if "full:" not in text or "requires_confirmation: true" not in text:
        fail(errors, "profiles.yaml: full profile must require confirmation")


def validate_hardware(text: str, errors: list[str]) -> None:
    tiers = subsection_keys(text, "tiers")
    missing = sorted(REQUIRED_TIERS - tiers)
    if missing:
        fail(errors, f"hardware-tiers.yaml: missing tier(s): {', '.join(missing)}")
    if "low:" in text and "default_profile: core" not in text:
        fail(errors, "hardware-tiers.yaml: low tier must default to core profile")
    if "nomic-embed-text" not in text:
        fail(errors, "hardware-tiers.yaml: local embedding model must be recommended")


def validate_memory(text: str, errors: list[str]) -> None:
    canonical = subsection_keys(text, "canonical")
    missing_canonical = sorted(CANONICAL_MEMORY_COLLECTIONS - canonical)
    if missing_canonical:
        fail(errors, f"memory.yaml: missing canonical collection(s): {', '.join(missing_canonical)}")

    legacy = subsection_keys(text, "legacy")
    missing_legacy = sorted(LEGACY_MEMORY_COLLECTIONS - legacy)
    if missing_legacy:
        fail(errors, f"memory.yaml: missing legacy collection(s): {', '.join(missing_legacy)}")

    if "embedding_dimensions: 768" not in text:
        fail(errors, "memory.yaml: Merlin embedding dimensions must be 768")
    if "documents:" in text and "vector_size: 1536" not in text:
        fail(errors, "memory.yaml: legacy documents collection must remain documented as 1536 dimensions")
    if "writes_require_user_approval: true" not in text:
        fail(errors, "memory.yaml: writes must require user approval by default")


def validate_trace(text: str, errors: list[str]) -> None:
    required = set(list_values_under_key(text, "required_fields"))
    missing = sorted(REQUIRED_TRACE_FIELDS - required)
    if missing:
        fail(errors, f"trace.yaml: missing required trace field(s): {', '.join(missing)}")
    if "redact_before_write: true" not in text:
        fail(errors, "trace.yaml: redact_before_write must be true")
    if "append_only: true" not in text:
        fail(errors, "trace.yaml: append_only must be true")


def validate_orchestration(text: str, errors: list[str]) -> None:
    if "decision: hybrid" not in text:
        fail(errors, "orchestration.yaml: decision must remain hybrid")
    if "make_cloud_calls_by_default" not in text:
        fail(errors, "orchestration.yaml: control plane must forbid cloud calls by default")
    if "mandatory_n8n_for_basic_chat" not in text:
        fail(errors, "orchestration.yaml: n8n must not be mandatory for basic chat")


def validate_persona(text: str, errors: list[str]) -> None:
    if "name: Merlin" not in text:
        fail(errors, "persona.yaml: persona name must be Merlin")
    if "local_first: true" not in text:
        fail(errors, "persona.yaml: local_first must be true")
    if "cloud_by_default: false" not in text:
        fail(errors, "persona.yaml: cloud_by_default must be false")
    if "Do not claim omniscience" not in text:
        fail(errors, "persona.yaml: must keep humility boundary")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Merlin Phase 2A config contracts.")
    parser.add_argument("--config-dir", default="configs/merlin", help="Merlin config directory")
    args = parser.parse_args()

    repo = Path.cwd()
    config_dir = (repo / args.config_dir).resolve()
    errors: list[str] = []

    if config_dir.name != "merlin" or config_dir.parent.name != "configs":
        fail(errors, f"config dir must be configs/merlin, got {config_dir}")
    if (repo / "config").exists():
        fail(errors, "legacy root config/ directory must not exist")
    if not config_dir.is_dir():
        fail(errors, f"Merlin config directory missing: {config_dir}")
        texts: dict[str, str] = {}
    else:
        texts = validate_required_files(config_dir, errors)

    if texts:
        policy_gates = validate_policy(texts["policy.yaml"], errors)
        validate_routes(texts["routes.yaml"], policy_gates, errors)
        validate_profiles(texts["profiles.yaml"], errors)
        validate_hardware(texts["hardware-tiers.yaml"], errors)
        validate_memory(texts["memory.yaml"], errors)
        validate_trace(texts["trace.yaml"], errors)
        validate_orchestration(texts["orchestration.yaml"], errors)
        validate_persona(texts["persona.yaml"], errors)

    if errors:
        print("Merlin config validation failed", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 2

    print("Merlin config validation")
    print(f"config_dir: {args.config_dir}")
    print(f"yaml_files_validated: {len(REQUIRED_FILES)}")
    print("policy_gates_validated: true")
    print("route_policy_crosscheck: true")
    print("memory_dimensions_checked: true")
    print("side_effects: none")
    print("PASS: Merlin config validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
