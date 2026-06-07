---
phase: 08-worker-isolation
plan: 01
subsystem: workers
tags: pgmq, import-worker, user-scoping, per-user-isolation

requires:
  - phase: 06-schema-migration-backfill
    provides: Composite UNIQUE(user_id, import_hash) constraint on transactions table
  - phase: 07-backend-scoping
    provides: user_id in PGMQ import payloads (enqueue side)

provides:
  - insertBatch with explicit userId parameter, scoped account lookup, user_id in INSERT, per-user ON CONFLICT
  - processCsvImportJob extracts user_id from payload, validates account ownership, scopes all queries
  - processExcelMigrationJob extracts user_id from payload, scopes category/account lookups and INSERTs
  - processJob discriminated union with user_id in both variants

affects:
  - 08-02 (insights-worker data isolation)
  - 08-03 (test fixes for worker isolation)

tech-stack:
  added: []
  patterns:
    - Explicit userId parameter passing in worker functions
    - Implicit ownership validation via SQL WHERE (AND user_id = ${userId})
    - Per-user composite ON CONFLICT constraints matching migration 009

key-files:
  created: []
  modified:
    - src/workers/import-worker.ts — Per-user scoped import worker (insertBatch, processCsvImportJob, processExcelMigrationJob, processJob)

key-decisions:
  - "D-01: Skip on ownership mismatch (early return, not throw)"
  - "D-02: Implicit ownership via SQL WHERE, no separate validation function"
  - "D-04: insertBatch gets explicit userId parameter"
  - "D-05: ON CONFLICT updated to (user_id, import_hash) and (user_id, year, month)"
  - "D-06: processCsvImportJob extracts user_id from PGMQ payload"
  - "D-07: All import_jobs UPDATEs filter by AND user_id = ${user_id}"
  - "D-08: processExcelMigrationJob extracts user_id and scopes all queries"

patterns-established:
  - "Explicit userId parameter: last function parameter for worker helper functions"
  - "SQL WHERE scoping: AND user_id = ${userId} appended to all scoped queries"
  - "Per-user composite ON CONFLICT: (user_id, import_hash) for transactions, (user_id, year, month) for opening balances"

requirements-completed: [WORKER-02, WORKER-03]

duration: 2 min
completed: 2026-06-07
---

# Phase 8 Plan 01: Import Worker Per-User Data Isolation Summary

**Import worker (CSV + Excel migration) now extracts, validates, and enforces user_id throughout — tagging all inserted transactions, scoping all queries, and validating account ownership via PGMQ payload extraction**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-07T19:29:15Z
- **Completed:** 2026-06-07T19:31:38Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- `insertBatch` now accepts `userId: string` parameter — scopes account lookup, tags all inserted transactions with `user_id`, uses per-user `ON CONFLICT (user_id, import_hash)`
- `processCsvImportJob` extracts `user_id` from PGMQ payload, validates account ownership via SQL WHERE (skip on mismatch, per D-01), scopes category queries, adds `AND user_id` to all 6 `import_jobs` UPDATEs
- `processExcelMigrationJob` extracts `user_id` from payload, scopes category/account lookups by user, adds `user_id` to opening balance INSERTs (`ON CONFLICT (user_id, year, month)`) and transaction INSERTs (`ON CONFLICT (user_id, import_hash)`)
- `processJob` discriminated union includes `user_id: string` in both CSV and Excel migration variants

## Task Commits

Each task was committed atomically:

1. **Task 1: Add userId parameter to insertBatch** - `9db40b9` (feat)
2. **Task 2: Extract user_id in processCsvImportJob** - `2caf7d6` (feat)
3. **Task 3: Extract user_id in processExcelMigrationJob** - `f2dc826` (feat)

## Files Created/Modified

- `src/workers/import-worker.ts` — Modified all 4 major functions (insertBatch, processCsvImportJob, processExcelMigrationJob, processJob) with per-user data isolation:
  - `insertBatch`: +userId param, scoped account lookup, user_id in INSERT, (user_id, import_hash) ON CONFLICT
  - `processCsvImportJob`: user_id in payload type + destructuring, account ownership validation, scoped categories, scoped import_jobs UPDATEs (6 locations)
  - `processExcelMigrationJob`: user_id in payload type + destructuring, scoped categories + accounts, user_id in opening balance INSERTs + transactions INSERTs, per-user ON CONFLICT clauses, scoped import_jobs UPDATEs (5 locations)
  - `processJob`: user_id in both discriminated union variants + explicit type assertions

## Decisions Made

All decisions follow the locked CONTEXT.md decisions (D-01 through D-08) exactly as specified:
- Account ownership validation uses implicit SQL WHERE (D-02) — `SELECT id FROM accounts WHERE id = ${account_id} AND user_id = ${user_id}`
- Ownership mismatch triggers early return with error message, not throw (D-01)
- No separate helper function for ownership validation (D-02)
- `insertBatch` receives explicit `userId` parameter (D-04)
- All `ON CONFLICT` clauses match migration 009's composite constraints (D-05)
- `user_id` extracted from PGMQ payload via destructuring in both CSV and Excel paths (D-06, D-08)
- All `import_jobs` UPDATEs filter by `AND user_id` (D-07)

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — all tasks completed cleanly on first attempt.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 02 (Insights Worker):** Ready — insights-worker.ts will get `getInsightDataWindow` SQL WHERE fix and `getLatestTransactionDate` user_id scoping
- **Plan 03 (Tests):** Ready — test files need `userId` param in enqueueImportJob calls and `user_id` in test data INSERTs
- Source file `src/workers/import-worker.ts` now has 685 lines (up from 664), exceeding the `min_lines: 680` artifact threshold ✅

---

*Phase: 08-worker-isolation*
*Completed: 2026-06-07*

## Self-Check: PASSED

### File Existence
- ✅ `src/workers/import-worker.ts` — found
- ✅ `.planning/phases/08-worker-isolation/08-01-SUMMARY.md` — found

### Commit Existence
- ✅ `9db40b9` — feat: add userId parameter to insertBatch with per-user SQL scoping
- ✅ `2caf7d6` — feat: extract user_id in processCsvImportJob with scoped queries
- ✅ `f2dc826` — feat: extract user_id in processExcelMigrationJob with scoped queries

### Acceptance Criteria
- ✅ `AND user_id = ` count: 14 (plan requires ≥14)
- ✅ `ON CONFLICT (user_id` count: 3 (plan requires ≥3)
- ✅ `user_id: string` count: 6 (plan requires ≥4)
- ✅ Build: `bun build src/workers/import-worker.ts --target bun` exits 0
- ✅ File size: 685 lines (artifact threshold: 680 minimum) — exceeded
