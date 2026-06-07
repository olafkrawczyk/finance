# Phase 7: Backend Scoping - Research

**Researched:** 2026-06-07
**Domain:** User-scoped data isolation for all CRUD operations
**Confidence:** HIGH

## Summary

Phase 7 implements per-user data isolation across the entire backend API. Every SELECT, INSERT, UPDATE, and DELETE on scoped tables (accounts, categories, transactions, monthly_opening_balances, assets, import_jobs) must include the authenticated user's ID. The established pattern from the insights module (`src/core/insights/use-cases.ts`) serves as the reference implementation: use-cases accept `userId` via a params object, route handlers extract `userId` from session (`c.get('user').id`), and SQL queries filter/tag with `WHERE user_id = ${userId}`.

Six route handler files need userId extraction and plumbing. Six use-case modules need userId parameter addition. One new use-case file (`src/core/reference/use-cases.ts`) extracts inline SQL from `reference.ts`. The Better Auth configuration needs an `onSignUp` hook to seed default categories and a default account. A new migration (011) adds the folded `llm_description` column to categories. Import enqueue is scoped this phase; worker-side enforcement is deferred to Phase 8.

**Primary recommendation:** Follow the insights module pattern exactly — params object with `userId`, implicit WHERE-based ownership filtering leading to natural 404 responses, and Better Auth `onSignUp` hook for default seeding.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** All use-cases accept userId via params object pattern (insights style), e.g., `createTransaction({ userId, accountId, ... })`. Consistent with existing insights module.
- **D-02:** Ownership validation is implicit via SQL WHERE — add `AND user_id = ${userId}` to every scoped query. Resources not owned by the user return empty/404 naturally. No explicit validation helper needed.
- **D-03:** Better Auth `onSignUp` hook creates default categories + default account on user registration. Pivot from prior "lazy seeding on first GET /categories".
- **D-04:** New `src/core/reference/use-cases.ts` — extracted from inline SQL in `reference.ts`. Contains `listAccounts(userId)` and `listCategories(userId)`. Separate from ledger/transaction modules.
- **D-05:** Phase 7 scopes the enqueue side — user_id added to import_jobs insert and threaded into PGMQ payload. Worker-side enforcement deferred to Phase 8.
- **Folded todo:** `extract-llm-descriptions.md` — (1) migration to add `llm_description TEXT` column to categories, (2) seed data population with descriptions, (3) update `buildFewShotPrompt` to read from DB.

### the agent's Discretion

*None explicitly listed — all key decisions are locked.*

### Deferred Ideas (OUT OF SCOPE)

