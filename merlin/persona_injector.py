"""Build Merlin system prompts from validated persona config."""

from __future__ import annotations

import io
import re
from contextlib import redirect_stdout
from typing import TYPE_CHECKING

from merlin.config_loader import load_all_configs
from merlin.router import RouteDecision

if TYPE_CHECKING:
    from merlin.swarm_coordinator import SwarmContext


PI_WARMTH_BLOCK = (
    "Ask one follow-up question when the user's intent is ambiguous.\n"
    "Reference earlier context naturally within this session.\n"
    "Acknowledge before answering when emotional subtext is present.\n"
    "Never rush to the answer when the user needs to be heard first."
)

VOICE_MODE_BLOCK = (
    "VOICE MODE: Keep response under 150 words. No code blocks,\n"
    "JSON, file paths, or URLs. Use complete sentences."
)

SECRET_ASSIGNMENT_PATTERN = re.compile(
    r"(?i)\b(api[_-]?key|token|password|secret|credential)\s*[:=]\s*['\"]?[^'\"\s]+"
)
FILE_PATH_PATTERN = re.compile(r"(?<!\w)(?:~|/Users|/private|/tmp|/var|[A-Za-z]:\\)[^\s,;:]+")


def _load_persona_quietly():
    with redirect_stdout(io.StringIO()):
        return load_all_configs().persona.persona


def _sanitize_prompt(text: str) -> str:
    text = SECRET_ASSIGNMENT_PATTERN.sub(r"\1: [redacted]", text)
    return FILE_PATH_PATTERN.sub("[redacted-path]", text)


def _bullet_block(items: list[str]) -> str:
    return "\n".join(f"- {item}" for item in items)


def build_system_prompt(route_decision: RouteDecision, voice_ready: bool = False) -> str:
    """Build a local-first Merlin system prompt for the selected route."""

    persona = _load_persona_quietly()
    guardian = persona.guardian_ethos or {}
    team_modes = persona.team_modes or {}
    active_mode = team_modes.get(route_decision.staff_mode) or team_modes.get(route_decision.route_id) or {}
    active_focus = active_mode.get("focus", "Use Merlin's local-first operating principles for this task.")

    sections = [
        "[Merlin Identity]",
        f"Name: {persona.name}",
        f"Role: {persona.role}",
        "Mission:",
        _bullet_block(persona.mission),
        "",
        "[Guardian Ethos]",
        f"Purpose: {guardian.get('purpose', '')}",
        "Commitments:",
        _bullet_block(list(guardian.get("commitments", []))),
        "Boundaries:",
        _bullet_block(list(guardian.get("boundaries", []))),
        "",
        "[Active Team Mode]",
        f"Staff mode: {route_decision.staff_mode}",
        f"Route ID: {route_decision.route_id}",
        f"Focus: {active_focus}",
        "",
        "[Response Contract]",
        _bullet_block(persona.response_contract or []),
        "",
        "[Pi Warmth]",
        PI_WARMTH_BLOCK,
    ]

    if voice_ready:
        sections.extend(["", "[Voice Mode]", VOICE_MODE_BLOCK])

    return _sanitize_prompt("\n".join(sections))
