# Project Research Summary

**Project:** Financial Planning App (v1.1 — Multi-Tenant Data Isolation)
**Domain:** Personal financial management — single-user to multi-user migration
**Researched:** 2026-06-07
**Confidence:** HIGH

## Executive Summary

This project adds multi-tenant data isolation to an existing single-user financial planning application. The app (Bun/Hono/postgres.js + React/Tailwind, with Better Auth) currently shares all financial data — accounts, categories, transactions, assets, opening balances, and import jobs — across every authenticated user. The `insights` table is the only exception, already scoped by `user_id`. The v1.1 milestone delivers per-user data isolation: each user sees and acts upon only their own data, with no sharing, RBAC, or team features.

**The recommended approach, strongly supported across all four research streams, is application-layer `user_id` scoping as the primary isolation mechanism.** This means adding a `user_id TEXT NOT NULL REFERENCES "user"(id)` column to six domain tables, then injecting `AND user_id = ${userId}` into every SQL query. This pattern is already proven in the codebase (the `insights` module uses it), requires zero new packages, and works safely with the existing postgres.js connection pool. Row-Level Security (RLS) is recommended as a **deferred stretch goal** — it adds connection-pool complexity that doesn't payoff for a single-admin app until data leakage becomes a demonstrated risk.

**Key risks are concentrated in four areas:** (1) missing `user_id` filters in existing queries (especially UPDATE/DELETE by ID), (2) the import worker operating outside HTTP middleware (no session context), (3) global UNIQUE constraints that will break under multi-tenancy (categories, assets, import_hash, opening_balances), and (4) frontend caches that leak data across user sessions. Each risk has a clear prevention strategy documented in the research. The recommended build order has hard dependencies: migration first, then use-case updates, then routes, then workers, then tests, then frontend, with a final audit pass before shipping.

## Key Findings

### Recommended Stack

**Stay with what works; add no new packages.** The existing stack handles everything needed:

| Technology | Purpose | Why Recommended |
|------------|---------|-----------------|
| postgres.js ^3.4.9 | Database client | Already in production. Tagged template SQL + dynamic fragments suffice for `AND user_id = ?` filters. |
| node-pg-migrate ^8.0.4 | Schema migrations | Already configured with `migrationFileLanguage: 'sql'`. Single migration file for all column additions + constraint changes. |
| Better Auth ^1.6.14 | Authentication | Already integrated. `requireAuth` middleware sets `c.get('user')` with `user.id` (TEXT type) — the tenant context source. |
| pg ^8.21.0 | Better Auth peer dep | Required by Better Auth internally for its own Pool connection. Separate from app's postgres.js. |

**Primary isolation:** Application-layer `AND user_id = ${userId}` in every query. Pattern already demonstrated in `insights/use-cases.ts`.

**No ORM, no new middleware libraries, no separate databases.** Adding Kysely/Prisma/Drizzle would create a dual-query-pattern maintenance burden for a single additional WHERE clause.

**Key constraint:** Better Auth's `"user".id` is `TEXT` (e.g., `"user_abc123"`), not UUID. All `user_id` foreign key columns must be `TEXT` to match. The `insights` table already demonstrates this correctly.

**No new packages needed anywhere** — not for scoping, not for testing, not for seeding.

### Expected Features

**Must have (table stakes):**
1. **user_id columns on all 6 domain tables** — migration adds column + FK + composite indexes
2. **Query scoping on every SQL operation** — ~15-20 query sites across use-cases and route handlers
3. **INSERTs include user_id** — mechanical change, `userId` from session only
4. **UNIQUE constraint migration** — 4 constraints must become user-scoped composite constraints
5. **Existing data backfill** — assign all existing rows to the first registered user
6. **Authorization checks on mutations** — verify ownership of referenced resources (account_id, category_id)
7. **On-signup seed data** — lazy-seeded default categories + default account for new users

