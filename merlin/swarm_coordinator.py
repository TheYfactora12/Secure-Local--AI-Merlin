"""Merlin swarm coordinator.

Thin adapter between the native router and persona injector. It receives an
already-resolved RouteDecision and turns it into immutable context for staff
prompt construction. It performs no model calls, network calls, or I/O.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime

from merlin.router import RouteDecision


@dataclass(frozen=True)
class SwarmContext:
    """Resolved context passed from router to persona injector."""

    staff_mode: str
    selected_model_alias: str
    preferred_model_alias: str
    model_fallback_applied: bool
    model_fallback_reason: str | None
    agent_target: str
    approval_gates: list[str]
    requires_approval: bool
    confidence: float
    route_id: str
    task_type: str
    resolved_at: str = field(default_factory=lambda: datetime.now(UTC).isoformat())


def build_swarm_context(decision: RouteDecision) -> SwarmContext:
    """Convert a RouteDecision into immutable staff context."""

    return SwarmContext(
        staff_mode=decision.staff_mode,
        selected_model_alias=decision.selected_model_alias,
        preferred_model_alias=decision.preferred_model_alias,
        model_fallback_applied=decision.model_fallback_applied,
        model_fallback_reason=decision.model_fallback_reason,
        agent_target=decision.agent_target,
        approval_gates=list(decision.approval_gates),
        requires_approval=decision.requires_approval,
        confidence=decision.confidence,
        route_id=decision.route_id,
        task_type=decision.task_type,
    )


build_swarm_context.__annotations__["return"] = SwarmContext