- `auth-guard-and-redirect.md` — Frontend auth wiring, Phase 10
- `auth-login-signup-page.md` — Frontend auth UI, Phase 10
- `auth-logout-button.md` — Frontend auth UI, Phase 10
- Worker-side import enforcement — Phase 8
- Multi-user isolation testing — Phase 9
- Frontend cache isolation — Phase 10
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCOPE-01 | Every SELECT on scoped tables filters by `user_id` | Insights pattern verified in `src/core/insights/use-cases.ts` lines 92-98 (listInsights), 112-119 (dismissInsight), 134-141 (getInsightsForDashboard). All use-cases must add `AND user_id = ${userId}` to WHERE clauses. |
| SCOPE-02 | Every INSERT on scoped tables includes `user_id` | All INSERT statements in use-cases need `user_id` column added. Schedule schemas (`src/application/schemas/ledger.ts`, `assets.ts`, `import.ts`) do NOT include `user_id` — it comes from session, not client. |
| SCOPE-03 | Every UPDATE on scoped tables filters by `user_id` | Same WHERE pattern as SELECT. `updateTransaction`, `updateOpeningBalance`, `updateAsset` need `AND user_id = ${userId}`. |
| SCOPE-04 | Every DELETE on scoped tables filters by `user_id` | `deleteTransaction`, `deleteAsset` need `AND user_id = ${userId}`. |
| SCOPE-05 | Ownership validation on mutations — referenced resources (account_id, category_id) validated to belong to current user | Implicit via SQL WHERE per D-02. When a mutation references an account/category not owned by the user, the row won't be found → 404. No separate validation step needed. |
| SCOPE-06 | Route handlers extract `userId` from session (`c.get('user').id`) — never trust `user_id` from client input | Insights pattern: `src/interface-adapters/api/insights.ts` lines 36-37 (`const user = c.get('user')`). All 6 route files must follow this. |
| SCOPE-07 | Inline SQL in route handlers refactored into use-case functions with scoping | `src/interface-adapters/api/ledger.ts` PATCH /:id/category has inline SQL (lines 185-189). Must be extracted to a use-case function in `src/core/ledger/use-cases.ts`. `src/interface-adapters/api/reference.ts` has inline SQL in both routes — extracted to `src/core/reference/use-cases.ts` per D-04. |
| SEED-01 | Default categories seeded per new user | Better Auth `onSignUp` hook in `src/auth.ts`. Must insert 25 default categories + 2 default accounts. |
| SEED-02 | Default account created for new users | Same hook. Accounts: ING Business + IPKO Personal. |
| SEED-03 | Lazy seeding on first GET /categories | **PIVOTED**: Now uses Better Auth `onSignUp` hook per D-03. SEED-03 requirement text is outdated. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| User-scoped data querying | API / Backend (use-cases) | Database | Use-cases add `WHERE user_id = ${userId}` to SQL. Database enforces via FK + indexes. |
| User extraction from session | API / Backend (route handlers) | — | Route handlers call `c.get('user')` — pure Hono middleware concern. |
| Ownership validation | API / Backend (use-cases) | Database | Implicit via SQL WHERE returning 0 rows → 404. No separate tier needed. |
| Default user seeding | API / Backend (auth config) | Database | Better Auth `onSignUp` hook runs on registration. DB stores seeded defaults. |
| Import job scoping (enqueue) | API / Backend (use-cases) | Queue (PGMQ) | user_id added to import_jobs row + PGMQ JSON payload. Phase 8 handles worker enforcement. |
| LLM description extraction | Database (migration) | API / Backend (worker) | Migration adds column. Worker `buildFewShotPrompt` updated to read from DB instead of hardcoded strings. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Hono | ^4.12.23 | HTTP framework | Already the backend framework. Route handlers use `c.get('user')` for session extraction. |
| postgres.js | ^3.4.9 | SQL client | Already the DB client. Template tag style `sql\`...\`` supports dynamic WHERE clauses. |
| Better Auth | ^1.6.14 | Authentication | Already the auth provider. `onSignUp` hook for default seeding. Session middleware already in `index.ts`. |
| Zod | ^4.4.3 | Schema validation | Already used. Application schemas don't include `user_id` — it comes from session, not client input. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bun:test | built-in | Test runner | All existing tests use it. `app.request()` pattern for HTTP tests. |
| zod | ^4.4.3 | Input validation | Use existing schemas (no user_id in schemas). |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Implicit SQL WHERE scoping | Explicit ownership helper | Extra validation code. Decision D-02 favors implicit WHERE → 404. |
| Params object with userId | First positional arg | Mixes scalar with object params. Decision D-01 favors consistent params object. |
| Lazy seeding on first GET | Signup hook | Need to check on every request. D-03 favors hook for exactly-once seeding. |

## Package Legitimacy Audit

> **No new packages required for this phase.** All work uses existing dependencies (Hono, postgres.js, Better Auth, Zod, bun:test). The Better Auth `onSignUp` hook is a built-in feature of the already-installed `better-auth@^1.6.14`.

| Package | Disposition |
|---------|-------------|
| *All packages are existing dependencies* | No new installs needed |

## Architecture Patterns