**Should have (differentiators - stretch for v1.1):**
- **RLS as defense-in-depth** — skip for now. Adds connection pool complexity.
- **Migration without downtime** — not needed for self-hosted app. Schedule 15-30 min maintenance window.

**Defer (v1.2+):**
- Data export/deletion per user
- Soft-delete support
- Sharing/permissions/RBAC
- Organization/team accounts (Better Auth Organization plugin)
- User-specific database schemas

**Explicitly not building:**
- Organization/team accounts — scope is "no sharing, no RBAC"
- Row-Level Security as primary isolation — connection-pool risk
- User-specific schemas/separate databases — not justified for personal finance

### Architecture Approach

**Row-level isolation via user-ID scoping at the API layer.** Every tenant-scoped query includes `WHERE user_id = ${userId}`. This is explicit, auditable, and connection-pool safe.

```
Session Middleware (c.get('user') → userId)
  → Route Handlers (extract userId, pass to use-cases)
    → Use-Case Functions (accept userId param, inject into SQL)
      → postgres.js (tagged template queries with WHERE user_id = ?)
        → PostgreSQL (6 scoped tables + user_id FK + composite indexes)
```

**Major components (modified, not new):**
1. **Route handlers** (6 files) — extract `userId` from `c.get('user')`, pass to every use-case call. Never trust `user_id` from client input.
2. **Use-case functions** (4 use-case files) — accept `userId` as parameter, include `WHERE user_id = ${userId}` in every SQL query. Pattern from `insights/use-cases.ts`.
3. **Migration 007** — adds `user_id` columns, backfills data, adds composite indexes, replaces global UNIQUE constraints with per-user composite constraints.
4. **Category seeder** — lazy-seeds default categories + default account on first data access for new users.
5. **Workers** (import + insights) — import worker gets `user_id` from PGMQ payload; insights worker already scoped correctly.

**Key patterns to follow:**
- `userId` as a function parameter (not module-level state, not thread-local)
- `user_id` from session only, never from client input (security boundary)
- Lazy seeding on first GET /categories (no signup hook dependency)
- Scoped unique constraints: `UNIQUE(user_id, name)` replaces global `UNIQUE(name)`
- Deferred RLS — only if app-layer scoping proves insufficient

### Critical Pitfalls

1. **Missing `user_id` filters in existing queries** — The highest-risk pitfall. Every `SELECT`, `UPDATE`, `DELETE` on scoped tables must include `AND user_id = ${userId}`. A single missed filter (especially in UPDATE/DELETE by ID) leaks or corrupts cross-user data. **Prevention:** Systematic audit of every `sql\`` call site (~20 locations across 6 use-case files + route handlers + workers). Use case from PITFALLS.md: the `PATCH /:id/category` endpoint has inline SQL that bypasses use-cases entirely.

2. **Worker auth session gap** — Workers (import-worker, insights-worker) run outside HTTP middleware and have no `c.get('user')`. The import worker currently has zero user context. **Prevention:** Add `user_id` to PGMQ message schemas and `import_jobs` table. Workers extract user from the queue payload, never from an auth session.

3. **Global UNIQUE constraint collisions** — Four constraints break under multi-tenancy: `categories.name`, `assets.name`, `transactions.import_hash`, and `monthly_opening_balances(year, month)`. Each must become a composite `UNIQUE(user_id, ...)`. **Prevention:** Drop global constraints in migration, create per-user composite unique indexes. Order matters — backfill before adding composite constraints.

4. **Frontend cache leaking data across user sessions** — React Query keys without `user.id` prefix, or not clearing cache on logout, causes users to briefly see stale data from the previous session. **Prevention:** Key all queries by `user.id`, call `queryClient.clear()` on auth change.

5. **NOT NULL + backfill order** — Adding `user_id` as NOT NULL on existing tables requires a multi-step migration: add as nullable, backfill, then `SET NOT NULL`. Skipping the backfill step or ordering incorrectly causes migration failures or data integrity holes.

## Implications for Roadmap

