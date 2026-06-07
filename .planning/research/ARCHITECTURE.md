# Architecture: Multi-Tenant Data Isolation

**Domain:** Financial planning app with existing single-tenant schema
**Researched:** 2026-06-07
**Overall confidence:** HIGH (verified against existing codebase + Postgres docs)

## Recommended Architecture

### Design: Row-Level Isolation via User-ID Scoping (API Layer + Optional RLS)

**Primary mechanism:** Every tenant-scoped query includes `AND user_id = ${userId}`. This is explicit, auditable, and requires no connection-pool gymnastics.

**Defense-in-depth (optional):** Postgres Row-Level Security (RLS) policies using session-level `app.current_user_id`. This protects against bugs even if a query forgets the filter.

```
┌─────────────────────────────────────────────────────────────┐
│                        Hono Server                          │
│                                                             │
│  ┌─────────────┐  ┌────────────────────┐  ┌──────────────┐ │
│  │ Auth Middleware│  │ Tenant Middleware  │  │ Route        │ │
│  │ (session →     │  │ (userId →          │  │ Handlers     │ │
│  │  c.set('user')) │  │  c.set('userId'))  │  │              │ │
│  └──────┬──────┘  └─────────┬──────────┘  └──────┬───────┘ │
│         │                   │                      │        │
│         ▼                   ▼                      ▼        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │               Use-Case Functions                    │    │
│  │  (accept userId param, include in SQL queries)      │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                   │
│                         ▼                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            postgres.js (connection pool)             │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                       │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  RLS Policies (defense-in-depth, optional)            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐             │  │
│  │  │ accounts │ │categories│ │transactions│            │  │
│  │  │ pol: user│ │ pol: user│ │ pol: user│             │  │
│  │  │ _id =    │ │ _id =    │ │ _id =    │             │  │
│  │  │ app.     │ │ app.     │ │ app.     │             │  │
│  │  │ current_ │ │ current_ │ │ current_ │             │  │
│  │  │ user_id  │ │ user_id  │ │ user_id  │             │  │
│  │  └──────────┘ └──────────┘ └──────────┘             │  │
│  │                                                     │  │
│  │  All tables have: user_id TEXT REFERENCES "user"(id)│  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow for a Tenant-Scoped Request

```
1. Request arrives → Hono receives it
2. Session middleware runs:
   - auth.api.getSession({ headers })
   - c.set('user', session.user)
   - c.set('session', session.session)
3. requireAuth middleware runs (or is integrated into session middleware):
   - Returns 401 if no session
4. Route handler:
   - Gets userId = c.get('user')!.id
   - Calls use-case with userId in params
5. Use-case function:
   - Includes `WHERE user_id = ${userId}` in all SQL queries
