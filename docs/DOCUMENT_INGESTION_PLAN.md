# Document Ingestion Plan

Status: v1.2 planning. No ingestion runtime, parser dependency, or background
indexer is added by this document.

Document ingestion is valuable, but it can also overload 8GB Macs and create
privacy risk if files are indexed without clear consent. The first version must
be explicit, local-only, reversible, and small-batch by default.

## MVP Scope

- User selects files or a folder explicitly.
- Merlin shows estimated size, file count, and hardware-tier warning before
  indexing.
- Writes require memory approval.
- Chunks are written only to a document collection with the correct vector
  dimension.
- Raw source paths are redacted from logs.
- No cloud parsing or cloud embedding.
- No background folder watcher by default.

## Not In MVP

- Automatic indexing of home directories.
- Email, iCloud, Google Drive, Dropbox, or network share crawling.
- Browser history ingestion.
- OCR-heavy pipelines on 8GB by default.
- Cloud document parsing.
- Self-training or fine-tuning on documents.

## Hardware Policy

| Tier | Ingestion behavior |
|---|---|
| `low` 8-15GB | Small batches only; warn before PDFs; no OCR-heavy jobs by default |
| `base` 16-23GB | Limited batches; one ingestion job at a time |
| `mid` 24-47GB | Moderate batches; scheduled indexing only after approval |
| `high` 48GB+ | Larger local indexes, still approval-gated |

## Candidate Adapters

These projects can influence the adapter design, but should not become required
dependencies until a dedicated implementation issue justifies them:

- Docling for structured document parsing.
- Unstructured for broad file-type parsing.
- PyMuPDF or `pypdf` for lightweight PDF text extraction.
- Tesseract only as an optional OCR path.

## Collection Safety

The current memory system has strict dimension rules. Document ingestion must
not write 768-dimensional `nomic-embed-text` vectors into the legacy
1536-dimensional `documents` collection.

Before implementation, choose one of these explicitly:

1. Use an existing 768-dimensional Merlin document collection.
2. Keep `documents` as 1536-dimensional and gate any cloud embedding/API-key
   behavior behind approval.
3. Create a new local-only 768-dimensional document collection and document the
   migration path.

## Manual Test Plan For Future Implementation

```bash
python merlin/config_loader.py
bash scripts/doctor.sh
bash cli/wizard merlin memory plan --memory-type document --text "test"
```

Future ingestion tests must verify:

- 8GB low tier refuses or warns on large batches.
- Memory writes require approval.
- Dimension mismatch raises before any write.
- Raw file paths and secrets are not logged.
- Qdrant down results in degraded mode, not data loss or crash.
- Deleting indexed documents removes the associated vectors.