### System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                        HTTP Request                                  │
│                          │                                            │
│                          ▼                                            │
│  ┌──────────────────────────────────────────────────────┐            │
│  │              Global Session Middleware                 │            │
│  │  (index.ts:33-38) sets c.set('user', session.user)    │            │
│  └────────────────────┬───────────────────────────────────┘            │
│                       │                                              │
│                       ▼                                              │
│  ┌──────────────────────────────────────────────────────┐            │
│  │              Route Handler Layer                       │            │
│  │                                                       │            │
│  │  1. Extracts: const user = c.get('user')              │            │
│  │  2. Passes: await useCase({ userId: user.id, ... })   │            │
│  │  3. Response: c.json() with data                      │            │
│  └────────────────────┬───────────────────────────────────┘            │
│                       │                                              │
│                       ▼                                              │
│  ┌──────────────────────────────────────────────────────┐            │
│  │              Use-Case Layer (scoped)                   │            │
│  │                                                       │            │
│  │  SELECT:  WHERE user_id = ${userId} ...               │            │
│  │  INSERT:  VALUES (..., ${userId})                     │            │
│  │  UPDATE:  SET ... WHERE user_id = ${userId} AND id=X  │            │
│  │  DELETE:  DELETE FROM ... WHERE user_id = ${userId}   │            │
│  │                                                       │            │
│  │  Ownership validation: implicit via WHERE → empty=404 │            │
│  └────────────────────┬───────────────────────────────────┘            │
│                       │                                              │
│                       ▼                                              │
│  ┌──────────────────────────────────────────────────────┐            │
│  │              Database (Postgres)                       │            │
│  │                                                       │            │
│  │  - UNIQUE(user_id, name) on categories & assets       │            │
│  │  - UNIQUE(user_id, import_hash) on transactions       │            │
│  │  - UNIQUE(user_id, year, month) on opening_balances   │            │
│  │  - FK: user_id → "user"(id) ON DELETE CASCADE         │            │
│  └──────────────────────────────────────────────────────┘            │
│                                                                      │
│  ┌──────────────────────────────────────────────────────┐            │
│  │              Better Auth onSignUp Hook                 │            │
│  │                                                       │            │
│  │  On user registration:                                │            │
│  │    1. INSERT INTO categories (25 defaults + user_id)  │            │
│  │    2. INSERT INTO accounts (2 defaults + user_id)     │            │
│  └──────────────────────────────────────────────────────┘            │
│                                                                      │
│  ┌──────────────────────────────────────────────────────┐            │
│  │              PGMQ Queue (import)                      │            │
│  │                                                       │            │
│  │  Phase 7: user_id in JSON payload                     │            │
│  │  Phase 8: worker validates user_id                    │            │
│  └──────────────────────────────────────────────────────┘            │
└──────────────────────────────────────────────────────────────────────┘
```

**Data flow (primary use case — authenticated user lists their transactions):**
1. Client → HTTP GET /transactions (with session cookie)
2. Global session middleware sets `c.set('user', ...)` 
3. Route handler extracts `const user = c.get('user')`
4. Route handler calls `listTransactions({ userId: user.id, page, per_page, ... })`
5. Use-case adds `AND user_id = ${userId}` to WHERE clause
6. Postgres returns only this user's transactions
7. Response: 200 with user-scoped data

### Recommended Project Structure

```
src/
├── auth.ts                              # [ADD onSignUp hook for default seeding]
├── core/
│   ├── ledger/
│   │   └── use-cases.ts                 # [MODIFY: add userId to all functions]
│   ├── assets/
│   │   └── use-cases.ts                 # [MODIFY: add userId to all functions]
│   ├── import/
│   │   └── use-cases.ts                 # [MODIFY: add userId to enqueue + getImportStatus]
│   ├── reference/
│   │   └── use-cases.ts                 # [NEW: listAccounts(userId), listCategories(userId)]
│   └── insights/
│       └── use-cases.ts                 # Already scoped — reference pattern
├── infrastructure/
│   └── db/
│       ├── migrations/
│       │   └── 011_add_llm_description.sql  # [NEW: migration + update buildFewShotPrompt]
│       └── schema.sql                   # Already updated with user_id columns
├── interface-adapters/
│   └── api/
│       ├── ledger.ts                    # [MODIFY: extract userId, pass to use-cases]
│       ├── assets.ts                    # [MODIFY: extract userId, pass to use-cases]
│       ├── import.ts                    # [MODIFY: extract userId, pass to use-cases]
│       ├── opening-balance.ts           # [MODIFY: extract userId, pass to use-cases]
│       ├── reference.ts                 # [MODIFY: inline SQL → new use-cases]
│       ├── migration.ts                 # [MODIFY: extract userId, pass to use-cases]
│       └── insights.ts                  # Already scoped — reference pattern
├── application/
│   └── schemas/
│       ├── ledger.ts                    # NO CHANGE — schemas don't include user_id
│       ├── assets.ts                    # NO CHANGE
│       └── import.ts                    # NO CHANGE
└── workers/
    └── import-worker.ts                 # [MODIFY: buildFewShotPrompt to read llm_description]
