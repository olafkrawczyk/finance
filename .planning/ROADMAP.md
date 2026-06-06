# Roadmap: Financial Planning App

## Phase 1: Foundation (Core Ledger & DB)

**Goal:** Establish the immutable ledger and database schema.
**Plans:** 3/3 plans complete
Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Environment + DB foundation: Bun install, Postgres+PGMQ (Docker), schema, 25-category seed, health check

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — Domain layer: entities, Zod v4 schemas, ledger + opening-balance use-cases, monthly summary

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-03-PLAN.md — Core API: Hono routes (transactions, summary, opening-balance CRUD, reference), Bun server entry

## Phase 2: Ingestion & Auth

**Goal:** Implement user authentication and LLM-powered bank CSV import.
**Plans:** 5/5 plans complete

**Wave 1** *(parallel)*

- [x] 02-01-PLAN.md — Auth Foundation: Better Auth config (Google/GitHub OAuth), session middleware, requireAuth, protect all Phase 1 routes, auth tests
- [x] 02-02-PLAN.md — Import Schema & Domain: import_jobs table, PGMQ import_queue init, health check, ImportJob/ParsedTransaction entities, Zod schemas, schema tests

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-03-PLAN.md — Import API: POST /import (multipart, enqueue PGMQ), GET /import/:job_id (status), import use-cases, import API + dedup tests
- [x] 02-04-PLAN.md — Import Worker: PGMQ polling loop, OpenRouter few-shot LLM parsing, ING/IPKO CSV preprocessing, batch insert (50 rows), SHA-256 dedup, worker + parse + LLM tests

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 02-05-PLAN.md — Import UI: Vite + React + Tailwind setup, ImportUpload component (account/format/file selectors), ImportStatus component (polling, progress, errors), route wiring

**Verification:** Import both sample CSVs (`ing.csv`, `ipko.csv`). Verify correct transaction count, no duplicates on re-import, Blokada rows skipped.

## Phase 3: Views & Categorization

**Goal:** Build the frontend matching the budget.xlsx views exactly.
**Plans:** 7/7 plans complete

**Wave 1** *(parallel)*

- [x] 03-01-PLAN.md — Backend API + Schema: immutability trigger relaxation, PATCH /transactions/:id/category, migration, schema push [BLOCKING]
- [x] 03-02-PLAN.md — Frontend foundations: Recharts + react-is install, Vite proxy routes, api.ts extension, linearRegression.ts utility

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 03-03-PLAN.md — UI Components: ZbiorczyTable, TransactionTable, MonthSidebar, CategoryDropdown
- [x] 03-04-PLAN.md — Chart Components: BalanceChart, ComboChart, SavingsChart, SavingsLogChart (Recharts)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 03-05-PLAN.md — Data View Pages: DashboardPage (4 charts + LR prediction), ZbiorczyPage, MonthlyPage (drill-down)
- [x] 03-06-PLAN.md — Action Pages: CategorizePage (bulk-select + assign), AddTransactionPage (manual entry form)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 03-07-PLAN.md — App Integration: routes, header nav, layout update, ImportStatus Categorize button, typography fix (font-extrabold → font-semibold)

**Verification:** Import ing.csv + ipko.csv, categorize, verify Zbiorczy numbers match a known month from budget.xlsx.

## Phase 4: AI Insights & Forecasting

**Goal:** Integrate OpenRouter for advanced financial analysis.

**Plans:** 5 plans

**Wave 1**

- [ ] 04-01-PLAN.md — DB migration, entities, Zod schemas, schema tests (backbone foundation)

**Wave 2** *(blocked on Wave 1)*

- [ ] 04-02-PLAN.md — PGMQ insights worker + use-cases (dual-model OpenRouter calls, dedup logic)
- [ ] 04-03-PLAN.md — API routes + server wiring (Hono /insights endpoints, integration tests)

**Wave 3** *(blocked on Wave 2)*

- [ ] 04-04-PLAN.md — Frontend dashboard widget + API client + ComboChart dual prediction lines

**Wave 4** *(blocked on Wave 3)*

- [ ] 04-05-PLAN.md — InsightsPage + InsightCard + nav integration + Vite proxy

**Verification:** Generate insights for a sample dataset and verify JSON parsing.

## Phase 5: Polishing & Deployment

**Goal:** Prepare for production use.

- [ ] Comprehensive E2E testing.
- [ ] Performance tuning for Postgres queries.
- [ ] Security audit and hardening.
- [ ] Final UI/UX polish.
