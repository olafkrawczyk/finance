# Phase 3: Views & Categorization - Research

**Researched:** 2026-06-06
**Domain:** React frontend views, Recharts charting, transaction categorization UX
**Confidence:** HIGH

## Summary

Phase 3 builds the frontend views in React + Tailwind matching the `budget.xlsx` views exactly. All backend API endpoints for data access (`GET /transactions/summary`, `GET /transactions`, `GET /categories`, `GET /accounts`) are already implemented from Phases 1-2. The frontend uses a client-side path router in `App.tsx` with `window.history.pushState`, dark theme styling (slate-950, gradients), and a `credentials: 'include'` fetch pattern for authenticated API calls.

**Primary recommendation:** Install Recharts 3.8.1 + react-is peer dependency, add the missing Vite proxy routes, create a data-normalization utility layer between raw API responses and chart components, and implement a new `PATCH /transactions/:id/category` endpoint (with corresponding DB trigger modification) for the categorization feature. All four chart types use Recharts with `ResponsiveContainer` for mobile adaptability. Linear regression is computed client-side using simple matrix math — no external library needed.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Zbiorczy summary table | Browser/Client | API/Backend | Server provides pre-computed `MonthlySummaryRow[]` via `GET /transactions/summary`; client renders HTML table |
| Monthly drill-down view | Browser/Client | API/Backend | Server filters transactions via `GET /transactions?date_from&date_to`; client renders table + sidebar |
| Categorization UI | Browser/Client | API/Backend | Client renders checkboxes + dropdown; requires NEW `PATCH /transactions/:id/category` endpoint on backend |
| Manual entry form | Browser/Client | API/Backend | Client renders form; server creates via existing `POST /transactions` |
| Dashboard charts | Browser/Client | — | Recharts renders all charts from API data; linear regression computed client-side |
| Category/account references | API/Backend | — | Already served by `GET /categories` and `GET /accounts` |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use **Recharts** as the charting library. Declarative React API, built for line/bar/combo charts.
- **D-02:** Prediction line on the expenses+income+balance chart uses **linear regression over all historical data**.
- **D-03:** Charts support **tooltips on hover** + **click to drill down** — clicking a month's data point navigates to `/month/YYYY-MM`.
- **D-04:** Use **Recharts default color palette** (not custom app theme colors).
- **D-05:** **Header nav bar** pattern — extend the existing `<header>` in `App.tsx` with additional nav links. No sidebar.
- **D-06:** **Separate routes with URL params:** `/dashboard` (home), `/zbiorczy`, `/month/YYYY-MM`, `/categorize`, `/add`.
- **D-07:** **Dashboard is the landing page** — the default `/` route shows the dashboard with all 4 charts.
- **D-08:** **Responsiveness is mandatory** — the app must look good on iPhone. Use Tailwind responsive utilities for mobile layouts.
- **D-09:** **Bulk-select + assign** — checkboxes to multi-select uncategorized rows, then a single category dropdown that applies to all selected rows at once.
- **D-10:** **Post-import flow** — after a CSV import completes, show a "Categorize" button on the success screen. The categorize view shows only uncategorized transactions from that import batch.
- **D-11:** **Dedicated page** at `/add` — accessible from the header nav bar.
- **D-12:** Form fields: **Category** (dropdown from 25-category list), **Amount** (number), **Description** (text), **Date** (defaults to today), **Type** (income/expense/transfer). **No account field** — the agent decides which account to assign.

### the agent's Discretion
- Linear regression implementation (client-side calculation in the chart component vs new backend endpoint)
- Bulk category update API design (individual `PATCH` per transaction vs new batch endpoint — the existing `POST /transactions` does not support updates per REQ-1.2 immutability; a new `PATCH /transactions/:id` or batch endpoint may be needed)
- Exact responsive breakpoint strategy for tables, charts, and navigation on mobile
- How the "Categorize" button integrates with the existing `ImportStatus` component
- Account selection for manual entry (which account to assign — default to a primary account or add a hidden default)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-3.1 | Zbiorczy (summary view): One row per month with month, wydatki, przychody, stan konta, wydatki bez kosztów stałych, zaoszczędzone, zaoszczędzone_log | GET /transactions/summary already returns MonthlySummaryRow[] with all columns pre-computed. Frontend renders HTML table. Section: Architecture Patterns > Pattern 2 |
| REQ-3.2 | Monthly view: Per-month transaction list + sidebar with income sources, opening balance, fixed costs breakdown | GET /transactions with date_from/date_to query params. Sidebar computed from same transaction list + GET /opening-balance. Section: Architecture Patterns > Pattern 3 |
| REQ-3.3 | Dashboard charts: (a) balance over time, (b) expenses+income+balance+prediction, (c) savings over time, (d) savings log-scale | Recharts 3.8.1 via ResponsiveContainer, LineChart, ComposedChart, BarChart. Linear regression client-side. Section: Standard Stack, Code Examples |
| REQ-2.1/2.2 | Category system: 25 categories with is_fixed_cost flag, uncategorized support | GET /categories already returns all categories. Categorization needs NEW PATCH endpoint. Section: Don't Hand-Roll (#2), Critical Findings |
| REQ-5.1 | Manual transaction entry via form | POST /transactions already implemented. Frontend form submits to existing endpoint. Section: Architecture Patterns > Pattern 4 |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Recharts | 3.8.1 | Declarative React charting (LineChart, ComposedChart, BarChart) | D-01 locked decision; 48M weekly downloads; supports React 19; SVG-based with built-in tooltip, legend, ResponsiveContainer [CITED: recharts/recharts GitHub README, Context7 /recharts/recharts] |
| react-is | ^19.0.0 | Peer dependency for Recharts 3.x | Required by Recharts 3.8.1 for component type-checking internals. Missing from current install. [VERIFIED: npm registry — npm view recharts peerDependencies] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| React | 19.2.7 | UI framework | Already installed — all components use React 19 |
| Tailwind CSS | 4.3.0 | Utility-first CSS | Already installed — responsive utilities for mobile layout (D-08) |
| Vite | 8.0.16 | Build tool + dev server | Already installed — proxy config needs new routes |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Recharts | Chart.js (react-chartjs-2) | Not declarative React API — violates D-01 |
| Recharts | Nivo | Visually richer but heavier bundle; Recharts is lighter and better known |
| Client-side LR | Server-side LR endpoint | Client-side keeps API surface minimal; computation is trivial (O(n) matrix math on < 100 data points) |