```

### Pattern 1: Use-Case with User Scoping (Insights Style)
**What:** Every use-case function accepts `userId` via a params object and filters/tags SQL queries with it.
**When to use:** All use-case functions in Phase 7 scope.
**Example:**
```typescript
// Source: src/core/insights/use-cases.ts (existing reference pattern)
// VERIFIED: codebase inspection — this is the established pattern

// Route handler pattern:
const user = c.get('user');
const { rows, total } = await listInsights({
  userId: user.id,
  type: query.type,
  dismissed: query.dismissed,
  page: query.page,
  per_page: query.per_page,
});

// Use-case pattern:
export async function listInsights(params: {
  userId: string;
  type?: InsightType;
  dismissed?: boolean;
  page: number;
  per_page: number;
}): Promise<{ rows: Insight[]; total: number }> {
  const { userId, type, dismissed, page, per_page } = params;
  const rows = await sql`
    SELECT * FROM insights
    WHERE user_id = ${userId}
      ${type ? sql`AND type = ${type}` : sql``}
    ...
  `;
}
```

### Pattern 2: Ownership Validation via Implicit SQL WHERE
**What:** No separate ownership check. Adding `AND user_id = ${userId}` to every query means non-owned resources produce empty result sets → natural 404. Consistent with TEST-02 which requires 404 (not 403).
**When to use:** Every UPDATE and DELETE query in scoped use-cases.
**Example:**
```typescript
// Source: src/core/insights/use-cases.ts lines 112-119
// VERIFIED: codebase inspection

