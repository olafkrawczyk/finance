---
phase: 03-views-categorization
fixed_at: 2026-06-06T14:45:00Z
review_path: .planning/phases/03-views-categorization/03-REVIEW.md
iteration: 1
findings_in_scope: 10
fixed: 10
skipped: 0
status: all_fixed
---

# Phase 03: Code Review Fix Report

**Fixed at:** 2026-06-06T14:45:00Z
**Source review:** .planning/phases/03-views-categorization/03-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 10 (5 Critical, 5 Warning)
- Fixed: 10
- Skipped: 0

## Fixed Issues

### CR-01: Delete trigger crashes at runtime — `NEW` is NULL inside a BEFORE DELETE trigger

**Files modified:** `src/infrastructure/db/schema.sql`, `src/infrastructure/db/migrations/003_allow_category_update.sql`
**Commit:** 848b1bd
**Applied fix:** Created a dedicated `block_delete()` function that raises the immutability exception unconditionally without referencing `NEW`. Updated the `trg_transactions_no_delete` trigger in both schema.sql and the migration to call `block_delete()` instead of `block_immutable_change()`. The migration now also creates `block_delete()` and re-creates the trigger so the fix applies on existing databases running 003.

### CR-02: PATCH `/transactions/:id/category` passes raw path parameter to SQL without UUID validation

**Files modified:** `src/interface-adapters/api/ledger.ts`
**Commit:** daa9d12
**Applied fix:** Added `import { z } from 'zod'` and a module-level `uuidSchema = z.uuid()`. The PATCH handler now calls `uuidSchema.safeParse(rawId)` before running the SQL query; non-UUID path params are rejected with a 400 response containing `{ message: 'Invalid transaction id' }`.

### CR-03: `stan_konta = 0` incorrectly treated as "no balance" — falsy coercion bug

**Files modified:** `frontend/src/pages/DashboardPage.tsx`, `frontend/src/pages/ZbiorczyPage.tsx`
**Commit:** aad3028
**Applied fix:** Changed `r.stan_konta ? parseFloat(r.stan_konta) : null` to `r.stan_konta != null ? parseFloat(r.stan_konta) : null` in both files. This preserves genuine zero balances instead of mapping them to null.

### CR-04: Hard-coded `date_to` day `31` produces invalid dates for short months

**Files modified:** `frontend/src/pages/MonthlyPage.tsx`
**Commit:** 0937ccd
**Applied fix:** Replaced the hard-coded `` `${yearStr}-${monthStr}-31` `` with `new Date(year, month, 0).getDate()` to compute the real last day of the month. The day is zero-padded via `String(lastDay).padStart(2, '0')`.

### CR-05: `getOpeningBalance` silently omits `month` parameter when month is `0` (January)

**Files modified:** `frontend/src/api.ts`
**Commit:** 5b150b4
**Applied fix:** Replaced `if (year)` and `if (month)` truthiness checks with `if (year != null)` and `if (month != null)`. This is semantically correct for numeric parameters where 0 is a valid (if unlikely) value.

### WR-01: `predictPoints` imported but never called — dead import

**Files modified:** `frontend/src/pages/DashboardPage.tsx`
**Commit:** 81b6dc9
**Applied fix:** Removed `predictPoints` from the import statement, leaving only `linearRegression` which is the function actually used.

### WR-02: `intervalId` race — first `fetchStatus` invocation can call `clearInterval(undefined)`

**Files modified:** `frontend/src/components/ImportStatus.tsx`
**Commit:** 88e9d67
**Applied fix:** Swapped the order: `intervalId = setInterval(fetchStatus, 2000)` is now assigned before the initial `fetchStatus()` call. This ensures `clearInterval(intervalId)` inside `fetchStatus` always has a valid interval id to clear, even on synchronous resolution.

### WR-03: `AssignCategorySchema` allows `null` to be submitted but trigger/query require `NOT NULL`

**Files modified:** `src/application/schemas/ledger.ts`
**Commit:** 433a456
**Applied fix:** Added a block comment above `AssignCategorySchema` explaining that category assignment is one-way (null to UUID) and that the DB trigger enforces this at the persistence layer. Added an inline comment on `category_id: z.uuid()` to make the intentional rejection of null explicit.

### WR-04: `ZbiorczyTable` calls `.toFixed(2)` on `zaoszczedzone_log` without NaN guard

**Files modified:** `frontend/src/components/ZbiorczyTable.tsx`
**Commit:** fcd9bc5
**Applied fix:** Wrapped the `.toFixed(2)` call with an `isNaN()` guard: `{isNaN(row.zaoszczedzone_log) ? '—' : row.zaoszczedzone_log.toFixed(2)}`. Renders an em-dash for months where the field is NaN (e.g., null/undefined from server).

### WR-05: `MonthlyPage` fetches up to 500 transactions silently — pagination silently drops transactions

**Files modified:** `frontend/src/api.ts`, `frontend/src/pages/MonthlyPage.tsx`
**Commit:** c1a8261
**Applied fix:** `getTransactions` now returns `{ data, meta }` instead of just `data`, exposing `meta.total` to callers. MonthlyPage extracts `txResult.data` and `txResult.meta`, then checks if `txMeta.total > normalizedTx.length`. When truncation is detected, a yellow warning banner is rendered above the transaction list informing the user that only the first 500 entries are displayed.

---

_Fixed: 2026-06-06T14:45:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