6. Response returned (filtered to current user's data only)
```

---

## Component Boundaries

### New Components

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Tenant Context Middleware** | (Optional) Sets Postgres session variable `app.current_user_id` for RLS | Postgres pool (via raw query) |
| **Category Seeder** | Seeds default categories for newly signed-up users | Postgres (`categories` table) |
| **Migration 007** | Adds `user_id` columns, backfills, adds indexes, drops old unique constraints | Postgres schema |

### Modified Components

| Component | What Changes | Communicates With |
|-----------|-------------|-------------------|
| **Route Handlers** (all 6 route files) | Extract `userId` from `c.get('user')`, pass to every use-case call | Use-case functions |
| **Use-Case Functions** (4 use-case files) | Accept `userId` parameter, include in all SQL queries | Postgres (`sql` tagged templates) |
| **`requireAuth` Middleware** | (Minimal change) Already provides `user`. Ensure `user.id` is always available | Better Auth API |
| **Workers** (import + insights) | Scope queries by user. Import worker gets user from `import_jobs.user_id` or PGMQ payload | Postgres, PGMQ |
| **Better Auth Config** | (Minimal/no change) Current session flow unchanged. May add signup hook for category seeding | Postgres |

### Unchanged Components

| Component | Why Unchanged |
|-----------|---------------|
| **Better Auth Library** | Auth session management works unchanged. We only read `user.id` from existing sessions |
| **PGMQ Queue System** | Messages already carry `user_id` (insights) or will get it added (import). Queue mechanism unchanged |
| **Frontend** | API responses change shape only if `user_id` leaks into response objects. Data shape otherwise identical |

---

## Data Flow (Before vs After)

### Before (Single-Tenant)
```
Client → Route → Use-Case → SQL without user_id filter → All data
```

### After (Multi-Tenant)
```
Client → Route (gets userId from session) → Use-Case → SQL WITH user_id filter → User's data only
```

### Specific Query Changes

**listTransactions (BEFORE):**
```typescript
const rows = await sql`
  SELECT * FROM transactions
  WHERE true
    ${account_id ? sql`AND account_id = ${account_id}` : sql``}
    ...
`;
```

**listTransactions (AFTER):**
```typescript
const rows = await sql`
  SELECT * FROM transactions
  WHERE user_id = ${userId}
    ${account_id ? sql`AND account_id = ${account_id}` : sql``}
    ${type ? sql`AND type = ${type}` : sql``}
    ...
`;
```

### Worker Data Flow

**Insights Worker** — ALREADY user-scoped (has `userId` from PGMQ payload):
```
PGMQ message → processAnalysisMessage → userId extracted
  → getInsightDataWindow(userId) [already scoped]
  → getCategoryAggregates(txIds) [already scoped by tx IDs from user's data]
  → insertInsightBatch [{ user_id: userId, ... }] [already scoped]
```

**Import Worker** — NEEDS user_id on import_jobs:
```
PGMQ message (includes job_id) → processJob
  → reads import_jobs row (needs user_id column)
  → insertBatch: transactions inserted WITH user_id from import_jobs.user_id
```

---

## Migration Strategy

### Step 1: Add `user_id` Column (Migration SQL)

```sql
-- 007_multi_tenant_isolation.sql

-- 1. Add user_id columns (nullable initially for backfill)
ALTER TABLE accounts ADD COLUMN user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE categories ADD COLUMN user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE transactions ADD COLUMN user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE monthly_opening_balances ADD COLUMN user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE assets ADD COLUMN user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE;
ALTER TABLE import_jobs ADD COLUMN user_id TEXT REFERENCES "user"(id) ON DELETE CASCADE;

-- 2. Create indexes for user_id lookups
CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_mob_user ON monthly_opening_balances(user_id);
CREATE INDEX IF NOT EXISTS idx_assets_user ON assets(user_id);
CREATE INDEX IF NOT EXISTS idx_import_jobs_user ON import_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, date DESC);

-- 3. Backfill existing data with the first user's ID
-- (Assumption: existing data belongs to the very first registered user)
UPDATE accounts SET user_id = (SELECT id FROM "user" ORDER BY "createdAt" ASC LIMIT 1);
UPDATE categories SET user_id = (SELECT id FROM "user" ORDER BY "createdAt" ASC LIMIT 1);
UPDATE transactions SET user_id = (SELECT id FROM "user" ORDER BY "createdAt" ASC LIMIT 1);
UPDATE monthly_opening_balances SET user_id = (SELECT id FROM "user" ORDER BY "createdAt" ASC LIMIT 1);
UPDATE assets SET user_id = (SELECT id FROM "user" ORDER BY "createdAt" ASC LIMIT 1);
UPDATE import_jobs SET user_id = (SELECT id FROM "user" ORDER BY "createdAt" ASC LIMIT 1);

-- 4. Make user_id NOT NULL after backfill
ALTER TABLE accounts ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE categories ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE transactions ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE monthly_opening_balances ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE assets ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE import_jobs ALTER COLUMN user_id SET NOT NULL;

-- 5. Update unique constraints
-- Categories: name was globally unique → now unique per user
ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_name_key;
ALTER TABLE categories ADD UNIQUE (user_id, name);

-- Assets: name was globally unique → now unique per user
ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_name_key;
ALTER TABLE assets ADD UNIQUE (user_id, name);

-- 6. Drop global indexes that overlap with user-scoped indexes
DROP INDEX IF EXISTS idx_tx_account_date;
DROP INDEX IF EXISTS idx_tx_category;
DROP INDEX IF EXISTS idx_tx_date_type;
DROP INDEX IF EXISTS idx_mob_year_month;
```

### Step 2: Update Use-Cases

Every use-case function that queries tenant-scoped tables needs:
1. A `userId` parameter (string)
2. `WHERE user_id = ${userId}` in SQL queries

**Tables to scope:**
| Table | Current Scoping | New Scoping |
|-------|----------------|-------------|
| `accounts` | None | `WHERE user_id = ${userId}` |
| `categories` | None | `WHERE user_id = ${userId}` |
| `transactions` | None | `WHERE user_id = ${userId}` |
| `monthly_opening_balances` | None | `WHERE user_id = ${userId}` |
| `assets` | None | `WHERE user_id = ${userId}` |
| `import_jobs` | None | `WHERE user_id = ${userId}` |
| `insights` | Already has `user_id` | Already scoped |

**Full list of use-case functions needing updates:**

1. `src/core/ledger/use-cases.ts` — createTransaction, listTransactions, getTransaction, updateTransaction, deleteTransaction, getMonthlySummary, listOpeningBalances, createOpeningBalance, updateOpeningBalance
2. `src/core/assets/use-cases.ts` — listAssets, createAsset, updateAsset, deleteAsset
3. `src/core/import/use-cases.ts` — enqueueImportJob, getImportStatus, insertBatch (worker)
4. `src/core/insights/use-cases.ts` — getInsightDataWindow (already has userId), getCategoryAggregates (already scoped by transaction IDs)
5. `src/workers/import-worker.ts` — processExcelMigrationJob, processCsvImportJob (need user_id from import_jobs data)
6. `src/workers/insights-worker.ts` — already scoped

### Step 3: Update Route Handlers

Each route handler needs to:
1. Get `userId` from `c.get('user').id`
2. Pass it to use-case functions

**Example pattern (ledger.ts):**

```typescript
// BEFORE
ledgerRoutes.post('/', requireAuth, zValidator('json', CreateTransactionSchema, ...), async (c) => {
  const input = c.req.valid('json');
  const tx = await createTransaction(input);
  ...
});

// AFTER
ledgerRoutes.post('/', requireAuth, zValidator('json', CreateTransactionSchema, ...), async (c) => {
  const input = c.req.valid('json');
  const userId = c.get('user')!.id;
  const tx = await createTransaction({ ...input, user_id: userId });
  ...
});
```

### Step 4: Handle Default Category Seeding

**Pattern: Lazy seeding on first data access**

New users start with zero categories. On first request to `GET /categories`, check if the user has categories. If not, seed defaults.

```typescript
// In reference.ts (GET /categories):
referenceRoutes.get('/categories', requireAuth, async (c) => {
  try {
    const userId = c.get('user')!.id;
    await ensureDefaultCategories(userId);
    const rows = await sql`
      SELECT * FROM categories WHERE user_id = ${userId} ORDER BY name
    `;
    ...
  }
});
```

```typescript
// Category seeding function
export async function ensureDefaultCategories(userId: string): Promise<void> {
  const [{ count }] = await sql`SELECT COUNT(*) AS count FROM categories WHERE user_id = ${userId}`;
  if (Number(count) > 0) return; // Already seeded

  const defaults = [
    { name: 'biedronka', is_fixed_cost: false },
    { name: 'żabka', is_fixed_cost: false },
    // ... all 25 default categories matching seed.sql
  ];

  for (const cat of defaults) {
    await sql`
      INSERT INTO categories (name, is_fixed_cost, user_id)
      VALUES (${cat.name}, ${cat.is_fixed_cost}, ${userId})
      ON CONFLICT (user_id, name) DO NOTHING
    `;
  }
}
```

**Alternative: Seed on signup via Better Auth plugin hook**
Better Auth v1.x+ supports database hooks. We could register an `afterSignUp` hook via `databaseHooks` option in the auth config. This is cleaner but requires checking if Better Auth supports it in this version.

For v1.1, the lazy seeding approach is simpler and less risky.

### Step 5: Add RLS (Optional Defense-in-Depth)

This is optional for v1.1. If added:

```sql
-- Enable RLS on tenant tables
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_opening_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_jobs ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY user_isolation_accounts ON accounts
  USING (user_id = current_setting('app.current_user_id', true)::TEXT);

CREATE POLICY user_isolation_categories ON categories
  USING (user_id = current_setting('app.current_user_id', true)::TEXT);

CREATE POLICY user_isolation_transactions ON transactions
  USING (user_id = current_setting('app.current_user_id', true)::TEXT);

CREATE POLICY user_isolation_mob ON monthly_opening_balances
  USING (user_id = current_setting('app.current_user_id', true)::TEXT);

CREATE POLICY user_isolation_assets ON assets
  USING (user_id = current_setting('app.current_user_id', true)::TEXT);

CREATE POLICY user_isolation_import_jobs ON import_jobs
  USING (user_id = current_setting('app.current_user_id', true)::TEXT);

-- GRANT USAGE on all tenant tables to your app role (adjust if needed)
```

The RLS approach requires setting `app.current_user_id` on each connection. This is the challenge with connection pooling.

**Two options for wiring RLS:**

**Option A: Per-request reserved connection** (recommended if RLS is critical)
```typescript
// Tenant middleware using reserved connection
const tenantMiddleware = createMiddleware(async (c, next) => {
  const user = c.get('user');
  if (user) {
    // Reserve a connection from the pool
    const connection = await sql.reserve();
    await connection.unsafe(
      `SELECT set_config('app.current_user_id', ${user.id}, true)`
    );
    // Store connection in context for this request only
    c.set('tenantSql', connection);
    await next();
    // Release back to pool after response
    connection.release();
  } else {
    await next();
  }
});
```

**Option B: SET LOCAL inside transaction** (simpler, but every query must use `sql.begin()`)
```typescript
await sql.begin(async (tx) => {
  await tx`SELECT set_config('app.current_user_id', ${userId}, true)`;
  // All queries in this transaction inherit the setting
  const rows = await tx`SELECT * FROM transactions WHERE ...`;
  // RLS policies automatically filter
});
```

**For v1.1, I recommend skipping RLS.** The API-layer scoping is sufficient, straightforward, and well-tested. RLS adds connection-pool complexity that doesn't pay off until you need protection against accidental data leaks from direct DB access.

---

## Patterns to Follow

### Pattern 1: userId as First Param in Use-Cases

**What:** Every use-case function explicitly accepts `userId` as its first or second parameter.

**When:** For any function querying a tenant-scoped table.

**Example:**
```typescript
export async function listAssets(userId: string): Promise<Asset[]> {
  const rows = await sql`
    SELECT * FROM assets 
    WHERE user_id = ${userId} 
    ORDER BY name ASC
  `;
  return rows as Asset[];
}
```

### Pattern 2: user_id Inserted from Route Context (Never from Client)

**What:** The `user_id` value is always extracted from the authenticated session in the route handler, never trusted from client input.

**When:** All INSERT operations.

**Example:**
```typescript
// Route handler — SAFE: userId comes from session
ledgerRoutes.post('/', requireAuth, async (c) => {
  const userId = c.get('user')!.id;       // ← from session
  const input = c.req.valid('json');      // ← from client (NEVER trust user_id in here)
  const tx = await createTransaction({ ...input, user_id: userId });
  ...
});
```

### Pattern 3: Default Categories Seeded Lazily

**What:** On first data access, check and seed default categories for a new user.

**When:** In `GET /categories` route handler.

**Why:** No user is blocked from first operation. Better Auth signup hooks would be cleaner but require additional research/configuration. Lazy seeding is simple and reliable.

### Pattern 4: Scoped Unique Constraints

**What:** Replace global UNIQUE constraints with per-user UNIQUE constraints.

**When:** Tables where record names must be unique per user but can overlap between users (categories, assets).

**Example:**
```sql
ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_name_key;
ALTER TABLE categories ADD UNIQUE (user_id, name);
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Threading user_id Through Every Function Call Manually

**What:** Defining `userId` as a module-level variable or passing it through 5 layers of functions.

**Why bad:** Breaks module isolation. Module-level state is not request-safe (pool connections share modules). Manual threading creates deep parameter chains.

**Instead:** Accept `userId` as a parameter in use-case functions. Route handlers extract it from `c.get('user').id` and pass it down. Keep it explicit.

### Anti-Pattern 2: RLS Without API-Layer Scoping

**What:** Relying solely on RLS policies without adding `WHERE user_id = ?` to application queries.

**Why bad:** Connection pooling makes RLS hard to wire up correctly. If `SET app.current_user_id` isn't called on the right connection, RLS either blocks everything or allows everything. API-layer scoping is always the correct source of truth.

**Instead:** API-layer scoping first. Add RLS later as defense-in-depth only if needed.

### Anti-Pattern 3: Creating a Separate DB Instance Per Request

**What:** Creating a new `postgres()` connection per request just to set session variables.

**Why bad:** Connection pool is bypassed, causing connection exhaustion under load. Overwhelms Postgres with connection overhead.

**Instead:** Use `sql.reserve()` + `sql.release()` for per-request connection needs, or use `SET LOCAL` inside `sql.begin()` transactions.

### Anti-Pattern 4: Accepting user_id from Client Input

**What:** Letting the request body or URL params specify the user_id for an operation.

**Why bad:** Anyone can impersonate any user. Authentication bypass.

**Instead:** Always extract user_id from the server-side session (`c.get('user').id`).

---

## Scalability Considerations

| Concern | At 1 user | At 100 users | At 10K users |
|---------|-----------|--------------|--------------|
| **Indexes** | `idx_transactions_user_date` covers most queries | Same indexes scale fine | Consider partial indexes (e.g., `WHERE user_id = 'active_user'`). Materialized summary views per user. |
| **Connection pool** | 10 connections (current) | 10-20 connections | 20-50 connections. RLS adds per-request connection overhead. |
| **Default category seeding** | Instant | Instant (1ms per new user) | Add background job for bulk seeding if needed. |
| **Query performance** | No change | `WHERE user_id = ?` uses index — no perf impact | Same. Add `user_id` prefix to composite indexes. |
| **Backfill migration** | Single-user, instant | Still instant (< 1s) | Run as background migration. Batch UPDATE. |
| **RLS (if added)** | No overhead | Policy evaluation is cheap | Monitor for policy overhead in complex queries. |

---

## Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Tenant isolation mechanism | API-layer `WHERE user_id = ?` scoping | Explicit, auditable, connection-pool safe. RLS is defense-in-depth. |
| user_id column type | TEXT (matching Better Auth `"user".id`) | Avoids join/type-cast overhead. Matches existing pattern. |
| Category seeding timing | Lazy (on first GET /categories) | No signup hook dependency. Immediate for existing users. No migration needed. |
| Existing data owner | First registered user (by `createdAt`) | Simple, deterministic. No migration prompts needed. |
| Unique constraint strategy | User-scoped `UNIQUE(user_id, name)` | Allows same category name for different users. |
| Route-level vs global tenant middleware | Route-level (pass userId per handler) | Keeps changes explicit and auditable. No magic. Existing middleware already provides `c.get('user')`. |
| RLS implementation | Deferred (not in v1.1) | Connection-pool complexity doesn't justify benefit for single-admin app. |

---

## Implementation Order

The build order has hard dependencies:

```
1. Migration SQL (007_multi_tenant_isolation.sql)
   ↓
2. Category seeding utility
   ↓
3. Use-case function updates (add userId params + SQL)
   ↓
4. Route handler updates (extract userId, pass to use-cases)
   ↓
5. Worker updates (import_jobs + insights already scoped)
   ↓
6. Test updates + new isolation tests
   ↓
7. Seed/SQL file updates (seed.sql + seed-dev.sql need user_id)
   ↓
8. Frontend adjustments (if any)
   ↓
9. [Optional] RLS policies
```

### Why This Order

1. **Migration first** — nothing can work without the database schema in place
2. **Category seeding** — utility needed before use-cases can be tested
3. **Use-cases** — the core business logic must be updated before routes call them
4. **Route handlers** — last layer in the request chain, depends on use-cases
5. **Workers** — run in separate process, decoupled from HTTP. Update after main data flow is working
6. **Tests** — need all code changes before tests make sense
7. **Seed/SQL** — dev seed data needs user_id columns populated
8. **Frontend** — likely no changes needed, but verify

---

## Sources

- [PostgreSQL Row Security Policies (Official Docs — v18)](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) — HIGH confidence
- [PostgreSQL CREATE POLICY (Official Docs)](https://www.postgresql.org/docs/current/sql-createpolicy.html) — HIGH confidence
- [PostgreSQL SET](https://www.postgresql.org/docs/current/sql-set.html) — HIGH confidence (custom session parameter pattern for RLS)
- [Hono Context set/get](https://hono.dev/docs/api/context) — HIGH confidence (verified against existing codebase)
- [Hono Middleware](https://hono.dev/docs/guides/middleware) — HIGH confidence (existing pattern in requireAuth)
- [postgres.js README](https://github.com/porsager/postgres) — HIGH confidence (connection pool, reserved connections, tagged templates)
- [Better Auth — Session API](https://www.better-auth.com/docs/plugins/session) — MEDIUM confidence (verified against existing auth.ts)
- Existing codebase analysis (`index.ts`, `auth.ts`, all route files, all use-cases, workers) — HIGH confidence