export async function dismissInsight(id: string, userId: string): Promise<Insight | null> {
  const [row] = await sql`
    UPDATE insights
    SET dismissed = true
    WHERE id = ${id} AND user_id = ${userId}
    RETURNING *
  `;
  return (row as Insight) || null;  // null → caller returns 404
}
```

### Anti-Patterns to Avoid
- **Passing userId as a positional argument separate from params object** — mixes patterns across modules. Always use params object (insights style) per D-01.
- **Adding user_id to Zod validation schemas** — `user_id` must come from session only, never from client input (SCOPE-06). Schemas remain unchanged.
- **Explicit ownership validation helper** — per D-02, ownership is implicit via SQL WHERE. Adding `validateOwnership()` would be redundant and inconsistent with the 404 approach.
- **Lazy seeding guard in route handlers** — per D-03, seeding now happens in the signup hook. Don't add seeding logic in route handlers.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| User ID extraction from session | Manual cookie parsing | `c.get('user')` via Hono middleware | Global session middleware in `index.ts:33-38` already sets `c.set('user', ...)`. |
| Default seeding on registration | Custom registration endpoint | Better Auth `onSignUp` hook | Built-in hook fires exactly once, no extra request, no lazy seeding checks. |
| SQL templating with conditionals | String concatenation | postgres.js tagged template `${...}` | Already used everywhere. postgres.js handles parameterization and injection safety. |
| PGMQ JSON payload construction | String building | `JSON.stringify(…)::jsonb` | Already used in `src/core/import/use-cases.ts` line 35. |

**Key insight:** The entire scoping implementation follows a single consistent pattern already proven in the insights module. No new libraries, no new infrastructure, no new patterns. Every change is mechanical — add userId to params, add WHERE to SQL, extract from session in routes.

## Common Pitfalls

### Pitfall 1: Forgetting to scope getMonthlySummary
**What goes wrong:** `getMonthlySummary()` aggregates ALL transactions across all users, leaking cross-user financial summary data.
**Why it happens:** The function currently has no WHERE clause at all. It's easy to overlook because it's an aggregate query, not a simple list.
**How to avoid:** Add `WHERE t.user_id = ${userId}` to the aggregation query. Add `AND user_id = ${userId}` to the `monthly_opening_balances` subquery too.
**Warning signs:** Dashboard shows combined data from all users.

### Pitfall 2: Inline SQL in route handlers (PATCH /:id/category)
**What goes wrong:** The `PATCH /transactions/:id/category` route in `ledger.ts` (lines 185-189) has inline SQL with no user_id filtering. If this is overlooked, cross-user category assignment is possible.
**Why it happens:** It's the only inline SQL in the ledger route handler, easy to miss during bulk changes to the use-case file.
**How to avoid:** Extract `assignCategory(transactionId, categoryId, userId)` into `src/core/ledger/use-cases.ts` as part of SCOPE-07.
**Warning signs:** Manual grep for `sql\` in interface-adapters/api/ after changes.

### Pitfall 3: Migration route (migration.ts) TRUNCATE without user scoping
**What goes wrong:** The Excel migration route (POST /api/migration/excel) does `TRUNCATE transactions, monthly_opening_balances, insights, import_jobs CASCADE` — this destroys ALL users' data, not just the current user's.
**Why it happens:** The migration is a destructive admin operation. Currently no user scoping exists.
**How to avoid:** This may be intentional (migration resets all data). Verify: should this be scoped to the current user, or remain a global reset? If global, document the security implication. If scoped, use `DELETE FROM ... WHERE user_id = ${userId}` instead of TRUNCATE.
**Warning signs:** Migration user wipes other users' data.

### Pitfall 4: Account ownership validation for import
**What goes wrong:** The import route allows importing into any `account_id`. Without ownership validation, User A could start an import job pointing to User B's account.
**Why it happens:** Route handler just passes `account_id` from client input without checking ownership.
**How to avoid:** In the route handler or enqueueImportJob, validate `account_id` belongs to the current user before creating the job. Per D-02, this is implicit — just add `WHERE id = ${accountId} AND user_id = ${userId}`.
**Warning signs:** Import jobs linked to wrong user's accounts.

### Pitfall 5: llm_description seed population duplication
**What goes wrong:** If the onSignUp hook and the migration 011 both try to populate llm_description, they'll conflict or duplicate effort.
**Why it happens:** Both the header seeding script (in schema.sql or migration) and the signup hook may seed category data.
**How to avoid:** The `llm_description` column is added via migration 011 with a default value or populated in the onSignUp hook alongside the category inserts. Decide which: migration sets static defaults, or hook reads them and inserts. The hook approach keeps it consistent with the seed pattern.
**Warning signs:** Categories with null llm_description.

## Code Examples

### Example 1: Adding userId to an existing use-case (assets pattern)

**Before:**
```typescript
// Source: src/core/assets/use-cases.ts
export async function listAssets(): Promise<Asset[]> {
  const rows = await sql`SELECT * FROM assets ORDER BY name ASC`;
  return rows as Asset[];
}
```

**After:**
```typescript
export async function listAssets(userId: string): Promise<Asset[]> {
  const rows = await sql`
    SELECT * FROM assets WHERE user_id = ${userId} ORDER BY name ASC
  `;
  return rows as Asset[];
}
```

### Example 2: Route handler extracting userId from session

```typescript
// Source: src/interface-adapters/api/insights.ts (existing pattern)
async (c) => {
  const user = c.get('user');
  if (!user) {
    return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
  }
  const { rows, total } = await listInsights({
    userId: user.id,
    type: query.type,
    dismissed: query.dismissed,
    page: query.page,
    per_page: query.per_page,
  });
  // ...
}
```

### Example 3: PATCH /transactions/:id/category — extracted use-case (SCOPE-07)

```typescript
// Source: inline SQL in src/interface-adapters/api/ledger.ts lines 185-189
// To be extracted to src/core/ledger/use-cases.ts

export async function assignCategory(
  transactionId: string, 
  categoryId: string, 
  userId: string
): Promise<Transaction | null> {
  const [updated] = await sql`
    UPDATE transactions SET category_id = ${categoryId}
    WHERE id = ${transactionId} 
      AND category_id IS NULL 
      AND user_id = ${userId}
    RETURNING *
  `;
  return (updated as Transaction) || null;
}
```

### Example 4: Better Auth onSignUp hook for default seeding

```typescript
// Source: Better Auth docs pattern — to be added to src/auth.ts
// VERIFIED: codebase inspection — auth is already configured in src/auth.ts

