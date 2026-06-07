# Phase 6: Schema Migration & Backfill - Pattern Map

**Mapped:** 2026-06-07
**Files analyzed:** 6 (3 new, 3 modified)
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `src/infrastructure/db/migrations/008_add_user_id_columns.sql` | migration | sequential (DDL) | `src/infrastructure/db/migrations/007_setup_pgmq.sql` | exact (same role, same tool) |
| `src/infrastructure/db/migrations/009_update_uniques.sql` | migration | sequential (DDL) | `src/infrastructure/db/migrations/007_setup_pgmq.sql` | exact (same role, same tool) |
| `src/infrastructure/db/migrations/010_add_indexes.sql` | migration | sequential (DDL) | `src/infrastructure/db/migrations/007_setup_pgmq.sql` | exact (same role, same tool) |
| `src/infrastructure/db/schema.sql` | config/schema | sequential | `src/infrastructure/db/schema.sql` (self) | exact — modify in place |
| `src/workers/import-worker.ts` | utility | transform | `src/workers/import-worker.ts` (self — `computeImportHash` lines 92-96) | exact — modify in place (D-06, may defer) |
| `tests/schema-migration.test.ts` | test | request-response (integration) | `tests/import-dedup.test.ts` | role-match (same test framework, SQL assertions) |

## Pattern Assignments

### `src/infrastructure/db/migrations/008_add_user_id_columns.sql` (migration, sequential DDL)

**Analog:** `src/infrastructure/db/migrations/007_setup_pgmq.sql`

**Marker pattern** (lines 1-3, 21-23):
```sql
-- 002_setup_pgmq: Enable PGMQ extension and create worker queues

-- Up Migration

... DDL ...

-- Down Migration

... reverse DDL ...;
```

**Key points:**
- The comment header can differ from the filename (e.g., file is `007_setup_pgmq.sql` but header says `002_setup_pgmq`)
- `-- Up Migration` and `-- Down Migration` markers are case-sensitive — must match exactly
- Blank lines between markers and SQL for readability
- `-- Down Migration` marker is optional if no down migration is needed, but **for this phase down migrations are required** (D-07)

**ALTER TABLE ADD COLUMN with FK pattern** — from `001_initial_schema.sql` lines 87, 94 (Better Auth FK references):
```sql
"userId"      TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE
```

Note: Better Auth tables use double-quoted identifiers and `ON DELETE CASCADE`. Domain tables should follow same FK pattern:
```sql
ALTER TABLE accounts
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;
```

**Why `TEXT` not `UUID`:** The `"user"(id)` column is `TEXT` (Better Auth convention), so the FK reference must match [VERIFIED: schema.sql line 72].

**Existing migration that demonstrates pure up-only** — `005_rename_arval_to_auto.sql` (1 line, no markers) and `006_create_assets_table.sql` (no down migration marker, though could use one).

For 008, 009, 010: **Always include both `-- Up Migration` and `-- Down Migration` markers** per D-07.

---

### `src/infrastructure/db/migrations/009_update_uniques.sql` (migration, sequential DDL)

**Analog:** `src/infrastructure/db/migrations/007_setup_pgmq.sql` (marker pattern inherited)
**Analog for DDL pattern:** `src/infrastructure/db/migrations/004_insights_table.sql` lines 1-16 (table creation with UNIQUE)

**DROP/ADD CONSTRAINT pattern** — derived from existing DDL patterns in schema.sql:
```sql
-- Drop global UNIQUE, add per-user composite UNIQUE
ALTER TABLE categories DROP CONSTRAINT categories_name_key;
ALTER TABLE categories ADD CONSTRAINT categories_user_id_name_key UNIQUE(user_id, name);
```

**Constraint naming convention:** PostgreSQL auto-generates `{table}_{column}_key` for inline UNIQUE. Verify via `SELECT conname FROM pg_constraint WHERE conrelid = 'table_name'::regclass`.

**Up/Down symmetry pattern** — from `007_setup_pgmq.sql`:
```
-- Up Migration creates/alters
-- Down Migration reverses every Up operation in reverse order
```

For 009, the down migration restores the original global constraints in reverse order of the up migration (see RESEARCH.md Example 2).

---

### `src/infrastructure/db/migrations/010_add_indexes.sql` (migration, sequential DDL)

**Analog:** `src/infrastructure/db/migrations/004_insights_table.sql` lines 18-22 (CREATE INDEX pattern):
```sql
CREATE INDEX IF NOT EXISTS idx_insights_user_type ON insights(user_id, type);
CREATE INDEX IF NOT EXISTS idx_insights_user_dismiss ON insights(user_id, dismissed);
```

**CREATE INDEX IF NOT EXISTS pattern** — from `001_initial_schema.sql` lines 45-48:
```sql
CREATE INDEX IF NOT EXISTS idx_tx_account_date ON transactions(account_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_tx_category     ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_tx_date_type    ON transactions(date, type);
CREATE INDEX IF NOT EXISTS idx_mob_year_month  ON monthly_opening_balances(year, month);
```

