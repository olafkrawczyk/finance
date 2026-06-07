# Pitfalls: Multi-Tenant Data Isolation

**Domain:** Multi-tenant Postgres financial planning app (converting single-tenant)
**Researched:** 2026-06-07
**Confidence:** HIGH (verified against Postgres 18 docs and codebase audit)

## Critical Pitfalls

### Pitfall 1: Enabling RLS on Existing Tables — The "Everything Vanishes" Moment

**What goes wrong:**
You run `ALTER TABLE transactions ENABLE ROW LEVEL SECURITY` without first creating a policy, and every query returns zero rows. Or you create an RLS policy that doesn't match the actual `user_id` column type (Better Auth uses `TEXT`, domain tables might use `UUID`), so the policy expression fails silently and no rows are visible.

**Why it happens:**
Postgres RLS defaults to **deny** — when RLS is enabled on a table but no policy exists, zero rows are visible or modifiable. Additionally, the table owner (the Postgres user your app connects as) **bypasses RLS by default** (`ALTER TABLE ... FORCE ROW LEVEL SECURITY` is required to make even the owner subject to RLS). This creates a testing blindspot: in development, the app user is often the table owner, so RLS appears to work until you test with a different role.

The `insights` table already has `user_id TEXT NOT NULL` (matching Better Auth's `TEXT` PK). But in this codebase, Better Auth's `"user"."id"` is `TEXT` while the domain tables (`accounts`, `categories`, `transactions`) use `UUID` for their PKs. If you add a `user_id UUID` column and write an RLS policy comparing `user_id = current_setting('app.user_id')::UUID`, the cast must match exactly — any mismatch produces a policy that evaluates to false for all rows.

**How to avoid:**
1. **Before enabling RLS:** Create at least one permissive policy first (e.g., `CREATE POLICY user_isolation ON transactions USING (user_id = current_setting('app.user_id')::TEXT)`).
2. **Test with FORCE RLS:** Use `ALTER TABLE transactions FORCE ROW LEVEL SECURITY` in test environments — without this, the app's DB user (table owner) bypasses RLS, masking isolation failures.
3. **Use a session-level variable** for the user ID rather than relying on `current_user` (which returns the DB role, not the app user). Set it with `SET app.user_id = '...'` at the start of each request.
4. **Match the column type** to Better Auth's `TEXT` user ID — do not cast to UUID in the policy unless the column IS UUID and you handle the cast consistently.
5. **Explicitly test** that enabling RLS doesn't break any existing query by running the full test suite under both `ENABLE` and `DISABLE` states.

**Warning signs:**
- Queries return 0 rows after migration that worked before
- Dashboard shows empty data for the existing single user
- RLS works in development but fails in production (because dev DB user is owner)
- Errors like `current_setting('app.user_id') not found` — the session variable was never set

**Phase to address:**
Phase that adds RLS policies — but also must coordinate with the "add user_id to tables" migration phase. RLS should be enabled in the same migration that adds user_id columns, after backfill is complete.

---

### Pitfall 2: Adding NOT NULL `user_id` to Existing Tables with Data

**What goes wrong:**
You `ALTER TABLE transactions ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id)` on a production database that has thousands of transactions, and Postgres rejects it because existing rows have NULL for the new column.

Or you add the column as nullable, backfill it, then try `ALTER TABLE ... ALTER COLUMN user_id SET NOT NULL` — but this takes an `ACCESS EXCLUSIVE` lock and blocks all reads/writes. For large tables this causes downtime.

**Why it happens:**
This is the canonical schema migration problem: you can't add a NOT NULL column to a table that has rows unless you provide a DEFAULT (which is often wrong), or you do a multi-step migration. Developers in a hurry either:
- Add the column as nullable and forget to make it NOT NULL later (creating a data integrity hole)
- Use a DEFAULT like `'legacy'` which becomes garbage data
- Attempt the `SET NOT NULL` on a large table in production, causing downtime

In this codebase specifically:
- `transactions` has ~500+ rows (from seed-dev + imports)
- `accounts` has 2 seeded rows
- `categories` has 25 seeded rows
- `monthly_opening_balances` has ~20 rows
- `assets` has whatever user created
- `import_jobs` has however many imports were run

All these tables need `user_id` added.

**How to avoid:**
1. **Multi-step migration:**
   - Step 1: `ALTER TABLE transactions ADD COLUMN user_id TEXT REFERENCES "user"(id)` (nullable)
   - Step 2: Backfill: `UPDATE transactions SET user_id = (SELECT id FROM "user" LIMIT 1)` (for single-tenant → first user)
   - Step 3: `ALTER TABLE transactions ALTER COLUMN user_id SET NOT NULL` (safe now — no NULLs)
2. **For Postgres 16+:** Use `ALTER TABLE transactions ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id)` within a transactional migration that backfills in batches to avoid long locks.
3. **Backfill strategy:** For tables with < 10K rows, single UPDATE is fine. For larger tables, batch in chunks of 1000 with `WHERE user_id IS NULL LIMIT 1000`.
4. **Default user strategy:** Since this is a single-tenant → multi-tenant conversion, all existing data belongs to the first user. Hardcode the first user's ID (from `"user"` table) in the backfill migration.
5. **Test the migration** against a copy of production data first, measuring lock duration.

**Warning signs:**
- Migration script fails with `column "user_id" of relation "transactions" contains null values`
- `user_id` column exists but is nullable (integrity hole)
- App code needs to handle `user_id IS NULL` cases years later

**Phase to address:**
Schema migration phase (first phase of the milestone). Must happen before any RLS or query-scoping changes.

---

### Pitfall 3: Query Scoping — Missing `user_id` Filters in Existing Queries

**What goes wrong:**
You add `user_id` to the tables and pass it from the middleware, but you miss updating some SQL queries. A user calls `GET /transactions` and sees all transactions across all users. Or worse, a user can `DELETE /transactions/:id` from another user's account because the delete query only checks `WHERE id = :id` without also checking `AND user_id = :current_user_id`.

**Why it happens:**
This project has no ORM or query builder — every query is a raw SQL template literal via `postgres.js` (`sql` tagged function). There is no centralized query layer (repository, DAO) that could automatically inject `user_id` filters. Every `SELECT`, `UPDATE`, `DELETE`, and `INSERT` in every use-case file must be manually audited and updated.

Audit of this codebase reveals the following queries that currently have **NO user_id filter**:

| File | Query | Risk |
|------|-------|------|
| `core/ledger/use-cases.ts` | `createTransaction` — INSERT | LOW (no read) |
| `core/ledger/use-cases.ts` | `listTransactions` — SELECT | **HIGH** — cross-user data leak |
| `core/ledger/use-cases.ts` | `getMonthlySummary` — SELECT | **HIGH** — cross-user data leak |
| `core/ledger/use-cases.ts` | `getTransaction` — SELECT by id | **HIGH** — can read any transaction |
| `core/ledger/use-cases.ts` | `updateTransaction` — UPDATE by id | **CRITICAL** — can modify any transaction |
| `core/ledger/use-cases.ts` | `deleteTransaction` — DELETE by id | **CRITICAL** — can delete any transaction |
| `core/ledger/use-cases.ts` | `createOpeningBalance` — INSERT | LOW |
| `core/ledger/use-cases.ts` | `listOpeningBalances` — SELECT | **HIGH** — sees all users' balances |
| `core/ledger/use-cases.ts` | `updateOpeningBalance` — UPDATE by id | **HIGH** — can modify any balance |
| `core/assets/use-cases.ts` | `listAssets` — SELECT | **HIGH** — cross-user data leak |
| `core/assets/use-cases.ts` | `createAsset` — INSERT | LOW |
| `core/assets/use-cases.ts` | `updateAsset` — UPDATE by id | **CRITICAL** — modify any asset |
| `core/assets/use-cases.ts` | `deleteAsset` — DELETE by id | **CRITICAL** — delete any asset |
| `core/import/use-cases.ts` | `enqueueImportJob` — INSERT | LOW |
| `core/import/use-cases.ts` | `getImportStatus` — SELECT by id | **HIGH** — can read any import |
| `interface-adapters/api/reference.ts` | `GET /accounts` — SELECT all | **HIGH** — leaks all accounts |
| `interface-adapters/api/reference.ts` | `GET /categories` — SELECT all | **HIGH** — leaks all categories |
| `interface-adapters/api/ledger.ts` | `PATCH /:id/category` — inline SQL | **CRITICAL** — no ownership check |
| `workers/import-worker.ts` | `processExcelMigrationJob` — SELECT categories, accounts | **HIGH** — doesn't check user ownership |
| `workers/import-worker.ts` | `processCsvImportJob` — SELECT categories | **HIGH** — loads ALL categories |
| `workers/import-worker.ts` | `insertBatch` — INSERT | LOW (but should tag with user_id) |

The `insights` use-cases already have user_id scoping (passed as parameter) — these are the model to follow.

**How to avoid:**
1. **Use a lint rule or grep** for every occurrence of `sql\`` template literal that operates on domain tables (`transactions`, `accounts`, `categories`, `assets`, `monthly_opening_balances`, `import_jobs`).
2. **Add user_id as a parameter** to every use-case function that reads or modifies data. The pattern from `insights/use-cases.ts` is correct: `listInsights({ userId, ... })`, `dismissInsight(id, userId)`.
3. **For INSERT queries**, include `user_id` in the column list even if you trust the caller. This prevents bugs when row-level data is later joined or exported.
4. **For UPDATE/DELETE by id**, add `AND user_id = ${userId}` to the WHERE clause. This is the most critical — without it, any authenticated user can modify or delete another user's data.
5. **For SELECT queries**, add `WHERE user_id = ${userId}` or add it to the WHERE chain.
6. **The `PATCH /:id/category` endpoint** in ledger.ts has inline SQL that directly updates `transactions` — this MUST be refactored to use a use-case that accepts `userId` and checks ownership.
7. **Workers need special handling** — see Pitfall 4.

**Warning signs:**
- An authenticated user can set another user's ID in their browser devtools and fetch their data
- API responses include more data than the current user owns
- Deleting a record returns success for IDs that don't belong to the user

**Phase to address:**
Query-scoping phase. Should be planned as a systematic audit of every use-case file, not done ad-hoc per endpoint.

---

### Pitfall 4: Auth Session in Workers — Passing `user_id` Through PGMQ

**What goes wrong:**
The `import-worker.ts` and `insights-worker.ts` connect directly to the database — they never go through the Hono middleware. So they have no `requireAuth` context and no `c.get('user')`. The import worker needs to know **which user** owns the account being imported into, but currently:
- `enqueueImportJob` (API side) creates an `import_jobs` record with `account_id` but **no user_id**
- The PGMQ message for CSV import includes `{ job_id, account_id, csv_content, bank_format }` — **no user_id**
- `processCsvImportJob` inserts into `transactions` without tagging the rows with a user_id

The insights worker already handles this correctly: `processAnalysisMessage` receives `userId` from the PGMQ payload, and passes it through to all queries. But the import worker is completely blind to user_id.

**Why it happens:**
Workers don't run inside an HTTP request context. There's no session to validate. The `auth.api.getSession()` call in `requireAuth` requires HTTP headers. Workers don't have headers. The user_id must be **passed through the PGMQ message payload** and trusted.

Additionally, the `enqueueImportJob` function and its corresponding API route (`POST /import`) don't ever resolve which user owns the account_id — they trust whatever account_id is sent. With multi-tenancy, the API must also verify that the `account_id` belongs to the requesting user before enqueuing.

**How to avoid:**
1. **Add `user_id` to the `import_jobs` table** and to the PGMQ message schema for all job types (CSV import, excel migration, analysis).
2. **In the import API route** (`POST /import`), resolve `user_id` from `c.get('user').id` and include it in both the `import_jobs` record and the PGMQ payload.
3. **In the import worker**, extract `user_id` from the PGMQ message and use it as the `user_id` value when inserting transactions.
4. **In the analysis worker**, the pattern already works (`processAnalysisMessage` gets `userId` from payload) — just ensure the `enqueueAnalysisJob` function always puts the current user's ID in the message.
5. **Validate ownership**: The import worker should verify that the `account_id` in the PGMQ message belongs to the `user_id` in the same message before processing.

**Warning signs:**
- Transactions imported via CSV don't have `user_id` set after migration
- `import_jobs` records show no `user_id` association
- One user can trigger an import using another user's account_id by crafting API requests

**Phase to address:**
Worker user-scoping phase. Must happen after the schema migration (which adds `user_id` columns) but can run in parallel with query scoping since workers have their own code paths.

---

### Pitfall 5: `import_hash` UNIQUE Constraint — Cross-User Collision

**What goes wrong:**
Currently `transactions.import_hash` has a global `UNIQUE` constraint. With multi-tenancy, User A imports a transaction with hash `abc123` and User B imports a different transaction that coincidentally has the same hash (same date + amount + description). The second insert fails with a duplicate key violation.

**Why it happens:**
The `import_hash` is computed from `SHA256(date|amount|description)` — no user_id or account_id is included (see spike-findings-finance). Two users could legitimately have transactions with the same date, amount, and description (e.g., both paid the same utility bill on the same day). Currently this doesn't matter because there's only one user. With multi-tenancy, this becomes a real collision surface.

The UNIQUE constraint can't simply be made UNIQUE (user_id, import_hash) because that would require dropping and recreating the constraint, which takes an exclusive lock.

**How to avoid:**
1. **Drop the existing UNIQUE constraint** on `import_hash` and create a new unique index on `(user_id, import_hash)`:
   ```sql
   -- In a migration:
   ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_import_hash_key;
   CREATE UNIQUE INDEX idx_transactions_user_import_hash ON transactions(user_id, import_hash);
   ```
2. **Update `computeImportHash`** to include `user_id` in the hash input (optional but helps distinguish identical transactions across users).
3. **Update the `insertBatch` function** to pass `user_id` from the PGMQ message and include it in the INSERT.
4. **Handle the migration carefully**: any existing duplicate import_hash values across users would block creating the unique index. Since this is a single-user→multi-user conversion, there won't be cross-user duplicates during the migration, but the index creation must happen after the backfill.

**Warning signs:**
- `duplicate key value violates unique constraint "transactions_import_hash_key"` errors after multi-user goes live
- Import silently fails for 50% of batches in multi-user scenarios
- Two users report the same `import_hash` constraint violation

**Phase to address:**
Schema migration phase (same as Pitfall 2 — coordinate the constraint change with adding user_id column).

---

### Pitfall 6: Global UNIQUE Constraints on `categories.name` and `assets.name`

**What goes wrong:**
Currently `categories(name)` has `UNIQUE` and `assets(name)` has `UNIQUE`. With multi-tenancy, User A creates a custom category "Vacation" and User B also wants "Vacation". The second insert fails with `duplicate key value violates unique constraint "categories_name_key"`.

**Why it happens:**
These were designed as global reference tables. The seed data inserts 25 global categories. With multi-tenancy, each user needs their own set of categories and assets. The UNIQUE constraint prevents duplicate names within the table, but now the scope should be per-user, not global.

**How to avoid:**
1. **Drop global UNIQUE constraints**, create per-user unique constraints:
   ```sql
   ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_name_key;
   CREATE UNIQUE INDEX idx_categories_user_name ON categories(user_id, name);
   
   ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_name_key;
   CREATE UNIQUE INDEX idx_assets_user_name ON assets(user_id, name);
   ```
2. **For the seed data migration**: Either:
   - Copy the 25 seeded categories for every user (via trigger on user signup), OR
   - Make categories global + user-owned (add a `is_global` flag and scope queries to `WHERE user_id = X OR is_global = true`)
3. **Better approach for this project**: Since the requirement is "each user sees only their own data", the simplest approach is to make categories per-user. On signup, copy the 25 default categories into the user's namespace. The `seed.sql` should become a template that runs per-user, not globally.
4. **For existing data**: Assign all existing categories to the first user's user_id during the backfill migration.

**Warning signs:**
- `duplicate key value violates unique constraint "categories_name_key"` when second user signs up
- Seed data insertion fails for new users
- Category/asset names unexpectedly conflict between users

**Phase to address:**
Schema migration + seed data restructuring. This must be coordinated — the constraint change affects the seed data approach.

---

### Pitfall 7: `monthly_opening_balances` — Global UNIQUE Constraint on `(year, month)`

**What goes wrong:**
Currently `monthly_opening_balances` has `UNIQUE(year, month)`. With multi-tenancy, this means only one user can have an opening balance for January 2025. User B can't set their own opening balance because the constraint already exists.

**Why it happens:**
This table was designed as a global net-worth tracker. With multi-tenancy, each user needs their own set of monthly opening balances. The UNIQUE constraint is scoped globally, not per-user.

**How to avoid:**
1. **Drop the global UNIQUE** on `(year, month)` and create `UNIQUE(user_id, year, month)`:
   ```sql
   ALTER TABLE monthly_opening_balances DROP CONSTRAINT IF EXISTS monthly_opening_balances_year_month_key;
   ALTER TABLE monthly_opening_balances ADD UNIQUE (user_id, year, month);
   ```
2. **Backfill**: Assign all existing opening balances to the first user.
3. **Update the `createOpeningBalance` and `listOpeningBalances` use-cases** to accept and filter by `userId`.

**Warning signs:**
- `duplicate key value violates unique constraint "monthly_opening_balances_year_month_key"` after second user tries to open the app
- Monthly opening balances display incorrect data for new users

**Phase to address:**
Schema migration phase (combined with the other constraint changes).

---

### Pitfall 8: Frontend — Cached Data Survives Across User Sessions

**What goes wrong:**
User A logs in, browses transactions, then logs out. User B logs in on the same browser. User B briefly sees User A's transaction data before the React app re-fetches. Or User A's stale data in React Query/providers is served to User B during the component mount cycle.

**Why it happens:**
React apps using client-side state (React Query cache, Zustand, Context, or even plain `useState`) store fetched data in memory. When a new user logs in, the old data is still in the cache. If the component renders before the API responds, the stale cross-user data flashes on screen. Even if it's quickly replaced, it's a data leak.

Additionally, browser `localStorage` or `sessionStorage` might contain cached API responses or user preferences that include data from the previous user.

**How to avoid:**
1. **Clear all React Query caches on logout/login**: Use `queryClient.clear()` or `queryClient.invalidateQueries()` when the auth state changes.
2. **Key all queries by user_id**: In React Query, every query key should include the current user ID: `['transactions', user.id]`. This naturally separates caches between users.
3. **Use a `key` prop on the root component** that changes per user: `<App key={user.id} />` — this forces React to unmount and remount the entire component tree, which clears all local state and effects.
4. **Don't store user data in localStorage** — only store auth tokens (and use httpOnly cookies for those).
5. **Add a "loading" state** that prevents rendering any data until the first API call completes after login.
6. **Test explicitly**: Login as User A, load data, logout (without clearing browser state), login as User B, check that no User A data appears even briefly.

**Warning signs:**
- Flash of another user's data on login/logout transition
- React DevTools shows stale user IDs in query keys after logout
- Console logs show API calls for user A's data while user B is logged in

**Phase to address:**
Frontend state management phase. Address after backend scoping is complete.

---

### Pitfall 9: Testing Blindspots — What Multi-Tenant Isolation Tests Typically Miss

**What goes wrong:**
You write tests that:
- Create user A, create data for user A, assert user A can read it ✓
- Create user B, assert user B cannot read user A's data ✓
- Deploy to production

But you didn't test:
- User B can't DELETE user A's data
- User B can't UPDATE user A's data
- User B can't assign a category that belongs to user A
- User B's import job doesn't read user A's accounts/categories
- Opening balances are isolated
- The insights worker only processes the correct user's transactions
- The monthly summary only shows the current user's data
- API returns 404 (not 403) when accessing another user's non-existent-by-them resource — leaking existence info

**Why it happens:**
Most developers write "happy path" isolation tests (User A can read own data) and one "negative" test (User B cannot read User A's data via the list endpoint). But multi-tenancy affects EVERY CRUD operation and every background worker. A single missed WHERE clause in an UPDATE or DELETE is a data corruption vulnerability.

Additionally, many tests use the same database connection (and thus the same DB role), which means RLS tests are unreliable without `FORCE ROW LEVEL SECURITY` (see Pitfall 1).

**How to avoid:**
1. **Test matrix** — for every resource type (transactions, accounts, categories, assets, opening balances, import jobs, insights), test all 5 operations with cross-user access:
   - User A can CREATE → User A can READ/UPDATE/DELETE
   - User B CANNOT READ User A's item by ID
   - User B CANNOT UPDATE User A's item
   - User B CANNOT DELETE User A's item
   - User B CANNOT see User A's items in list queries
2. **Test 404 vs 403 behavior**: Accessing another user's specific resource should return 404 (not 403) to prevent information leakage about whether the resource exists.
3. **Test workers with cross-user data**: Create import jobs and insights for user A, then verify the worker processes them and does NOT affect user B's data, even when user B's data uses the same account names.
4. **Test with RLS FORCE enabled**: Use `ALTER TABLE ... FORCE ROW LEVEL SECURITY` in test setup so you're testing real isolation, not just app-layer filtering.
5. **Test concurrent operations**: Two users inserting transactions simultaneously should not interfere.
6. **Test with a third user**: Pitfall detection improves significantly with 3+ users. Two-user tests often miss bugs that only manifest with n>2.

**Warning signs:**
- Test suite only has 2 users for isolation tests
- No negative test for UPDATE/DELETE operations
- Workers are not tested with multi-user data
- Tests run without `FORCE RLS` enabled

**Phase to address:**
Testing phase. Should be planned as a dedicated phase with clear test matrix, not left as "test as you go."

---

### Pitfall 10: "Looks Done But Isn't" — The Ownership Validation Gap

**What goes wrong:**
You've added `user_id` to every table, set up RLS, and updated all queries. But there's one gap: the API route handler at `PATCH /transactions/:id/category` in `interface-adapters/api/ledger.ts` does a direct SQL update with `WHERE id = ${id} AND category_id IS NULL` — it never checks that the transaction belongs to the current user, and it never checks that the `category_id` belongs to the current user.

Or: the `POST /import` endpoint validates the `account_id` but doesn't check if that account belongs to the current user. A malicious user could import data into another user's account by guessing their account UUID.

**Why it happens:**
The project uses a layered architecture (interface-adapters → application → core), but some endpoints have inline SQL that bypasses the core use-case layer. These inline queries don't go through the same code review path.

Additionally, when you add `userId` to use-case functions, it's obvious you need to add it everywhere. But inline SQL in route handlers is easy to forget because it's not in the "hot path" of refactoring.

Audit of inline/non-use-case queries:
- `PATCH /transactions/:id/category` in `ledger.ts` — inline SQL, no user_id check
- `GET /accounts` in `reference.ts` — inline SQL, no user_id filter
- `GET /categories` in `reference.ts` — inline SQL, no user_id filter

**How to avoid:**
1. **Refactor all inline SQL** in route handlers into use-case functions that accept `userId` as a parameter.
2. **Create a `verifyOwnership` pattern** — a helper function that checks `SELECT user_id FROM transactions WHERE id = $1` matches the current user before any mutation.
3. **For every mutation endpoint**: validate that ALL foreign keys referenced in the operation belong to the current user — not just the primary resource. E.g., when categorizing a transaction, check both the transaction AND the category belong to the user.
4. **Run a query audit checklist** before considering the milestone complete:
   - [ ] Every SELECT, UPDATE, DELETE has `user_id` filter
   - [ ] Every INSERT includes `user_id` value
   - [ ] Every foreign key reference (account_id, category_id) belongs to the same user
   - [ ] No inline SQL in route handlers bypasses core use-cases
   - [ ] Worker PGMQ messages carry user_id
   - [ ] Worker validates ownership of referenced resources

**Warning signs:**
- API route handler contains `sql\`` directly (not through a use-case)
- Any mutation that takes an ID parameter doesn't also verify user ownership
- Foreign key lookups (e.g., looking up a category by ID) don't filter by user

**Phase to address:**
Final audit/QA phase. Should be the last phase before shipping — a systematic codebase audit that verifies every query point.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| **App-layer filtering only (no RLS)** | Simpler migration, no RLS learning curve | One missed filter = data leak; no defense-in-depth | Never for production — always pair app-layer + RLS |
| **Reuse same DB user for all tenants** | No infra changes needed | RLS is bypassed by default (table owner), nullifying the defense | Only during development. Production needs separate roles or FORCE RLS. |
| **Seed categories per-user on first API hit** | No signup hook needed | Race condition: two concurrent requests create duplicate categories for same user | Acceptable for MVP if using INSERT...ON CONFLICT as safety net |
| **Keep global UNIQUE constraints and add user_id** | Smaller migration script | Impossible to add per-user unique names; users get confusing constraint errors | Never — must drop global constraints and add per-user ones |
| **Skip worker user-scoping (trust PGMQ origin)** | Less code change | PGMQ messages don't have auth; any injection into the queue bypasses all tenant isolation | Never — workers must validate and carry user_id |
| **Let table owner bypass RLS** | No config change needed | RLS provides zero protection in development/testing; false sense of security | Never — always use `FORCE ROW LEVEL SECURITY` in test environments |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| **Better Auth + user_id column type** | Using UUID for user_id in domain tables while Better Auth uses TEXT PK | Match Better Auth's TEXT type for user_id columns. The `insights` table already uses `user_id TEXT NOT NULL REFERENCES "user"(id)` — follow this pattern. |
| **PGMQ messages + user context** | Not including user_id in the message payload | Always include `user_id` in PGMQ messages. Workers are authless. |
| **OpenRouter API + multi-tenant** | LLM prompt includes another user's data in category list | When building AI prompts, only pass the current user's categories. The `buildFewShotPrompt` function reads ALL categories — must filter. |
| **Docker + multi-user dev setup** | Only testing with one DB user / one app user | Create at least 2 test users in dev seed data and switch between them to verify isolation. |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| **Missing WHERE user_id index** | Sequential scans on large tables after user_id filter is added | Create indexes: `CREATE INDEX CONCURRENTLY idx_transactions_user ON transactions(user_id)` | At 10K+ rows per table |
| **RLS policy with subquery** | Slow queries because RLS evaluates subquery per row | Use session-level variable (`current_setting`) instead of subquery in RLS policy | At 1K+ rows |
| **Generic `user_id` index without covering columns** | Index-only scans not possible; `SELECT *` needs table lookups | Create composite indexes: `(user_id, created_at DESC)`, `(user_id, date DESC)`, etc. | At 100K+ rows |
| **NOT NULL validation on large table** | Long-running ALTER TABLE blocks all access | Backfill before setting NOT NULL, use `ALTER TABLE ... VALIDATE CONSTRAINT` separately | At 100K+ rows (lock duration) |
| **Row-level security evaluation overhead** | Each query gets slower as RLS expression is evaluated per row | Benchmark with `EXPLAIN ANALYZE` before and after RLS; consider index-only queries | Usually negligible under 1M rows |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| **RLS bypassed by table owner** | All RLS protection is nullified because the app DB user is the table owner | `ALTER TABLE ... FORCE ROW LEVEL SECURITY` |
| **Returning 403 instead of 404 for cross-user access** | Leaks information about whether a resource exists | Return 404 for all "not found" cases regardless of whether the user owns the resource |
| **Not scoping foreign key lookups** | User A assigns User B's category to their own transaction, causing cross-user data corruption | Validate all FK references belong to the current user before mutation |
| **PGMQ message injection** | Attacker enqueues malicious messages that bypass auth checks | Always include and validate `user_id` in PGMQ message payloads |
| **Missing user_id on INSERT** | Orphan rows with NULL user_id that are invisible to all users | Use NOT NULL constraint + include user_id in every INSERT |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| **New user sees empty dashboard** | First-time user has no categories, no accounts, no data — everything is blank | Seed default categories + a default account on user signup (via Better Auth hook or lazy seeding) |
| **"Data lost" on logout/login** | User sees old data flash briefly before API responds | Use per-user React Query keys, clear cache on auth change, add loading skeleton |
| **Category/account name collision errors** | User tries to create "Groceries" category but gets "name already exists" error (because another user has it) | Make names unique per user, not globally. Show user-friendly error if it's a duplicate within their scope. |
| **Import silently fails** | User uploads CSV and 0 rows are imported because all hashes conflict with another user's data | Per-user unique constraint on import_hash prevents this entirely |

## "Looks Done But Isn't" Checklist

- [ ] **Transactions query**: `listTransactions` adds `WHERE user_id = ${userId}` (currently doesn't filter)
- [ ] **Monthly summary**: `getMonthlySummary` adds `WHERE t.user_id = ${userId}` (currently shows ALL users' data)
- [ ] **Single transaction access**: `getTransaction` checks `WHERE id = ${id} AND user_id = ${userId}` (currently only checks id)
- [ ] **Transaction update**: `updateTransaction` adds `AND user_id = ${userId}` (currently only checks id)
- [ ] **Transaction delete**: `deleteTransaction` adds `AND user_id = ${userId}` (currently only checks id)
- [ ] **Category assignment patch**: The inline SQL in `PATCH /:id/category` verifies transaction ownership AND category ownership
- [ ] **Accounts list**: `GET /accounts` filters by user_id
- [ ] **Categories list**: `GET /categories` filters by user_id
- [ ] **Assets CRUD**: All asset queries filter by user_id (currently none do)
- [ ] **Opening balances CRUD**: All opening balance queries filter by user_id and use per-user UNIQUE constraint
- [ ] **Import jobs**: `import_jobs` table has user_id column; API route validates account ownership before enqueuing
- [ ] **Import worker**: Reads user_id from PGMQ message, tags all inserted transactions with correct user_id
- [ ] **Import dedup**: `import_hash` UNIQUE constraint replaced with per-user unique index `(user_id, import_hash)`
- [ ] **Category name uniqueness**: Global UNIQUE replaced with per-user UNIQUE `(user_id, name)`
- [ ] **Asset name uniqueness**: Global UNIQUE replaced with per-user UNIQUE `(user_id, name)`
- [ ] **Opening balance uniqueness**: Global UNIQUE `(year, month)` replaced with per-user `(user_id, year, month)`
- [ ] **RLS policies**: Created for all domain tables, matching user_id column type (TEXT)
- [ ] **RLS FORCE**: Enabled in test environment; table owner doesn't bypass RLS during testing
- [ ] **Insights queries**: Already user-scoped — verify that linked_transaction_ids only reference user's transactions
- [ ] **Insights worker**: Already passes userId through PGMQ — verify it also validates ownership
- [ ] **Frontend cache**: React Query keys include user.id; cache cleared on auth change
- [ ] **Seed data**: Default categories + accounts created per-user on signup (not globally only)
- [ ] **Error responses**: Cross-user resource access returns 404, not 403
- [ ] **Migration rollback**: All schema changes are reversible (column additions can be dropped, constraints can be recreated)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| **RLS enabled, no policy** | LOW | `ALTER TABLE ... DISABLE ROW LEVEL SECURITY`, create policy, re-enable |
| **NOT NULL user_id added without backfill** | MEDIUM | Temporarily alter to nullable, backfill, alter back to NOT NULL |
| **Cross-user data leak discovered** | HIGH | Identify the query scope gap, fix and deploy. Audit all queries of the same pattern. Notify affected users if PII was exposed. |
| **import_hash constraint blocks import** | MEDIUM | Drop global constraint, create per-user unique index. Retry failed imports. |
| **Category name collision** | LOW | Drop global unique constraint, create per-user unique index. Rename conflicting categories. |
| **Worker processed data for wrong user** | HIGH (data corruption) | Isolate affected records, move to correct user_id, audit PGMQ message history, fix message schema to include user_id |
| **Stale frontend cache shows wrong user's data** | LOW | `queryClient.clear()` on auth change; add user.id to query keys |
| **ForeignKey constraint fails because user_id types don't match** | MEDIUM | Drop constraint, alter column type (TEXT ↔ UUID), recreate constraint. May require table rewrite. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| **P1: RLS "everything vanishes"** | RLS Policy Setup phase | Run full test suite with and without FORCE RLS; verify policies match column types |
| **P2: NOT NULL user_id migration** | Schema Migration phase | Verify all domain tables have NOT NULL user_id, backfilled for existing rows |
| **P3: Query scoping misses** | Query Scoping phase | Code review of every use-case file; run cross-user test matrix |
| **P4: Worker auth session** | Worker User-Scoping phase | Verify PGMQ messages carry user_id; test worker with multi-user data |
| **P5: import_hash collision** | Schema Migration phase | Verify constraint changed to `(user_id, import_hash)`; test concurrent imports |
| **P6: Category/asset name collision** | Schema Migration phase | Verify global UNIQUE constraints replaced with per-user constraints; test duplicate name creation across users |
| **P7: Opening balance collision** | Schema Migration phase | Verify `UNIQUE(user_id, year, month)`; test per-user opening balance creation |
| **P8: Frontend cached data** | Frontend State Management phase | Test login/logout sequence; verify query keys include user.id |
| **P9: Testing blindspots** | Testing phase | Review test matrix for 5 operations × 3 users; verify FORCE RLS in tests |
| **P10: Ownership validation gap** | Final Audit phase | Run "Looks Done But Isn't" checklist; code review of every endpoint and worker |

## Sources

- [PostgreSQL 18 RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) — HIGH confidence
- [CREATE POLICY Documentation](https://www.postgresql.org/docs/current/sql-createpolicy.html) — HIGH confidence
- [ALTER TABLE Documentation (FORCE ROW LEVEL SECURITY)](https://www.postgresql.org/docs/current/sql-altertable.html) — HIGH confidence
- Codebase audit (`src/` full scan) — HIGH confidence, matches actual project state
- [spike-findings-finance: import-dedup.md](file:///home/olafk/finance/.opencode/skills/spike-findings-finance/references/import-dedup.md) — MEDIUM confidence (noted import_hash missing account_id)
- [Better Auth Documentation](https://better-auth.com/) — MEDIUM confidence (typed schema verified in codebase)

---
*Pitfalls research for: multi-tenant data isolation (converting single-tenant financial planning app)*
*Researched: 2026-06-07*