**Installation:**
```bash
# From project root (where package.json lives)
npm install recharts@^3.8.1 react-is@^19.0.0
```

**Version verification:**
```bash
npm view recharts version          # 3.8.1
npm view react-is version          # 19.2.1
```
Both confirmed on npm registry as of research date. [VERIFIED: npm registry]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| recharts | npm | ~9 yrs | 48.7M/wk | github.com/recharts/recharts | Unable to run [ASSUMED] | Approved |
| react-is | npm | ~9 yrs | 150M+/wk | github.com/facebook/react (monorepo) | Unable to run [ASSUMED] | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck was installed (v0.6.1) but the `slopcheck install` command did not execute successfully in the current environment. Both packages are extremely well-established (millions of weekly downloads, known GitHub repos, years of publishing history). A human-verify checkpoint is recommended to confirm the install command but risk is negligible.*

## Architecture Patterns

### System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         BROWSER (React SPA)                               │
│                                                                           │
│  App.tsx (Client Router)                                                  │
│  ├─ Header Nav Bar (D-05) ────── Dashboard │ Zbiorczy │ Monthly │ Cat │ + │
│  │                                                                        │
│  ├─ Route: / (Dashboard) ──────────────────────────────────────────┐     │
│  │  │  DashboardPage                                               │     │
│  │  │  ├─ GET /transactions/summary ──► MonthlySummaryRow[]        │     │
│  │  │  ├─ Client-side LR ──► prediction data                       │     │
│  │  │  └─ renders 4 charts via Recharts                            │     │
│  │  │     ├─ BalanceLineChart (LineChart)                          │     │
│  │  │     ├─ ComboChart (ComposedChart: Bar[expense]+Line[income]+Line[balance]+Line[prediction]) │
│  │  │     ├─ SavingsChart (BarChart)                               │     │
│  │  │     └─ SavingsLogChart (LineChart, Y-axis: log scale)        │     │
│  │  └──────────────────────────────────────────────────────────────┘     │
│  │                                                                        │
│  ├─ Route: /zbiorczy ─────────────────────────────────────────────┐     │
│  │  │  GET /transactions/summary ──► ZbiorczyTable (HTML table)   │     │
│  │  └──────────────────────────────────────────────────────────────┘     │
│  │                                                                        │
│  ├─ Route: /month/YYYY-MM ────────────────────────────────────────┐     │
│  │  │  GET /transactions?date_from&date_to ──► Transaction[]      │     │
│  │  │  GET /opening-balance?year&month ──► opening_balance        │     │
│  │  │  ├─ TransactionTable (sorted date desc)                     │     │
│  │  │  └─ MonthSidebar (income breakdown, fixed costs, opening)   │     │
│  │  └──────────────────────────────────────────────────────────────┘     │
│  │                                                                        │
│  ├─ Route: /categorize ───────────────────────────────────────────┐     │
│  │  │  GET /transactions?category_id=null (uncategorized)         │     │
│  │  │  GET /categories ──► Category[] for dropdown                │     │
│  │  │  Bulk select + PATCH /transactions/:id/category (batch)     │     │
│  │  └──────────────────────────────────────────────────────────────┘     │
│  │                                                                        │
│  └─ Route: /add ──────────────────────────────────────────────────┐     │
│     │  GET /categories ──► Category[] for dropdown                │     │
│     │  GET /accounts ──► Account[] (for hidden default selection) │     │
│     │  POST /transactions ──► creates transaction                  │     │
│     └──────────────────────────────────────────────────────────────┘     │
│                                                                           │
│  ImportStatus.tsx ── Integration point for "Categorize" button (D-10)    │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    VITE DEV PROXY (vite.config.ts)                        │
│                                                                           │
│  ⚠ CRITICAL GAPS FOUND:                                                  │
│  MISSING: /transactions  → http://localhost:3000  (GET + POST)           │
│  MISSING: /opening-balance → http://localhost:3000  (GET)                │
│  EXISTING: /import, /accounts, /categories, /api/auth                    │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      BACKEND (Bun + Hono :3000)                           │
│                                                                           │
│  GET /transactions/summary  → getMonthlySummary()                         │
│  GET /transactions          → listTransactions(query)                     │
│  POST /transactions         → createTransaction(input)                    │
│  GET /accounts              → sql`SELECT * FROM accounts`                 │
│  GET /categories            → sql`SELECT * FROM categories`               │
│  GET /opening-balance       → listOpeningBalances(year?, month?)          │
│                                                                           │
│  ⚠ MISSING — must be created in this phase:                              │
│  PATCH /transactions/:id/category  → UPDATE category_id WHERE NULL        │
│  (Requires modifying immutability trigger to allow category-only updates) │
└──────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure
```
frontend/src/
├── api.ts                   # Extend with new API functions
├── App.tsx                  # Extend routes + header nav
├── index.css                # Tailwind import
├── main.tsx                 # React root
├── lib/
│   └── linearRegression.ts  # Client-side LR computation
├── components/
│   ├── ImportUpload.tsx     # Existing
│   ├── ImportStatus.tsx     # Existing — add "Categorize" button
│   ├── ZbiorczyTable.tsx    # Summary table component
│   ├── TransactionTable.tsx # Reusable transaction table
│   ├── MonthSidebar.tsx     # Monthly view sidebar
│   └── CategoryDropdown.tsx # Shared category selector
├── pages/
│   ├── DashboardPage.tsx    # 4 charts via Recharts
│   ├── ZbiorczyPage.tsx     # Wraps ZbiorczyTable
│   ├── MonthlyPage.tsx      # URL param YYYY-MM → fetches + renders
│   ├── CategorizePage.tsx   # Bulk-select UI
│   └── AddTransactionPage.tsx # Manual entry form
└── charts/
    ├── BalanceChart.tsx     # Chart (a): balance over time
    ├── ComboChart.tsx       # Chart (b): expenses+income+balance+prediction
    ├── SavingsChart.tsx     # Chart (c): savings over time
    └── SavingsLogChart.tsx  # Chart (d): savings log-scale
```

