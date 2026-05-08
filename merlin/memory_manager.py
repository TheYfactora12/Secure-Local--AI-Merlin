"""Merlin Qdrant memory manager with strict dimension guards."""

from __future__ import annotations

import json
import logging
import io
import hashlib
import uuid
from contextlib import redirect_stdout
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Any
from urllib import error, request

from merlin.config_loader import DimensionMismatchError, load_all_configs

if TYPE_CHECKING:
    from merlin.preference_extractor import PreferenceCandidate


logger = logging.getLogger(__name__)

OLLAMA_EMBEDDINGS_URL = "http://localhost:11434/api/embeddings"
DEFAULT_TIMEOUT_SECONDS = 5
SKILL_OUTCOMES_COLLECTION = "skill_outcomes"
SKILL_OUTCOMES_VECTOR_SIZE = 384
SWARM_MEMORY_COLLECTION = "swarm_memory"
SWARM_MEMORY_VECTOR_SIZE = 384


def _utc_now() -> str:
    """Return current UTC time as ISO 8601 string."""
    return datetime.now(tz=timezone.utc).isoformat()


@dataclass(frozen=True)
class CollectionSpec:
    name: str
    qdrant_name: str
    dims: int
    distance: str
    ttl: int | None
    description: str


class MemoryManager:
    def __init__(self, timeout: int = DEFAULT_TIMEOUT_SECONDS) -> None:
        with redirect_stdout(io.StringIO()):
            self.config = load_all_configs().memory
        self.timeout = timeout
        self.qdrant_url = self.config.defaults.qdrant_url.rstrip("/")
        self.embedding_model = self.config.defaults.embedding_model
        self.embedding_dimensions = self.config.defaults.embedding_dimensions
        self.collections = self._build_collection_specs()
        self.degraded = False
        self._check_qdrant()

    # ------------------------------------------------------------------
    # Phase 3C: PreferenceStore methods
    # ------------------------------------------------------------------

    def write_approved_preference(
        self,
        candidate: "PreferenceCandidate",
        approval_id: str,
    ) -> str | None:
        """Persist an approved PreferenceCandidate to swarm_memory.

        ONLY call after explicit human approval. Never auto-write.
        Deduplication: skips write if a semantically identical record exists
        (exact preference_text match — full semantic dedup is Phase 3D).

        Returns point_id str or None on failure.
        """
        # Exact-text dedup guard before write
        existing = self.search_preferences_by_text(candidate.preference_text)
        if existing:
            logger.info("preference_dedup_skip text=%r", candidate.preference_text[:60])
            return None

        point_id = str(uuid.uuid4())
        payload = {
            "memory_type": "preference",
            "preference_text": candidate.preference_text,
            "category": candidate.category,
            "confidence": candidate.confidence,
            "evidence": candidate.evidence,
            "approval_id": approval_id,
            "source": "auto_extracted",
            "created_at": _utc_now(),
        }
        body = {
            "points": [
                {
                    "id": point_id,
                    "vector": [0.0] * SWARM_MEMORY_VECTOR_SIZE,
                    "payload": payload,
                }
            ]
        }
        try:
            self._request_json(
                "PUT",
                f"/collections/{SWARM_MEMORY_COLLECTION}/points?wait=true",
                body,
            )
            logger.info(
                "preference_written point_id=%s category=%s",
                point_id,
                candidate.category,
            )
            return point_id
        except OSError as exc:
            logger.warning("preference_write_failed error=%s", exc)
            return None

    def get_preferences_by_category(
        self,
        category: str,
        limit: int = 10,
    ) -> list[dict]:
        """Retrieve approved preferences from swarm_memory filtered by category.

        Returns list of payload dicts, newest first.
        Returns empty list if Qdrant is unavailable — never raises.
        """
        body = {
            "filter": {
                "must": [
                    {"key": "memory_type", "match": {"value": "preference"}},
                    {"key": "category", "match": {"value": category}},
                ]
            },
            "limit": limit,
            "with_payload": True,
            "with_vectors": False,
        }
        try:
            response = self._request_json(
                "POST",
                f"/collections/{SWARM_MEMORY_COLLECTION}/points/scroll",
                body,
            )
            result = response.get("result", {})
            points = result.get("points", []) if isinstance(result, dict) else []
            payloads = [p.get("payload", {}) for p in points if p.get("payload")]
            payloads.sort(key=lambda p: p.get("created_at", ""), reverse=True)
            return payloads
        except OSError as exc:
            logger.warning("get_preferences_failed category=%s error=%s", category, exc)
            return []

    def search_preferences_by_text(
        self,
        preference_text: str,
        limit: int = 5,
    ) -> list[dict]:
        """Search swarm_memory for preferences matching exact text (dedup guard).

        Returns matching payload dicts or empty list.
        """
        body = {
            "filter": {
                "must": [
                    {"key": "memory_type", "match": {"value": "preference"}},
                    {"key": "preference_text", "match": {"value": preference_text}},
                ]
            },
            "limit": limit,
            "with_payload": True,
            "with_vectors": False,
        }
        try:
            response = self._request_json(
                "POST",
                f"/collections/{SWARM_MEMORY_COLLECTION}/points/scroll",
                body,
            )
            result = response.get("result", {})
            points = result.get("points", []) if isinstance(result, dict) else []
            return [p.get("payload", {}) for p in points if p.get("payload")]
        except OSError as exc:
            logger.warning("search_preferences_failed error=%s", exc)
            return []

    # ------------------------------------------------------------------
    # Existing methods below — unchanged
    # ------------------------------------------------------------------

    def write(self, collection: str, text: str, metadata: dict[str, Any]) -> str | None:
        spec = self._collection_spec(collection)
        self._validate_configured_embedding_dimension(spec)
        if self.degraded:
            self._log_degraded("write", collection)
            return None

        vector = self._embed_text(text)
        self._validate_vector_dimensions(spec, vector)
        point_id = str(uuid.uuid4())
        payload = dict(metadata)
        payload["text"] = text
        body = {"points": [{"id": point_id, "vector": vector, "payload": payload}]}

        try:
            self._request_json("PUT", f"/collections/{spec.qdrant_name}/points?wait=true", body)
        except OSError:
            self._activate_degraded("write", collection)
            return None
        return point_id

    def write_audit_event(self, event_type: str, metadata: dict[str, Any]) -> str | None:
        """Append an audit event without embedding user content.

        Audit payloads are operational telemetry, not user memory. They use a
        neutral vector so route/policy events can be indexed without calling
        Ollama or storing raw prompts.
        """

        spec = self._collection_spec("merlin-audit")
        self._validate_configured_embedding_dimension(spec)
        if self.degraded:
            self._log_degraded("write_audit_event", spec.name)
            return None

        point_id = str(uuid.uuid4())
        payload = dict(metadata)
        payload["event_type"] = event_type
        body = {
            "points": [
                {
                    "id": point_id,
                    "vector": [0.0] * spec.dims,
                    "payload": payload,
                }
            ]
        }

        try:
            self._request_json("PUT", f"/collections/{spec.qdrant_name}/points?wait=true", body)
        except OSError:
            self._activate_degraded("write_audit_event", spec.name)
            return None
        return point_id

    def write_task_outcome_signature(self, outcome: dict[str, Any], task_signature: str) -> str | None:
        """Write an approved task outcome with a local task-signature embedding.

        This is claim-hardening evidence for retrieval-feedback routing. It
        stores hashed/redacted operational metadata only. The raw task signature
        is embedded locally via Ollama and is not persisted in the Qdrant
        payload.
        """

        if not outcome.get("approval_id"):
            return None

        spec = self._collection_spec("merlin-audit")
        self._validate_configured_embedding_dimension(spec)
        if self.degraded:
            self._log_degraded("write_task_outcome_signature", spec.name)
            return None

        try:
            vector = self._embed_text(task_signature)
            self._validate_vector_dimensions(spec, vector)
        except (OSError, ValueError, DimensionMismatchError) as exc:
            logger.warning("task_signature_embedding_skipped route_id=%s error=%s", outcome.get("route_id"), exc)
            return None

        point_id = str(uuid.uuid4())
        payload = self._task_outcome_payload(outcome, task_signature)
        body = {"points": [{"id": point_id, "vector": vector, "payload": payload}]}

        try:
            self._request_json("PUT", f"/collections/{spec.qdrant_name}/points?wait=true", body)
        except OSError:
            self._activate_degraded("write_task_outcome_signature", spec.name)
            return None
        return point_id

    def search_task_outcomes_by_signature(
        self,
        task_signature: str,
        route_id: str,
        limit: int = 50,
    ) -> list[dict[str, Any]]:
        """Search approved task outcomes by local task-signature embedding.

        Returns Qdrant hit dictionaries with `id`, `score`, and `payload`.
        Returns [] if Qdrant or local embeddings are unavailable.
        """

        spec = self._collection_spec("merlin-audit")
        self._validate_configured_embedding_dimension(spec)
        if self.degraded:
            self._log_degraded("search_task_outcomes_by_signature", spec.name)
            return []

        try:
            vector = self._embed_text(task_signature)
            self._validate_vector_dimensions(spec, vector)
        except (OSError, ValueError, DimensionMismatchError) as exc:
            logger.warning("task_signature_search_skipped route_id=%s error=%s", route_id, exc)
            return []

        body = {
            "vector": vector,
            "limit": limit,
            "with_payload": True,
            "with_vectors": False,
            "filter": {
                "must": [
                    {"key": "event_type", "match": {"value": "task_outcome"}},
                    {"key": "route_id", "match": {"value": route_id}},
                ]
            },
        }

        try:
            response = self._request_json("POST", f"/collections/{spec.qdrant_name}/points/search", body)
        except OSError:
            self._activate_degraded("search_task_outcomes_by_signature", spec.name)
            return []

        hits = response.get("result", [])
        if not isinstance(hits, list):
            return []
        approved: list[dict[str, Any]] = []
        for hit in hits:
            payload = hit.get("payload", {}) if isinstance(hit, dict) else {}
            if payload.get("approval_id"):
                approved.append({"id": hit.get("id"), "score": hit.get("score"), "payload": payload})
        return approved

    def write_skill_outcome(self, outcome: dict[str, Any]) -> str | None:
        """Write a consent-gated skill outcome record.

        This uses a neutral placeholder vector. Embeddings and semantic skill
        retrieval are intentionally deferred to a later phase.
        """

        required = {
            "agent_target",
            "skill_domain",
            "outcome_rating",
            "route_id",
            "confidence_at_routing",
            "hardware_tier",
            "created_at",
        }
        missing = sorted(key for key in required if key not in outcome)
        if missing:
            raise ValueError(f"skill outcome missing required keys: {', '.join(missing)}")
        if self.degraded:
            self._log_degraded("write_skill_outcome", SKILL_OUTCOMES_COLLECTION)
            return None

        try:
            self._ensure_skill_outcomes_collection()
        except OSError:
            return None
        point_id = str(uuid.uuid4())
        payload = {
            "agent_target": str(outcome["agent_target"]),
            "skill_domain": str(outcome["skill_domain"]),
            "outcome_rating": str(outcome["outcome_rating"]),
            "route_id": str(outcome["route_id"]),
            "confidence_at_routing": float(outcome["confidence_at_routing"]),
            "hardware_tier": str(outcome["hardware_tier"]),
            "created_at": str(outcome["created_at"]),
            "week": _iso_week(str(outcome["created_at"])),
        }
        body = {
            "points": [
                {
                    "id": point_id,
                    "vector": [0.0] * SKILL_OUTCOMES_VECTOR_SIZE,
                    "payload": payload,
                }
            ]
        }

        try:
            self._request_json("PUT", f"/collections/{SKILL_OUTCOMES_COLLECTION}/points?wait=true", body)
        except OSError:
            self._activate_degraded("write_skill_outcome", SKILL_OUTCOMES_COLLECTION)
            return None
        return point_id

    def search(self, collection: str, query: str, top_k: int = 5) -> list[dict[str, Any]]:
        spec = self._collection_spec(collection)
        self._validate_configured_embedding_dimension(spec)
        if self.degraded:
            self._log_degraded("search", collection)
            return []

        vector = self._embed_text(query)
        self._validate_vector_dimensions(spec, vector)
        body = {"vector": vector, "limit": top_k, "with_payload": True}

        try:
            response = self._request_json("POST", f"/collections/{spec.qdrant_name}/points/search", body)
        except OSError:
            self._activate_degraded("search", collection)
            return []

        return [
            {"id": item.get("id"), "score": item.get("score"), "payload": item.get("payload", {})}
            for item in response.get("result", [])
        ]

    def delete(self, collection: str, point_id: str) -> bool:
        spec = self._collection_spec(collection)
        if self.degraded:
            self._log_degraded("delete", collection)
            return False
        try:
            response = self._request_json(
                "POST",
                f"/collections/{spec.qdrant_name}/points/delete?wait=true",
                {"points": [point_id]},
            )
        except OSError:
            self._activate_degraded("delete", collection)
            return False
        return response.get("status") in {"ok", "accepted"}

    def list_collections(self) -> list[dict[str, Any]]:
        if self.degraded:
            self._log_degraded("list_collections", "*")
            return [
                {"name": spec.name, "count": None, "dims": spec.dims, "ttl": spec.ttl}
                for spec in self.collections.values()
            ]

        results: list[dict[str, Any]] = []
        for spec in self.collections.values():
            count = None
            try:
                response = self._request_json("POST", f"/collections/{spec.qdrant_name}/points/count", {"exact": True})
                count = response.get("result", {}).get("count")
            except OSError:
                self._activate_degraded("list_collections", spec.name)
            results.append({"name": spec.name, "count": count, "dims": spec.dims, "ttl": spec.ttl})
        return results

    def scroll_collection(self, collection: str, limit: int = 1000) -> list[dict[str, Any]]:
        if self.degraded:
            self._log_degraded("scroll_collection", collection)
            return []
        try:
            response = self._request_json(
                "POST",
                f"/collections/{collection}/points/scroll",
                {"limit": limit, "with_payload": True, "with_vectors": False},
            )
        except OSError:
            self._activate_degraded("scroll_collection", collection)
            return []
        result = response.get("result", {})
        if isinstance(result, dict):
            points = result.get("points", [])
            return points if isinstance(points, list) else []
        return []

    def _build_collection_specs(self) -> dict[str, CollectionSpec]:
        specs: dict[str, CollectionSpec] = {}
        distance = self.config.defaults.distance
        for name, collection in self.config.canonical.items():
            spec = CollectionSpec(
                name=name.replace("_", "-"),
                qdrant_name=name,
                dims=collection.vector_size,
                distance=distance,
                ttl=None,
                description=collection.purpose,
            )
            specs[name] = spec
            specs[spec.name] = spec

        for name, collection in self.config.legacy.items():
            spec = CollectionSpec(
                name=name,
                qdrant_name=name,
                dims=collection.vector_size,
                distance=distance,
                ttl=None,
                description=f"{collection.status}: {collection.owner}",
            )
            specs[name] = spec
        return specs

    def _collection_spec(self, collection: str) -> CollectionSpec:
        try:
            return self.collections[collection]
        except KeyError as exc:
            raise KeyError(f"Unknown memory collection: {collection}") from exc

    def _validate_configured_embedding_dimension(self, spec: CollectionSpec) -> None:
        if self.embedding_dimensions != spec.dims:
            raise DimensionMismatchError(
                "memory.yaml",
                f"collections.{spec.name}.dims",
                f"embedding model returns {self.embedding_dimensions} dims but {spec.name} expects {spec.dims}",
            )

    def _validate_vector_dimensions(self, spec: CollectionSpec, vector: list[float]) -> None:
        if len(vector) != spec.dims:
            raise DimensionMismatchError(
                "memory.yaml",
                f"collections.{spec.name}.dims",
                f"vector has {len(vector)} dims but {spec.name} expects {spec.dims}",
            )

    def _task_outcome_payload(self, outcome: dict[str, Any], task_signature: str) -> dict[str, Any]:
        allowed = {
            "event_type",
            "task_hash",
            "route_id",
            "staff_mode",
            "agent_target",
            "confidence_at_routing",
            "outcome_status",
            "latency_ms",
            "keyword_matches",
            "hardware_tier",
            "user_feedback",
            "created_at",
            "approval_id",
            "skill_domain",
            "outcome_rating",
        }
        payload = {key: outcome[key] for key in sorted(allowed) if key in outcome}
        payload["event_type"] = "task_outcome"
        payload["source"] = "task_signature_retrieval"
        payload["task_signature_hash"] = hashlib.sha256(task_signature.encode("utf-8")).hexdigest()
        payload["raw_input_stored"] = False
        return payload

    def _embed_text(self, text: str) -> list[float]:
        body = {"model": self.embedding_model, "prompt": text}
        response = self._request_absolute_json("POST", OLLAMA_EMBEDDINGS_URL, body)
        embedding = response.get("embedding")
        if not isinstance(embedding, list):
            raise ValueError("Ollama embedding response did not include an embedding list")
        return [float(value) for value in embedding]

    def _check_qdrant(self) -> None:
        try:
            self._request_json("GET", "/collections")
        except OSError:
            self._activate_degraded("startup", "*")

    def _ensure_skill_outcomes_collection(self) -> None:
        body = {"vectors": {"size": SKILL_OUTCOMES_VECTOR_SIZE, "distance": "Cosine"}}
        try:
            self._request_json("PUT", f"/collections/{SKILL_OUTCOMES_COLLECTION}", body)
        except OSError:
            self._activate_degraded("ensure_collection", SKILL_OUTCOMES_COLLECTION)
            raise

    def _activate_degraded(self, operation: str, collection: str) -> None:
        self.degraded = True
        logger.warning("Memory degraded mode active: operation=%s collection=%s", operation, collection)

    def _log_degraded(self, operation: str, collection: str) -> None:
        logger.warning("Memory degraded mode active: operation=%s collection=%s", operation, collection)

    def _request_json(self, method: str, path: str, body: dict[str, Any] | None = None) -> dict[str, Any]:
        return self._request_absolute_json(method, f"{self.qdrant_url}{path}", body)

    def _request_absolute_json(self, method: str, url: str, body: dict[str, Any] | None = None) -> dict[str, Any]:
        data = None if body is None else json.dumps(body).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        req = request.Request(url, data=data, headers=headers, method=method)
        try:
            with request.urlopen(req, timeout=self.timeout) as response:
                raw = response.read().decode("utf-8")
        except (error.URLError, TimeoutError, OSError) as exc:
            raise OSError(str(exc)) from exc
        return json.loads(raw) if raw else {}


def _iso_week(created_at: str) -> str:
    try:
        parsed = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
    except ValueError:
        return "unknown"
    year, week, _ = parsed.isocalendar()
    return f"{year}-{week:02d}"
