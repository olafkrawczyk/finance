# Roadmap: Financial Planning App

## Milestones

- ✅ **v1.0 MVP** — Phases 1-5 (shipped 2026-06-07)
- ✅ **v1.1 Multi-Tenant Data Isolation** — Phases 6-10 (completed 2026-06-10)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1–5, 4.x inserts) — SHIPPED 2026-06-07</summary>

- [x] Phase 1: Foundation (Core Ledger & DB) — 3/3 plans
- [x] Phase 2: Ingestion & Auth — 5/5 plans
- [x] Phase 3: Views & Categorization — 7/7 plans
- [x] Phase 4: AI Insights & Forecasting — 5/5 plans
- [x] Phase 04.9: Transaction List Enhancements & Reversal — 4/4 plans
- [x] Phase 4.5: Spiked Features — 2/2 plans
- [x] Phase 4.6: Dashboard & Assets — 2/2 plans
- [x] Phase 4.7: Auth UI — 2/2 plans
- [x] Phase 4.8: Excel Data Migration — 3/3 plans
- [x] Phase 5: Polishing & Deployment — 4/4 plans

</details>

### 🚧 v1.2 Account Management & Starting Balances

**Milestone Goal:** Users can create, rename, and delete accounts, and set starting balances per account so the balance-over-time charts reflect accurate financial baselines.

- [ ] **Phase 11: Account CRUD & Starting Balances** — Account management UI + starting balance setting per account

### ✅ v1.1 Multi-Tenant Data Isolation (Completed 2026-06-10)

**Milestone Goal:** Each user sees only their own accounts, categories, and transactions. Basic isolation with no sharing, RBAC, or cross-user visibility.

- [x] **Phase 6: Schema Migration & Backfill** — Add `user_id` columns, backfill data, set per-user unique constraints and composite indexes (completed 2026-06-07)
- [x] **Phase 7: Backend Scoping** — Every use-case, route handler, and seed path enforces per-user data isolation (completed 2026-06-07)
- [x] **Phase 8: Worker Isolation** — PGMQ workers process only the correct user's data via scoped queries and payload-based userId (completed 2026-06-07)
- [x] **Phase 9: Testing & Verification** — Comprehensive multi-user isolation matrix, negative tests, worker tests, migration rollback
- [x] **Phase 10: Frontend Cache Isolation** — React Query keys scoped per user, cache cleared on auth change, loading skeletons (completed 2026-06-08)

## Phase Details

### Phase 6: Schema Migration & Backfill

**Goal**: Database schema supports per-user data isolation with existing data preserved
**Depends on**: Phase 5 (Polishing & Deployment)
**Requirements**: SCHEMA-01, SCHEMA-02, SCHEMA-03, SCHEMA-04, SCHEMA-05, SCHEMA-06, SCHEMA-07, SCHEMA-08, SCHEMA-09, SCHEMA-10, SCHEMA-11
**Success Criteria** (what must be TRUE):

  1. All 6 domain tables (accounts, categories, transactions, monthly_opening_balances, assets, import_jobs) have `user_id TEXT NOT NULL` column with FK to `"user"(id)` and `ON DELETE CASCADE`
  2. All existing rows are backfilled and assigned to the first registered user — no data loss after migration
  3. Users can create categories and assets with the same name as another user's resources — global UNIQUE becomes per-user composite `UNIQUE(user_id, name)`
  4. Import hashes are unique per-user via `UNIQUE(user_id, import_hash)`, preventing cross-user dedup collisions
  5. Common query patterns (lookup by id, list by user) are efficiently indexed with composite `(user_id, ...)` indexes

**Plans**: 2 plans
Plans:

- [x] `06-01-PLAN.md` — Create 3 SQL migration files (008: add user_id columns, 009: per-user UNIQUE constraints, 010: index documentation)
- [x] `06-02-PLAN.md` — Update schema.sql to match post-migration state, create schema migration tests, update import-dedup tests