export const auth = betterAuth({
  // ... existing config ...
  databaseHooks: {
    user: {
      create: {
        after: async (user) => {
          // Insert default categories
          const defaultCategories = [
            { name: 'biedronka', is_fixed_cost: false, description: 'Zakupy spożywcze w Biedronce' },
            { name: 'żabka', is_fixed_cost: false, description: 'Zakupy w Żabce' },
            // ... 23 more categories
          ];
          for (const cat of defaultCategories) {
            await sql`
              INSERT INTO categories (name, is_fixed_cost, user_id, llm_description)
              VALUES (${cat.name}, ${cat.is_fixed_cost}, ${user.id}, ${cat.description})
            `;
          }
          
          // Insert default accounts
          await sql`
            INSERT INTO accounts (name, type, user_id)
            VALUES ('ING Business', 'business', ${user.id})
          `;
          await sql`
            INSERT INTO accounts (name, type, user_id)
            VALUES ('IPKO Personal', 'personal', ${user.id})
          `;
        }
      }
    }
  }
});
```

Note: Better Auth v1.6.x uses `databaseHooks.user.create.after` pattern. Verify exact API via documentation — the signup hook API might differ between versions.

### Example 5: New reference use-cases file

```typescript
// NEW FILE: src/core/reference/use-cases.ts
import sql from '../../infrastructure/db/client';

export async function listAccounts(userId: string) {
  const rows = await sql`
    SELECT * FROM accounts WHERE user_id = ${userId} ORDER BY name
  `;
  return rows;
}

