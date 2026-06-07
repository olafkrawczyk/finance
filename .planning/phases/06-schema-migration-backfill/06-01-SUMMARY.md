---
phase: 06-schema-migration-backfill
plan: 01
subsystem: database
tags: [postgresql, node-pg-migrate, schema-migration, user-id, constraints, indexes]

# Dependency graph
requires:
  - phase: 05-polishing-deploy
    provides: Docker deployment with automated DB migrations (node-pg-migrate SQL pattern)
provides:
  - user_id columns with FK to "user"(id) on all 6 domain tables
  - Per-user composite UNIQUE constraints replacing global UNIQUE on 4 tables
  - Documentation confirming D-04 minimal essential index policy
affects: [07-query-scoping, 08-worker-isolation, 09-rollback-test]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ALTER TABLE ADD COLUMN with NOT NULL FK referencing TEXT user id"
    - "DROP/ADD UNIQUE CONSTRAINT with IF EXISTS / IF NOT EXISTS safety"
    - "Comment-only documentation migration for no-op index decisions"

key-files:
  created:
    - src/infrastructure/db/migrations/008_add_user_id_columns.sql
    - src/infrastructure/db/migrations/009_update_uniques.sql
    - src/infrastructure/db/migrations/010_add_indexes.sql
  modified: []

key-decisions:
  - "D-01 followed: DB wiped before onboarding, user_id added as NOT NULL directly"
  - "D-03 followed: migrations split by concern (columns, constraints, indexes)"
  - "D-04 followed: no extra indexes beyond constraint-created ones"
  - "D-05 followed: UNIQUE(import_hash) → UNIQUE(user_id, import_hash)"
  - "D-07 followed: all 3 migrations include down migrations"

patterns-established:
  - "ALTER TABLE ADD COLUMN ... REFERENCES "user"(id) uses TEXT type to match Better Auth convention"
  - "DROP CONSTRAINT IF EXISTS used on all constraint drops for safety per Pitfall 1"
  - "ADD CONSTRAINT IF NOT EXISTS used in down migrations for idempotency"
  - "Comment-only migrations document index decisions without DDL"

requirements-completed: [SCHEMA-01, SCHEMA-02, SCHEMA-03, SCHEMA-04, SCHEMA-05, SCHEMA-06, SCHEMA-07, SCHEMA-08, SCHEMA-09, SCHEMA-10, SCHEMA-11]

# Metrics
duration: 4 min
completed: 2026-06-07
---

# Phase 6 Plan 1: Schema Migration Files Summary

**Three SQL migration files adding user_id columns, per-user UNIQUE constraints, and index documentation to all 6 domain tables using node-pg-migrate marker-based SQL pattern**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-07T16:10:30Z
- **Completed:** 2026-06-07T16:14:30Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- **008_add_user_id_columns.sql:** Added `user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE` to all 6 domain tables (accounts, categories, transactions, monthly_opening_balances, assets, import_jobs) with full down migration
- **009_update_uniques.sql:** Replaced 4 global UNIQUE constraints with per-user composite UNIQUE constraints (categories/assets name, transactions import_hash, monthly_opening_balances year+month) using `DROP CONSTRAINT IF EXISTS` safety pattern
- **010_add_indexes.sql:** Comment-only migration documenting that UNIQUE constraints from 009 create all required btree indexes per D-04, with idx_mob_year_month retention noted as deferred

## Task Commits

Each task was committed atomically:

1. **Task 1: Create 008_add_user_id_columns.sql** — `b44add5` (feat)
2. **Task 2: Create 009_update_uniques.sql** — `cd8b344` (feat)
3. **Task 3: Create 010_add_indexes.sql** — `a383a38` (feat)

## Files Created
- `src/infrastructure/db/migrations/008_add_user_id_columns.sql` — 6 ALTER TABLE ADD COLUMN user_id (up) + 6 DROP COLUMN user_id (down)
- `src/infrastructure/db/migrations/009_update_uniques.sql` — 4 DROP/ADD UNIQUE constraint pairs (up) + reverse (down)
- `src/infrastructure/db/migrations/010_add_indexes.sql` — Comment-only migration documenting constraint-created indexes

## Decisions Made
None — plan executed exactly as specified. All decisions (D-01 through D-10) were already locked in CONTEXT.md and followed precisely.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Minor: Plan's automated verification for 009 counted `grep -c "user_id"` expecting 4 hits, but constraint names appear in both Up and Down sections giving 8 hits. This is correct behavior — all constraint names verified individually and the migration structure is sound. No functional impact.

## Threat Flags

No new security-relevant surface introduced. Threat mitigations T-06-01 (ON DELETE CASCADE) and T-06-02 (DROP CONSTRAINT IF EXISTS) both properly applied.

## Next Phase Readiness

- Three migrations ready for application via `bun src/infrastructure/db/migrate.ts up`
- Plan 02 (schema.sql update) can proceed as the next plan in Phase 6
- Phase 7 (Query Scoping) depends on these migrations being applied first

## Self-Check: PASSED

All 3 migration files exist on disk. All 4 commits (3 task commits + 1 metadata commit) verified in git log.

---

*Phase: 06-schema-migration-backfill*
*Completed: 2026-06-07*
