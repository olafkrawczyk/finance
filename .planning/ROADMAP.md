# Roadmap: Financial Planning App

## Phase 1: Foundation (Core Ledger & DB)

**Goal:** Establish the immutable ledger and database schema.
**Plans:** 2/3 plans executed
Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Environment + DB foundation: Bun install, Postgres+PGMQ (Docker), schema, 25-category seed, health check

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — Domain layer: entities, Zod v4 schemas, ledger + opening-balance use-cases, monthly summary

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 01-03-PLAN.md — Core API: Hono routes (transactions, summary, opening-balance CRUD, reference), Bun server entry

## Phase 2: Ingestion & Auth

**Goal:** Implement user authentication and LLM-powered bank CSV import.

- [ ] Integrate Better Auth for OAuth/SSO (Google/GitHub).
- [ ] `POST /import` endpoint: accept CSV upload + account_id → enqueue PGMQ job → return `{ job_id }`.
- [ ] PGMQ worker: dequeue → call OpenRouter with few-shot prompt (ING + IPKO examples) → receive `[{date, amount, description, raw_type}]` JSON → insert transactions with `category_id=NULL`.
- [ ] ING parser support: ISO-8859-2 encoding, skip 20-row metadata header, semicolon-delimited, comma decimal separators.
- [ ] IPKO parser support: comma-quoted UTF-8, skip `Blokada` rows, signed amounts.
- [ ] Deduplication: `import_hash` = SHA-256(date+amount+description); skip on conflict.
- [ ] Import status endpoint: `GET /import/:job_id` returns `{ status, processed, errors }`.
- [ ] UI: file upload form with account selector, progress indicator, error list.
- [ ] **Verification:** Import both sample CSVs (`ing.csv`, `ipko.csv`). Verify correct transaction count, no duplicates on re-import, Blokada rows skipped.

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
