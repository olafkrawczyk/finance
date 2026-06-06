---
phase: 03-views-categorization
plan: 01
subsystem: api
tags: [postgres, hono, zod, testing]

# Dependency graph
requires:
  - phase: 02-ingestion-auth
    provides: [auth middleware, transactions ledger]
provides:
  - PATCH /transactions/:id/category endpoint for category assignment
  - Updated immutability trigger allowing category-id assignment from NULL to non-null
  - Database migration 003_allow_category_update.sql
affects: [03-views-categorization]

# Tech tracking
tech-stack:
  added: []
  patterns: [Zod route validation, db exception handling]

key-files:
  created: [src/infrastructure/db/migrations/003_allow_category_update.sql]
  modified: [src/infrastructure/db/schema.sql, src/application/schemas/ledger.ts, src/interface-adapters/api/ledger.ts, tests/api.test.ts]

key-decisions:
  - "Decided to relax database transaction immutability specifically for setting category_id on previously uncategorized rows while keeping all other fields fully immutable."

patterns-established:
  - "Pattern: DB-level immutable trigger exception logic for specific column updates from NULL -> non-null"

requirements-completed:
  - REQ-2.3

# Metrics
duration: 10min
completed: 2026-06-06
---

# Phase 3 Plan 1: Backend Categorization Foundation Summary

**Implemented the `PATCH /transactions/:id/category` Hono endpoint, updated the DB immutability trigger to allow NULL-to-non-null category assignment, and successfully ran the migration on PostgreSQL.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-06T13:34:25Z
- **Completed:** 2026-06-06T13:43:30Z
- **Tasks:** 3 completed
- **Files modified/created:** 5

## Accomplishments
- Modified the PostgreSQL immutability function `block_immutable_change()` to permit updating `category_id` from NULL to a non-null UUID, while maintaining strict immutability checks on all other transaction fields.
- Created and successfully applied database migration `003_allow_category_update.sql` to relax the immutability trigger in running Postgres container.
- Added `AssignCategorySchema` Zod validation in `src/application/schemas/ledger.ts`.
- Implemented Hono handler for `PATCH /transactions/:id/category` requiring session authentication and validating input.
- Added thorough integration tests confirming that unauthenticated patches fail, invalid formats reject, categorization succeeds, double-categorization fails, and modifications of other fields are blocked.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace immutability trigger + create migration file** - `53213b8` (feat)
2. **Task 2: Add AssignCategorySchema + PATCH /transactions/:id/category endpoint** - `e274325` (feat)
3. **Task 3: Push database migration to running Postgres** - executed inline, tested in `9e5f2c8` (test)

**Plan metadata/tests:** `9e5f2c8` (test: add integration tests for PATCH /transactions/:id/category and immutability trigger)

## Files Created/Modified
- [schema.sql](file:///home/olafk/finance/src/infrastructure/db/schema.sql) - Updated `block_immutable_change()` trigger function
- [003_allow_category_update.sql](file:///home/olafk/finance/src/infrastructure/db/migrations/003_allow_category_update.sql) - Migration file for trigger updates
- [ledger.ts](file:///home/olafk/finance/src/application/schemas/ledger.ts) - Added `AssignCategorySchema`
- [ledger.ts](file:///home/olafk/finance/src/interface-adapters/api/ledger.ts) - Implemented `PATCH /transactions/:id/category` route
- [api.test.ts](file:///home/olafk/finance/tests/api.test.ts) - Integration tests for the new endpoint and trigger exceptions

## Decisions Made
- Allowed `category_id` setting on previously uncategorized rows while keeping all other fields fully immutable. This supports the bank CSV ingestion workflow where transactions import with no category and are assigned one later in the UI.

## Deviations from Plan
None - plan executed exactly as written.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Backend database schema and API routing are fully ready to support transaction categorization.
- Ready to begin frontend implementation for Zbiorczy view, Monthly view, and categorization/manual entry forms.

---
*Phase: 03-views-categorization*
*Completed: 2026-06-06*