Based on research, the following phase structure is recommended. The order has hard dependencies — e.g., use-cases can't be updated before the schema migration runs, and routes can't be updated before use-cases.

### Phase 1: Schema Migration + Backfill

**Rationale:** Everything depends on the database having `user_id` columns. This must come first — no code changes work without the schema.

**Delivers:**
- SQL migration file (`007_multi_tenant_isolation.sql`) with:
  - `ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE` on 6 tables
  - Backfill existing rows to first registered user
  - Composite indexes on `(user_id, ...)` for common query patterns
  - Drop 4 global UNIQUE constraints, add per-user composite `UNIQUE(user_id, ...)`
  - Composite unique index `(user_id, import_hash)` replacing global import_hash constraint
- Seed SQL files updated with `user_id` values for dev data

**Addresses features:** T-1 (user_id columns), T-4 (UNIQUE constraints), T-6 (data backfill), P-5 (import_hash collision), P-6 (category/asset name collision), P-7 (opening balance collision)

**Avoids pitfalls:** P-2 (NOT NULL order — multi-step: nullable → backfill → NOT NULL), P-7 (opening balance constraint)

**Research flag:** No deeper research needed. Schema migration patterns are well-established. Confidence: HIGH.

---

### Phase 2: Use-Case Updates (Core Scoping)

**Rationale:** The core business logic layer must accept and enforce `userId` before route handlers can pass it. This is where the actual isolation lives.

**Delivers:**
- `userId` parameter added to every use-case function in `ledger/use-cases.ts`, `assets/use-cases.ts`, `import/use-cases.ts`
- All `SELECT`, `INSERT`, `UPDATE`, `DELETE` queries include `user_id` filter or value
- `PATCH /:id/category` inline SQL refactored into a use-case function with ownership checks
- Ownership validation pattern: `verifyOwnership(resourceType, resourceId, userId)` helper for mutation endpoints
- The `on conflict` clause accounts for new composite unique constraints

**Addresses features:** T-2 (query scoping), T-3 (INSERTs include user_id), T-5 (authorization checks)

**Avoids pitfalls:** P-3 (query scoping misses — systematic audit of every query site), P-10 (ownership validation gap)

**Research flag:** Standard patterns. Use-cases are well-structured and the `insights` module provides an exact model to follow. **Skip research-phase.** Confidence: HIGH.

---

### Phase 3: Route Handler Updates

**Rationale:** Routes depend on use-cases. Must come after Phase 2 since the function signatures change.

**Delivers:**
- All route handlers in `ledger.ts`, `reference.ts`, `assets.ts`, `import.ts` extract `userId = c.get('user')!.id` and pass to use-cases
- `GET /accounts` and `GET /categories` in `reference.ts` updated with user_id filter
- No route handler sets `user_id` from request body — enforced by code review
- Lazy seeding hook: `GET /categories` checks and seeds defaults for new users

**Addresses features:** T-2 (query scoping — route layer), D-2 (seed data on signup — lazy)

**Avoids pitfalls:** P-10 (inline SQL in route handlers — specifically the `PATCH /:id/category` endpoint)

**Research flag:** Well-documented pattern. Routes already follow consistent structure. **Skip research-phase.** Confidence: HIGH.

---

### Phase 4: Worker User-Scoping

**Rationale:** Workers run in a separate process without HTTP middleware. They need `user_id` passed through PGMQ message payloads. Must follow the schema migration (Phase 1) since `import_jobs` needs `user_id` column.

**Delivers:**
- `import_jobs.user_id` column populated on enqueue (API route passes `userId` from session)
- PGMQ message schemas updated to include `user_id` for CSV import and Excel migration jobs
- Import worker extracts `user_id` from PGMQ payload, tags all inserted transactions
- Import worker validates `account_id` belongs to `user_id` before processing
- Insights worker already scoped — verify and add explicit `user_id` validation
- `enqueueImportJob` and `enqueueAnalysisJob` functions accept and propagate `userId`

