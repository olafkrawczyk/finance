---
phase: 03-views-categorization
reviewed: 2026-06-06T14:23:41Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - src/infrastructure/db/migrations/003_allow_category_update.sql
  - frontend/src/App.tsx
  - frontend/src/api.ts
  - frontend/src/charts/BalanceChart.tsx
  - frontend/src/charts/ComboChart.tsx
  - frontend/src/charts/SavingsChart.tsx
  - frontend/src/charts/SavingsLogChart.tsx
  - frontend/src/components/CategoryDropdown.tsx
  - frontend/src/components/ImportStatus.tsx
  - frontend/src/components/ImportUpload.tsx
  - frontend/src/components/MonthSidebar.tsx
  - frontend/src/components/TransactionTable.tsx
  - frontend/src/components/ZbiorczyTable.tsx
  - frontend/src/lib/linearRegression.ts
  - frontend/src/pages/DashboardPage.tsx
  - frontend/src/pages/MonthlyPage.tsx
  - frontend/src/pages/ZbiorczyPage.tsx
  - src/application/schemas/ledger.ts
  - src/infrastructure/db/schema.sql
  - src/interface-adapters/api/ledger.ts
  - tests/api.test.ts
  - tests/linearRegression.test.ts
findings:
  critical: 5
  warning: 5
  info: 3
  total: 13
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-06-06T14:23:41Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

The implementation covers DB migration, backend ledger API, frontend chart/table components, and three page views (Dashboard, Zbiorczy, Monthly). The architecture is sound and the immutability trigger design is well-intentioned. However, five blockers were found: the delete trigger references `NEW` which is `NULL` on DELETE and will crash at runtime on any attempted delete; the `id` path parameter in the PATCH endpoint is passed raw to SQL without UUID validation, enabling path-traversal/injection; `stan_konta = 0` is incorrectly treated as absent data in both page normalizations; the `date_to` hard-coded as day `31` produces invalid dates for months shorter than 31 days; and `getOpeningBalance` silently drops month `0` (January) due to falsy check.

---

## Critical Issues

### CR-01: Delete trigger crashes at runtime — `NEW` is NULL inside a BEFORE DELETE trigger

**File:** `src/infrastructure/db/schema.sql:74-76`

**Issue:** `trg_transactions_no_delete` fires `block_immutable_change()`, a function that unconditionally dereferences `NEW.category_id`, `NEW.amount`, `NEW.type`, `NEW.date`, `NEW.account_id`, and `NEW.description`. In PostgreSQL, `NEW` is `NULL` for row-level DELETE triggers. The `IF` condition will raise `ERROR: record "new" is not assigned yet` the first time any row is deleted (e.g., test teardown `TRUNCATE transactions CASCADE` implicitly bypasses triggers, but a direct `DELETE` hits this). The trigger never reaches the `RAISE EXCEPTION 'Transactions are immutable'` path — it dies first.

**Fix:** Create a dedicated, separate function for the delete trigger that simply raises the exception unconditionally:

```sql
CREATE OR REPLACE FUNCTION block_delete()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Transactions are immutable. Deletes are not permitted.';
END;
$$;

DROP TRIGGER IF EXISTS trg_transactions_no_delete ON transactions;
CREATE TRIGGER trg_transactions_no_delete
  BEFORE DELETE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_delete();
```

The same fix must be applied in `src/infrastructure/db/migrations/003_allow_category_update.sql` — that migration re-creates `block_immutable_change()` but leaves the broken delete trigger in place from `schema.sql`.

---

### CR-02: PATCH `/transactions/:id/category` passes raw path parameter to SQL without UUID validation

**File:** `src/interface-adapters/api/ledger.ts:94-98`

**Issue:** `c.req.param('id')` is interpolated directly into the parameterized query with no format check. While `postgres` (the npm library) parameterises the value, the `:id` segment can be an arbitrary string like `../../admin` or a 36-char crafted value that passes through to the DB. More concretely, if `:id` is not a valid UUID the Postgres query silently returns zero rows, which currently returns 404 — but the lack of validation means any unexpected input reaches the DB layer without being rejected at the API boundary. This is inconsistent with every other endpoint that uses `z.uuid()` on path-equivalent IDs, and it violates the schema-at-the-boundary principle already established in `AssignCategorySchema`.

**Fix:** Validate the `:id` param as a UUID before running the query:

```ts
import { z } from 'zod';

const idSchema = z.uuid();

async (c) => {
  const rawId = c.req.param('id');
  const parseResult = idSchema.safeParse(rawId);
  if (!parseResult.success) {
    return c.json(
      { data: null, error: { message: 'Invalid transaction id' }, meta: null },
      400
    );
  }
  const id = parseResult.data;
  // ... rest of handler
}
```

---

### CR-03: `stan_konta = 0` incorrectly treated as "no balance" — falsy coercion bug

