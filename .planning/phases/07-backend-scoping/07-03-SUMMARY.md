---
phase: 07
plan: 03
completed: 2026-06-07
subsystem: route-handlers
tags:
  - user-scoping
  - session
  - inline-sql
  - migration
key-files:
  - src/interface-adapters/api/ledger.ts
  - src/interface-adapters/api/assets.ts
  - src/interface-adapters/api/import.ts
  - src/interface-adapters/api/opening-balance.ts
  - src/interface-adapters/api/reference.ts
  - src/interface-adapters/api/migration.ts
metrics:
  tasks_total: 3
  tasks_completed: 3
  commits: 4
  duration_minutes: 10
---

# Plan 07-03: Route Handler User Scoping

## Summary

Wired all 6 route handler files to extract `userId` from Hono session context and pass to scoped use-cases. Refactored inline SQL in `reference.ts` and `ledger.ts` into use-case calls. Added `userId` to import enqueue PGMQ payload. Replaced global TRUNCATE in migration.ts with per-user DELETE statements.

## Commits

| # | Hash | Description |
|---|------|-------------|
| 1 | dcd254f | feat(07-03): scope ledger routes with userId extraction + assignCategory use-case |
| 2 | e6278a6 | feat(07-03): scope assets, opening-balance, reference routes |
| 3 | ff8947c | feat(07-03): scope import and migration routes with userId extraction |
| 4 | aca3e2f | feat(07-03): scope migration TRUNCATE to per-user DELETE |

## Deviations

- **TRUNCATE → per-user DELETE**: User chose Approach B (per-user DELETE) instead of the planned Approach A (global TRUNCATE). Changed `TRUNCATE ... CASCADE` to individual `DELETE FROM ... WHERE user_id = ${userId}` for each table.

## Self-Check

**Result:** PASSED

All acceptance criteria verified:
- ✅ All 6 files have `c.get('user').id` extraction
- ✅ `import sql` removed from ledger.ts and reference.ts (no inline SQL)
- ✅ PATCH /:id/category uses `assignCategory()` instead of inline SQL
- ✅ reference.ts uses `listAccounts`/`listCategories` from new use-cases module
- ✅ import.ts enqueue passes userId in PGMQ payload
- ✅ migration.ts uses per-user DELETE instead of global TRUNCATE
- ✅ All files compile without errors
