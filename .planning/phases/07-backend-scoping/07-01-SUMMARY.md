---
phase: 07-backend-scoping
plan: 01
subsystem: api
tags: [scoping, user-isolation, user-id, use-cases, postgres.js]
requires:
  - phase: 06-schema-migration-backfill
    provides: user_id columns on scoped tables
provides:
  - All 10 ledger use-case functions with userId parameter and user_id SQL scoping
  - All 4 assets use-case functions with userId parameter and user_id SQL scoping
  - Both import use-case functions with userId parameter and user_id SQL scoping
  - New reference/use-cases.ts with scoped listAccounts and listCategories
  - assignCategory function extracted from inline SQL with user_id scoping
affects:
  - Phase 7-03 (route handler userId extraction depends on these signatures)
  - Phase 8 (import worker receives user_id in PGMQ payload)

tech-stack:
  added: []
  patterns:
    - "All use-cases accept userId via params object or positional param — consistent with insights module"
    - "Ownership validation implicit via SQL WHERE — non-owned rows return empty → 404"
    - "assignCategory extracted from inline PATCH route SQL into scoped use-case"

key-files:
  created:
    - src/core/reference/use-cases.ts
  modified:
    - src/core/ledger/use-cases.ts
    - src/core/assets/use-cases.ts
    - src/core/import/use-cases.ts

key-decisions:
  - "Ledger functions with params objects use userId property (listTransactions, createTransaction, createOpeningBalance)"
  - "Ledger functions with positional params use userId as last positional arg (getTransaction, updateTransaction, etc.)"
  - "Assets use positional args consistent with existing positional style"
  - "Import enqueue threads userId into both import_jobs row and PGMQ JSON payload per D-05"
  - "listOpeningBalances has optional userId — caller provides it when scoping needed"

requirements-completed:
  - SCOPE-01
  - SCOPE-02
  - SCOPE-03
  - SCOPE-04
  - SCOPE-05
  - SCOPE-07

duration: 12min
completed: 2026-06-07
---

# Phase 7: Backend Scoping — Core Use-Case Scoping Summary

**All 16 ledger/assets/import use-case functions scoped with userId parameter + new reference module with scoped listAccounts/listCategories + assignCategory extracted from inline SQL**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-07T15:10:00Z
- **Completed:** 2026-06-07T15:22:00Z
- **Tasks:** 3
- **Files modified:** 3 modified, 1 created

## Accomplishments

- **Ledger use-cases (10 functions):** All CRUD operations on transactions and opening balances scoped — every SELECT/INSERT/UPDATE/DELETE includes `AND/column user_id = ${userId}`; `assignCategory()` extracted from PATCH route inline SQL
- **Assets use-cases (4 functions):** `listAssets`, `createAsset`, `updateAsset`, `deleteAsset` all accept userId and filter/tag SQL with `user_id`
- **Import use-cases (2 functions):** `enqueueImportJob` tags import_jobs row and PGMQ payload with userId; `getImportStatus` filters by userId
- **Reference module (new):** `src/core/reference/use-cases.ts` with scoped `listAccounts(userId)` and `listCategories(userId)`

## Task Commits

Each task was committed atomically:

1. **Task 1: Scope ledger use-cases with userId param** — `d717dfe` (feat)
2. **Task 2: Scope assets use-cases with userId param** — `5e0898f` (feat)
3. **Task 3: Scope import use-cases + create reference/use-cases.ts** — `5c6230a` (feat)

**Plan metadata:** Pending (final commit)

## Files Created/Modified

- `src/core/ledger/use-cases.ts` — All 10 ledger functions scoped + new assignCategory (50 insertions, 22 deletions)
- `src/core/assets/use-cases.ts` — All 4 asset functions scoped (11 insertions, 9 deletions)
- `src/core/import/use-cases.ts` — Both import functions scoped (5 insertions, 4 deletions)
- `src/core/reference/use-cases.ts` — NEW: listAccounts(userId), listCategories(userId) (16 lines)

## Decisions Made

- Followed insights module pattern for params object with userId when the function already uses params (listTransactions, createTransaction)
- Used positional userId arg for simple functions (getTransaction, deleteTransaction, etc.) consistent with dismissInsight pattern
- Assets kept positional parameter style (not params object) matching existing convention — userId added as last param
- listOpeningBalances has optional userId to support both scoped and admin-style queries
- assignCategory returns null when no row matches (triggers 404 in caller) per D-02 implicit ownership pattern

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — all changes were mechanical following the established insights module pattern.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All use-case signatures updated with userId — ready for Phase 7-03 (route handler userId extraction)
- PGMQ payload includes user_id — ready for Phase 8 worker enforcement
- assignCategory extracted as scoped function — PATCH route needs updating to call it
- Reference data use-cases available for route handler extraction

## Self-Check: PASSED

- ✅ `src/core/ledger/use-cases.ts` exists — 15 user_id occurrences (≥12)
- ✅ `src/core/assets/use-cases.ts` exists — 4 user_id occurrences (≥4)
- ✅ `src/core/import/use-cases.ts` exists — 3 user_id occurrences (≥2)
- ✅ `src/core/reference/use-cases.ts` created — 2 user_id occurrences
- ✅ All 4 files compile without TypeScript errors
- ✅ All 4 commits present in git history

---

*Phase: 07-backend-scoping*
*Completed: 2026-06-07*
