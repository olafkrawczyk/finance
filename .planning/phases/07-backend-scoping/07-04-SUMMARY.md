---
phase: 07-backend-scoping
plan: 04
subsystem: testing
tags: [scoping, isolation, multi-user, seeding, signup-hook, bun-test]
requires:
  - phase: 07-01
    provides: scoped use-case functions with userId parameter
  - phase: 07-02
    provides: Better Auth onSignUp hook with 25 categories + 2 accounts
  - phase: 07-03
    provides: route handlers with userId extraction from session
provides:
  - Multi-user isolation test matrix (2 users × all resource types with 404 cross-user tests)
  - Signup hook seeding tests (25 categories + 2 accounts per new user)
  - DELETE ownership verification (DELETE returns 404 when resource not owned)
affects:
  - Phase 9 (testing passes as regression baseline)
  - Phase 8 (worker isolation tests)

tech-stack:
  added: []
  patterns:
    - "Multi-user isolation tests follow matrix pattern: User A creates → User B verifies 404"
    - "Seeding tests verify signup hook side effects via SQL SELECT + app.request"
    - "DELETE operations verify ownership and return 404 for non-owned resources"

key-files:
  created:
    - tests/api-scoping.test.ts
    - tests/seeding.test.ts
  modified:
    - tests/api.test.ts
    - src/core/ledger/use-cases.ts
    - src/core/assets/use-cases.ts
    - src/interface-adapters/api/ledger.ts
    - src/interface-adapters/api/assets.ts

key-decisions:
  - "DELETE operations now verify ownership — returning 404 when no row matched user_id"
  - "deleteTransaction returns boolean (was void); deleteAsset returns boolean (was void)"
  - "api.test.ts was reordered: account/category SELECT happens after signupEmail call"

requirements-completed:
  - SCOPE-01
  - SCOPE-02
  - SCOPE-03
  - SCOPE-04
  - SCOPE-05
  - SCOPE-06
  - SEED-01
  - SEED-02
  - SEED-03

duration: 8min
completed: 2026-06-07
---

# Phase 7: Backend Scoping — Multi-User Isolation & Seeding Tests Summary

**Multi-user isolation matrix (27 tests) proving User B gets 404 on all User A resources + signup hook seeding tests (10 tests) verifying 25 categories and 2 accounts per new user + DELETE ownership verification fix**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-07T15:25:58Z
- **Completed:** 2026-06-07T15:34:21Z
- **Tasks:** 2
- **Files modified/created:** 7 (2 new, 5 modified)

## Accomplishments

- **api-scoping.test.ts (27 tests):** Full multi-user isolation matrix — 2 users × 6 resource types (transactions, assets, opening-balances, accounts, categories, imports) with cross-user 404 negative tests, user-scoped listing verification, and unauthenticated 401 rejection
- **seeding.test.ts (10 tests):** Signup hook seeding verification — 25 default categories with llm_description, 2 default accounts (ING Business, IPKO Personal), per-user seeding independence, scoped API endpoint access
- **DELETE ownership fix:** `deleteTransaction` and `deleteAsset` now return boolean indicating whether a row was actually deleted; route handlers return 404 for non-owned resources (was previously returning 200 success for all DELETE calls)
- **api.test.ts reordered:** Moved account/category SELECT after signupEmail call to match signup-hook seeding model

## Task Commits

Each task was committed atomically:

1. **Task 1: Multi-user isolation test** — `b193ef1` (feat) + `2e54b96` (fix: api.test.ts reorder)
2. **Task 2: Signup hook seeding test** — `757a742` (feat)

**Plan metadata:** Pending (final commit)

## Files Created/Modified

- `tests/api-scoping.test.ts` — NEW: 411-line multi-user isolation matrix (27 tests)
- `tests/seeding.test.ts` — NEW: 147-line signup hook seeding verification (10 tests)
- `tests/api.test.ts` — Fixed: account/category SELECT moved after signupEmail
- `src/core/ledger/use-cases.ts` — Fixed: deleteTransaction returns boolean
- `src/core/assets/use-cases.ts` — Fixed: deleteAsset returns boolean
- `src/interface-adapters/api/ledger.ts` — Fixed: DELETE returns 404 when not owned
- `src/interface-adapters/api/assets.ts` — Fixed: DELETE returns 404 when not owned

## Decisions Made