### Phase 7: Backend Scoping

**Goal**: API enforces user-scoped data isolation for all CRUD operations across the entire backend
**Depends on**: Phase 6
**Requirements**: SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05, SCOPE-06, SCOPE-07, SEED-01, SEED-02, SEED-03
**Success Criteria** (what must be TRUE):

  1. Every SELECT on scoped tables includes `AND user_id = <sessionUserId>` — no cross-user data leakage via reads
  2. Every INSERT on scoped tables tags data with the authenticated user's ID; every UPDATE/DELETE filters by user_id — no cross-user data modification
  3. Mutations validate ownership of referenced resources (account_id, category_id belong to the current user)
  4. All route handlers extract `userId` from session (`c.get('user').id`), never from client input; inline SQL in routes refactored into use-case functions
  5. New users automatically receive default categories and a default account on first `GET /categories` — no signup hook dependency

**Plans**: 4 plans
Plans:

- [ ] `07-01-PLAN.md` — Core use-case scoping: add userId to all ledger/assets/import use-cases, create reference/use-cases.ts, extract assignCategory
- [ ] `07-02-PLAN.md` — Migration 011 (llm_description column) + Better Auth signup hook + buildFewShotPrompt update
- [ ] `07-03-PLAN.md` — Route handler userId extraction + inline SQL refactoring + import enqueue scoping
- [ ] `07-04-PLAN.md` — Multi-user isolation tests + seeding tests

### Phase 8: Worker Isolation

**Goal**: Background workers (import, insights) process only the correct user's data, with full ownership validation
**Depends on**: Phase 7
**Requirements**: WORKER-01, WORKER-02, WORKER-03, WORKER-04
**Success Criteria** (what must be TRUE):

  1. PGMQ message payloads for import jobs carry `user_id` — the enqueuing user's identity propagates through the queue
  2. Import worker extracts `user_id` from PGMQ payload and tags all inserted transactions with the queuing user's ID
  3. Import worker validates that `account_id` belongs to `user_id` before processing records
  4. Insights worker explicitly scopes all queries by `user_id` — confirmed no regression from existing behavior

**Plans**: 3 plans
Plans:

- [x] `08-01-PLAN.md` — CSV Import Worker Scoping: insertBatch userId param, processCsvImportJob ownership validation, processExcelMigrationJob scoped queries
- [x] `08-02-PLAN.md` — Insights & Ledger Scoping: getLatestTransactionDate/getInsightDataWindow WHERE fix, getCategoryAggregates userId param, createTransaction auto-trigger fix, ImportJob entity update
- [x] `08-03-PLAN.md` — Test Updates: import-worker test userId fix, insights-worker test user_id column fix

### Phase 9: Testing & Verification

**Goal**: Comprehensive test coverage proves no cross-user data leakage exists, including edge cases and migration rollback
**Depends on**: Phase 8
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05
**Success Criteria** (what must be TRUE):

  1. Multi-user isolation matrix passes: 2+ users × 6 resource types × CREATE/READ/UPDATE/DELETE/LIST are properly isolated
  2. User B receives 404 (not 403) when accessing User A's resources by ID — resource existence hidden cross-user
  3. Worker isolation tests confirm import worker processes only the correct user's queued data
  4. Concurrent user tests show no data leakage during simultaneous inserts by two users
  5. Migration rollback (`down()`) restores previous schema state — up/down round-trip verified

**Plans**: 4 plansPlans:

- [x] `09-01-PLAN.md` — EXTEND api-scoping.test.ts: pagination, filtered query, bulk create isolation tests (TEST-01, TEST-02)
- [x] `09-02-PLAN.md` — EXTEND import-worker + insights-worker: multi-user worker isolation tests (TEST-03)
- [x] `09-03-PLAN.md` — CREATE concurrent-isolation.test.ts: concurrent user insert isolation (TEST-04)
- [x] `09-04-PLAN.md` — CREATE migration-rollback.test.ts: up/down schema assertions (TEST-05)

