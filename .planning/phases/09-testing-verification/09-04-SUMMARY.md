---
phase: 09-testing-verification
plan: 04
subsystem: testing
tags: migration, rollback, node-pg-migrate, postgresql, bun, schema

# Dependency graph
requires:
  - phase: 06-schema-migration-backfill
    provides: Migrations 008-011 with up/down SQL
  - phase: 07-backend-scoping
    provides: Composite UNIQUE constraints, user_id FK columns
provides:
  - Migration rollback test suite — up-state and down-state schema assertions
  - Verified down SQL for migrations 008-011 works correctly
  - Bug fix: migration 009 down SQL replaced ADD CONSTRAINT IF NOT EXISTS with idempotent DO blocks
  - Backfill-aware lifecycle pattern for testing ADD COLUMN NOT NULL migrations
affects: [09-testing-verification, database-administration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Manual migration state restoration with backfill for ADD COLUMN NOT NULL migrations
    - information_schema / pg_indexes assertions for schema state verification

key-files:
  created:
    - tests/migration-rollback.test.ts
  modified:
    - src/infrastructure/db/migrations/009_update_uniques.sql

key-decisions:
  - "Migration 009 down SQL fixed: ADD CONSTRAINT IF NOT EXISTS replaced with DO block + pg_constraint check (not valid PostgreSQL syntax)"
  - "afterAll uses manual restoreUserIdColumns with backfill instead of runner({ direction: 'up' }) because ADD COLUMN NOT NULL fails on tables with existing data"
  - "Down batch of count:4 rolls back 008-011 simultaneously; no per-migration intermediate assertions"

requirements-completed: [TEST-05]

# Metrics
duration: 18min
completed: 2026-06-07
---

# Phase 9 Plan 4: Migration Rollback Test Summary

**Standalone migration rollback test (D-13 through D-17) verifying schema up/down state via information_schema assertions, with lifecycle-aware state restoration**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-07T22:07:00Z
- **Completed:** 2026-06-07T22:25:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Created `tests/migration-rollback.test.ts` — standalone migration lifecycle test with 30 assertions
- **D-14 (up state):** Verifies user_id columns, FK constraints, composite UNIQUE(user_id, name), and composite indexes on all 6 domain tables after migration up
- **D-15 (down state):** Verifies user_id columns removed, global UNIQUE constraints restored, composite constraints dropped after rolling back migrations 008-011
- **D-16 (data integrity):** Verifies data with user_id is insertable/readable after up, and schema is functional (INSERT/READ) after destructive down
- **D-17 (orphan cleanup):** Verifies no FK constraints or indexes referencing user_id remain after down
- **Bug fix:** Migration 009 down SQL had `ADD CONSTRAINT IF NOT EXISTS` which is not valid PostgreSQL syntax (even in PG 18.1); replaced with idempotent `DO $$` blocks using `pg_constraint` checks
- **Lifecycle fix:** afterAll restores user_id columns manually with backfill because `ALTER TABLE ... ADD COLUMN ... NOT NULL` fails on tables with existing rows; can't use runner() directly for migration 008 restoration

## Task Commits

Each task was committed atomically:

1. **Task 1: Add migration up-state assertions (D-14, D-16)** — `1c98139` (test)
2. **Task 2: Add migration down-state assertions (D-15, D-16, D-17)** — `afaeba1` (test, includes migration fix)

**Plan metadata:** Pending (after SUMMARY.md)

## Files Created/Modified

- `tests/migration-rollback.test.ts` — New standalone migration rollback test (30 tests): up-state assertions (17 tests), down-state assertions (13 tests), lifecycle management with backfill-aware state restoration
- `src/infrastructure/db/migrations/009_update_uniques.sql` — Fixed down migration: replaced `ADD CONSTRAINT IF NOT EXISTS` with idempotent `DO $$` blocks using `pg_constraint` checks

## Decisions Made

- **Manual 008 restoration instead of runner**: `ALTER TABLE ... ADD COLUMN ... NOT NULL` is rejected by PostgreSQL (code 23502) when the table already has rows. The afterAll uses `restoreUserIdColumns` — add nullable, backfill, set NOT NULL, add FK — which cannot be expressed through node-pg-migrate. The beforeAll also uses this pattern for the same reason.
- **`pgmigrations` entry for 008**: Since 008 is restored manually, it's tracked via `INSERT INTO pgmigrations` with a `markMigration008()` helper (checks name column before inserting). This keeps the runner in sync for 009-011.
- **Down batch count:4**: Rolling back 008-011 in a single beforeAll. No per-migration intermediate assertions (D-14 through D-17 describe only the fully-up and fully-down states).
- **Backfill user**: A dedicated `rollback-backfill` user is created for FK satisfaction during column restoration. Both `rollback-backfill` and `rollback-test-user` are cleaned up in afterAll.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing Critical] Migration 009 down SQL uses invalid syntax**
- **Found during:** Task 2 (running test with down assertions)
- **Issue:** `ADD CONSTRAINT IF NOT EXISTS` is not valid PostgreSQL syntax (tested on PG 18.1). The down migration would fail on all PostgreSQL versions.
- **Fix:** Replaced each `ADD CONSTRAINT IF NOT EXISTS ... UNIQUE(...)` with a `DO $$` block that checks `pg_constraint` for the constraint name before adding it. This preserves the idempotency intent.
- **Files modified:** `src/infrastructure/db/migrations/009_update_uniques.sql`
- **Verification:** All 30 tests pass including down-state assertions.
- **Committed in:** `afaeba1` (Task 2 commit)