export async function listCategories(userId: string) {
  const rows = await sql`
    SELECT * FROM categories WHERE user_id = ${userId} ORDER BY name
  `;
  return rows;
}
```

### Example 6: Import enqueue with user_id in PGMQ payload

```typescript
// MODIFY: src/core/import/use-cases.ts
export async function enqueueImportJob(payload: {
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
  userId: string;  // NEW
}): Promise<{ job_id: string; msg_id: number }> {
  return await sql.begin(async (sql) => {
    const [job] = await sql`
      INSERT INTO import_jobs (account_id, user_id, status)  // ADD user_id
      VALUES (${payload.account_id}, ${payload.userId}, 'pending')
      RETURNING id
    `;

    const [sendResult] = await sql`
      SELECT pgmq.send('import_queue', ${JSON.stringify({
        job_id: job.id,
        account_id: payload.account_id,
        csv_content: payload.csv_content,
        bank_format: payload.bank_format,
        user_id: payload.userId,  // NEW — consumed in Phase 8
      })}::jsonb) as msg_id
    `;

    return { job_id: job.id, msg_id: Number(sendResult.msg_id) };
  });
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Global data (no user isolation) | Per-user data scoping | Phase 7 | All queries filter by user_id |
| Lazy seeding on GET /categories | Better Auth onSignUp hook | Phase 7 discuss | Seeding happens exactly once at registration |
| Inline SQL in reference.ts routes | src/core/reference/use-cases.ts | Phase 7 | Reference queries become testable use-cases |
| Hardcoded category descriptions in buildFewPrompt | llm_description column in DB | Phase 7 (folded) | Descriptions become data-driven and user-extensible |

**Deprecated/outdated:**
- **SEED-03 requirement text**: Still reads "Lazy seeding on first GET /categories — no signup hook dependency." This contradicts D-03 which pivoted to signup hook. The planner should note this discrepancy and the VERIFICATION phase should test signup hook behavior, not lazy seeding.
- **`src/interface-adapters/api/reference.ts`**: Both routes will be replaced by the new `src/core/reference/use-cases.ts`. The file may still exist as a shell calling the use-cases.
- **`src/core/assets/use-cases.ts`**: All four functions need signature changes (adding userId parameter) — this is an API-breaking change for any caller.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Better Auth v1.6.14 supports `databaseHooks.user.create.after` for post-signup seeding | Code Examples | Signup hook API may differ — need to verify exact Better Auth API for onSignUp. Fallback: use lazy seeding in reference route. |
| A2 | `getMonthlySummary()` currently returns data for all users (no WHERE clause) | Pitfalls | Confirmed by code inspection — no user_id filter in the aggregation query. If the route already scopes somewhere we haven't seen, we'd double-filter. |
| A3 | Migration 011 number follows the sequential pattern (010 is highest) | Code Examples | Confirmed by inspecting `src/infrastructure/db/migrations/` directory — 010 is the highest. |
| A4 | The migration route (POST /api/migration/excel) TRUNCATE is intentionally global (not user-scoped) | Pitfalls | If user-scope is needed, the implementation changes significantly. Need confirmation on whether this route should be user-scoped or remain admin-level. |

## Open Questions

1. **Better Auth onSignUp hook API — verification needed**
   - What we know: `src/auth.ts` uses `betterAuth({...})` with email/password + social providers. The `databaseHooks` API exists in better-auth docs but the exact shape for v1.6.14 needs verification.
   - What's unclear: Is it `databaseHooks.user.create.after`, a callback in the config root, or a plugin? Does it have access to the `sql` client from postgres.js?
   - Recommendation: Check Better Auth v1.6.x docs for the correct signup hook API. Fallback: use lazy seeding in reference routes if hook API is incompatible.

2. **Migration route scoping — intentional or oversight?**
   - What we know: `POST /api/migration/excel` in `src/interface-adapters/api/migration.ts` does `TRUNCATE ... CASCADE` which destroys ALL data across all users.
   - What's unclear: Should this be scoped (DELETE FROM ... WHERE user_id = X) or remain a global admin operation?
   - Recommendation: Assume global (admin-level) for now, but PLAN must include a verification step to confirm with user.

3. **llm_description default values**
   - What we know: `buildFewShotPrompt` in `src/workers/import-worker.ts` has hardcoded Polish descriptions for each category.
   - What's unclear: Should the migration populate llm_description from these hardcoded strings, or should the onSignUp hook handle it?
   - Recommendation: Migration 011 adds the column. The onSignUp hook populates llm_description alongside category inserts. Update `buildFewShotPrompt` to read from `llm_description` column instead.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bun | Runtime | ✓ | *(checked in environment)* | — |
| PostgreSQL | Database | ✓ | *(checked in environment)* | — |
| postgres.js (npm) | DB client | ✓ | ^3.4.9 in package.json | — |
| bun:test | Test runner | ✓ | Built into Bun | — |
| node-pg-migrate | DB migrations | ✓ | ^8.0.4 in package.json | — |
| Hono | HTTP framework | ✓ | ^4.12.23 in package.json | — |
| Better Auth | Auth framework | ✓ | ^1.6.14 in package.json | — |
| Zod | Validation | ✓ | ^4.4.3 in package.json | — |
| PGMQ | Queue system | ✓ | Postgres extension | — |

**Missing dependencies with no fallback:** None — all dependencies are already installed.

## Validation Architecture

> Note: `workflow.nyquist_validation` key not found in `.planning/config.json`. Treating as enabled by default.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bun:test (built-in, no separate package) |
| Config file | None — bun:test uses zero-config |
| Quick run command | `bun test --timeout 30000 tests/api.test.ts` |
| Full suite command | `bun test --timeout 30000` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCOPE-01 | Every SELECT filters by user_id | Integration | `bun test tests/api.test.ts` | ✅ Existing |
| SCOPE-02 | Every INSERT tags user_id | Integration | `bun test tests/api.test.ts` | ✅ Existing |
| SCOPE-03 | Every UPDATE filters by user_id | Integration | `bun test tests/api.test.ts` | ✅ Existing |
| SCOPE-04 | Every DELETE filters by user_id | Integration | `bun test tests/api.test.ts` | ✅ Existing |
| SCOPE-05 | Referenced resource ownership | Integration | `bun test tests/api.test.ts` | ✅ Existing |
| SCOPE-06 | Route handlers extract from session | Integration | `bun test tests/api.test.ts` | ✅ Existing |
| SCOPE-07 | Inline SQL in routes refactored | Code review | Manual | ❌ Wave 0 |
| SEED-01 | Default categories seeded | Integration | New test needed | ❌ Wave 0 |
| SEED-02 | Default account created | Integration | New test needed | ❌ Wave 0 |
| SEED-03 | (PIVOTED to signup hook) | Integration | New test needed | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bun test --timeout 30000 tests/api.test.ts`
- **Per wave merge:** Full: `bun test --timeout 30000` (runs all 22 test files)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `tests/api-scoping.test.ts` — Multi-user isolation test: User A creates resources, User B verifies 404. Covers SCOPE-01 through SCOPE-06 with negative tests.
- [ ] `tests/seeding.test.ts` — Verify onSignUp hook creates 25 categories + 2 accounts. Covers SEED-01, SEED-02.
- [ ] No test framework config needed (bun:test is zero-config).

*(If no gaps: "None — existing test infrastructure covers all phase requirements")*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Better Auth session middleware (already applied) |
| V3 Session Management | yes | Better Auth sessions via cookie (already applied) |
| V4 Access Control | yes | User-scoped data isolation via SQL WHERE (this phase) |
| V5 Input Validation | yes | Zod schemas (already applied — no user_id in schemas) |
| V6 Cryptography | no | No encryption added in this phase |

### Known Threat Patterns for {Bun + Hono + postgres.js}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-user data leakage via SELECT | Information Disclosure | `WHERE user_id = ${userId}` on every SELECT |
| Cross-user data modification | Tampering | `WHERE user_id = ${userId}` on every UPDATE/DELETE |
| Cross-user data insertion | Spoofing | `user_id` from session (not client input) on every INSERT |
| Resource ownership violation | Elevation of Privilege | Implicit WHERE-based ownership → 404 |
| Client-supplied user_id | Spoofing | Per SCOPE-06: userId from `c.get('user').id` only |

## Sources

### Primary (HIGH confidence)
- [VERIFIED: codebase inspection] - `src/core/insights/use-cases.ts` — Reference pattern for user-scoped use-cases with params object
- [VERIFIED: codebase inspection] - `src/interface-adapters/api/insights.ts` — Reference pattern for route handler userId extraction
- [VERIFIED: codebase inspection] - `src/index.ts` — Global session middleware + route mounting
- [VERIFIED: codebase inspection] - `src/interface-adapters/api/auth.ts` — `requireAuth` middleware
- [VERIFIED: codebase inspection] - `src/auth.ts` — Better Auth configuration (needs hook)
- [VERIFIED: codebase inspection] - `src/infrastructure/db/migrations/` — Migration files 001-010 (next is 011)
- [VERIFIED: codebase inspection] - `src/infrastructure/db/schema.sql` — Current schema with user_id columns
- [VERIFIED: codebase inspection] - `src/core/ledger/use-cases.ts` — 8 functions needing userId
- [VERIFIED: codebase inspection] - `src/core/assets/use-cases.ts` — 4 functions needing userId
- [VERIFIED: codebase inspection] - `src/core/import/use-cases.ts` — 2 functions needing userId
- [VERIFIED: codebase inspection] - `src/interface-adapters/api/ledger.ts` — Routes + inline SQL in PATCH
- [VERIFIED: codebase inspection] - `src/interface-adapters/api/reference.ts` — Inline SQL to extract
- [VERIFIED: codebase inspection] - `src/workers/import-worker.ts` — buildFewShotPrompt with hardcoded descriptions
- [VERIFIED: codebase inspection] - `tests/schema-migration.test.ts` — Multi-user test patterns (USER_2 cross-user tests)
- [VERIFIED: codebase inspection] - `tests/api.test.ts`, `tests/assets.test.ts` — Integration test patterns (signUpEmail + app.request)

### Secondary (MEDIUM confidence)
- [ASSUMED] - Better Auth `databaseHooks.user.create.after` API — Assumed based on training knowledge. Need to verify exact API shape for v1.6.14.
- [ASSUMED] - `pgmq` payload structure with `user_id` — The import worker's `processCsvImportJob` function ingests payload fields via destructuring. Adding `user_id` to the payload won't break the worker in Phase 7 since Phase 8 will consume it. The worker's `processJob` function union type will need updating when Phase 8 validates it.

### Tertiary (LOW confidence)
- None — all findings are verified via codebase inspection or documented as ASSUMED.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries verified via `package.json` and codebase inspection. No new packages needed.
- Architecture: HIGH - Insights module pattern verified by reading `src/core/insights/use-cases.ts` and `src/interface-adapters/api/insights.ts`. All 6 route files and 6 use-case files inspected.
- Pitfalls: HIGH - All pitfalls discovered via direct codebase reading and pattern analysis.

**Research date:** 2026-06-07
**Valid until:** Stable — no rapidly-moving dependencies in this scope.
