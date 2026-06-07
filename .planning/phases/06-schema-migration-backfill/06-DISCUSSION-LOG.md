# Phase 6: Schema Migration & Backfill - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 6-Schema Migration & Backfill
**Areas discussed:** Backfill strategy, Migration order & nullability, Composite index selection, import_hash scoping, Down-migration strategy

---

## Backfill Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Earliest by createdAt | SELECT id FROM "user" ORDER BY createdAt ASC LIMIT 1 | |
| Admin/specific user ID | Hardcode or config a specific user ID | |
| User freeform response | "doesnt matter, we wipe db and start over before onboarding new users we will import data" | ✓ |

**User's choice:** DB will be wiped before onboarding users. No backfill needed.
**Notes:** Dramatically simplifies the migration — no nullable columns, no "first user" logic.

---

## Migration Order & Nullability

| Option | Description | Selected |
|--------|-------------|----------|
| Single migration | One .sql file with all ALTER TABLE, DROP/ADD CONSTRAINT, CREATE INDEX | |
| Split by concern | Separate files: add columns, update constraints, add indexes | ✓ |
| You decide | Let agent choose | |

**User's choice:** Split by concern.
**Notes:** Multiple migration files — one per logical operation.

---

## Composite Index Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Full coverage | (user_id, account_id, date DESC) + (user_id, category_id) + (user_id, date, type) + etc. | |
| Minimal essential | Only (user_id, name) for UNIQUE constraints and (user_id, import_hash) | ✓ |
| You decide | Let agent choose | |

**User's choice:** Minimal essential — only what constraints require.

---

## import_hash Scoping

| Option | Description | Selected |
|--------|-------------|----------|
| Per-user constraint is enough | UNIQUE(user_id, import_hash) prevents cross-user collisions | |
| Also add account_id to hash | Update computeImportHash to include account_id | ✓ |
| You decide | Let agent choose | |

**User's choice:** Also add account_id to hash.
**Notes:** Hash becomes SHA-256 of `date|amount|description|account_id`.

---

## Down-migration Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Drop columns (destructive) | DROP COLUMN user_id, restore old constraints | ✓ |
| No-op stubs | Down migration does nothing | |
| You decide | Let agent choose | |

**User's choice:** Drop columns (destructive).
**Notes:** Supports Phase 9 rollback test (TEST-05) — proper up/down round-trip.

---

## Deferred Ideas

- **Hash algorithm update timing** — `computeImportHash` changes could be done in this phase or deferred to Phase 8 (worker isolation).