**Addresses features:** T-2 (worker query scoping)

**Avoids pitfalls:** P-4 (worker auth session gap — the primary worker pitfall)

**Research flag:** Workers have their own code paths and message schemas. **Needs deeper research during planning** — specifically mapping the PGMQ message payload structure and ensuring `user_id` flows correctly through the enqueue → process pipeline. The import worker may need a design sketch for how it receives and validates user context. Phase may require `/gsd-plan-phase --research-phase <4>`.

---

### Phase 5: Testing + Isolation Test Matrix

**Rationale:** All code changes must be in place before tests can validate them. Tests need at least 2 test users and real cross-user scenarios.

**Delivers:**
- Test matrix covering CREATE/READ/UPDATE/DELETE/LIST for all 6 resource types × 3 users
- Negative tests: User B cannot read/update/delete User A's data by ID
- Worker isolation tests: Worker processes only the correct user's data
- API returns 404 (not 403) for cross-user resource access by ID
- Concurrent operation tests (two users inserting simultaneously)
- Migration rollback test
- Frontend cache clearance test

**Addresses features:** All T-features, verification

**Avoids pitfalls:** P-9 (testing blindspots — the specific test matrix prevents this)

**Research flag:** Well-established testing patterns. Use Bun's built-in test runner. **Skip research-phase.** Confidence: HIGH.

---

### Phase 6: Frontend State Management

**Rationale:** The backend API responses won't change shape, but the frontend's client-side state management must be isolation-aware. Doesn't block backend deployment.

**Delivers:**
- React Query keys updated to include `user.id`: e.g., `['transactions', user.id]`
- `queryClient.clear()` or full invalidation on login/logout to prevent stale-data flashes
- Per-user cache separation ensures no data leaks via client-side state
- Optional: `<App key={user.id} />` pattern for hard reset on user change
- Loading skeleton states to prevent brief cross-user data display during re-fetch

**Addresses features:** D-3 (frontend isolation)

**Avoids pitfalls:** P-8 (frontend cached data surviving across sessions)

**Research flag:** Standard React Query patterns. Needs a quick audit of existing query keys and auth state management. **Potentially skip research-phase** — well-documented patterns, low complexity.

---

### Phase 7: Final Audit + RLS (Stretch)

**Rationale:** Final pass before shipping. Systematically verifies every query point. RLS is deferred to a future milestone but migration SQL is prepared.

**Delivers:**
- Run the "Looks Done But Isn't" checklist from PITFALLS.md (~25 checks)
- Automated grep/scan for `sql\`` template literals on domain tables without `user_id` filter
- Verify all inline SQL has been refactored into use-case functions
- (Stretch) Optional RLS policies — CREATE POLICY per table, enabled with FORCE ROW LEVEL SECURITY in test envs only
- Migration rollback verified
- Recovery strategies documented

**Addresses features:** Quality assurance, (stretch) D-1 (RLS)

**Avoids pitfalls:** P-1 (RLS), P-10 (ownership validation gap — final audit catches anything missed)

**Research flag:** **Needs deeper research during planning** — if RLS is pursued, the connection-pool integration pattern (`sql.reserve()` + `sql.release()` per request or `SET LOCAL` inside `sql.begin()`) needs a design decision. The research makes a strong case to skip RLS for v1.1.

---

### Phase Ordering Rationale

The build order follows hard dependency chains: schema → use-cases → routes → workers → tests → frontend → audit.

- **Phase 1 first** because no code change works without the database columns existing
- **Phase 2 before Phase 3** because route handlers call use-case functions whose signatures change
- **Phases 2+3 before Phase 4** because worker enqueue functions (called from routes) need to pass userId
- **Phases 1-4 before Phase 5** because tests need the actual scoping code deployed
- **Phase 6 independent** — can run in parallel with Phase 5 since frontend changes are isolated from backend
- **Phase 7 last** — final check before shipping

