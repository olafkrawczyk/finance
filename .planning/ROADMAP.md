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
**Plans:** 5 plans created

**Wave 1** *(parallel)*

- [ ] 02-01-PLAN.md — Auth Foundation: Better Auth config (Google/GitHub OAuth), session middleware, requireAuth, protect all Phase 1 routes, auth tests
- [ ] 02-02-PLAN.md — Import Schema & Domain: import_jobs table, PGMQ import_queue init, health check, ImportJob/ParsedTransaction entities, Zod schemas, schema tests

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 02-03-PLAN.md — Import API: POST /import (multipart, enqueue PGMQ), GET /import/:job_id (status), import use-cases, import API + dedup tests
- [ ] 02-04-PLAN.md — Import Worker: PGMQ polling loop, OpenRouter few-shot LLM parsing, ING/IPKO CSV preprocessing, batch insert (50 rows), SHA-256 dedup, worker + parse + LLM tests

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 02-05-PLAN.md — Import UI: Vite + React + Tailwind setup, ImportUpload component (account/format/file selectors), ImportStatus component (polling, progress, errors), route wiring

**Verification:** Import both sample CSVs (`ing.csv`, `ipko.csv`). Verify correct transaction count, no duplicates on re-import, Blokada rows skipped.

## Phase 3: Views & Categorization

**Goal:** Build the frontend matching the budget.xlsx views exactly.

- [ ] **Zbiorczy view:** Table with month | wydatki | przychody | stan konta | wydatki bez kosztów stałych | zaoszczędzone | zaoszczędzone log.
- [ ] **Monthly view:** Per-month transaction list (category, amount, description, date) + sidebar: income sources, opening balance, fixed costs by category.
- [ ] **Categorization UI:** Batch-assign categories to uncategorized imported transactions. Dropdown from the 26-category list.
- [ ] **Manual entry form:** Add transaction: category, amount, description, date, type, account.
- [ ] **Dashboard charts:** Balance over time, expenses+income+balance+prediction, savings, savings log-scale.
- [ ] **Verification:** Import ing.csv + ipko.csv, categorize, verify Zbiorczy numbers match a known month from budget.xlsx.

## Phase 4: AI Insights & Forecasting

**Goal:** Integrate OpenRouter for advanced financial analysis.

- [ ] Setup OpenRouter API integration.
- [ ] Implement AI worker for spending analysis.
- [ ] Build forecasting models using AI insights.
- [ ] Create AI-driven "Recommendations" UI component.
- [ ] **Verification:** Generate insights for a sample dataset and verify JSON parsing.

## Phase 5: Polishing & Deployment

**Goal:** Prepare for production use.

- [ ] Comprehensive E2E testing.
- [ ] Performance tuning for Postgres queries.
- [ ] Security audit and hardening.
- [ ] Final UI/UX polish.
