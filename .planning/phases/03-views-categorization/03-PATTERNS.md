# Phase 03: Views & Categorization - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 24 (14 new, 10 modified)
**Analogs found:** 20 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `index.ts` ✎ | config/route-mount | request-response | `index.ts` (same file, add `.route()` line) | exact |
| `src/interface-adapters/api/ledger.ts` ✎ | controller | CRUD | `src/interface-adapters/api/opening-balance.ts` (PUT with `:id` param) + `ledger.ts` (same file, PATCH pattern) | exact |
| `src/application/schemas/ledger.ts` ✎ | model/schema | validation | `src/application/schemas/ledger.ts` (same file, `CreateTransactionSchema`) | exact |
| `src/infrastructure/db/schema.sql` ✎ | migration/ddl | schema | `src/infrastructure/db/schema.sql` (same file, `CREATE OR REPLACE FUNCTION` pattern) | exact |
| `src/infrastructure/db/migrations/003_allow_category_update.sql` 🆕 | migration/ddl | schema | `src/infrastructure/db/schema.sql` + `src/infrastructure/db/apply.ts` | role-match |
| `frontend/src/App.tsx` ✎ | app/router | request-response | `frontend/src/App.tsx` (same file, existing client-side router + header nav) | exact |
| `frontend/src/api.ts` ✎ | utility | request-response | `frontend/src/api.ts` (same file, `fetch` + `credentials: 'include'` + envelope unwrap) | exact |
| `frontend/src/components/ImportStatus.tsx` ✎ | component | request-response | `frontend/src/components/ImportStatus.tsx` (same file, button + action pattern) | exact |
| `vite.config.ts` ✎ | config | proxy | `vite.config.ts` (same file, proxy entry pattern) | exact |
| `package.json` ✎ | config | dep-addition | `package.json` (same file) | exact |
| `frontend/src/lib/linearRegression.ts` 🆕 | utility | transform | **No analog** — RESEARCH.md §Code Examples has full implementation | none |
| `frontend/src/components/ZbiorczyTable.tsx` 🆕 | component | request-response | `frontend/src/components/ImportUpload.tsx` (component structure, Tailwind dark theme, error state) | role-match |
| `frontend/src/components/TransactionTable.tsx` 🆕 | component | request-response | `frontend/src/components/ImportUpload.tsx` (component structure) + `frontend/src/components/ImportStatus.tsx` (data display with states) | role-match |
| `frontend/src/components/MonthSidebar.tsx` 🆕 | component | request-response | `frontend/src/components/ImportUpload.tsx` (component structure, Tailwind dark theme) | role-match |
| `frontend/src/components/CategoryDropdown.tsx` 🆕 | component | request-response | `frontend/src/components/ImportUpload.tsx` (select dropdown — lines 111-127) | exact |
| `frontend/src/pages/DashboardPage.tsx` 🆕 | page | request-response | `frontend/src/components/ImportStatus.tsx` (fetch + loading states) + `frontend/src/components/ImportUpload.tsx` (error display) | role-match |
| `frontend/src/pages/ZbiorczyPage.tsx` 🆕 | page | request-response | `frontend/src/components/ImportUpload.tsx` (fetch-on-mount + render pattern) | role-match |
| `frontend/src/pages/MonthlyPage.tsx` 🆕 | page | request-response | `frontend/src/components/ImportStatus.tsx` (URL param extraction) + `frontend/src/components/ImportUpload.tsx` (fetch + render) | role-match |
| `frontend/src/pages/CategorizePage.tsx` 🆕 | page | request-response + event-driven | `frontend/src/components/ImportUpload.tsx` (form with select + submit pattern) | role-match |
| `frontend/src/pages/AddTransactionPage.tsx` 🆕 | page | form-submission | `frontend/src/components/ImportUpload.tsx` (form with selects, inputs, submit button) | exact |
| `frontend/src/charts/BalanceChart.tsx` 🆕 | component | chart/render | **No analog** — RESEARCH.md §Code Examples has Recharts LineChart pattern | none |
| `frontend/src/charts/ComboChart.tsx` 🆕 | component | chart/render | **No analog** — RESEARCH.md §Code Examples has Recharts ComposedChart pattern | none |
| `frontend/src/charts/SavingsChart.tsx` 🆕 | component | chart/render | **No analog** — follows same pattern as `BalanceChart.tsx` (this phase) + RESEARCH.md | none |
| `frontend/src/charts/SavingsLogChart.tsx` 🆕 | component | chart/render | **No analog** — follows same pattern as `BalanceChart.tsx` (this phase) + RESEARCH.md | none |

---

## Pattern Assignments

### 1. `index.ts` ✎ — Add route mount for new PATCH endpoint

**Analog:** `index.ts` lines 49-52 (existing `.route()` mounts)

**Add route mount** (after line 49):
```typescript
// Pattern from lines 49-52:
app.route('/transactions', ledgerRoutes);   // line 49: ledgersRoutes already mounted
app.route('/opening-balance', openingBalanceRoutes);
app.route('/import', importRoutes);
app.route('/', referenceRoutes);
```

