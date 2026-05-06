"""Merlin Qdrant memory manager with strict dimension guards."""

from __future__ import annotations

import json
import logging
import io
import uuid
from contextlib import redirect_stdout
from dataclasses import dataclass
from typing import Any
from urllib import error, request

from merlin.config_loader import DimensionMismatchError, load_all_configs


logger = logging.getLogger(__name__)

OLLAMA_EMBEDDINGS_URL = "http://localhost:11434/api/embeddings"
DEFAULT_TIMEOUT_SECONDS = 5


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

    def _embed_text(self, text: str) -> list[float]:
        body = {"model": self.embedding_model, "prompt": text}
        response = self._request_absolute_json("POST", OLLAMA_EMBEDDINGS_URL, body)
        embedding = response.get("embedding")
        if not isinstance(embedding, list):
            raise ValueError("Ollama embedding response did not include an embedding list")
        return [float(value) for value in embedding]

    def _check_qdrant(self) -> None:
        try:
            self._request_json("GET", "/healthz")
        except OSError:
            self._activate_degraded("startup", "*")

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
