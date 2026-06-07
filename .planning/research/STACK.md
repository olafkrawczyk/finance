# Stack Research: Multi-Tenant Data Isolation

**Domain:** Postgres multi-tenant data isolation for existing financial planning app (Bun/Hono/postgres.js)
**Researched:** 2026-06-07
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| postgres.js (existing) | ^3.4.9 | Database client | Already in production. No ORM migration needed. Tagged template SQL + dynamic query fragments are sufficient for adding `AND user_id = ?` filters. Stay with what works. |
| node-pg-migrate (existing) | ^8.0.4 | Schema migrations | Already configured with `migrationFileLanguage: 'sql'`. Add migration for `user_id` columns + RLS policies. No change needed. |
| Better Auth (existing) | ^1.6.14 | Authentication | Already integrated. Session middleware already sets `c.get('user')` with `user.id` (TEXT type). This is the tenant context source. |
| pg (existing peer dep) | ^8.21.0 | Better Auth DB adapter | Required by Better Auth for its own Pool connection. Already in use. No change needed. |

### Recommended Approach: Application-Layer Scoping (Primary)

**Decision:** Add `user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE` to existing tables, then enforce scoping in the application layer by injecting `AND user_id = ${userId}` into every query. This is the primary isolation mechanism.

**Why not RLS (pure Postgres approach):**
- Connection pool: postgres.js uses a pool of up to 10 connections. `SET SESSION app.user_id` would leak user context between requests. `SET LOCAL` requires wrapping every request in a transaction — invasive change to all route handlers.
- Existing codebase: all 37+ query sites use raw `sql` tagged templates. Adding `AND user_id = $1` is a mechanical, auditable change consistent with existing patterns.
- Single-user-per-request: no shared sessions or concurrent user identities on the same connection.
- Existing precedent: `insights` table already has `user_id` and all its queries already filter by it (see `src/core/insights/use-cases.ts` lines 94, 102, 116, 134, 167).

### Recommended Approach: RLS as Defense-in-Depth (Secondary / Optional)

If RLS is desired as a safety net, add it AFTER the application-layer scoping is complete. The pattern:

1. Create custom Postgres GUC parameter: no extension needed — Postgres accepts any `app.*` custom parameter name per [Customized Options](https://www.postgresql.org/docs/current/runtime-config-custom.html).
2. Set it per-request via `SET LOCAL app.current_user_id = 'user-id'` inside a `sql.begin()` transaction wrapper.
3. Create permissive RLS policies: `USING (user_id = current_setting('app.current_user_id')::TEXT)`.
4. Use `ALTER TABLE ... FORCE ROW LEVEL SECURITY` to ensure even the table owner is subject to RLS (important because the app user is also the table owner).

**RLS Pool Problem:** Postgres.js does not support custom `SET` statements in its `connection` startup options. The `connection` option only supports standard protocol parameters (`application_name`, etc.). To use RLS safely with a pool, you MUST wrap every request in a transaction:

```typescript
// Middleware pattern for RLS with connection pool
app.use('*', async (c, next) => {
  const session = c.get('session');
  if (session) {
    // Must set LOCAL inside a transaction for pool safety
    // Without this wrapper, the setting leaks to the next request
    await next(); 
  } else {
    await next();
  }
});
```

The problem: `SET LOCAL` only works inside a transaction block. You'd need to wrap every route handler in `sql.begin()`. This is invasive and error-prone for a single-user-scoped app.

**Verdict:** RLS is technically feasible but adds significant complexity for marginal benefit in this context. Implement application-layer scoping first. Add RLS in a future milestone only if multi-user data leakage is a demonstrated risk.

### Query Scoping Implementation Pattern

**Recommended: Middleware-injected user_id via Hono context (NO new packages needed):**

The existing `requireAuth` middleware already sets `c.get('user')`. The pattern is already demonstrated in `src/core/insights/use-cases.ts` — pass `userId` as a function parameter.

**Pattern for app-layer scoping:**

```typescript
// src/interface-adapters/api/ledger.ts (example modification)
ledgerRoutes.get(
  '/',
  requireAuth,
  async (c) => {
    const user = c.get('user')!; // requireAuth guarantees non-null
    const query = c.req.valid('query');
    const { rows, total } = await listTransactions(query, user.id);
    // ...
  }
);
```

```typescript
// src/core/ledger/use-cases.ts (example modification)
export async function listTransactions(
  params: ListTransactionsParams,
  userId: string  // NEW: inject user context
): Promise<{ rows: Transaction[]; total: number }> {
  const { page, per_page, account_id, type, date_from, date_to, uncategorized } = params;
  const offset = (page - 1) * per_page;

  const rows = await sql`
    SELECT * FROM transactions
    WHERE user_id = ${userId}  -- NEW: scoping filter
      ${account_id ? sql`AND account_id = ${account_id}` : sql``}
      ${type ? sql`AND type = ${type}` : sql``}
      ${date_from ? sql`AND date >= ${date_from}` : sql``}
      ${date_to ? sql`AND date <= ${date_to}` : sql``}
      ${uncategorized ? sql`AND category_id IS NULL` : sql``}
    ORDER BY date DESC, created_at DESC
    LIMIT ${per_page} OFFSET ${offset}
  `;
  // ...
}
```

**No new packages needed for this pattern.** It uses existing postgres.js tagged template capabilities.

### Migration Strategy

**Migration file pattern** (`src/infrastructure/db/migrations/007_add_user_id_columns.sql`):

```sql
-- ↑↑↑ UP MIGRATION ↑↑↑

-- Step 1: Add user_id columns with NOT NULL, referencing Better Auth's "user" table
-- Better Auth stores user.id as TEXT (not UUID), so user_id must be TEXT to match
ALTER TABLE accounts ADD COLUMN user_id TEXT NOT NULL DEFAULT '' REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE categories ADD COLUMN user_id TEXT NOT NULL DEFAULT '' REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE transactions ADD COLUMN user_id TEXT NOT NULL DEFAULT '' REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE monthly_opening_balances ADD COLUMN user_id TEXT NOT NULL DEFAULT '' REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE import_jobs ADD COLUMN user_id TEXT NOT NULL DEFAULT '' REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE assets ADD COLUMN user_id TEXT NOT NULL DEFAULT '' REFERENCES "user"(id) ON DELETE CASCADE;

-- Step 2: Backfill existing rows to the first admin user
-- NOTE: This requires a manual step — identify the admin user before running migration
-- UPDATE accounts SET user_id = 'admin-user-id' WHERE user_id = '';
-- UPDATE categories SET user_id = 'admin-user-id' WHERE user_id = '';
-- ... (for each table)

-- Step 3: Remove DEFAULT after backfill
ALTER TABLE accounts ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE categories ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE transactions ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE monthly_opening_balances ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE import_jobs ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE assets ALTER COLUMN user_id DROP DEFAULT;

-- Step 4: Add indexes for user_id scoping
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_monthly_opening_balances_user_id ON monthly_opening_balances(user_id);
CREATE INDEX idx_import_jobs_user_id ON import_jobs(user_id);
CREATE INDEX idx_assets_user_id ON assets(user_id);

-- Step 5: Add composite indexes for common query patterns
-- Transactions are commonly queried by user_id + date
CREATE INDEX idx_transactions_user_date ON transactions(user_id, date DESC);
-- Accounts queried by user_id + name
CREATE INDEX idx_accounts_user_name ON accounts(user_id, name);

-- Step 6: (Optional) Enable RLS and create policies
-- ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE accounts FORCE ROW LEVEL SECURITY;
-- CREATE POLICY user_isolation ON accounts
--   USING (user_id = current_setting('app.current_user_id')::TEXT);
-- ... (repeat for each table)

-- ↓↓↓ DOWN MIGRATION ↓↓↓

DROP INDEX IF EXISTS idx_accounts_user_id;
DROP INDEX IF EXISTS idx_categories_user_id;
DROP INDEX IF EXISTS idx_transactions_user_id;
DROP INDEX IF EXISTS idx_monthly_opening_balances_user_id;
DROP INDEX IF EXISTS idx_import_jobs_user_id;
DROP INDEX IF EXISTS idx_assets_user_id;
DROP INDEX IF EXISTS idx_transactions_user_date;
DROP INDEX IF EXISTS idx_accounts_user_name;

ALTER TABLE accounts DROP COLUMN IF EXISTS user_id;
ALTER TABLE categories DROP COLUMN IF EXISTS user_id;
ALTER TABLE transactions DROP COLUMN IF EXISTS user_id;
ALTER TABLE monthly_opening_balances DROP COLUMN IF EXISTS user_id;
ALTER TABLE import_jobs DROP COLUMN IF EXISTS user_id;
ALTER TABLE assets DROP COLUMN IF EXISTS user_id;

-- DROP POLICY IF EXISTS user_isolation ON accounts; (etc.)
```

**Key migration details:**
- Use `TEXT` type for `user_id` to match Better Auth's `user.id` type (TEXT, not UUID)
- Use `REFERENCES "user"(id) ON DELETE CASCADE` for referential integrity (matching existing `insights` table pattern)
- Add `DEFAULT ''` temporarily for the ADD COLUMN step (Postgres requires a DEFAULT for NOT NULL columns on existing tables)
- Backfill after adding columns, then drop the DEFAULT
- Add composite indexes for the most common query patterns (user_id + date, user_id + name)
- The `insights` table already has `user_id` — no migration needed for it

### Testing Strategy

| Test Type | Approach | Tools |
|-----------|----------|-------|
| Data isolation | Create users A + B. A creates data. B queries. Assert B sees nothing from A. | Existing test framework (to be determined) |
| Migration | Run migration against a copy of production data. Verify backfill correctness. | `bun run db:migrate` with test database |
| Query audit | Automated scan of all `use-cases.ts` files for `user_id` filter presence after refactor. | `grep` / custom script |
| RLS (if used) | Connect as app user, attempt cross-tenant data access directly via SQL. | Direct SQL connection |

**No new packages needed for testing isolation** — Bun's built-in test runner or the existing test framework suffices.

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Kysely / Prisma / Drizzle ORM | Existing codebase uses raw SQL via postgres.js. Adding an ORM creates a dual-query-pattern maintenance burden for zero benefit in tenant scoping. The `user_id` filter is one additional clause per query. | Postgres.js tagged templates (existing) |
| Supabase-js | Supabase's RLS helpers are designed for the Supabase hosted platform, not self-hosted Postgres. Their `supabase.from('table').select()` replaces the entire query layer. Would require a full rewrite. | Native Postgres RLS (if used) or app-layer filtering |
| `pg` package replacement | Better Auth uses `pg.Pool` internally. Replacing it would break Better Auth. Postgres.js is used for application queries — keep both. | Keep both `postgres` (app) and `pg` (Better Auth peer dep) |
| PgBouncer | Single-server local Postgres doesn't need connection pooling at the Postgres level. PgBouncer would break the `SET LOCAL` RLS pattern entirely (transaction pooling mode strips session state). | Postgres.js connection pool (existing, max: 10) |
| Multi-tenant middleware libraries (e.g., `@neondatabase/serverless`, `postgres-query-builder`) | Unnecessary dependencies. The required pattern is a single `AND user_id = ?` clause. | Hono middleware + existing postgres.js |

## Stack Patterns by Variant

**If using RLS (defense-in-depth):**
- Use `SET LOCAL app.current_user_id = $1` inside a `sql.begin()` wrapper for every request that touches tenant-scoped tables
- Use permissive policies with `USING (user_id = current_setting('app.current_user_id')::TEXT)`
- Use `FORCE ROW LEVEL SECURITY` to prevent table owner bypass
- Postgres custom GUC params use the `app.*` namespace — no `CREATE EXTENSION` needed
- **Known limitation:** Postgres.js's `connection` option in the client constructor does NOT support arbitrary SET commands (it only supports standard startup parameters). The `SET LOCAL` must be executed as a separate SQL statement inside a transaction.

**If using only application-layer filtering (recommended):**
- Pass `userId: string` as the first or last parameter to every use-case function
- Add `WHERE user_id = ${userId}` as the first filter clause in every query
- Use a TypeScript lint rule to require `userId` parameter in database functions
- Create a helper type: `type WithUserId = { userId: string }` for function signatures

**For background workers (import-worker, insights-worker):**
- Must receive `userId` in the pgmq message payload
- The `import_queue` and `analysis_queue` messages already include user context (see `src/core/insights/use-cases.ts` line 127: `{ user_id: userId, triggered_by: 'manual' }`)
- Workers must pass `userId` through to all use-case functions

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| postgres.js ^3.4.9 | Bun 1.x | Tagged template syntax works identically in Bun runtime |
| node-pg-migrate ^8.0.4 | PostgreSQL 13+ (app uses latest) | Configured with `migrationFileLanguage: 'sql'` — SQL-only migration files |
| better-auth ^1.6.14 | pg ^8.21.0 | Better Auth uses `pg.Pool` internally for its own DB access, separate from app's postgres.js |
| pg ^8.21.0 | better-auth ^1.6.14 | Peer dependency of Better Auth. Used only by Better Auth, not by app queries. |

## Sources

- [PostgreSQL RLS Docs](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) — Row Security Policies (HIGH confidence)
- [PostgreSQL Customized Options](https://www.postgresql.org/docs/current/runtime-config-custom.html) — Custom GUC parameters (`app.*` namespace) (HIGH confidence)
- [PostgreSQL ALTER TABLE](https://www.postgresql.org/docs/current/sql-altertable.html) — Column add/drop/index operations (HIGH confidence)
- [postgres.js GitHub](https://github.com/porsager/postgres) — Tagged template SQL client, connection pool behavior, `connection` option limitations (HIGH confidence via code read of existing use)
- [node-pg-migrate GitHub](https://github.com/salsita/node-pg-migrate) — SQL migration file support, `migrationFileLanguage: 'sql'` (HIGH confidence via existing config)
- [Better Auth Hono Integration](https://www.better-auth.com/docs/integrations/hono) — Session middleware pattern (HIGH confidence via existing implementation)
- [Kysely GitHub](https://github.com/kysely-org/kysely) — Type-safe query builder, evaluated as alternative (MEDIUM confidence)

---

*Stack research for: Multi-tenant data isolation (v1.1)*
*Researched: 2026-06-07*