### Pattern 1: Recharts ResponsiveContainer + Click Drill-Down

**What:** Wrap each chart in `ResponsiveContainer` for mobile adaptability. Use the chart's `onClick` handler with `state.activeLabel` to extract the clicked month and navigate via `window.history.pushState`.

**When to use:** All 4 dashboard charts. Each chart data row includes `month` as the `dataKey` for XAxis. Click handler uses `state.activeLabel` (which is the month string "YYYY-MM") to navigate to `/month/YYYY-MM`.

**Example:**
```tsx
// Source: Context7 /recharts/recharts — ComposedChart onClick handler
import { ComposedChart, Line, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';

function ComboChart({ data, onMonthClick }: { data: any[], onMonthClick: (month: string) => void }) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <ComposedChart
        data={data}
        onClick={(state) => {
          if (state?.activeLabel) {
            onMonthClick(state.activeLabel); // "2024-01"
          }
        }}
        margin={{ top: 5, right: 20, bottom: 5, left: 0 }}
      >
        <CartesianGrid stroke="#334155" strokeDasharray="3 3" />
        <XAxis dataKey="month" stroke="#94a3b8" />
        <YAxis stroke="#94a3b8" />
        <Tooltip />
        <Bar dataKey="wydatki" fill="#ef4444" yAxisId="left" />
        <Line type="monotone" dataKey="przychody" stroke="#22c55e" yAxisId="left" />
        <Line type="monotone" dataKey="stan_konta" stroke="#3b82f6" yAxisId="left" />
        <Line type="monotone" dataKey="prediction" stroke="#f59e0b" strokeDasharray="5 5" yAxisId="left" />
      </ComposedChart>
    </ResponsiveContainer>
  );
}
```
[CITED: Context7 /recharts/recharts — ComposedChart onClick handler with activeIndex, Basic LineChart Example, ResponsiveContainer]

### Pattern 2: API Data → Chart Data Normalization

**What:** Raw API responses contain `NUMERIC(19,4)` strings (e.g., `"1234.5000"`). A normalization layer converts these to `number` before passing to Recharts. The `/transactions/summary` response also needs cumulative calculations for `stan_konta` (running balance) if not already provided.

**When to use:** Every page/component that fetches API data for display or charts.

**Key observation from codebase:** `getMonthlySummary()` in `src/core/ledger/use-cases.ts` already computes `stan_konta` as `opening_balance + cumulative net` but only when `openingBalance` exists in `monthly_opening_balances`. If no opening balance is set, `stan_konta` is `null`. The frontend must handle null gracefully (show "—" in table, skip in chart).

