# Plan 02-02 Summary: Import Schema & Domain

Completed on 2026-06-06.

## Deliverables
- [x] **Database Schema**: Appended `import_jobs` table to `schema.sql` including the `updated_at` column, indexes on `account_id` and `status`, and a trigger to automatically update `updated_at`. Also added Better Auth tables to support testing.
- [x] **Database Seed**: Added idempotent `import_queue` creation via pgmq in `seed.sql`.
- [x] **Database Health**: Extended `src/infrastructure/db/health.ts` to report `import_queue` readiness.
- [x] **Domain Entities**: Created `src/core/import/entities.ts` containing the TS interfaces `ImportJob` and `ParsedTransaction`.
- [x] **Validation Schemas**: Created `src/application/schemas/import.ts` exporting Zod validation schemas: `ImportUploadSchema`, `ImportStatusQuerySchema`, and `ParsedTransactionSchema`.
- [x] **Tests**: Created `tests/import-schemas.test.ts` to verify Zod validations and queue health. Updated health check assertion in `tests/api.test.ts` to prevent test breakages.

## Verification Results
- Database migrations applied successfully via `bun run src/infrastructure/db/apply.ts`.
- `bun test tests/import-schemas.test.ts` runs 100% green.
