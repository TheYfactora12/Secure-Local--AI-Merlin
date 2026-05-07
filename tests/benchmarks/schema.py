"""Canonical benchmark case and result schema."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal

BenchmarkSuite = Literal["epbench", "memoryarena", "amabench"]
MemoryLayer = Literal[
    "merlin_session",
    "merlin_user",
    "merlin_documents",
    "merlin_tools",
    "merlin_audit",
]


@dataclass(frozen=True)
class MemoryRecord:
    record_id: str
    text: str
    layer: MemoryLayer
    timestamp: str
    metadata: dict[str, str] = field(default_factory=dict)


@dataclass(frozen=True)
class BenchmarkCase:
    case_id: str
    suite: BenchmarkSuite
    query: str
    expected_ids: tuple[str, ...]
    records: tuple[MemoryRecord, ...]
    expected_layer: MemoryLayer
    top_k: int = 5
    horizon: int = 1


@dataclass(frozen=True)
class CaseResult:
    case_id: str
    suite: BenchmarkSuite
    retrieved_ids: tuple[str, ...]
    expected_ids: tuple[str, ...]
    expected_layer: MemoryLayer
    latency_ms: int

    @property
    def hit(self) -> bool:
        return any(record_id in self.retrieved_ids for record_id in self.expected_ids)