**DROP INDEX IF EXISTS pattern** — for down migration:
```sql
DROP INDEX IF EXISTS idx_mob_year_month;
```

**Note per D-04:** Minimal essential indexes only. The UNIQUE constraints in 009 already create btree indexes on `(user_id, name)` for categories/assets, `(user_id, import_hash)` for transactions, and `(user_id, year, month)` for monthly_opening_balances. This file may be nearly empty if no additional indexes are needed.

---

### `src/infrastructure/db/schema.sql` (config/schema — MODIFY)

**Analog:** The file itself (modify in place to match post-migration state)

**Current pattern** for each table (lines 2-8 — accounts example):
```sql
CREATE TABLE IF NOT EXISTS accounts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('personal', 'business')),
  currency   TEXT NOT NULL DEFAULT 'PLN',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Target pattern** (after modification) for each domain table — each table gets `user_id` column:
```sql
CREATE TABLE IF NOT EXISTS accounts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('personal', 'business')),
  currency   TEXT NOT NULL DEFAULT 'PLN',
  user_id    TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,  -- NEW
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Constraint changes in schema.sql:**
- `UNIQUE(name)` on categories → remove inline UNIQUE, add `UNIQUE(user_id, name)` as table-level or inline
- `UNIQUE(name)` on assets → same pattern
- `UNIQUE(import_hash)` on transactions → remove inline UNIQUE, add `UNIQUE(user_id, import_hash)`
- `UNIQUE(year, month)` on monthly_opening_balances → same pattern

**Reference for constraint syntax** — from existing table: `monthly_opening_balances` line 42:
```sql
UNIQUE (year, month)
```

Note: PostgreSQL doesn't allow per-column inline UNIQUE with two columns. So `UNIQUE(user_id, name)` must be table-level:
```sql
CREATE TABLE IF NOT EXISTS categories (
  ...
  UNIQUE(user_id, name)
);
```

---

### `src/workers/import-worker.ts` (utility, transform — MODIFY)

**Analog:** Self (lines 92-96 — `computeImportHash` function)

**Current hash computation** (lines 92-96):
```typescript
export function computeImportHash(date: string, amount: string, description: string): string {
  return createHash('sha256')
    .update(`${date}|${amount}|${description}`)
    .digest('hex');
}
```

**Target pattern** (with `account_id` per D-06):
```typescript
export function computeImportHash(date: string, amount: string, description: string, accountId: string): string {
  return createHash('sha256')
    .update(`${date}|${amount}|${description}|${accountId}`)
    .digest('hex');
}
```

**Usage pattern** in `insertBatch` (line 298):
```typescript
const hash = computeImportHash(tx.date, tx.amount, tx.description);
// → becomes:
const hash = computeImportHash(tx.date, tx.amount, tx.description, accountId);
```

**ON CONFLICT pattern** (lines 302-325):
```typescript
await sql`
  INSERT INTO transactions (...)
  VALUES (...)
  ON CONFLICT (import_hash) DO NOTHING
`;
```

**Key change:** After migration, `import_hash` UNIQUE constraint becomes `UNIQUE(user_id, import_hash)`, so `ON CONFLICT (import_hash)` will fail until updated to `ON CONFLICT (user_id, import_hash)` — or more practically, `ON CONFLICT ON CONSTRAINT transactions_user_id_import_hash_key`.

**Note per CONTEXT.md D-06:** This change may be deferred to Phase 8 (Worker Isolation). The pattern documentation is included here regardless.

---

### `tests/schema-migration.test.ts` (test, request-response/integration)

**Analog:** `tests/import-dedup.test.ts` (lines 1-56)

**Full testing pattern** (lines 1-45):
```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import { createHash } from 'crypto';
import sql from '../src/infrastructure/db/client';

let accountId: string;

beforeAll(async () => {
  await sql`TRUNCATE transactions CASCADE`;
  const accounts = await sql`SELECT id FROM accounts LIMIT 1`;
  if (accounts.length === 0) {
    throw new Error('No seeded accounts found');
  }
  accountId = accounts[0].id;
});

describe('Import Deduplication Tests', () => {
  it('skips duplicate transactions by import_hash via ON CONFLICT DO NOTHING', async () => {
    // ... test body with sql`...` queries
    expect(Number(rows[0].count)).toBe(1);
  });
});
```

**Pattern for schema migration tests** — verify column existence using `information_schema`:
```typescript
it('adds user_id column to accounts table', async () => {
  const result = await sql`
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'accounts' AND column_name = 'user_id'
  `;
  expect(result.length).toBe(1);
  expect(result[0].data_type).toBe('text');
  expect(result[0].is_nullable).toBe('NO');
});
```

