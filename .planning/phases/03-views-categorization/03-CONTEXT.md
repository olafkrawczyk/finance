# Phase 3: Views & Categorization - Context

**Gathered:** 2026-06-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the frontend views matching `budget.xlsx` exactly: a Zbiorczy (summary) table with running totals, a Monthly drill-down view per month, a categorization UI for batch-assigning categories to imported transactions, a manual transaction entry form, and a dashboard with 4 charts. All frontend — the backend API endpoints (`GET /summary`, `GET /transactions`, `POST /transactions`, `GET /categories`, `GET /accounts`) are already implemented by Phases 1-2.

</domain>

<decisions>
## Implementation Decisions

### Charting Library
- **D-01:** Use **Recharts** as the charting library. Declarative React API, built for line/bar/combo charts.
- **D-02:** Prediction line on the expenses+income+balance chart uses **linear regression over all historical data**.
- **D-03:** Charts support **tooltips on hover** + **click to drill down** — clicking a month's data point navigates to `/month/YYYY-MM`.
- **D-04:** Use **Recharts default color palette** (not custom app theme colors).

### Navigation & Routing
- **D-05:** **Header nav bar** pattern — extend the existing `<header>` in `App.tsx` with additional nav links. No sidebar.
- **D-06:** **Separate routes with URL params:** `/dashboard` (home), `/zbiorczy`, `/month/YYYY-MM`, `/categorize`, `/add`.
- **D-07:** **Dashboard is the landing page** — the default `/` route shows the dashboard with all 4 charts.
- **D-08:** **Responsiveness is mandatory** — the app must look good on iPhone. Use Tailwind responsive utilities for mobile layouts.

### Categorization UX
- **D-09:** **Bulk-select + assign** — checkboxes to multi-select uncategorized rows, then a single category dropdown that applies to all selected rows at once.
- **D-10:** **Post-import flow** — after a CSV import completes, show a "Categorize" button on the success screen. The categorize view shows only uncategorized transactions from that import batch.

### Manual Entry
- **D-11:** **Dedicated page** at `/add` — accessible from the header nav bar.
- **D-12:** Form fields: **Category** (dropdown from 25-category list), **Amount** (number), **Description** (text), **Date** (defaults to today), **Type** (income/expense/transfer). **No account field** — the agent decides which account to assign.

### the agent's Discretion
- Linear regression implementation (client-side calculation in the chart component vs new backend endpoint)
- Bulk category update API design (individual `PATCH` per transaction vs new batch endpoint — the existing `POST /transactions` does not support updates per REQ-1.2 immutability; a new `PATCH /transactions/:id` or batch endpoint may be needed)
- Exact responsive breakpoint strategy for tables, charts, and navigation on mobile
- Chart dimensions, aspect ratios, and mobile layout (stacked vs side-by-side)
- How the "Categorize" button integrates with the existing `ImportStatus` component
- Account selection for manual entry (which account to assign — default to a primary account or add a hidden default)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Scope
- `.planning/REQUIREMENTS.md` — REQ-3.1 (Zbiorczy), REQ-3.2 (Monthly view), REQ-3.3 (Dashboard charts), REQ-2.1/2.2 (category system), REQ-5.1 (manual entry)
- `.planning/ROADMAP.md` — Phase 3 goal, task list, and verification criteria
- `.planning/PROJECT.md` — Tech stack: React + Tailwind, Bun + Hono, Postgres

### Prior Phase Decisions
- `.planning/phases/01-foundation-core-ledger-db/01-CONTEXT.md` — D-01/D-02 (opening balance model, stan_konta = total net worth), D-09/D-10 (API envelope: `{ data, error, meta }`), D-06 (6 fixed-cost categories: ZUS, PIT36, VAT, mieszkanie, kredyt, arval)

### Backend API (already built)
- `src/core/ledger/entities.ts` — Transaction, MonthlySummaryRow, Category, Account type definitions
- `src/core/ledger/use-cases.ts` — `getMonthlySummary()`, `listTransactions()`, `createTransaction()` functions
- `src/interface-adapters/api/ledger.ts` — `GET /transactions`, `POST /transactions`, `GET /summary` endpoints
- `src/interface-adapters/api/reference.ts` — `GET /categories`, `GET /accounts` endpoints

### Existing Frontend (already built)
- `frontend/src/App.tsx` — Client-side router, header nav bar, dark theme layout, Footer component
- `frontend/src/api.ts` — API client pattern: `fetch` with `credentials: 'include'`, envelope unwrapping (`json.data`)
- `frontend/src/components/ImportUpload.tsx` — Component patterns: dark theme styling (slate-950, slate-100), gradient buttons, form inputs
- `frontend/src/components/ImportStatus.tsx` — Import job status polling component — integration point for post-import Categorize button

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **App.tsx header/nav layout** — extend the existing `<header>` with new nav links for Zbiorczy, Monthly, Dashboard, Categorize, Manual Entry
- **api.ts fetch pattern** — all API calls use `fetch(url, { credentials: 'include' })` and return `json.data`. Follow this pattern for new API calls.
- **ImportUpload dark theme styling** — consistent Tailwind classes (slate-950 bg, slate-800 borders, blue/indigo gradients, rounded-2xl cards). Reuse for new components.
- **ImportStatus polling pattern** — if a batch categorization endpoint is async, follow the polling pattern from ImportStatus.

### Established Patterns
- **Client-side path router** in App.tsx — `window.history.pushState` + `popstate` listener. Extend with new route paths.
- **Auth:** All fetch calls include `credentials: 'include'` for Better Auth session cookies.
- **Tailwind utility classes** — no custom CSS beyond `@import "tailwindcss"` in index.css.
- **API envelope:** All responses are `{ data, error, meta }`. Use `json.data` to extract payload.

### Integration Points
- **App.tsx `<header>`** — add nav buttons for new views
- **App.tsx `renderContent()`** — add route matching for `/dashboard`, `/zbiorczy`, `/month/*`, `/categorize`, `/add`
- **ImportStatus component** — add a Categorize button post-import-success
- **GET /summary** — returns `MonthlySummaryRow[]` with all Zbiorczy columns pre-computed
- **GET /transactions** — with `date_from`/`date_to` query params for monthly drill-down
- **POST /transactions** — for manual entry form submissions
- **GET /categories** — for category dropdowns in categorization UI and manual entry form

</code_context>

<specifics>
## Specific Ideas

- **Mobile-first approach:** The app must work well on iPhone screens. Tables (Zbiorczy, Monthly) likely need horizontal scroll on mobile. Charts should stack vertically. The header nav may need to collapse or use compact labels.
- Dashboard charts: balance over time (line), expenses+income+balance+prediction (combo with regression line), savings over time (line/bar), savings log-scale (line).
- The categorization UI needs a new API endpoint to update `category_id` on existing transactions. Since REQ-1.2 mandates immutability (no updates to transactions), this is an explicit exception for category assignment on uncategorized imported transactions.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-views-categorization*
*Context gathered: 2026-06-06*