**What could be parallel:**
- Phases 2 and 3 (if use-case stubs are provided first) — but safer to do sequentially
- Phases 5 and 6 (frontend tests + backend tests are independent)
- Phase 7's audit checklist with minimal code changes

**Deferred:**
- RLS (stretch) — not recommended for v1.1. Complexity outweighs benefit for single-user-turned-multi-user app.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Workers):** Must map exact PGMQ message schema for import worker, verify enqueue → process pipeline, and design user_id flow through the queue. Import worker has no existing user context. This needs a design sketch or `/gsd-plan-phase --research-phase <4>`.
- **Phase 7 (if RLS pursued):** Connection-pool integration pattern (`SET LOCAL` inside `sql.begin()` vs. `sql.reserve()` per request) needs a decision. Strong evidence to skip RLS entirely for v1.1.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Schema Migration):** Well-documented Postgres migration pattern. node-pg-migrate already configured.
- **Phase 2 (Use-Cases):** The `insights` module provides exact pattern to follow.
- **Phase 3 (Routes):** Routes follow consistent pattern. Mechanical changes.
- **Phase 5 (Testing):** Standard cross-user isolation test matrix.
- **Phase 6 (Frontend):** Standard React Query key management + cache invalidation.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Existing stack verified against production codebase. No new packages needed. Postgres RLS integration well-documented but deferred. |
| Features | HIGH | All 6 must-have features identified through direct codebase audit. Anti-features clearly scoped out per project constraints. |
| Architecture | HIGH | Architecture verified against actual codebase structure. The `insights` module provides proven reference pattern. 37+ query sites audited. |
| Pitfalls | HIGH | Every pitfall verified against real codebase code. 486-line document with specific file/line references. Recovery strategies costed. |

**Overall confidence:** HIGH

### Gaps to Address

- **Worker PGMQ message schema detail:** The exact payload structure for import worker PGMQ messages was not fully mapped during research. Phase 4 planning needs to read the actual message schema files and design the user_id injection point.
- **Frontend query key audit:** The exact set of React Query keys used across all frontend components was not audited during research. Phase 6 planning needs a quick scan to identify all query keys and update them with `user.id`.
- **import_hash computation detail:** The `computeImportHash` function should ideally include `user_id` in the hash input for defense-in-depth. This needs verification during Phase 2 implementation — a minor change but worth noting.
- **Seed data list for Polish personal finance categories:** The exact set of default categories for lazy seeding was suggested but not verified against the existing `seed.sql`. Phase 2 implementation should reconcile against the actual seed file.

## Sources

### Primary (HIGH confidence)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) — Row Security Policies, ALTER TABLE, FORCE RLS
- [PostgreSQL Customized Options](https://www.postgresql.org/docs/current/runtime-config-custom.html) — Custom GUC parameters (`app.*` namespace)
- [postgres.js GitHub](https://github.com/porsager/postgres) — Tagged template SQL, connection pool, reserved connections
- [Hono Context API](https://hono.dev/docs/api/context) — c.get/c.set patterns, existing middleware chain
- [Better Auth Hono Integration](https://www.better-auth.com/docs/integrations/hono) — Session middleware, `c.get('user')` pattern
- [Better Auth Database Hooks](https://www.better-auth.com/docs/concepts/database) — Post-signup seeding hooks
- Existing codebase audit: all route files, all use-cases, workers, `seed.sql`, `auth.ts`, `index.ts` — verified against actual project state
- [spike-findings-finance: import-dedup.md](file:///home/olafk/finance/.opencode/skills/spike-findings-finance/references/import-dedup.md) — import_hash computation, dedup patterns

### Secondary (MEDIUM confidence)
- Domain experience with multi-tenant migrations (YNAB, Actual Budget, Firefly III architecture patterns)
- Community consensus on RLS vs application-layer isolation for single-admin apps

---

*Research completed: 2026-06-07*
*Ready for roadmap: yes*