New PATCH route is added within `ledgerRoutes` (the `ledgerRoutes` router already mounted at `/transactions`). No changes needed in `index.ts` beyond what's already there — the new handler is added inside `ledger.ts`.

**Verdict:** No `index.ts` changes are needed. The new `PATCH /transactions/:id/category` is registered inside `ledgerRoutes` which is already mounted at `/transactions`.

---

### 2. `src/interface-adapters/api/ledger.ts` ✎ — Add PATCH /transactions/:id/category

**Analog:** `src/interface-adapters/api/opening-balance.ts` lines 51-73 (PUT `/:id` with `zValidator`) + `src/interface-adapters/api/ledger.ts` lines 10-32 (POST handler pattern)

**Imports to add** (add to existing import block, lines 1-5):
```typescript
// Existing:
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { CreateTransactionSchema, ListTransactionsQuerySchema } from '../../application/schemas/ledger';
import { createTransaction, listTransactions, getMonthlySummary } from '../../core/ledger/use-cases';
import { requireAuth } from './auth';
```

Add at end of import block:
```typescript
import { AssignCategorySchema } from '../../application/schemas/ledger';
```

Also add `sql` import for the category update:
```typescript
import sql from '../../infrastructure/db/client';
```

**Core PATCH pattern** (from `opening-balance.ts` lines 51-72 — PUT `/:id` pattern adapted for PATCH):
```typescript
// PATCH /transactions/:id/category — assign category to uncategorized transaction
ledgerRoutes.patch(
  '/:id/category',
  requireAuth,
  zValidator('json', AssignCategorySchema, (result, c) => {
    if (!result.success) {
      return c.json(
        { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
        400
      );
    }
  }),
  async (c) => {
    try {
      const id = c.req.param('id');
      const { category_id } = c.req.valid('json');
      const [updated] = await sql`
        UPDATE transactions SET category_id = ${category_id}
        WHERE id = ${id} AND category_id IS NULL
        RETURNING *
      `;
      if (!updated) {
        return c.json(
          { data: null, error: { message: 'Transaction not found or already categorized' }, meta: null },
          404
        );
      }
      return c.json({ data: updated, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);
```

**Error handling pattern** (from `ledger.ts` lines 26-30):
```typescript
// Universal catch pattern used across all handlers:
} catch (err) {
  const message = err instanceof Error ? err.message : 'Internal server error';
  return c.json({ data: null, error: { message }, meta: null }, 500);
}
```

**Envelope pattern** (from every handler — `{ data, error, meta }`):
```typescript
// Success: c.json({ data: ..., error: null, meta: null }, 200)
// Error:   c.json({ data: null, error: { message }, meta: null }, 400/404/500)
```

---

### 3. `src/application/schemas/ledger.ts` ✎ — Add AssignCategorySchema

**Analog:** `src/application/schemas/ledger.ts` lines 3-12 (`CreateTransactionSchema`)

**Add after `UpdateOpeningBalanceSchema`** (line 23, before `ListTransactionsQuerySchema`):
```typescript
// PATCH /transactions/:id/category
export const AssignCategorySchema = z.object({
  category_id: z.uuid(),
});
```

Following the same Zod import pattern (line 1: `import * as z from 'zod'`). Schema follows existing naming convention `[Action]Schema`.

---

### 4. `src/infrastructure/db/schema.sql` ✎ — Replace immutability trigger

**Analog:** `src/infrastructure/db/schema.sql` lines 51-61 (existing `CREATE OR REPLACE FUNCTION block_immutable_change()` + `CREATE TRIGGER`)

**Replace lines 51-61** with updated trigger that allows category-only updates from NULL → non-null:

```sql
-- Immutability trigger that allows category assignment on uncategorized transactions
CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Allow setting category_id on previously uncategorized rows
  -- (all other fields must remain unchanged)
  IF OLD.category_id IS NULL 
     AND NEW.category_id IS NOT NULL 
     AND OLD.amount = NEW.amount 
     AND OLD.type = NEW.type 
     AND OLD.date = NEW.date 
     AND OLD.account_id = NEW.account_id 
     AND OLD.description IS NOT DISTINCT FROM NEW.description THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'Transactions are immutable. Use a correcting entry instead.';
END;
$$;

DROP TRIGGER IF EXISTS trg_transactions_no_update ON transactions;
CREATE TRIGGER trg_transactions_no_update
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_immutable_change();
```

Pattern matches existing SQL:
- `CREATE OR REPLACE FUNCTION` (line 51)
- `DROP TRIGGER IF EXISTS ... ON transactions` (line 58)
- `CREATE TRIGGER ... BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION ...` (lines 59-61)

---

### 5. `src/infrastructure/db/migrations/003_allow_category_update.sql` 🆕