**File:** `frontend/src/pages/DashboardPage.tsx:26` and `frontend/src/pages/ZbiorczyPage.tsx:17`

**Issue:** Both files use `r.stan_konta ? parseFloat(r.stan_konta) : null` to normalize the server value. JavaScript's truthiness rule treats the string `"0"` and the number `0` as falsy, so a genuine zero account balance is mapped to `null`. This causes: the BalanceChart to drop that data point (the `filter(d => d.stan_konta !== null)` guard in `BalanceChart.tsx:23`); the regression to skip that month; and the ZbiorczyTable to render `—` instead of `0.00` for that row's `stan_konta` column.

**Fix:** Use an explicit null/undefined check:

```ts
stan_konta: r.stan_konta != null ? parseFloat(r.stan_konta) : null,
```

---

### CR-04: Hard-coded `date_to` day `31` produces invalid dates for short months

**File:** `frontend/src/pages/MonthlyPage.tsx:27`

**Issue:** `const dateTo = \`${yearStr}-${monthStr}-31\`` generates invalid dates for February (28/29 days), April, June, September, and November (30 days). The backend schema validates `date_to` against `z.iso.date()` which will reject `2026-02-31` with a 400 error, leaving the Monthly page permanently broken for those months with an unhelpful error message. For months that do have 31 days the query works but only by accident.

**Fix:** Compute the real last day of the month:

```ts
const lastDay = new Date(year, month, 0).getDate(); // month=0-based trick: day 0 = last day of prior month
const dateTo = `${yearStr}-${monthStr}-${String(lastDay).padStart(2, '0')}`;
```

---

### CR-05: `getOpeningBalance` silently omits `month` parameter when month is `0` (January)

**File:** `frontend/src/api.ts:126`

**Issue:** `if (month) searchParams.set('month', String(month))` evaluates `month = 0` as falsy. Month `0` is not a valid ISO calendar month so this particular value would not arise from natural navigation; however the schema `z.number().int().min(1).max(12)` confirms month is always 1–12. The parallel risk is the `if (year)` guard on line 125: `year = 0` is also falsy, though far less likely to occur. Both guards are semantically wrong for numeric parameters — the intent is to check `!= null`, not truthiness.

**Fix:**

```ts
if (year != null) searchParams.set('year', String(year));
if (month != null) searchParams.set('month', String(month));
```

---

## Warnings

### WR-01: `predictPoints` imported but never called — dead import

**File:** `frontend/src/pages/DashboardPage.tsx:3`

**Issue:** `predictPoints` is imported from `../lib/linearRegression` but `DashboardPage` computes predictions inline using `linearRegression` directly (lines 51-55). `predictPoints` is entirely unused. This is not just a style nit — it misleads maintainers into thinking `predictPoints` is exercised and could survive code-coverage checks unchallenged.

**Fix:** Remove `predictPoints` from the import:

```ts
import { linearRegression } from '../lib/linearRegression';
```

---

### WR-02: `intervalId` race — first `fetchStatus` invocation can call `clearInterval(undefined)`

**File:** `frontend/src/components/ImportStatus.tsx:27-56`

**Issue:** `let intervalId: any` is declared but uninitialized. `fetchStatus` is immediately called (line 53) before `intervalId` is assigned (line 56). If the first `getImportStatus` call resolves synchronously (e.g., in tests or with a cached service worker), the `.then` branch on line 42 or the `.catch` on line 47 calls `clearInterval(intervalId)` with `intervalId === undefined`. `clearInterval(undefined)` is a no-op in browsers, so the subsequently-assigned interval on line 56 will never be cleared, causing it to fire indefinitely until the component unmounts.

The cleanup function on line 58 is correct — it closes over the `let` binding and will work for the normal asynchronous case. The edge case is exclusively the synchronous-resolve scenario.

**Fix:** Initialize and assign `intervalId` before calling `fetchStatus`:

```ts
fetchStatus(); // call after interval is assigned, or assign first:
intervalId = setInterval(fetchStatus, 2000);
fetchStatus(); // initial call
```

Or restructure: assign the interval first, then trigger an immediate call explicitly. The pattern used in the existing code is commonly fine in practice but fragile by design.

---

### WR-03: `AssignCategorySchema` allows `null` to be submitted but the trigger/query require `NOT NULL`

**File:** `src/application/schemas/ledger.ts:26-28` and `src/interface-adapters/api/ledger.ts:95`

**Issue:** `AssignCategorySchema` defines `category_id: z.uuid()` — this correctly requires a UUID and rejects null. However the endpoint is designed specifically to assign a category to a previously-uncategorized transaction. There is no endpoint for _removing_ a category assignment. If someone adds `nullable()` to this schema in the future it would silently pass validation, reach the `UPDATE ... SET category_id = NULL WHERE category_id IS NULL` query, and match zero rows (returning 404) without ever actually clearing the category. The DB trigger also does not permit `NULL → NULL` updates. This is a latent design inconsistency worth documenting with a comment or schema refinement.