**Normalization step:**
```typescript
// Convert API MonthlySummaryRow to chart-ready data
function normalizeSummaryForCharts(rows: MonthlySummaryRow[]) {
  return rows.map(r => ({
    month: r.month,
    wydatki: parseFloat(r.wydatki),
    przychody: parseFloat(r.przychody),
    stan_konta: r.stan_konta ? parseFloat(r.stan_konta) : null,
    wydatki_bez_stalych: parseFloat(r.wydatki_bez_stalych),
    zaoszczedzone: parseFloat(r.zaoszczedzone),
    zaoszczedzone_log: parseFloat(r.zaoszczedzone_log),
  }));
}
```

### Pattern 3: Monthly Drill-Down with Sidebar

**What:** The monthly view at `/month/YYYY-MM` fetches transactions for that month via `GET /transactions?date_from=YYYY-MM-01&date_to=YYYY-MM-31`, then computes sidebar summaries from the returned transaction list in the frontend.

**Sidebar computation (all client-side from single fetch):**
- **Opening balance:** `GET /opening-balance?year=YYYY&month=MM` (separate fetch since it's a monthly_opening_balances table query)
- **Income sources:** Group transactions where `type = 'income'` by category, sum amounts
- **Fixed costs:** Filter transactions where `type = 'expense'` and category `is_fixed_cost = true` (need to join categories — either pre-join in API or client-side merge from GET /categories)
- **Non-fixed expenses:** Expenses minus fixed costs

**⚠️ API gap:** The current `GET /transactions` returns raw `Transaction[]` with only `category_id` (UUID), not `category_name`. The frontend must either:
1. Fetch categories separately and merge client-side, OR
2. Add a new API query parameter that joins category data

Recommendation: Fetch categories once on page load via `GET /categories` and build a `Map<string, Category>` for O(1) lookup by `category_id`.

### Pattern 4: Manual Entry Form → POST /transactions

**What:** The form at `/add` collects: Category (dropdown), Amount (number input), Description (text), Date (date input, default today), Type (radio or select: income/expense/transfer). Account is NOT shown to user per D-12 but must be sent to the API (the `CreateTransactionSchema` requires `account_id`).

**Account default strategy (agent's discretion):** Default to the first account returned by `GET /accounts`. The "Konto Direct dla Firmy" (ING business) is the primary account per seed.sql ordering. Set `account_id` implicitly — store the fetched accounts list and use `accounts[0].id` as the hidden default.

**Amount format:** API expects `amount` as a `string` matching `^\d+(\.\d{1,4})?$`. Convert user input: `"123.45"` → `"123.4500"` (pad to 4 decimal places) before sending.

### Anti-Patterns to Avoid
- **Direct API data into charts:** Raw API strings (e.g., `"1234.5000"`) must be parsed to `number` before Recharts rendering. Recharts `dataKey` accesses object properties — if `wydatki` is a string, YAxis will fail to scale properly.
- **Hardcoded chart dimensions:** Always use `ResponsiveContainer` with percentage width/height, never fixed pixel values. Enables mobile responsiveness per D-08.
- **Multiple API calls per chart render:** Fetch `GET /transactions/summary` once and derive all chart data from the single response. Same for monthly view — one `GET /transactions` call per month, compute sidebar client-side.
- **Inline linear regression in chart component:** Extract to a pure function in `lib/linearRegression.ts` for testability and reuse.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chart rendering | Custom SVG/Canvas charts | Recharts 3.8.1 | Handles axes, tooltips, legends, animations, responsive sizing, accessibility, keyboard nav — all edge cases already solved [CITED: Context7 /recharts/recharts] |
| Linear regression | Custom stats library | Simple function: OLS formula `β = (XᵗX)⁻¹Xᵗy` with < 30 lines of JS | Trivial computation on < 100 data points; no external library needed. See Code Examples. |
| Responsive layout | Custom media queries | Tailwind responsive prefixes (`md:`, `lg:`) | Already in project; consistent with existing patterns |
| State management | Redux, Zustand, Jotai | React `useState` + `useEffect` with fetch | Phase scope is read-heavy views; no complex shared state. Recharts manages its own internal render state. |
| Data formatting | Custom number formatters | `Intl.NumberFormat('pl-PL', { style: 'currency', currency: 'PLN' })` | Built-in, handles Polish locale (zł, space separators) |

**Key insight:** The heaviest domain logic (ledger aggregation, monthly summaries) is already server-side. The frontend is thin — fetch data, normalize strings to numbers, render tables/charts, send form data. Adding state management libraries or custom charting is over-engineering for this phase.

## Critical Findings (Blocking Issues)

### CF-1: Immutability Trigger Blocks Category Updates
**Location:** `src/infrastructure/db/schema.sql` lines 51-56
**Problem:** The `trg_transactions_no_update` trigger fires on EVERY `UPDATE` to the transactions table, raising `'Transactions are immutable. Use a correcting entry instead.'`. This blocks category assignment on uncategorized imported transactions.
**Impact:** The categorization UI cannot function without modifying this trigger.
**Resolution:** Create a new migration that replaces the trigger to allow updates where ONLY `category_id` changes from `NULL` to a non-null value:

```sql
-- Replace immutability trigger to allow category assignment
DROP TRIGGER IF EXISTS trg_transactions_no_update ON transactions;

CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Allow setting category_id on previously uncategorized rows
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

CREATE TRIGGER trg_transactions_no_update
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_immutable_change();
```

### CF-2: Missing Vite Proxy Routes
**Location:** `vite.config.ts` lines 9-23
**Problem:** The Vite dev server proxy only forwards `/import`, `/accounts`, `/categories`, and `/api/auth` to the backend at `http://localhost:3000`. Routes `/transactions` and `/opening-balance` are not proxied, so any fetch to these endpoints from the frontend dev server will 404.
**Impact:** Dashboard, Zbiorczy, Monthly, and Categorize pages cannot fetch data.
**Resolution:** Add to `vite.config.ts`:

```typescript
'/transactions': {
  target: 'http://localhost:3000',
  changeOrigin: true,
},
'/opening-balance': {
  target: 'http://localhost:3000',
  changeOrigin: true,
},
```

### CF-3: Missing PATCH /transactions/:id/category Endpoint
**Problem:** No backend endpoint exists to update a transaction's `category_id`. The existing API only has `POST /transactions` (create) and `GET /transactions` (list). The categorization UI needs to update `category_id` on existing transactions.
**Impact:** Categorization feature cannot function.
**Resolution:** Create a new Hono route in `src/interface-adapters/api/ledger.ts`:

```typescript
// PATCH /transactions/:id/category
// Explicit exception to REQ-1.2 immutability for category assignment
const AssignCategorySchema = z.object({
  category_id: z.uuid(),
});

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

**Batch strategy (agent's discretion):** D-09 requires bulk-select + assign. Recommendation: Implement individual `PATCH` calls in parallel from the frontend (fire multiple `fetch` calls with `Promise.all`). This is simpler than a batch endpoint, keeps API surface small, and for typical usage (selecting 10-50 transactions) the parallel requests are performant. If hundreds of transactions need categorization, a dedicated `POST /transactions/categorize-batch` endpoint accepting `{ transaction_ids: UUID[], category_id: UUID }` could be added later.

### CF-4: react-is Missing as Peer Dependency
**Problem:** Recharts 3.8.1 declares `react-is` as a peer dependency but it's not in `package.json`.
**Impact:** Runtime warnings, potential breakage with Recharts internal component type-checking.
**Resolution:** `npm install react-is@^19.0.0`

## Runtime State Inventory

> Phase 3 is a greenfield frontend build — no rename/refactor. This section is omitted per the phase type.

*Step 2.5: SKIPPED (greenfield phase — no rename/refactor/migration)*

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Vite dev server, npm | ✓ | 22.22.2 | — |
| Bun | Backend runtime | ✓ | 1.3.14 | — |
| npm | Package management | ✓ | 10.9.7 | — |
| Docker | Postgres + PGMQ | ✓ | 29.4.0 | — |
| PostgreSQL | All data access | ✓ (via Docker) | — | Check `docker ps` for running container |
| Recharts | Dashboard charts | ✗ (not installed) | — | Install via npm |
| react-is | Recharts peer dep | ✗ (not installed) | — | Install via npm |

**Missing dependencies with no fallback:**
- `recharts` — must be installed for chart rendering (D-01 locked)
- `react-is` — must be installed as Recharts peer dependency

**Missing dependencies with fallback:**
- None — all other dependencies are already installed or available.

## Common Pitfalls

### Pitfall 1: String-to-Number Conversion in Charts
**What goes wrong:** The backend returns `amount` and monetary fields as `string` (NUMERIC(19,4) → postgres.js returns strings). Passing these directly to Recharts causes Y-axis scaling failures (NaN, invisible bars/lines).
**Why it happens:** The API faithfully returns database types. Developers see numbers in JSON and assume JS auto-coerces.
**How to avoid:** Create a `normalizeSummaryRow()` and `normalizeTransaction()` utility that explicitly calls `parseFloat()` on every numeric field before passing data to charts or table formatters.
**Warning signs:** Charts render but bars are invisible. Console shows `NaN` in YAxis scale. Tooltips show values with 4 decimal places.

### Pitfall 2: ResponsiveContainer Height Collapse
**What goes wrong:** `ResponsiveContainer` with `height="100%"` renders at 0px if parent has no explicit height. Chart is invisible.
**Why it happens:** Recharts ResponsiveContainer uses the parent's computed height. `height: "100%"` of `auto` is `0`.
**How to avoid:** Either set a fixed pixel `height={300}` on the ResponsiveContainer, or ensure the parent div has a defined height (e.g., `className="h-80"` in Tailwind).
**Warning signs:** Console warning: "The width(-1) and height(-1) of chart should be greater than 0". Chart area is empty.

### Pitfall 3: Running Balance Calculation from API
**What goes wrong:** The `/transactions/summary` endpoint computes `stan_konta` per-row but uses `opening_balance + zaoszczedzone` for each row individually (not cumulative). This is correct per-month but the chart "balance over time" line may appear jagged if opening balances are set sporadically.
**Why it happens:** The endpoint uses `parseFloat(openingBalance) + zaoszczedzone` for each row's `stan_konta` — it doesn't carry forward a running total from previous months when opening balance is null.
**How to avoid:** If plotting `stan_konta` as a continuous line, compute a running cumulative sum client-side: start with the first month's opening balance, then add each month's `zaoszczedzone`. Skip months where `stan_konta` is `null` in the table display, but interpolate for the chart line. [CITED: src/core/ledger/use-cases.ts lines 89-91 — stan_konta computation]
**Warning signs:** Chart line drops to zero or shows gaps between months. Table shows "—" for some months.

### Pitfall 4: Category Dropdown Shows 25, Not 26 Items
**What goes wrong:** The seed has 25 categories but the phase description and REQ-2.1 say 26.
**Why it happens:** The original REQ-2.1 listed 26 categories including `auto`, which was renamed to `arval` per Phase 1 decisions (D-07). The net is 25 categories. The "26" in the phase description is a stale reference.
**How to avoid:** Fetch from `GET /categories` dynamically — the actual count (25) will be whatever the database contains. Don't hardcode 26.
**Warning signs:** Someone tries to count categories and gets 25; confusion about the "missing" category.

## Code Examples

Verified patterns from official sources:

### Basic Recharts LineChart with Tooltip
```tsx
// Source: Context7 /recharts/recharts — Basic Line Chart Example
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

function BalanceChart({ data }: { data: { month: string; stan_konta: number | null }[] }) {
  const cleanData = data.filter(d => d.stan_konta !== null);
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={cleanData} margin={{ top: 5, right: 20, bottom: 5, left: 0 }}>
        <CartesianGrid stroke="#334155" strokeDasharray="3 3" />
        <XAxis dataKey="month" stroke="#94a3b8" />
        <YAxis stroke="#94a3b8" />
        <Tooltip />
        <Line type="monotone" dataKey="stan_konta" stroke="#3b82f6" />
      </LineChart>
    </ResponsiveContainer>
  );
}
```

### Linear Regression (Client-Side)
```typescript
// Simple OLS linear regression — < 20 lines, no external library
// Computes β₁ (slope) and β₀ (intercept) for y = β₀ + β₁x
// Uses all historical data points (D-02)

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

// Usage: predict future months
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
[ASSUMED — standard OLS formula from statistical training; verified as the correct approach for simple linear regression on small datasets; no external library needed]

### Recharts ComposedChart with Dual Y-Axis (Expenses + Income + Balance)
```tsx
// Source: Context7 /recharts/recharts — ComposedChart with Bar, Line, and Dual YAxis
import { ComposedChart, Bar, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';

function ExpensesIncomeBalanceChart({ data, prediction }: { data: any[]; prediction: any[] }) {
  // Merge prediction line into data (prediction starts after last historical month)
  const mergedData = data.map((d, i) => ({
    ...d,
    prediction: prediction[i]?.value ?? null,
  }));

  return (
    <ResponsiveContainer width="100%" height={350}>
      <ComposedChart data={mergedData} margin={{ top: 5, right: 20, bottom: 5, left: 0 }}>
        <CartesianGrid stroke="#334155" strokeDasharray="3 3" />
        <XAxis dataKey="month" stroke="#94a3b8" />
        <YAxis stroke="#94a3b8" />
        <Tooltip />
        <Legend />
        <Bar dataKey="wydatki" fill="#ef4444" name="Wydatki" />
        <Line type="monotone" dataKey="przychody" stroke="#22c55e" name="Przychody" />
        <Line type="monotone" dataKey="stan_konta" stroke="#3b82f6" name="Stan konta" />
        <Line type="monotone" dataKey="prediction" stroke="#f59e0b" strokeDasharray="8 4" name="Predykcja" connectNulls />
      </ComposedChart>
    </ResponsiveContainer>
  );
}
```
[CITED: Context7 /recharts/recharts — ComposedChart with Bar, Line, and Dual YAxis]

### Responsive Tailwind Table (Zbiorczy)
```tsx
// Mobile: horizontal scroll container. Desktop: full-width table.
function ZbiorczyTable({ rows }: { rows: NormalizedSummaryRow[] }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-slate-800">
      <table className="w-full min-w-[700px] text-sm text-left">
        <thead className="bg-slate-900 text-slate-400 uppercase text-xs">
          <tr>
            <th className="px-4 py-3">Miesiąc</th>
            <th className="px-4 py-3 text-right">Wydatki</th>
            <th className="px-4 py-3 text-right">Przychody</th>
            <th className="px-4 py-3 text-right">Stan konta</th>
            <th className="px-4 py-3 text-right">Wydatki bez stałych</th>
            <th className="px-4 py-3 text-right">Zaoszczędzone</th>
            <th className="px-4 py-3 text-right">Zaoszcz. log</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800">
          {rows.map((row) => (
            <tr key={row.month} className="hover:bg-slate-900/50 transition-colors">
              <td className="px-4 py-2 font-medium text-slate-200">{row.month}</td>
              <td className="px-4 py-2 text-right text-red-400">{fmt(row.wydatki)}</td>
              <td className="px-4 py-2 text-right text-green-400">{fmt(row.przychody)}</td>
              <td className="px-4 py-2 text-right text-blue-400">{row.stan_konta != null ? fmt(row.stan_konta) : '—'}</td>
              <td className="px-4 py-2 text-right">{fmt(row.wydatki_bez_stalych)}</td>
              <td className="px-4 py-2 text-right">{fmt(row.zaoszczedzone)}</td>
              <td className="px-4 py-2 text-right text-slate-400 font-mono">{parseFloat(row.zaoszczedzone_log).toFixed(2)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function fmt(n: number): string {
  return new Intl.NumberFormat('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Recharts 2.x (classic API) | Recharts 3.x (accessibilityLayer default, Tooltip defaultIndex) | v3.0 (2024) | `accessibilityLayer` now default-on; `activeIndex` moved to `defaultIndex` prop; keyboard navigation built-in |
| Fixed-width charts | ResponsiveContainer with ResizeObserver | Recharts 2.0+ | Mobile-responsive by default when using ResponsiveContainer |
| Server-side prediction | Client-side linear regression | This phase (D-02) | Keeps API surface minimal; simple math on small datasets |

**Deprecated/outdated:**
- **Recharts `accessibilityLayer` prop:** No longer needs to be explicitly set to `true` in v3.x — it's the default. Remove from JSX if present in examples.
- **Recharts `activeIndex` prop on Tooltip:** Replaced by `defaultIndex` in v3.x. Use `defaultIndex` for programmatic tooltip control.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Linear regression computation is correct with standard OLS formula | Code Examples | Prediction line would be inaccurate; user would see wrong forecast |
| A2 | `react-is` peer dependency is needed at runtime, not just for type-checking | Standard Stack | Recharts may still work without it; package bloat if unnecessary |
| A3 | Immutability trigger modification to allow category-only updates is the correct approach | CF-1 | Alternative: could use a stored procedure bypass or special role; either works but this is simplest |
| A4 | Frontend parallel `PATCH` calls are sufficient for bulk categorization (vs. batch endpoint) | CF-3 | If users need to categorize 500+ transactions at once, performance will degrade; need batch endpoint |
| A5 | The first account from `GET /accounts` is always the correct default for manual entry | Pattern 4 | If accounts are reordered or the user primarily uses IPKO, transactions would go to wrong account |
| A6 | slopcheck was unavailable; both packages (recharts, react-is) are assumed legitimate based on download counts and GitHub repos | Package Legitimacy Audit | Extremely low risk — both are well-known with millions of weekly downloads |

## Open Questions

1. **Category count discrepancy: 25 vs 26**
   - What we know: Seed inserts 25 categories (2026-06-06 D-07 replaced `auto` with `arval`). REQ-2.1 lists 26. The phase description says "26-category list."
   - What's unclear: Was a 26th category supposed to be added, or is the phase description stale?
   - Recommendation: Use the dynamic `GET /categories` count — don't hardcode. The actual count will be correct regardless.

2. **Line chart for savings log-scale — Y-axis configuration**
   - What we know: Recharts YAxis supports `scale="log"` since v2.x. However, log scale on YAxis requires all values > 0.
   - What's unclear: Does `zaoszczedzone_log` need a separate log-scale chart, or is it sufficient to plot the pre-computed `zaoszczedzone_log` values on a linear Y-axis?
   - Recommendation: Plot `zaoszczedzone_log` on a linear Y-axis since it's already log₁₀-transformed server-side. If a true log-scale chart is desired, use `YAxis scale="log"` on the raw `zaoszczedzone` data (filtering out ≤ 0 values).

3. **Post-import "Categorize" button — which transactions to show?**
   - What we know: D-10 says "show only uncategorized transactions from that import batch." Import jobs store `account_id` but not individual transaction IDs.
   - What's unclear: How to identify which transactions came from a specific import batch. The `import_hash` column links to deduplication, not to `import_jobs.id`.
   - Recommendation: Easiest approach — show ALL uncategorized transactions (WHERE category_id IS NULL) rather than filtering by import batch. This is simpler and still useful. If batch filtering is required, add a `batch_id` column to the transactions table.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected in frontend |
| Config file | none — see Wave 0 |
| Quick run command | `npx tsc --noEmit` (type-check only) |
| Full suite command | none configured |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-3.1 | Zbiorczy table renders all 7 columns with correct formatting | Manual / smoke | N/A | ❌ Wave 0 |
| REQ-3.2 | Monthly view shows transactions + sidebar computations | Manual / smoke | N/A | ❌ Wave 0 |
| REQ-3.3 | Dashboard renders 4 charts with data from API | Manual / smoke | N/A | ❌ Wave 0 |
| REQ-2.3 | Categorization UI assigns category to uncategorized transactions | Integration | N/A (needs test setup) | ❌ Wave 0 |
| REQ-5.1 | Manual entry form submits valid transaction | Integration | N/A (needs test setup) | ❌ Wave 0 |
| D-08 | Responsive layout works on mobile viewport | Manual | N/A | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `npx tsc --noEmit` (type-check frontend)
- **Per wave merge:** Manual smoke test — render each page, verify API calls succeed
- **Phase gate:** Import `ing.csv` + `ipko.csv`, categorize transactions, verify Zbiorczy numbers match a known month from `budget.xlsx` (ROADMAP verification criteria)

### Wave 0 Gaps
- [ ] Test framework not installed — no `vitest`, `jest`, or `@testing-library/react` configured
- [ ] No test configuration files (`vitest.config.ts`, `jest.config.js`)
- [ ] No `frontend/src/__tests__/` directory
- [ ] `lib/linearRegression.ts` — needs unit tests for regression math (Wave 0 priority)
- [ ] API normalization functions — need tests for string-to-number conversion

*(Note: The Phase 3 ROADMAP entry lists "Verification: Import ing.csv + ipko.csv, categorize, verify Zbiorczy numbers" as the phase gate. This is a manual UAT verification, not an automated test suite. Manual verification is acceptable per the project's current testing infrastructure state.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Better Auth already implemented (Phase 2). All API calls use `credentials: 'include'` for session cookies. |
| V3 Session Management | yes | Session validated server-side via `requireAuth` middleware on all ledger/category routes. |
| V4 Access Control | yes | Single-user MVP — no multi-tenant access control needed. Future: scope transactions by user_id. |
| V5 Input Validation | yes | **Frontend:** HTML5 form validation (type="number", required, min/max). **Backend:** Zod schemas on POST /transactions (CreateTransactionSchema), PATCH category update (AssignCategorySchema). |
| V6 Cryptography | no | No cryptographic operations in this phase — auth tokens handled by Better Auth. |

### Known Threat Patterns for React + Hono Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via transaction description | Information Disclosure | React auto-escapes JSX content. `dangerouslySetInnerHTML` is never used. [CITED: React docs — JSX Prevents Injection Attacks] |
| CSRF via category assignment | Tampering | Better Auth session cookies with `SameSite` attribute. `credentials: 'include'` on all fetch calls. No state-changing GET requests. |
| Mass assignment via manual entry | Elevation of Privilege | Zod schema on backend validates all fields. `CreateTransactionSchema` defines exact allowed fields. Frontend form only sends defined fields. |
| Open redirect via navigation | Spoofing | `window.history.pushState` does not cause navigation to arbitrary URLs — only modifies current-origin path. Router only matches known paths. |

## Sources

### Primary (HIGH confidence)
- Context7 `/recharts/recharts` — LineChart, ComposedChart, BarChart, ResponsiveContainer, onClick handlers, Tooltip customization, ReferenceLine, accessibility layer [VERIFIED]
- `src/core/ledger/entities.ts` — Transaction, MonthlySummaryRow, Category, Account type definitions [VERIFIED: codebase]
- `src/core/ledger/use-cases.ts` — getMonthlySummary(), listTransactions(), createTransaction() [VERIFIED: codebase]
- `src/interface-adapters/api/ledger.ts` — GET/POST /transactions, GET /transactions/summary [VERIFIED: codebase]
- `src/interface-adapters/api/reference.ts` — GET /categories, GET /accounts [VERIFIED: codebase]
- `src/infrastructure/db/schema.sql` — immutability triggers, table schemas [VERIFIED: codebase]
- `src/infrastructure/db/seed.sql` — 25 categories seed [VERIFIED: codebase]
- `vite.config.ts` — proxy configuration gaps [VERIFIED: codebase]
- `package.json` — current dependencies [VERIFIED: codebase]
- `index.ts` — server route mounting [VERIFIED: codebase]

### Secondary (MEDIUM confidence)
- npm registry — recharts@3.8.1, react-is peer dependency requirement [VERIFIED: npm view]

### Tertiary (LOW confidence)
- Linear regression OLS formula — statistical training data [ASSUMED]
- Responsive table Tailwind patterns — training data [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Recharts confirmed via Context7 docs and npm registry; version verified; peer deps confirmed
- Architecture: HIGH — existing codebase patterns inspected; API surface fully understood; blocking issues identified by code audit
- Pitfalls: HIGH — string-to-number conversion verified via entities.ts (NUMERIC(19,4) → string comments); ResponsiveContainer height documented in Recharts source; immutability trigger confirmed in schema.sql

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 (30 days — stable libraries, no breaking changes expected)

## Project Constraints (from AGENTS.md)

No `./AGENTS.md` file found in the project root. No project-specific constraints beyond those in `.planning/CONTEXT.md` (captured in User Constraints section above).