**Pattern for UNIQUE constraint verification:**
```typescript
it('enforces per-user UNIQUE on categories name', async () => {
  // Insert for user A succeeds
  await sql`
    INSERT INTO categories (name, user_id) VALUES ('test-cat', 'user-a')
  `;
  // Duplicate name for user A fails
  await expect(sql`
    INSERT INTO categories (name, user_id) VALUES ('test-cat', 'user-a')
  `).rejects.toThrow();
  // Same name for user B succeeds
  await sql`
    INSERT INTO categories (name, user_id) VALUES ('test-cat', 'user-b')
  `;
});
```

**Pattern for composite index verification** (from `002_backend-edit-delete-triggers` approach):
```typescript
it('creates composite index for user_id-based queries', async () => {
  const result = await sql`
    SELECT indexname, indexdef
    FROM pg_indexes
    WHERE tablename = 'categories' AND indexdef LIKE '%user_id%'
  `;
  expect(result.length).toBeGreaterThan(0);
});
```

---

## Shared Patterns

### Migration File Header
**Source:** `src/infrastructure/db/migrations/007_setup_pgmq.sql`
**Apply to:** All 3 new migration files (008, 009, 010)

Pattern:
```sql
-- NNN_description: Short one-line purpose

-- Up Migration

... SQL ...

-- Down Migration

... reverse SQL ...;
```

### ALTER TABLE ADD COLUMN with FK to "user"
**Source:** `src/infrastructure/db/migrations/001_initial_schema.sql` lines 87, 94 (Better Auth tables)
**Apply to:** `008_add_user_id_columns.sql`

Pattern:
```sql
ALTER TABLE <table_name>
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;
```

### DROP/ADD CONSTRAINT
**Source:** Deduced from schema.sql table definitions (e.g., line 42: `UNIQUE (year, month)`)
**Apply to:** `009_update_uniques.sql`

Pattern:
```sql
ALTER TABLE <table> DROP CONSTRAINT <old_constraint_name>;
ALTER TABLE <table> ADD CONSTRAINT <new_constraint_name> UNIQUE(user_id, <column(s)>);
```

### CREATE INDEX IF NOT EXISTS
**Source:** `src/infrastructure/db/migrations/001_initial_schema.sql` lines 45-48
**Apply to:** `010_add_indexes.sql`

Pattern:
```sql
CREATE INDEX IF NOT EXISTS <index_name> ON <table>(<column(s)>);
```

### test File Structure (bun:test)
**Source:** `tests/import-dedup.test.ts` and `tests/ledger.test.ts`
**Apply to:** `tests/schema-migration.test.ts`

Pattern:
```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';

beforeAll(async () => {
  // Clean up test data or set up preconditions
});

describe('Schema Migration Tests', () => {
  it('...', async () => {
    // Test body using sql`...` tagged template queries
    // Assert using expect(...).toBe(...)
  });
});
```

### Database Client Pattern
**Source:** `src/infrastructure/db/client.ts` (lines 1-7)
**Apply to:** All files that query the database

```typescript
import postgres from 'postgres'

const sql = postgres(process.env.DATABASE_URL!, {
  max: 10,
  idle_timeout: 20,
})

export default sql
```

### Transactional Batch Insert (from import-worker)
**Source:** `src/workers/import-worker.ts` lines 296-327
**Apply to:** Schema migration tests that need transactional setup

```typescript
await sql.begin(async (sql) => {
  for (const tx of transactions) {
    await sql`INSERT INTO transactions (...) VALUES (...)`;
  }
});
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | All files have analogs in the existing codebase |

## Migration Numbering

| Applies To | File | Next Number |
|------------|------|-------------|
| `src/infrastructure/db/migrations/` | `008_add_user_id_columns.sql` | 008 (001 through 007 exist) |
| `src/infrastructure/db/migrations/` | `009_update_uniques.sql` | 009 |
| `src/infrastructure/db/migrations/` | `010_add_indexes.sql` | 010 |

**Note on gap:** Migration `002_setup_pgmq.sql` was renamed to `007_setup_pgmq.sql` (content still says `-- 002_setup_pgmq`). The gap is cosmetic — node-pg-migrate tracks by file name stem, not number. Continue from 008.

## Migration Runner Configuration
**Source:** `src/infrastructure/db/migrate.ts` (lines 1-29)

```typescript
import { runner } from 'node-pg-migrate';

// Usage: bun src/infrastructure/db/migrate.ts [up|down] [--fake]
await runner({
  databaseUrl: DATABASE_URL,
  dir: 'src/infrastructure/db/migrations',
  direction,
  migrationsTable: 'pgmigrations',
  migrationFileLanguage: 'sql',
  fake: isFake,
});
```

**Invocation:**
- `bun src/infrastructure/db/migrate.ts up` — apply all pending migrations
- `bun src/infrastructure/db/migrate.ts down` — revert last migration batch

## Metadata

**Analog search scope:** `src/infrastructure/db/migrations/`, `src/infrastructure/db/`, `src/workers/`, `tests/`
**Files scanned:** 20+ (6 existing migrations, 5 infrastructure files, 2 workers, 20+ test files, seed.sql, schema.sql)
**Pattern extraction date:** 2026-06-07
