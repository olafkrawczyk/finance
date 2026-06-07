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
**Plans:** 5/5 plans complete

**Wave 1**

- [x] 04-01-PLAN.md — DB migration, entities, Zod schemas, schema tests (backbone foundation)

**Wave 2** *(blocked on Wave 1)*

- [x] 04-02-PLAN.md — PGMQ insights worker + use-cases (dual-model OpenRouter calls, dedup logic)
- [x] 04-03-PLAN.md — API routes + server wiring (Hono /insights endpoints, integration tests)

**Wave 3** *(blocked on Wave 2)*

- [x] 04-04-PLAN.md — Frontend dashboard widget + API client + ComboChart dual prediction lines

**Wave 4** *(blocked on Wave 3)*

- [x] 04-05-PLAN.md — InsightsPage + InsightCard + nav integration + Vite proxy

**Verification:** Generate insights for a sample dataset and verify JSON parsing.

### Phase 04.9: Transaction List Enhancements & Reversal (INSERTED)

**Goal:** Implement client-side transaction filters (search, type, category, and sort) and API-level reversed order for monthly summaries.
**Depends on:** Phase 4
**Plans:** 4 plans (2 original + 2 review-fix)
Plans:

- [x] 04.9-01-PLAN.md — Backend: Reverse order for `getMonthlySummary()`, update and verify existing tests or add specific tests for this logic.
- [x] 04.9-02-PLAN.md — Frontend: Client-side sorting, filtering, and searching in `MonthlyPage.tsx`, matching `04.9-UI-SPEC.md` contract.
- [x] 04.9-03-PLAN.md — Dashboard Regression Fix: Re-reverse summary data in DashboardPage to restore chronological order for charts/regression/forecast.
- [x] 04.9-04-PLAN.md — Frontend Filter Fixes & Tests: Always-visible filter panel, sort tiebreaker, Polish locale, uncategorized option, pure filter functions, and 12 unit tests.

## Phase 4.5: Spiked Features

**Goal:** Implement transaction CRUD (edit/delete all fields).
**Plans:** 2/2 plans complete

**Wave 1** *(parallel — backend + frontend)*

- [x] 04.5-01-PLAN.md — Backend: schema migration (triggers, updated_at), entities, schemas, use-cases, API routes (GET/PUT/DELETE /transactions/:id), tests
- [x] 04.5-02-PLAN.md — Frontend: API client, TransactionTable action buttons, AddTransactionPage edit mode, MonthlyPage delete dialog + edit nav, App.tsx route

**Note:** Import dedup (`reference_id` column, LLM extraction) deferred per D-08/D-09. Not in scope for this phase.

## Phase 4.6: Dashboard & Assets

**Goal:** Implement new dashboard tiles for Total Net Value (with asset management) and Current Month Summary, and format chart values.
**Plans:** 2/2 plans complete

**Wave 1** *(parallel — backend + frontend)*

- [x] 04.6-01-PLAN.md — Backend: schema migration for assets table, Zod validation schemas, core asset use-cases, Hono API routes (GET/POST/PUT/DELETE /assets), integration tests
- [x] 04.6-02-PLAN.md — Frontend: Assets API client, Assets management page (CRUD), Dashboard tiles (Total Net Value and Current Month Summary), and chart formatting (Tooltip and Y-Axis)

## Phase 4.7: Auth UI (Login/Logout/Guard)

**Goal:** Build frontend authentication UI — login/signup page, session-based route guarding, and logout.
**Plans:** 2/2 plans complete

**Wave 1** *(parallel — frontend plans)*

- [x] 04.7-01-PLAN.md — Auth Pages: Tabbed login/signup page with email/password + Google OAuth, redirect to /dashboard on success
- [x] 04.7-02-PLAN.md — Auth Guard & Logout + 401 Handler: Session check in App.tsx, redirect to /login if unauthenticated, loading spinner, logout button in header, global 401 redirect

**Verification:** Visit app without session → redirect to /login. Sign up with email → redirect to /dashboard. Logout → redirect to /login. Sign in with Google → redirect to /dashboard. Restart server mid-session → next API call redirects to /login.

## Phase 4.8: Excel Data Migration

**Goal:** Implement Excel binary spreadsheet ingestion via a dedicated `/migration` route with destructive warnings and custom category/account routing.

**Wave 1** *(parallel — backend + frontend)*

- [x] 04.8-01-PLAN.md — Backend Excel Ingestion: API route `/api/migration/excel` (multipart upload), dependency on XLSX parser, PGMQ ingestion task, account routing, category mapping, destructive truncate
- [x] 04.8-02-PLAN.md — Frontend Migration Page: `/migration` route, prominent destructive warning modal, upload status polling, error and success indicators
- [x] 04.8-03-PLAN.md — Gap Closure: Worker input validation, PGMQ retry-safe temp file cleanup, atomic outer transaction, empty workbook detection

**Verification:** Upload `budget.xlsx` via `/migration` route after confirming warning. Verify transactions are imported correctly (ING vs. PKO routing), opening balances match, and existing data was cleared.

## Phase 5: Polishing & Deployment

**Goal:** Containerize the app, automate DB migrations, manage production secrets, and harden auth for homelab deployment.

**Plans:** 4 plans in 2 waves

**Wave 1** *(parallel — infrastructure)*

- [ ] 05-01-PLAN.md — Docker infrastructure: multi-stage Dockerfile, entrypoint orchestration (4 processes), docker-compose app service, HEALTHCHECK
- [ ] 05-02-PLAN.md — DB migration tooling: node-pg-migrate install, migrate.ts runner, baseline 001_initial_schema.sql, fake-baseline on dev DB
- [ ] 05-03-PLAN.md — Production serving & secrets: Hono serveStatic, .env.example with all production vars, DEPLOYMENT.md

**Wave 2** *(blocked on Wave 1 — hardening)*

- [ ] 05-04-PLAN.md — Auth hardening verification: Docker build, container healthcheck, UI-SPEC V-01 through V-11 checklist verification