**Analog:** `src/infrastructure/db/schema.sql` (SQL pattern) + `src/infrastructure/db/apply.ts` (migration application pattern)

**Migration SQL** — use the CREATE OR REPLACE pattern (idempotent — schema.sql already handles this when re-run):
```sql
-- 003_allow_category_update: Relax immutability trigger to allow category assignment
-- Changes: Allow UPDATE where only category_id changes from NULL to a non-null value
-- All other fields must remain unchanged

CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.category_id IS NULL 
     AND NEW.category_id IS NOT NULL 
     AND OLD.amount = NEW.amount 
     AND OLD.type = NEW.type 
     AND OLD.date = NEW.date 
     AND OLD.account_id = NEW.account_id 
     AND OLD.description IS NOT DISTINCT FROM NEW.description THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'Transactions are immutable. Use a correcting entry instead.';
END;
$$;

DROP TRIGGER IF EXISTS trg_transactions_no_update ON transactions;
CREATE TRIGGER trg_transactions_no_update
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_immutable_change();
```

**Application pattern** (from `apply.ts` lines 4-16):
```typescript
// In applySchema() or a separate migration runner:
const migrationPath = join(import.meta.dir, 'migrations', '003_allow_category_update.sql');
const migrationSql = await Bun.file(migrationPath).text();
console.log('Applying 003_allow_category_update...');
await sql.unsafe(migrationSql);
```

---

### 6. `frontend/src/App.tsx` ✎ — Extend routes + header nav

**Analog:** `frontend/src/App.tsx` (same file — extend existing patterns)

**Imports to add** (after line 3):
```typescript
import ImportUpload from './components/ImportUpload';
import ImportStatus from './components/ImportStatus';
// Add:
import DashboardPage from './pages/DashboardPage';
import ZbiorczyPage from './pages/ZbiorczyPage';
import MonthlyPage from './pages/MonthlyPage';
import CategorizePage from './pages/CategorizePage';
import AddTransactionPage from './pages/AddTransactionPage';
```

**Header nav extension** (from existing pattern, lines 72-83):
```tsx
// Existing nav button pattern:
<button
  onClick={() => navigateTo('/import')}
  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
    currentPath.startsWith('/import') || currentPath === '/'
      ? 'bg-slate-900 text-blue-400'
      : 'text-slate-400 hover:text-slate-200'
  }`}
>
  CSV Ingestion
</button>
```

Add new nav buttons following this exact pattern:
```tsx
// Add after the CSV Ingestion button (line 83):
<button onClick={() => navigateTo('/dashboard')}
  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
    currentPath === '/dashboard' ? 'bg-slate-900 text-blue-400' : 'text-slate-400 hover:text-slate-200'
  }`}>
  Dashboard
</button>
<button onClick={() => navigateTo('/zbiorczy')}
  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
    currentPath.startsWith('/zbiorczy') ? 'bg-slate-900 text-blue-400' : 'text-slate-400 hover:text-slate-200'
  }`}>
  Zbiorczy
</button>
<button onClick={() => navigateTo('/categorize')}
  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
    currentPath.startsWith('/categorize') ? 'bg-slate-900 text-blue-400' : 'text-slate-400 hover:text-slate-200'
  }`}>
  Categorize
</button>
<button onClick={() => navigateTo('/add')}
  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
    currentPath.startsWith('/add') ? 'bg-slate-900 text-blue-400' : 'text-slate-400 hover:text-slate-200'
  }`}>
  + Add
