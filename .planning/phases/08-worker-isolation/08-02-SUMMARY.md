---
phase: 08-worker-isolation
plan: 02
subsystem: insights, ledger, import
tags: sql-scoping, user-isolation, pgmq-payload, entity-types

requires:
  - phase: 07-backend-scoping
    provides: userId parameter pattern, enqueueImportJob with user_id in PGMQ payload
provides:
  - Per-user scoped getLatestTransactionDate(userId) with WHERE user_id = ${userId}
  - getInsightDataWindow now actually filters by AND t.user_id = ${userId}
  - getCategoryAggregates gets userId param for scoped anchor date
  - createTransaction auto-trigger PGMQ payload includes user_id for worker context
  - ImportJob entity type now reflects user_id column in DB schema
affects: 08-03

tech-stack:
  added: []
  patterns:
    - "Insights use-cases: userId param always propagated and applied in SQL WHERE"
    - "PGMQ enqueue: all analysis_queue messages carry user_id in payload"

key-files:
  created: []
  modified:
    - src/core/insights/use-cases.ts
    - src/workers/insights-worker.ts
    - src/core/ledger/use-cases.ts
    - src/core/import/entities.ts

key-decisions:
  - "getCategoryAggregates receives userId as 2nd param (after transactionIds) — consistent with other insights use-cases"
  - "createTransaction auto-trigger payload matches enqueueAnalysisJob payload pattern: carries user_id for worker context"

patterns-established:
  - "Insights use-cases follow userId propagation pattern: accept as explicit param, pass through to all scoped SQL queries"
  - "PGMQ analysis_queue messages uniformly carry user_id — both manual enqueueAnalysisJob and auto-triggered createTransaction"

requirements-completed: [WORKER-01, WORKER-04]

duration: 1min
completed: 2026-06-07
---

# Phase 8: Worker Isolation — Plan 02 Summary

**Per-user SQL scoping in insights queries, createTransaction auto-trigger payload, and ImportJob entity type**

## Performance

- **Duration:** 1 min
- **Started:** 2026-06-07T19:33:18Z
- **Completed:** 2026-06-07T19:34:24Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Fixed `getLatestTransactionDate` — added `userId: string` param and `WHERE user_id = ${userId}` SQL clause, preventing cross-user date-window skew (D-10)
- Fixed `getInsightDataWindow` — `userId` param now actually passed to `getLatestTransactionDate(userId)` and `AND t.user_id = ${userId}` added to WHERE clause (D-09)
- Fixed `getCategoryAggregates` — added `userId: string` as 2nd param, passes it to `getLatestTransactionDate(userId)` for scoped anchor (D-09 propagation)
- Fixed `insights-worker.ts` call site — passes `userId` to `getCategoryAggregates(txIds, userId)`
- Fixed `createTransaction` auto-trigger — PGMQ payload now includes `user_id: input.userId` alongside `transaction_id: tx.id`, so the insights worker has user context (fixes Pitfall #5 — current auto-triggered analysis throws `Error('Message payload missing user_id')`)
- Added `user_id: string` to `ImportJob` entity interface — aligns TypeScript type with actual database schema

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix getLatestTransactionDate and getInsightDataWindow SQL WHERE clauses** — `1c7524d` (fix)
2. **Task 2: Fix getCategoryAggregates anchor + createTransaction auto-trigger** — `498d2b5` (fix)
3. **Task 3: Add user_id field to ImportJob entity interface** — `23dafc5` (feat)

## Files Created/Modified

- `src/core/insights/use-cases.ts` — `getLatestTransactionDate(userId)` with scoped SQL; `getInsightDataWindow` with `AND t.user_id = ${userId}` in WHERE; `getCategoryAggregates(transactionIds, userId)` passes userId for anchor
- `src/workers/insights-worker.ts` — `getCategoryAggregates(txIds, userId)` call passes userId
- `src/core/ledger/use-cases.ts` — `createTransaction` PGMQ payload includes `user_id: input.userId`
- `src/core/import/entities.ts` — `ImportJob.user_id: string` field added

## Decisions Made

- `getCategoryAggregates` receives `userId` as 2nd param (after `transactionIds`) — consistent with explicit-param pattern used across all insights use-cases
- `createTransaction` auto-trigger payload matches the same structure as `enqueueAnalysisJob` payload — both now carry `user_id` so `processAnalysisMessage` has user context regardless of trigger source

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — all changes were straightforward, no compilation errors or unexpected callers.

## Next Phase Readiness

- Insights data window queries are now properly scoped per user (D-09, D-10)
- `createTransaction` auto-trigger no longer silently fails — payload carries `user_id`
- ImportJob type reflects actual DB schema
- Ready for Plan 08-03 (import-worker user isolation)

---

*Phase: 08-worker-isolation*
*Completed: 2026-06-07*
