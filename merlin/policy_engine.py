"""Merlin fail-closed policy engine."""

from __future__ import annotations

import functools
import logging
from collections.abc import Callable
from typing import Any, TypeVar

from typing_extensions import ParamSpec

from merlin import config_loader
from merlin.config_loader import ConfigValidationError


logger = logging.getLogger(__name__)

P = ParamSpec("P")
R = TypeVar("R")

CONTROLLED_ACTION_GATES: tuple[str, ...] = (
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
    "secret_access",
    "webhook_execution",
)


class PolicyLoadError(Exception):
    """Raised when Merlin cannot load policy and must block the action."""


class ApprovalRequiredError(Exception):
    """Raised when policy requires user approval before an action can run."""

    def __init__(self, action_name: str, reason: str) -> None:
        self.action_name = action_name
        self.reason = reason
        super().__init__(f"Approval required for {action_name}: {reason}")


def _load_policy():
    try:
        return config_loader.load_all_configs().policy
    except ConfigValidationError as exc:
        raise PolicyLoadError(f"Policy could not be loaded: {exc}") from exc
    except Exception as exc:
        raise PolicyLoadError(f"Policy could not be loaded: {exc}") from exc


def _gate_for_action(action_name: str):
    policy = _load_policy()
    gate = policy.approval_gates.get(action_name)
    if gate is None:
        reason = f"Controlled action gate is missing from policy.yaml: {action_name}"
        logger.warning("Approval blocked: action=%s reason=%s", action_name, reason)
        raise ApprovalRequiredError(action_name, reason)
    return gate


def requires_approval(action_name: str) -> Callable[[Callable[P, R]], Callable[P, R]]:
    """Decorate a controlled action and enforce Merlin policy gates.

    The wrapper either executes the function or raises. It never swallows policy
    load errors, validation errors, approval requirements, or function errors.
    """

    if action_name not in CONTROLLED_ACTION_GATES:
        raise ValueError(f"Unknown controlled action gate: {action_name}")

    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        @functools.wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            gate = _gate_for_action(action_name)
            if gate.requires_approval:
                logger.warning("Approval required: action=%s reason=%s", action_name, gate.reason)
                raise ApprovalRequiredError(action_name, gate.reason)
            return func(*args, **kwargs)

        return wrapper

    return decorator


CONTROLLED_ACTION_DECORATORS: dict[str, Callable[[Callable[P, R]], Callable[P, R]]] = {
    gate: requires_approval(gate) for gate in CONTROLLED_ACTION_GATES
}
