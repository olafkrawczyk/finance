# Plan 02-03 Summary: Import API

Completed on 2026-06-06.

## Deliverables
- [x] **use-cases.ts**: Implemented `detectFormat` (auto-detects 'ing' vs 'ipko'), `enqueueImportJob` (inserts record + sends pgmq message inside an atomic `sql.begin` block), and `getImportStatus`.
- [x] **import.ts (API)**: Implemented authenticated `POST /import` (decodes arrayBuffer with `windows-1250` via `iconv-lite` to resolve diacritics correctly) and `GET /import/:job_id` status retrieval routes.
- [x] **index.ts**: Registered the import routes under `/import`.
- [x] **tests/import-api.test.ts**: Added integration tests checking route security, validation, job enqueuing, and status retrieval.
- [x] **tests/import-dedup.test.ts**: Added integration tests proving deterministic SHA-256 generation and database-level deduplication via unique constraints.

## Verification Results
- `bun test tests/import-api.test.ts tests/import-dedup.test.ts` runs 100% green.
