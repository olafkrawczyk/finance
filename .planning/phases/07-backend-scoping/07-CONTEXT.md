# Phase 7: Backend Scoping - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Every route handler, use-case function, and seed path enforces per-user data isolation. All CRUD operations on accounts, categories, transactions, opening balances, assets, and import jobs are scoped by `user_id`. Reference data queries (categories, accounts) extracted from inline SQL into use-case functions. New users receive default categories and account via Better Auth signup hook.

</domain>

<decisions>
## Implementation Decisions

### Use-case Signature Pattern
- **D-01:** All use-cases accept userId via params object pattern (insights style), e.g., `createTransaction({ userId, accountId, ... })`. Consistent with existing insights module.

### Ownership Validation
- **D-02:** Ownership validation is implicit via SQL WHERE — add `AND user_id = ${userId}` to every scoped query. Resources not owned by the user return empty/404 naturally (consistent with TEST-02 requiring 404, not 403). No explicit validation helper needed.

### Default Seeding
- **D-03:** Better Auth `onSignUp` hook creates default categories + default account on user registration. Pivot from prior "lazy seeding on first GET /categories" — user confirmed signup hook is preferred.

### Reference Data Use-cases
- **D-04:** New `src/core/reference/use-cases.ts` — extracted from inline SQL in `reference.ts`. Contains `listAccounts(userId)` and `listCategories(userId)`. Separate from ledger/transaction modules.

### Import Scoping Boundary (Phase 7 vs Phase 8)
- **D-05:** Phase 7 scopes the enqueue side — user_id added to import_jobs insert and threaded into PGMQ payload. Worker-side enforcement (validating account ownership, tagging transactions) deferred to Phase 8.

### Folded Todos
- **extract-llm-descriptions.md** — Extract LLM category descriptions from `buildFewShotPrompt` in `src/workers/import-worker.ts` into `llm_description` column on categories table. Requires: (1) migration to add `llm_description TEXT` column, (2) seed data population with descriptions, (3) update `buildFewShotPrompt` to read from DB.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` § SCOPE-01 through SCOPE-07 — Locked query scoping requirements
- `.planning/REQUIREMENTS.md` § SEED-01 through SEED-03 — Default seeding requirements

### Route Handlers (all need scoping)
- `src/interface-adapters/api/ledger.ts` — Transaction routes (POST, GET, PUT, DELETE, PATCH /:id/category)
- `src/interface-adapters/api/assets.ts` — Asset routes (GET, POST, PUT, DELETE)
- `src/interface-adapters/api/import.ts` — Import routes (POST, GET /:job_id)
- `src/interface-adapters/api/opening-balance.ts` — Opening balance routes (GET, POST, PUT)
- `src/interface-adapters/api/reference.ts` — Reference data (GET /accounts, GET /categories) — inline SQL to extract
- `src/interface-adapters/api/migration.ts` — Excel migration route (POST /excel)
- `src/interface-adapters/api/insights.ts` — Already scoped — reference pattern
- `src/index.ts` — Main app router, session middleware

### Use-cases (need userId param added)
- `src/core/ledger/use-cases.ts` — createTransaction, listTransactions, getMonthlySummary, getTransaction, updateTransaction, deleteTransaction, createOpeningBalance, updateOpeningBalance, listOpeningBalances
- `src/core/assets/use-cases.ts` — listAssets, createAsset, updateAsset, deleteAsset
- `src/core/import/use-cases.ts` — enqueueImportJob, getImportStatus

### Auth & Session
- `src/interface-adapters/api/auth.ts` — requireAuth middleware (sets `c.set('user', ...)`)
- `src/index.ts` lines 33-38 — Global session middleware

### Seeding & Migration
- `src/infrastructure/db/migrations/` — Next migration number: 011 (for llm_description column)
- `src/workers/import-worker.ts` — `buildFewShotPrompt` function (needs descriptions extracted)
- `src/infrastructure/db/schema.sql` — Categories table (needs llm_description column added)

### Existing Scoping Pattern
- `src/core/insights/use-cases.ts` — Established user-scoping pattern (params object with userId)
- `src/interface-adapters/api/insights.ts` — Route handler pattern for extracting user from session

### Phase 6 Context
- `.planning/phases/06-schema-migration-backfill/06-CONTEXT.md` — Prior decisions on user_id columns, fresh DB assumption

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/interface-adapters/api/auth.ts` — `requireAuth` middleware already sets `c.set('user', ...)` and `c.set('session', ...)`
- `src/index.ts:33-38` — Global session middleware that always populates user/session
- `src/core/insights/use-cases.ts` — Reference implementation for user-scoped use-cases with params object pattern

### Established Patterns
- **User extraction:** `const user = c.get('user');` then pass `user.id` to use-cases
- **Use-case signature:** Params object with `userId` property (insights pattern)
- **SQL scoping:** `WHERE user_id = ${userId}` in queries (insights pattern)
- **Error handling:** 404 for not-found, 401 from requireAuth for unauthenticated, no 403 for cross-user access

### Integration Points
- All route handlers import `requireAuth` from `./auth` — already applied
- `src/index.ts` mounts routes — no changes needed unless new routes are created
- Better Auth config in `src/auth.ts` — needs `onSignUp` hook registration
- Categories schema needs `llm_description TEXT` column via new migration

</code_context>

<specifics>
## Specific Ideas

No specific requirements — standard scoping approach using the established insights module pattern.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

### Reviewed Todos (not folded)
- **auth-guard-and-redirect.md** — Frontend auth wiring, Phase 10 concern
- **auth-login-signup-page.md** — Frontend auth UI, Phase 10 concern
- **auth-logout-button.md** — Frontend auth UI, Phase 10 concern

</deferred>

---

*Phase: 7-Backend Scoping*
*Context gathered: 2026-06-07*
