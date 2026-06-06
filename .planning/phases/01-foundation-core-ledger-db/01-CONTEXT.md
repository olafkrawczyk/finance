# Phase 1: foundation-core-ledger-db - Context

**Gathered:** 2026-06-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the immutable transaction ledger: database schema (with global monthly net worth tracking), seed data, and core read/write API including full opening balance management. No auth, no CSV import, no frontend — pure backend foundation.

</domain>

<decisions>
## Implementation Decisions

### Opening Balance / Net Worth Tracking
- **D-01:** `monthly_opening_balances` is a **global table** — remove `account_id` FK. Schema becomes: `id, year, month, opening_balance NUMERIC(19,4), notes TEXT (nullable), UNIQUE(year, month)`.
- **D-02:** `stan konta` = **total net worth**, not just bank account balance. It covers bank accounts + cash + ETF + silver + receivables + any other assets. This is set manually each month by the user.
- **D-03:** User sets opening balance at the start of each month (reflecting market movements, cash on hand, receivables, etc.). Transactions within the month adjust the running total.
- **D-04:** Phase 1 must include full CRUD for opening balance: `GET /opening-balance` (list all months or filter by year-month), `POST /opening-balance` (create for a month), `PUT /opening-balance/:id` (update when value changes). This endpoint is needed before Phase 2 historical import can produce correct `stan konta`.

### Category List & Fixed Costs
- **D-05:** Rename `auto` → `arval`, mark `is_fixed_cost = true`. The `arval` category tracks Arval lease monthly payments (fixed recurring cost).
- **D-06:** Fixed cost categories (6 total): `ZUS`, `PIT36`, `VAT`, `mieszkanie`, `kredyt`, `arval`. The plan previously had 5 — `arval` is the 6th.
- **D-07:** Total category count is **25** (not 26 — the "26" in REQUIREMENTS.md is a typo). The 25-name list in REQUIREMENTS is the authoritative list with `auto` renamed to `arval`.
- **D-08:** Fuel expenses use the existing `paliwo` category. No separate `auto` category needed.

### API Response Format
- **D-09:** All endpoints use a **standard envelope**: `{ data: <resource | array | null>, error: <null | { message: string }>, meta: <null | { total: number, page?: number, per_page?: number }> }`.
- **D-10:** List endpoints include `meta: { total, page, per_page }`. Single-resource endpoints set `meta: null`. Error responses set `data: null, meta: null`.
- **D-11:** Individual resources expose `created_at` from the DB. No `updated_at` needed (transactions are immutable; other tables have no update semantics in Phase 1).

### Claude's Discretion
- Error `message` format (string vs structured codes) — left to planner. Either `{ message: "..." }` or `{ code: "VALIDATION_ERROR", message: "..." }` is acceptable.
- Pagination defaults (default page size for list endpoints) — planner decides; 50 or 100 per page are reasonable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project requirements and scope
- `.planning/REQUIREMENTS.md` — Full requirements; REQ-1.x (ledger/transaction model), REQ-2.x (category system), REQ-3.x (views). Note: fixed cost list in REQ-2.2 is superseded by D-06 (arval added).
- `.planning/ROADMAP.md` — Phase 1 goal and plan list.
- `.planning/PROJECT.md` — Tech stack (Bun + Hono + postgres.js + PGMQ + Zod).

### Data model decisions (from xlsx + CSV analysis)
- `.planning/notes/2026-06-06-data-model-and-import-decisions.md` — Category derivation, Zbiorczy view spec, transfer detection, import format quirks. Read before finalizing schema.

### Prior research
- `.planning/phases/phase-1/RESEARCH.md` — Phase 1 research (project structure, architecture decisions). Referenced by all existing plans.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project. No existing code.

### Established Patterns
- None yet — Phase 1 establishes the patterns all subsequent phases follow.

### Integration Points
- Phase 2 (CSV import) depends on: `accounts` table (for account_id), `transactions` table (with import_hash), PGMQ queue initialized in Plan 01-01.
- Phase 3 (views) depends on: `GET /transactions`, `GET /summary`, `GET /opening-balance` being correct and performant.

</code_context>

<specifics>
## Specific Ideas

- The user's `stan konta` column in budget.xlsx evolved from "bank balance" to "total net worth" — the naming is historical. Downstream plans should use "total net worth" in comments/docs but keep `stan_konta` as the API field name for xlsx compatibility.
- Monthly opening balance notes field is optional but useful: user may want to record what's included (e.g., "ING 12000 + PKO 5000 + ETF 8000 + cash 500").
- Historical data starts July 2020 — the opening balance for that month will need to be set before or alongside historical import in Phase 2.

</specifics>

<deferred>
## Deferred Ideas

- Individual tracking of non-bank assets (ETF positions, silver grams, cash on hand) as separate entities — these are captured in the monthly opening balance total for now, not tracked as individual line items. Could become its own phase or feature if needed.
- Pagination on `GET /transactions` and `GET /summary` — simple for now, add proper cursor-based pagination if dataset grows beyond browser-render limits (this project manages data from July 2020+, so thousands of transactions are possible).

</deferred>

---

*Phase: 01-foundation-core-ledger-db*
*Context gathered: 2026-06-06*