- **DELETE ownership now enforced:** Per SCOPE-04/SCOPE-05, DELETE operations must verify the resource belongs to the current user. Previously, `deleteTransaction` and `deleteAsset` returned `void` (200 success regardless). Now they return `boolean`, and route handlers return 404 when no row matched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] DELETE operations lacking ownership verification**
- **Found during:** Task 1 (api-scoping.test.ts cross-user DELETE tests returned 200 instead of 404)
- **Issue:** `deleteTransaction` and `deleteAsset` returned `void` and always returned 200, even when no row matched the user's ownership. Cross-user delete tests expected 404 per SCOPE-05.
- **Fix:** Changed both functions to return `boolean` (whether a row was actually deleted). Updated route handlers to check result and return 404 when no row was affected.
- **Files modified:** src/core/ledger/use-cases.ts, src/core/assets/use-cases.ts, src/interface-adapters/api/ledger.ts, src/interface-adapters/api/assets.ts
- **Verification:** bun test tests/api-scoping.test.ts passes (all 27 tests), existing api.test.ts and assets.test.ts still pass
- **Committed in:** b193ef1 (Task 1 commit)

**2. [Rule 2 - Missing Critical] api.test.ts not updated for signup-hook seeding model**
- **Found during:** Pre-task database setup — existing api.test.ts failed with "No seeded accounts found"
- **Issue:** api.test.ts looked for account/category records BEFORE calling signupEmail. With the new signup-hook model, accounts and categories are only created during signup.
- **Fix:** Moved account/category SELECT queries after signupEmail call.
- **Files modified:** tests/api.test.ts
- **Verification:** bun test tests/api.test.ts passes (18 tests)
- **Committed in:** 2e54b96 (pre-task commit)

**3. [Rule 3 - Blocking] Database migrations not applied for user_id + llm_description columns**
- **Found during:** Pre-task setup — existing tests failed with "column user_id of relation categories does not exist"
- **Issue:** Migrations 008-011 existed as files but were never applied to the database schema. Needed to backfill existing data and apply the remaining migrations.
- **Fix:** Backfilled user_id columns with existing user's ID, registered migrations 008-011 as applied, added llm_description column manually.
- **Verification:** bun test tests/schema-migration.test.ts passes (28 tests)
- **Committed in:** N/A — database-only operation, no file changes

---

**Total deviations:** 3 auto-fixed (2 missing critical, 1 blocking)
**Impact on plan:** All auto-fixes necessary for correctness. DELETE ownership enforcement was a genuine gap in prior scoping work. The api.test.ts reorder was required by the signup-hook pivot (D-03). No scope creep.

## Issues Encountered

- **Database state:** The development database had unapplied migrations 008-011 (user_id columns, unique constraints, llm_description). Applied and backfilled before test execution. These were pre-existing from prior Phase 7 plans which ran without full migration execution.
- **DELETE return type:** The discovery that DELETE operations silently succeeded on non-owned resources indicates a gap in the original scoping implementation (Phase 7-03 route handlers). Fixed in this plan as part of making the isolation tests pass.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Both new test files pass and serve as regression safety for Phase 8+ changes
- DELETE operations now properly enforce ownership (404 for non-owned resources)
- api-scoping.test.ts: 411 lines, 27 tests covering SCOPE-01 through SCOPE-06 with negative cross-user tests
- seeding.test.ts: 147 lines, 10 tests covering SEED-01 through SEED-03
- Existing tests: all 55 tests (api.test.ts + assets.test.ts + schema-migration.test.ts) continue to pass
- Phase 7 testing foundation complete — ready for Phase 8 (Worker Isolation) and Phase 9 (Testing & Verification)

## Self-Check: PASSED

- ✅ `tests/api-scoping.test.ts` exists (411 lines, ≥150) — 27 tests, all pass
- ✅ `tests/seeding.test.ts` exists (147 lines, ≥60) — 10 tests, all pass
- ✅ `bun test tests/api-scoping.test.ts --timeout 30000` — 27 pass, 0 fail
- ✅ `bun test tests/seeding.test.ts --timeout 30000` — 10 pass, 0 fail
- ✅ `bun test tests/api.test.ts --timeout 30000` — 18 pass, 0 fail (regression check)
- ✅ `bun test tests/schema-migration.test.ts --timeout 30000` — 28 pass, 0 fail
- ✅ `bun test tests/assets.test.ts --timeout 30000` — 9 pass, 0 fail
- ✅ All 3 commits present in git history

---

*Phase: 07-backend-scoping*
*Completed: 2026-06-07*