</button>
```

**Route matching extension** (from existing pattern, lines 25-57):
```tsx
// In renderContent(), add before the 404 fallback (line 46):
if (currentPath === '/dashboard' || currentPath === '/') {
  return <DashboardPage onMonthClick={(month: string) => navigateTo(`/month/${month}`)} />;
}
if (currentPath === '/zbiorczy') {
  return <ZbiorczyPage />;
}
if (currentPath.startsWith('/month/')) {
  const yearMonth = currentPath.substring('/month/'.length);  // "YYYY-MM"
  return <MonthlyPage yearMonth={yearMonth} />;
}
if (currentPath === '/categorize') {
  return <CategorizePage />;
}
if (currentPath === '/add') {
  return <AddTransactionPage onSuccess={() => navigateTo('/dashboard')} />;
}
```

**Layout change** (line 88) — the `main` element currently uses `flex items-center justify-center` (centered single-card layout). For multi-view support, change to:
```tsx
// Line 88 current:
<main className="flex-grow flex items-center justify-center px-6 py-12">
// Change to:
<main className="flex-grow px-6 py-12 max-w-6xl mx-auto w-full">
```

---

### 7. `frontend/src/api.ts` ✎ — Add new API functions

**Analog:** `frontend/src/api.ts` lines 1-43 (existing fetch pattern)

**Add after existing functions** (after line 43):

```typescript
// Pattern from getAccounts() (lines 1-10): GET + envelope unwrap
export async function getMonthlySummary() {
  const res = await fetch('/transactions/summary', { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch summary: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

// Pattern from getAccounts() — GET with query params
export async function getTransactions(params?: {
  account_id?: string;
  type?: 'income' | 'expense' | 'transfer';
  date_from?: string;
  date_to?: string;
  page?: number;
  per_page?: number;
}) {
  const searchParams = new URLSearchParams();
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.set(key, String(value));
    });
  }
  const qs = searchParams.toString();
  const res = await fetch(`/transactions${qs ? '?' + qs : ''}`, { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch transactions: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

// Pattern from reference.ts API — GET categories
export async function getCategories() {
  const res = await fetch('/categories', { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch categories: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

// Pattern from startImport() (lines 12-31) — POST with JSON body + error envelope
export async function createTransaction(data: {
  account_id: string;
  category_id?: string | null;
  type: 'income' | 'expense' | 'transfer';
  amount: string;
  description?: string | null;
  date: string;
}) {
  const res = await fetch('/transactions', {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to create transaction: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

// Pattern from getImportStatus() (lines 33-42) — GET by ID
export async function assignCategory(transactionId: string, categoryId: string) {
  const res = await fetch(`/transactions/${transactionId}/category`, {
    method: 'PATCH',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ category_id: categoryId }),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to assign category: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

// Pattern from reference.ts — GET opening-balance
export async function getOpeningBalance(year?: number, month?: number) {
  const searchParams = new URLSearchParams();
  if (year) searchParams.set('year', String(year));
  if (month) searchParams.set('month', String(month));
  const qs = searchParams.toString();
  const res = await fetch(`/opening-balance${qs ? '?' + qs : ''}`, { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch opening balance: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}
```

---

### 8. `frontend/src/components/ImportStatus.tsx` ✎ — Add "Categorize" button on completed state

**Analog:** `frontend/src/components/ImportStatus.tsx` lines 199-206 (existing action button) + `frontend/src/api.ts` (navigate import pattern)

**Add categorize button** after the progress section, when `job.status === 'completed'` (around line 197, before the "Back to Imports" button):

```tsx
// Inside the completed state rendering, add after jobErrors section (line 197):
{job.status === 'completed' && (
  <button
    onClick={() => onBack()}  // Navigate to /categorize instead — modify props
    className="w-full py-4 px-6 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl font-bold transition-all duration-300 active:scale-95 shadow-lg mb-3"
  >
    Categorize Transactions
  </button>
)}
```

**Prop interface change** — add optional `onCategorize` callback:
```tsx
// Line 15-18: extend ImportStatusProps
interface ImportStatusProps {
  jobId: string;
  onBack: () => void;
  onCategorize?: () => void;  // ADD: Navigate to /categorize
}
```

---

### 9. `vite.config.ts` ✎ — Add missing proxy routes

**Analog:** `vite.config.ts` lines 9-25 (existing proxy entries)

**Add after `/api/auth` block** (line 25), same object structure:
```typescript
// Pattern from lines 10-13:
'/transactions': {
  target: 'http://localhost:3000',
  changeOrigin: true,
},
'/opening-balance': {
  target: 'http://localhost:3000',
  changeOrigin: true,
},
```

---

### 10. `package.json` ✎ — Add recharts + react-is

**Analog:** `package.json` lines 7-13 (existing dependencies)

Add to `dependencies`:
```json
"recharts": "^3.8.1",
"react-is": "^19.0.0"
```

---

### 11. `frontend/src/lib/linearRegression.ts` 🆕 — Client-side LR computation

**Analog:** **No existing analog.** Full implementation from RESEARCH.md §Code Examples.

**Pattern:** Pure function utility module — no React, no imports. Export two functions.

```typescript
// Simple OLS linear regression — < 30 lines, no external library
// Computes β₁ (slope) and β₀ (intercept) for y = β₀ + β₁x

interface Point { x: number; y: number }

export function linearRegression(points: Point[]): { slope: number; intercept: number; r2: number } {
  const n = points.length;
  if (n < 2) return { slope: 0, intercept: 0, r2: 0 };

  let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
  for (const p of points) {
    sumX += p.x;
    sumY += p.y;
    sumXY += p.x * p.y;
    sumX2 += p.x * p.x;
    sumY2 += p.y * p.y;
  }

  const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  const intercept = (sumY - slope * sumX) / n;

  // R-squared
  const yMean = sumY / n;
  let ssRes = 0, ssTot = 0;
  for (const p of points) {
    const predicted = slope * p.x + intercept;
    ssRes += (p.y - predicted) ** 2;
    ssTot += (p.y - yMean) ** 2;
  }
  const r2 = ssTot === 0 ? 0 : 1 - ssRes / ssTot;

  return { slope, intercept, r2 };
}

export function predictPoints(
  historicalData: { monthIndex: number; value: number }[],
  monthsToPredict: number
): { monthIndex: number; value: number }[] {
  const { slope, intercept } = linearRegression(
    historicalData.map(d => ({ x: d.monthIndex, y: d.value }))
  );
  const lastIndex = historicalData[historicalData.length - 1].monthIndex;
  return Array.from({ length: monthsToPredict }, (_, i) => ({
    monthIndex: lastIndex + i + 1,
    value: slope * (lastIndex + i + 1) + intercept,
  }));
}
```

---

### 12. `frontend/src/components/ZbiorczyTable.tsx` 🆕 — Summary table

**Analog:** `frontend/src/components/ImportUpload.tsx` (component structure, Tailwind styling)

**Component skeleton** (pattern from ImportUpload.tsx lines 1-17):
```tsx
import React from 'react';

interface NormalizedSummaryRow {
  month: string;
  wydatki: number;
  przychody: number;
  stan_konta: number | null;
  wydatki_bez_stalych: number;
  zaoszczedzone: number;
  zaoszczedzone_log: number;
}

interface ZbiorczyTableProps {
  rows: NormalizedSummaryRow[];
}
```

**Format utility** (from RESEARCH.md + standard `Intl.NumberFormat`):
```tsx
const fmt = (n: number): string =>
  new Intl.NumberFormat('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
```

**Styling pattern** (from ImportUpload.tsx lines 93, 103-106, 110-127):
```tsx
// Container: rounded-2xl border border-slate-800 bg-slate-900/80 backdrop-blur-xl shadow-2xl p-8
// Table header: bg-slate-900 text-slate-400 uppercase text-xs
// Table rows: divide-y divide-slate-800, hover:bg-slate-900/50 transition-colors
// Color coding: text-red-400 (expenses), text-green-400 (income), text-blue-400 (balance)
// Null handling: row.stan_konta !== null ? fmt(row.stan_konta) : '—'
```

**Mobile pattern** (D-08): Wrap table in `overflow-x-auto` with `min-w-[700px]` on the `<table>`. On mobile, the table scrolls horizontally.

---

### 13. `frontend/src/components/TransactionTable.tsx` 🆕 — Reusable transaction table

**Analog:** `frontend/src/components/ImportUpload.tsx` (Tailwind structure) + `frontend/src/components/ImportStatus.tsx` (data display with loading)

**Component structure** (same skeleton pattern as ImportUpload):
```tsx
interface NormalizedTransaction {
  id: string;
  date: string;
  description: string | null;
  category_name: string | null;
  type: 'income' | 'expense' | 'transfer';
  amount: number;
}

interface TransactionTableProps {
  transactions: NormalizedTransaction[];
  showCategory?: boolean;       // Show category column?
  showCheckbox?: boolean;        // For bulk-select (categorize)
  selectedIds?: Set<string>;     // For bulk-select
  onToggleSelect?: (id: string) => void;
  onSelectAll?: () => void;
}
```

**Styling:** Same Tailwind classes as ZbiorczyTable. Color code amounts: `text-green-400` for income, `text-red-400` for expense, `text-yellow-400` for transfer. Date formatted as `YYYY-MM-DD`.

---

### 14. `frontend/src/components/MonthSidebar.tsx` 🆕 — Monthly view sidebar

**Analog:** `frontend/src/components/ImportUpload.tsx` (card-style component, Tailwind)

**Component props:**
```tsx
interface MonthSidebarProps {
  openingBalance: string | null;          // from GET /opening-balance
  incomeByCategory: Map<string, number>;  // category name → sum
  fixedCostTotal: number;                 // sum of is_fixed_cost expenses
  nonFixedExpenses: number;
}
```

**Styling:** Card pattern from ImportUpload.tsx line 93: `bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl p-6`. Side-by-side with TransactionTable on desktop (flex/grid), stacked on mobile.

---

### 15. `frontend/src/components/CategoryDropdown.tsx` 🆕 — Shared category selector

**Analog:** `frontend/src/components/ImportUpload.tsx` lines 110-127 (select dropdown)

**Pattern directly from ImportUpload:**
```tsx
interface Category { id: string; name: string; }

interface CategoryDropdownProps {
  categories: Category[];
  value: string;
  onChange: (categoryId: string) => void;
  label?: string;
  includeUncategorized?: boolean;  // "—" option for clearing
}
```

**Select pattern** (from ImportUpload lines 115-127):
```tsx
<select
  id="category-select"
  className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
  value={value}
  onChange={(e) => onChange(e.target.value)}
>
  {includeUncategorized && <option value="">— (uncategorized)</option>}
  {categories.map((cat) => (
    <option key={cat.id} value={cat.id}>{cat.name}</option>
  ))}
</select>
```

---

### 16. `frontend/src/pages/DashboardPage.tsx` 🆕 — 4 charts page

**Analog:** `frontend/src/components/ImportStatus.tsx` (fetch + loading states pattern, lines 20-83)

**State pattern** (from ImportStatus.tsx lines 20-24):
```tsx
import React, { useState, useEffect } from 'react';
import { getMonthlySummary } from '../api';
import BalanceChart from '../charts/BalanceChart';
import ComboChart from '../charts/ComboChart';
import SavingsChart from '../charts/SavingsChart';
import SavingsLogChart from '../charts/SavingsLogChart';

interface DashboardPageProps {
  onMonthClick: (month: string) => void;
}

export default function DashboardPage({ onMonthClick }: DashboardPageProps) {
  const [data, setData] = useState<NormalizedSummaryRow[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  // ... fetch + loading/error states
```

**Fetch pattern** (from ImportStatus.tsx lines 25-57 + ImportUpload.tsx lines 25-35):
```typescript
useEffect(() => {
  getMonthlySummary()
    .then((rows) => {
      setData(rows.map(r => ({
        month: r.month,
        wydatki: parseFloat(r.wydatki),
        przychody: parseFloat(r.przychody),
        stan_konta: r.stan_konta ? parseFloat(r.stan_konta) : null,
        wydatki_bez_stalych: parseFloat(r.wydatki_bez_stalych),
        zaoszczedzone: parseFloat(r.zaoszczedzone),
        zaoszczedzone_log: parseFloat(r.zaoszczedzone_log),
      })));
      setLoading(false);
    })
    .catch((err) => {
      setError(err.message || 'Failed to load data');
      setLoading(false);
    });
}, []);
```

**Loading state** (from ImportStatus.tsx lines 77-83):
```tsx
if (loading) {
  return (
    <div className="flex items-center justify-center py-20">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
      <p className="text-slate-400 ml-4 text-sm">Loading dashboard...</p>
    </div>
  );
}
```

**Error state** (from ImportUpload.tsx lines 103-107):
```tsx
if (error) {
  return (
    <div role="alert" className="max-w-lg mx-auto p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
      {error}
    </div>
  );
}
```

**Chart layout** (D-08 mobile: stacked, desktop: 2x2 grid):
```tsx
<div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
  <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
    <h3 className="text-sm font-semibold text-slate-400 mb-4">Balance Over Time</h3>
    <BalanceChart data={data.filter(d => d.stan_konta != null)} onMonthClick={onMonthClick} />
  </div>
  <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
    <h3 className="text-sm font-semibold text-slate-400 mb-4">Expenses + Income + Balance</h3>
    <ComboChart data={data} onMonthClick={onMonthClick} />
  </div>
  <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
    <h3 className="text-sm font-semibold text-slate-400 mb-4">Savings Over Time</h3>
    <SavingsChart data={data} onMonthClick={onMonthClick} />
  </div>
  <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
    <h3 className="text-sm font-semibold text-slate-400 mb-4">Savings (Log Scale)</h3>
    <SavingsLogChart data={data} onMonthClick={onMonthClick} />
  </div>
</div>
```

---

### 17. `frontend/src/pages/ZbiorczyPage.tsx` 🆕 — Wraps ZbiorczyTable

**Analog:** `frontend/src/components/ImportUpload.tsx` (fetch-on-mount + render) + `frontend/src/components/ImportStatus.tsx` (loading/error states)

Same patterns as DashboardPage but simpler (single fetch → single table):
- `useEffect` fetch `getMonthlySummary()`
- `parseFloat()` normalization
- Loading spinner (ImportStatus pattern)
- Error alert (ImportUpload pattern)
- ZbiorczyTable component with normalized data

---

### 18. `frontend/src/pages/MonthlyPage.tsx` 🆕 — Monthly drill-down

**Analog:** `frontend/src/components/ImportStatus.tsx` (URL param extraction via `substring`) + DashboardPage (fetch pattern + normalization)

**URL param pattern** (from App.tsx line 37 — `currentPath.substring('/import/'.length)`):
```typescript
// Props interface
interface MonthlyPageProps { yearMonth: string; } // "YYYY-MM"

// Parse into year and month:
const [yearStr, monthStr] = yearMonth.split('-');
const year = parseInt(yearStr, 10);
const month = parseInt(monthStr, 10);

// Compute date range:
const dateFrom = `${yearStr}-${monthStr}-01`;
const dateTo = `${yearStr}-${monthStr}-31`;  // postgres handles month boundaries
```

**Fetch pattern** — two parallel fetches in useEffect:
```typescript
useEffect(() => {
  Promise.all([
    getTransactions({ date_from: dateFrom, date_to: dateTo, per_page: 500 }),
    getOpeningBalance(year, month),
    getCategories(),  // For category name lookup
  ]).then(([transactions, openingBalances, categories]) => {
    // Build categoryLookup: Map<id, Category>
    // Normalize transactions: parseFloat amounts
    // Compute sidebar: incomeByCategory, fixedCostTotal, etc.
  });
}, [yearMonth]);
```

**Layout:** Side-by-side: TransactionTable + MonthSidebar on desktop (`lg:grid-cols-[1fr_300px]`), stacked on mobile.

---

### 19. `frontend/src/pages/CategorizePage.tsx` 🆕 — Bulk-select + assign

**Analog:** `frontend/src/components/ImportUpload.tsx` (form with select + submit) + DashboardPage (fetch + useEffect)

**State model:**
```tsx
const [transactions, setTransactions] = useState<NormalizedTransaction[]>([]);
const [categories, setCategories] = useState<Category[]>([]);
const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
const [targetCategory, setTargetCategory] = useState<string>('');
const [assigning, setAssigning] = useState(false);
const [error, setError] = useState<string | null>(null);
```

**Bulk-assign pattern** (D-09 — individual PATCH in parallel via `Promise.all`):
```typescript
const handleAssign = async () => {
  if (selectedIds.size === 0 || !targetCategory) return;
  setAssigning(true);
  setError(null);
  try {
    const ids = Array.from(selectedIds);
    await Promise.all(ids.map(id => assignCategory(id, targetCategory)));
    // Remove assigned from list
    setTransactions(prev => prev.filter(t => !selectedIds.has(t.id)));
    setSelectedIds(new Set());
  } catch (err: any) {
    setError(err.message || 'Failed to assign categories');
  } finally {
    setAssigning(false);
  }
};
```

**Submit button pattern** (from ImportUpload.tsx lines 203-239):
```tsx
<button
  onClick={handleAssign}
  disabled={selectedIds.size === 0 || !targetCategory || assigning}
  className={`w-full py-4 px-6 rounded-xl font-bold text-white shadow-lg transition-all duration-300 ${
    selectedIds.size === 0 || !targetCategory || assigning
      ? 'bg-slate-800 text-slate-500 cursor-not-allowed shadow-none'
      : 'bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 hover:shadow-emerald-500/20 active:scale-95'
  }`}
>
  {assigning ? 'Assigning...' : `Assign Category to ${selectedIds.size} Transaction${selectedIds.size !== 1 ? 's' : ''}`}
</button>
```

**Fetch:** `getTransactions()` with no `date_from`/`date_to` (all transactions) + `getCategories()`. Filter client-side for `category_id === null`.

---

### 20. `frontend/src/pages/AddTransactionPage.tsx` 🆕 — Manual entry form

**Analog:** `frontend/src/components/ImportUpload.tsx` — exact pattern match: form with selects, inputs, submit button, loading, error

**State pattern** (from ImportUpload lines 16-23):
```tsx
const [categories, setCategories] = useState<Category[]>([]);
const [accounts, setAccounts] = useState<Account[]>([]);
const [categoryId, setCategoryId] = useState<string>('');
const [amount, setAmount] = useState<string>('');
const [description, setDescription] = useState<string>('');
const [date, setDate] = useState<string>(new Date().toISOString().split('T')[0]);
const [type, setType] = useState<'income' | 'expense'>('expense');
const [submitting, setSubmitting] = useState(false);
const [error, setError] = useState<string | null>(null);
const [success, setSuccess] = useState(false);
```

**Form field pattern** (from ImportUpload.tsx lines 110-127 — select; import for inputs):
```tsx
{/* Label + Select pattern */}
<div>
  <label htmlFor="category-select" className="block text-slate-300 text-sm font-semibold mb-2">
    Category
  </label>
  <select id="category-select"
    className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
    value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
    <option value="">Select category...</option>
    {categories.map(cat => <option key={cat.id} value={cat.id}>{cat.name}</option>)}
  </select>
</div>

{/* Text input pattern (new — adapt from select styling) */}
<div>
  <label className="block text-slate-300 text-sm font-semibold mb-2">Amount</label>
  <input type="number" step="0.01" min="0.01" required
    className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
    value={amount} onChange={(e) => setAmount(e.target.value)} />
</div>
```

**Amount normalization** (D-12 — pad to 4 decimal places):
```typescript
const formatAmount = (raw: string): string => {
  const num = parseFloat(raw);
  if (isNaN(num)) return '0.0000';
  return num.toFixed(4); // "123.4500"
};
```

**Account default** (hidden — D-12): Fetch accounts on mount, use `accounts[0].id` as default:
```typescript
const [defaultAccountId, setDefaultAccountId] = useState<string>('');
// In useEffect:
getAccounts().then(data => { setAccounts(data); if (data.length > 0) setDefaultAccountId(data[0].id); });
```

---

### 21-24. Chart Components (`charts/*.tsx`) 🆕

**Analog:** **No existing analog.** Pattern from RESEARCH.md §Code Examples + Recharts official docs. All 4 charts share:
- Same `ResponsiveContainer` wrapper with `width="100%" height={300}`
- Same click-drill-down pattern: `onClick={(state) => { if (state?.activeLabel) onMonthClick(state.activeLabel); }}`
- Same dark theme grid: `<CartesianGrid stroke="#334155" strokeDasharray="3 3" />`
- Same axis styling: `stroke="#94a3b8"`

---

## Shared Patterns

### Authentication
**Source:** `src/interface-adapters/api/auth.ts` lines 4-12 + `frontend/src/api.ts` (all functions use `credentials: 'include'`)
**Apply to:** All backend API handlers (`ledger.ts`), all frontend API functions (`api.ts`)
```typescript
// Backend middleware (auth.ts lines 4-12):
export const requireAuth = createMiddleware(async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  if (!session) {
    return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
  }
  c.set('user', session.user);
  c.set('session', session.session);
  await next();
});

// Frontend fetch (api.ts — all functions):
const res = await fetch('/path', { credentials: 'include' });
```

### API Envelope
**Source:** Every backend handler — `{ data, error, meta }` triple
**Apply to:** All new backend API handlers, all new frontend API functions
```typescript
// Success: c.json({ data: result, error: null, meta: null }, 200)
// Error:   c.json({ data: null, error: { message: '...' }, meta: null }, 400/404/500)
// Frontend unwrap: const json = await res.json(); return json.data;
```

### Error Handling (Backend)
**Source:** `ledger.ts` lines 26-30, `reference.ts` lines 14-17
**Apply to:** All new backend API handlers
```typescript
} catch (err) {
  const message = err instanceof Error ? err.message : 'Internal server error';
  return c.json({ data: null, error: { message }, meta: null }, 500);
}
```

### Error Handling (Frontend)
**Source:** `ImportUpload.tsx` lines 103-107 (error display) + lines 82-89 (try/catch)
**Apply to:** All new frontend pages/components
```tsx
// Error display (ImportUpload.tsx 103-107):
{error && (
  <div role="alert" className="mb-6 p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
    {error}
  </div>
)}

// Try/catch (ImportUpload.tsx 82-89):
try {
  const data = await apiCall(...);
  // handle success
} catch (err: any) {
  setError(err.message || 'Operation failed');
} finally {
  setLoading(false);
}
```

### Loading State
**Source:** `ImportStatus.tsx` lines 77-83 (spinner)
**Apply to:** All new frontend pages that fetch data
```tsx
if (!data) {
  return (
    <div className="flex items-center justify-center py-20">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
      <p className="text-slate-400 ml-4 text-sm">Loading...</p>
    </div>
  );
}
```

### Dark Theme Styling
**Source:** `ImportUpload.tsx` (throughout), `ImportStatus.tsx` (throughout), `App.tsx` lines 60-86
**Apply to:** All new frontend components and pages
```tsx
// Background: bg-slate-950 (app root), bg-slate-900/80 (cards)
// Borders: border-slate-800
// Text: text-slate-100 (primary), text-slate-400 (secondary), text-slate-200 (body)
// Accents: text-blue-400 (active/highlight), text-green-400 (income), text-red-400 (expenses)
// Cards: rounded-2xl, border border-slate-800, shadow-2xl, p-8
// Inputs: bg-slate-950, border border-slate-800, rounded-lg, px-4 py-3, text-slate-200, focus:border-blue-500
// Buttons primary: bg-gradient-to-r from-blue-600 to-indigo-600, rounded-xl, font-bold, transition-all, active:scale-95
// Buttons secondary: bg-slate-800 hover:bg-slate-700, rounded-xl, font-semibold, transition-colors
```

### Data Normalization (String → Number)
**Source:** `entities.ts` line 1 comment ("NUMERIC(19,4) columns are typed as string")
**Apply to:** All frontend pages/components that consume API data for rendering/charts
```typescript
// Always parse numeric fields before using in charts or formatting:
parseFloat(row.wydatki)
parseFloat(row.przychody)
// Handle nullable: r.stan_konta ? parseFloat(r.stan_konta) : null
```

### Polish Number Formatting
**Source:** RESEARCH.md §Don't Hand-Roll
**Apply to:** All table components displaying monetary values
```typescript
const fmt = (n: number): string =>
  new Intl.NumberFormat('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
```

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `frontend/src/lib/linearRegression.ts` | utility | transform | Pure math utility — no React/fetch analog exists. RESEARCH.md has complete implementation. |
| `frontend/src/charts/BalanceChart.tsx` | component | chart/render | Recharts is new to the project. RESEARCH.md §Code Examples has LineChart pattern with ResponsiveContainer. |
| `frontend/src/charts/ComboChart.tsx` | component | chart/render | Recharts is new. RESEARCH.md §Code Examples has ComposedChart with Bar+Line+prediction dashed line pattern. |
| `frontend/src/charts/SavingsChart.tsx` | component | chart/render | Recharts is new. Follows same pattern as BalanceChart.tsx (this phase) with BarChart instead of LineChart. |
| `frontend/src/charts/SavingsLogChart.tsx` | component | chart/render | Recharts is new. Follows same pattern as BalanceChart.tsx with log-scale YAxis or pre-computed log values on linear axis. |

---

## Metadata

**Analog search scope:** `frontend/src/` (all), `src/interface-adapters/api/` (all), `src/application/schemas/`, `src/infrastructure/db/`, `vite.config.ts`, `package.json`
**Files scanned:** 17 source files
**Pattern extraction date:** 2026-06-06
