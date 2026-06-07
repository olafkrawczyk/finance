---
phase: 08-worker-isolation
plan: 03
subsystem: tests
tags: integration-tests, worker-isolation, user-scoping, user_id

# Dependency graph
requires:
  - phase: 08-01
    provides: Per-user scoped import worker (insertBatch with userId, processCsvImportJob with user_id)
  - phase: 08-02
    provides: Per-user scoped insights queries, ImportJob entity with user_id

provides:
  - Updated import-worker.test.ts with userId param, user_id assertions, and working test setup
  - Updated insights-worker.test.ts with user_id column in test data INSERTs and fixed mock server

affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Test beforeAll setup: user lookup/creation fallback, account creation with user_id"
    - "Mock server: handle both response_format and plain model-based request routing"

key-files:
  created: []
  modified:
    - tests/import-worker.test.ts — userId params, user_id assertions, account/user setup
    - tests/insights-worker.test.ts — user_id in INSERTs, mock server forecast fix

key-decisions:
  - "Tests create test users/accounts when seed data is missing — enables running tests in isolation without seeded DB state"

requirements-completed: [WORKER-02, WORKER-03, WORKER-04]

# Metrics
duration: 8 min
completed: 2026-06-07
---

# Phase 8 Plan 03: Worker Isolation Tests Summary

**Import worker and insights worker integration tests updated to pass userId/user_id parameters matching per-user data isolation — both test files run clean with 0 failures**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-07T19:31:00Z
- **Completed:** 2026-06-07T19:39:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- **import-worker.test.ts** — Added `userId` variable with DB lookup in beforeAll; `userId` param added to `enqueueImportJob` call; added `expect(job.user_id).toBe(userId)` assertion; added `expect(txsWithUser.every(t => t.user_id === userId))` verification; fixed account creation fallback and `recoverStuckJobs` INSERT to include `user_id` (NOT NULL constraint)
- **insights-worker.test.ts** — Added `user_id` to category fallback INSERT; added `user_id` to account fallback INSERT; added `user_id` column to transaction INSERTs in beforeAll; fixed mock server to handle DeepSeek forecast requests (which don't send `response_format`)

## Task Commits

Each task was committed atomically:

1. **Task 1: Update import-worker.test.ts** — `bdc5a23` (fix)
2. **Task 2: Update insights-worker.test.ts** — `502aa6d` (fix)

## Files Created/Modified

- `tests/import-worker.test.ts` (±32/-5 lines, 181 total) — Added `userId` variable, beforeAll user lookup, account creation fallback, `userId` param in `enqueueImportJob`, `job.user_id` assertion, transaction `user_id` verification, and `user_id` in `recoverStuckJobs` INSERT
- `tests/insights-worker.test.ts` (±9/-8 lines, 243 total) — Added `user_id` to category/account/transaction INSERTs, fixed mock server forecast handler

## Decisions Made

- Tests now create their own users and accounts as fallback when seed data is missing — this makes the tests self-sufficient and not dependent on DB seed state

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Import-worker test couldn't find enough seeded accounts**
- **Found during:** Task 1 (import-worker.test.ts)
- **Issue:** The beforeAll queried for accounts but fewer than 2 existed in the test DB, causing immediate throw
- **Fix:** Added account creation fallback in beforeAll — if fewer than 2 accounts found, creates them with the test user's `user_id`
- **Files modified:** `tests/import-worker.test.ts`
- **Verification:** Test passes with 2/2 passing
- **Committed in:** `bdc5a23` (Task 1 commit)

**2. [Rule 3 - Blocking] recoverStuckJobs test INSERT missing user_id**
- **Found during:** Task 1 (import-worker.test.ts)
- **Issue:** `import_jobs.user_id` is NOT NULL, but the `recoverStuckJobs` test's direct SQL INSERT didn't include `user_id`
- **Fix:** Added `user_id` column and `${userId}` value to the INSERT
- **Files modified:** `tests/import-worker.test.ts`
- **Verification:** `recoverStuckJobs` test passes
- **Committed in:** `bdc5a23` (Task 1 commit)

**3. [Rule 3 - Blocking] Insights worker mock server returned 404 for forecasts**
- **Found during:** Task 2 (insights-worker.test.ts)
- **Issue:** `callDeepSeekForForecast` doesn't send `response_format` in request body, so the mock server's `schemaName === 'forecast_response'` check failed, causing 404 and 0 forecasts returned. The test asserted `forecastInsight` is defined but it was undefined.
- **Fix:** Updated condition to also match when `body.model` includes `'deepseek'` — handles both `response_format`-based and model-based request routing
- **Files modified:** `tests/insights-worker.test.ts`
- **Verification:** Full round-trip test now passes — both narrative alerts and forecasts are generated
- **Committed in:** `502aa6d` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** All fixes were necessary for the tests to compile and pass. None represent scope creep — they're pre-existing issues exposed by the `user_id` NOT NULL constraints.

## Issues Encountered

- **Pre-existing full suite failures:** The full `bun test` suite shows 21 failures in unrelated test files (ledger tests — auto-trigger `user_id` issue from Plan 02; UI tests — Polish text assertions; API tests — missing seed data; insights-llm test — mock server format handling). These are out of scope for Plan 03 and pre-date these changes.

## Known Stubs

None — both test files are fully wired and all test assertions pass.

## Threat Flags

None — test updates align test data with production schema. No new security surface introduced.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Both worker test files now fully reflect the per-user data isolation model
- Tests create their own test data when seed data is unavailable — robust against test environment variations
- Ready for Phase 09 (next in the milestone sequence)

## Self-Check: PASSED

### File Existence
- ✅ `tests/import-worker.test.ts` — found (181 lines, threshold 155)
- ✅ `tests/insights-worker.test.ts` — found (243 lines, threshold 242)
- ✅ `.planning/phases/08-worker-isolation/08-03-SUMMARY.md` — found

### Commit Existence
- ✅ `bdc5a23` — fix(08-03): update import-worker.test.ts with userId param and user_id assertions
- ✅ `502aa6d` — fix(08-03): update insights-worker.test.ts with user_id column in INSERTs

### Acceptance Criteria
- ✅ `let userId: string;` declared in describe scope
- ✅ `userId` assigned in `beforeAll` from DB query
- ✅ `enqueueImportJob` call includes `userId` parameter
- ✅ `expect(txsWithUser.every(t => t.user_id === userId)).toBe(true)` assertion exists
- ✅ `expect(job.user_id).toBe(userId)` assertion exists
- ✅ INSERT column list includes `user_id` 
- ✅ VALUES include `${userId}` for both rows
- ✅ `bun test tests/import-worker.test.ts` — 2 pass, 0 fail
- ✅ `bun test tests/insights-worker.test.ts` — 6 pass, 0 fail

---

*Phase: 08-worker-isolation*
*Completed: 2026-06-07*