**Fix (low-effort):** Add a comment on the schema and the endpoint handler that category assignment is one-way only (null → UUID), and that a separate "uncategorize" endpoint would require a different migration:

```ts
// NOTE: category assignment is one-way. Once set, category_id cannot be cleared
// through this endpoint. The DB trigger enforces this at the persistence layer.
export const AssignCategorySchema = z.object({
  category_id: z.uuid(), // must be a non-null UUID; null is not accepted
});
```

---

### WR-04: `ZbiorczyTable` calls `.toFixed(2)` on `zaoszczedzone_log` without NaN guard

**File:** `frontend/src/components/ZbiorczyTable.tsx:75`

**Issue:** `row.zaoszczedzone_log.toFixed(2)` will render `"NaN"` on screen if the server returns `null`, `undefined`, or a non-numeric string for that field — `parseFloat(null)` is `NaN` and `NaN.toFixed(2)` returns the string `"NaN"`. This is a realistic scenario if a month has no transactions (zaoszczedzone_log might not be computable). The other numeric columns route through `fmt()` which does not guard against NaN either, but at least the `stan_konta` path has an explicit null check (line 66). The `zaoszczedzone_log` field has no such guard.

**Fix:**

```tsx
{isNaN(row.zaoszczedzone_log) ? '—' : row.zaoszczedzone_log.toFixed(2)}
```

---

### WR-05: `MonthlyPage` fetches up to 500 transactions silently — pagination silently drops transactions

**File:** `frontend/src/pages/MonthlyPage.tsx:43`

**Issue:** `getTransactions({ ..., per_page: 500 })` hard-codes a limit of 500. The backend schema caps `per_page` at 500 (`max(500)`). A month with more than 500 transactions will silently display an incomplete list with no warning to the user. High-volume accounts (business account with daily transactions) can easily exceed 500 entries per month.

**Fix:** Either (a) check `meta.total` vs `data.length` in the response and display a warning banner when truncation has occurred, or (b) implement proper pagination with a "load more" control. Minimum viable fix: after the `setTransactions` call, check if the returned `meta.total` (from `json.meta.total` — currently `api.ts:getTransactions` returns only `json.data`) exceeds `rows.length` and surface an alert.

---

## Info

### IN-01: Unused import `getCategories` in `MonthlyPage` — results discarded after use

**File:** `frontend/src/pages/MonthlyPage.tsx:2`

**Issue:** `getCategories` is imported and called in the `Promise.all`, and its result is used to build `categoryMap`. This is correct. However, the `categories` variable type is `any[]` and there is no TypeScript interface applied, meaning category shape changes would not cause a type error. This is a type-safety note rather than a bug.

**Fix:** Define and apply a `Category` interface (already exported from `CategoryDropdown.tsx`) to the `categories` array:

```ts
import type { Category } from '../components/CategoryDropdown';
// ...
const categories: Category[] = await getCategories();
```

---

### IN-02: Duplicate conflicting Tailwind `font-*` classes in `MonthlyPage` and `ZbiorczyPage`

**File:** `frontend/src/pages/MonthlyPage.tsx:135,144` and `frontend/src/pages/ZbiorczyPage.tsx:56`

**Issue:** Several heading elements carry both `font-semibold` and `font-medium` in the same `className`. Tailwind's JIT applies the last-declared utility when two conflicting utilities are in the same class string. Depending on the generated CSS output order, the effective weight may be `500` (medium) instead of the intended `600` (semibold). The visual difference is subtle but it indicates a copy-paste error.

**Fix:** Remove `font-medium` from lines that already specify `font-semibold`.

---

### IN-03: `linearRegression.ts` — `predictPoints` crashes on empty `historicalData` array

**File:** `frontend/src/lib/linearRegression.ts:45`

**Issue:** `predictPoints` accesses `historicalData[historicalData.length - 1].monthIndex` on line 45 without a guard. If called with an empty array, this throws `TypeError: Cannot read properties of undefined`. `linearRegression` itself handles the empty case (returns zeroed metrics), but the outer `predictPoints` function does not. The current callers in `DashboardPage` guard with `if (points.length < 2) return []` before passing data to `linearRegression` directly — but `predictPoints` is still an exported public function, and `linearRegression.test.ts` does not test `predictPoints` with an empty input.

**Fix:**

```ts
export function predictPoints(...): ... {
  if (historicalData.length === 0) return [];
  const { slope, intercept } = linearRegression(...);
  const lastIndex = historicalData[historicalData.length - 1].monthIndex;
  ...
}
```

---

_Reviewed: 2026-06-06T14:23:41Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
