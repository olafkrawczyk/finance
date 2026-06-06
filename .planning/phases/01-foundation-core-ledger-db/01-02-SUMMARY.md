---
phase: 01-foundation-core-ledger-db
plan: 02
subsystem: database
tags: [bun, postgres, pgmq, zod, domain, typescript]

# Dependency graph
requires:
  - phase: 01-foundation-core-ledger-db
    plan: 01
    provides: bun runtime, postgres client singleton, core schemas and tables
provides:
  - core TypeScript domain interfaces (entities)
  - Zod v4 validation schemas
  - transaction use cases (createTransaction with atomic PGMQ push, listTransactions)
  - monthly summary use cases (getMonthlySummary excluding transfers)
  - opening balance CRUD use cases
  - schema and database integration tests
affects:
  - 01-03-PLAN.md

# Tech tracking
tech-stack:
  added: [zod]
  patterns: [Zod v4 validation, service layer pattern, SQL dynamic filters, parseFloat precision formatting]

key-files:
  created:
    - src/core/ledger/entities.ts
    - src/application/schemas/ledger.ts
    - src/core/ledger/use-cases.ts
  modified:
    - tests/schemas.test.ts
    - tests/ledger.test.ts

key-decisions:
  - "Typed all database numeric fields as strings in TypeScript entities to preserve exact decimal precision."
  - "Used Zod v4 z.uuid() and z.iso.date() to comply with strict Zod v4 guidelines."
  - "Aggregated monthly summaries by grouping by TO_CHAR(date, 'YYYY-MM') and filtering out 'transfer' type transactions."
  - "Bypassed transaction immutability in test suite setup by using TRUNCATE CASCADE instead of DELETE."

patterns-established:
  - "Zod v4 Validation: Using native UUID and ISO date validators."
  - "Atomic Queue Publishing: Wrapping database row creation and queue enqueueing in a single sql.begin transaction."

requirements-completed:
  - REQ-1.1
  - REQ-1.4
  - REQ-1.5
  - REQ-3.1
  - REQ-Tech-Zod
  - D-02
  - D-03
  - D-09
  - D-10
  - D-11

# Metrics
duration: 7min
completed: 2026-06-06
---

# Phase 01 Plan 02: Domain Layer Summary

**TypeScript ledger entities, Zod v4 validation schemas, atomic transaction enqueuing, transfer-excluding monthly summaries, and opening balance CRUD**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-06T10:53:20Z
- **Completed:** 2026-06-06T11:00:30Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- **TypeScript Domain Entities:** Created standard interfaces for `Transaction`, `MonthlyOpeningBalance`, `Account`, `Category`, and `MonthlySummaryRow`, keeping monetary columns represented as string values.
- **Zod v4 Schema Validation:** Created schemas for creating transactions, listing transactions, and creating/updating opening balances utilizing Zod v4's `z.uuid()` and `z.iso.date()`.
- **Atomic Transaction Enqueuing:** Configured `createTransaction` to insert a row and push to PGMQ `analysis_queue` atomically in one SQL transaction block.
- **Exclusion of Transfers:** Implemented `getMonthlySummary` to ignore all 'transfer' transactions during income and expense aggregates.
- **Opening Balance Uniqueness & CRUD:** Implemented opening balance creation, listing, and updating, checking constraints on year and month.
- **Test suite validation:** Expanded test coverage to 15 passing tests across 3 files.

## Task Commits

Each task was committed atomically:

1. **Task 1: Entities + Zod v4 schemas** - `d1e6f9a` (feat)
2. **Task 2: Ledger + opening-balance use-cases** - `d1e6f9a` (feat)

## Files Created/Modified
- `src/core/ledger/entities.ts` (created) - TypeScript domain models.
- `src/application/schemas/ledger.ts` (created) - Zod v4 request validation schemas.
- `src/core/ledger/use-cases.ts` (created) - Use case services (create transaction, summary, opening balance CRUD).
- `tests/schemas.test.ts` (modified) - Schema validation test cases.
- `tests/ledger.test.ts` (modified) - Use cases database integration test cases.

## Decisions Made
- **Type numeric fields as string:** This avoids any float rounding errors when doing data transfers between client, server, and database.
- **Use TRUNCATE CASCADE for test cleanup:** Since transactions table is immutable, normal delete fails. We used TRUNCATE to quickly clear tables between tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Postgres.js PGMQ message type string issue**
- **Found during:** Task 2 (Ledger integration test run)
- **Issue:** `readResult[0].message` was returned as a raw JSON string rather than a parsed object, breaking properties lookup.
- **Fix:** Added conditional `JSON.parse` if the message property is a string.
- **Files modified:** tests/ledger.test.ts
- **Verification:** Bun tests passed successfully.
- **Committed in:** d1e6f9a (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Essential for proper driver output handling. No scope creep.

## Issues Encountered
None.

## User Setup Required
None.

## Next Phase Readiness
- Domain entities, schemas, and use-cases fully tested.
- Ready to proceed to 01-03-PLAN.md (Core API, routes, Hono app server, and endpoints).

---
*Phase: 01-foundation-core-ledger-db*
*Completed: 2026-06-06*