### Phase 10: Frontend Cache Isolation

**Goal**: Client-side state never leaks data across user sessions — per-user cache scoping, auth-change clearance, and UX guardrails
**Depends on**: Phase 8 (backend API scoping complete, but can run in parallel with Phase 9)
**Requirements**: FRONTEND-01, FRONTEND-02, FRONTEND-03
**Success Criteria** (what must be TRUE):

  1. Every React Query key is prefixed with `user.id` — per-user cache separation prevents cross-user data display
  2. Query cache is cleared (or fully invalidated) on login and logout — no stale data flashes across sessions
  3. Loading skeletons are displayed during re-fetch after user change — prevents brief cross-user data display

**Plans**: 3 plansPlans:

- [x] `10-01-PLAN.md` — Install @tanstack/react-query, create infrastructure (client/queryKeys/provider/hooks), Skeleton component, wire main.tsx
- [x] `10-02-PLAN.md` — Convert MonthlyPage + DashboardPage to React Query hooks + skeleton layouts
- [x] `10-03-PLAN.md` — Convert remaining pages (Summary, Insights, Assets, Categorize, InsightsWidget, AddTransaction) to React Query hooks + skeleton

### Phase 11: Account CRUD & Starting Balances

**Goal**: Users can create, rename, and delete accounts from the UI, and set starting balances per account. The balance-over-time charts reflect these starting balances so the net worth view is accurate from the user's chosen baseline.

**Depends on**: Phase 10 (frontend infrastructure)

**Requirements**: ACCT-01, ACCT-02, ACCT-03, BAL-01, BAL-02

**Success Criteria** (what must be TRUE):

  1. Users can create a new account (name, type, currency, starting balance) from the UI — no direct DB manipulation needed
  2. Users can rename and delete existing accounts from the UI; deletion protects against data loss (prevents deleting accounts with transactions)
  3. Users can set or edit a starting balance date + amount per account — the monthly opening balance computation incorporates per-account starting balances
  4. The balance-over-time chart uses per-account starting balances (not a single global value) so the net worth line is accurate
  5. Assets are reflected in the net worth computation on the chart (or explicitly scoped out with reasoning)

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 3/3 | Complete | 2026-06-07 |
| 2. Ingestion & Auth | v1.0 | 5/5 | Complete | 2026-06-07 |
| 3. Views & Categorization | v1.0 | 7/7 | Complete | 2026-06-07 |
| 4. AI Insights & Forecasting | v1.0 | 5/5 | Complete | 2026-06-07 |
| 04.9 Transaction List Enh. | v1.0 | 4/4 | Complete | 2026-06-07 |
| 4.5 Spiked Features | v1.0 | 2/2 | Complete | 2026-06-07 |
| 4.6 Dashboard & Assets | v1.0 | 2/2 | Complete | 2026-06-07 |
| 4.7 Auth UI | v1.0 | 2/2 | Complete | 2026-06-07 |
| 4.8 Excel Data Migration | v1.0 | 3/3 | Complete | 2026-06-07 |
| 5. Polishing & Deployment | v1.0 | 4/4 | Complete | 2026-06-07 |
| 6. Schema Migration & Backfill | v1.1 | 2/2 | Complete   | 2026-06-07 |
| 7. Backend Scoping | v1.1 | 4/4 | Complete   | 2026-06-07 |
| 8. Worker Isolation | v1.1 | 3/3 | Complete | 2026-06-07 |
| 9. Testing & Verification | v1.1 | 4/4 | Complete | 2026-06-07 |
| 10. Frontend Cache Isolation | v1.1 | 3/3 | Complete   | 2026-06-08 |
| 11. Account CRUD & Starting Balances | v1.2 | 0/0 | Planned   | — |

## Archive

Full v1.0 phase details archived at: `.planning/milestones/v1.0-ROADMAP.md`
Requirements archived at: `.planning/milestones/v1.0-REQUIREMENTS.md`