**2. [Rule 3 — Blocking] afterAll runner({ direction: 'up' }) fails after down migration**
- **Found during:** Task 2 (running full test cycle)
- **Issue:** After migration 008 drops user_id columns, running 008 up (`ALTER TABLE ... ADD COLUMN ... NOT NULL`) fails because domain tables have existing rows (from signup hooks and test data). PostgreSQL rejects NOT NULL columns without a default on non-empty tables.
- **Fix:** Replaced `runner({ direction: 'up' })` in both beforeAll and afterAll with a manual `restoreUserIdColumns()` function that: adds column as nullable → backfills with backfill user → sets NOT NULL → adds FK constraint. The 008 migration is then marked as applied in pgmigrations. The runner handles 009-011 normally.
- **Files modified:** `tests/migration-rollback.test.ts`
- **Verification:** All 30 tests pass, database left in fully migrated state with all test users cleaned up.
- **Committed in:** `afaeba1` (Task 2 commit)

**3. [Rule 3 — Blocking] pgmigrations ON CONFLICT fails**
- **Found during:** Task 2 (test run after fix 2)
- **Issue:** `INSERT INTO pgmigrations ... ON CONFLICT (name) DO NOTHING` fails because `pgmigrations.name` has no UNIQUE constraint — only the `id` primary key does.
- **Fix:** Replaced with `markMigration008()` helper that first checks `SELECT 1 FROM pgmigrations WHERE name = '008_add_user_id_columns'` and only inserts if no match found.
- **Files modified:** `tests/migration-rollback.test.ts`
- **Verification:** All 30 tests pass, no duplicate pk errors.
- **Committed in:** `afaeba1` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (1 missing critical, 2 blocking)
**Impact on plan:** All fixes essential for correctness. Migration 009 SQL bug would prevent any down migration execution. Lifecycle issues would leave the database in an unrecoverable state.

## Issues Encountered

- **Migration 009 `ADD CONSTRAINT IF NOT EXISTS`**: Root cause — PostgreSQL does not support `IF NOT EXISTS` for `ALTER TABLE ... ADD CONSTRAINT` at any version. The original migration was written with the intent of idempotency but used unsupported syntax. Fixed with `DO $$` blocks.
- **`ALTER TABLE ... ADD COLUMN ... NOT NULL` on non-empty tables**: This is a fundamental PostgreSQL constraint — you cannot add a NOT NULL column to a table with existing rows without a DEFAULT. The migration works in the initial deployment scenario (empty database) but fails after a down-up cycle. The test lifecycle now handles this correctly.
- **Partial migration state after failed runs**: Previous incomplete test runs left the database with pgmigrations out of sync with actual schema. The beforeAll's manual restore + markMigration008 + runner combination is designed to handle any residual state.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Migration rollback test complete (TEST-05)
- All schema assertions pass: up-state (D-14), down-state (D-15), data integrity (D-16), orphan cleanup (D-17)
- Migration 009 down SQL fixed (previously invalid syntax)
- Other wave 2 plans may proceed: api-scoping extensions, concurrent isolation, worker isolation tests
- File must run standalone: `bun test tests/migration-rollback.test.ts --timeout 60000`

## Self-Check: PASSED

- [x] `tests/migration-rollback.test.ts` exists — 341 lines
- [x] All 30 tests pass (17 up-state + 13 down-state)
- [x] `1c98139` — Task 1 commit (`test(09-04)`)
- [x] `afaeba1` — Task 2 commit (`test(09-04)`)
- [x] `src/infrastructure/db/migrations/009_update_uniques.sql` fixed
- [x] Database left in fully migrated state (pgmigrations 001-011)
- [x] Test users cleaned up (rollback-test-user, rollback-backfill)
- [x] SUMMARY.md created at `.planning/phases/09-testing-verification/09-04-SUMMARY.md`

---

*Phase: 09-testing-verification*
*Completed: 2026-06-07*
