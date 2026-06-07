# Phase 6: Schema Migration & Backfill - Research

**Researched:** 2026-06-07
**Domain:** PostgreSQL schema migration — per-user `user_id` columns, constraint changes, index updates
**Confidence:** HIGH

## Summary

This phase adds `user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE` to all 6 domain tables (accounts, categories, transactions, monthly_opening_balances, assets, import_jobs). Since the DB will be wiped before onboarding new users (D-01), there is no backfill complexity — `user_id` is added as `NOT NULL` directly with no default value or data migration.

Three SQL migration files are needed, split by concern per D-03: (1) add columns, (2) drop global UNIQUE constraints → add per-user composite UNIQUE constraints, (3) add new indexes. The `node-pg-migrate` runner with `migrationFileLanguage: 'sql'` is already established — follow the existing `NNN_description.sql` convention with `-- Up Migration` / `-- Down Migration` markers.

**Primary recommendation:** Three consecutive SQL migrations (008, 009, 010) using `node-pg-migrate` with the established marker-based SQL pattern. The `schema.sql` reference file is updated last to reflect final state. The `computeImportHash` update (D-06) is a code change in `src/workers/import-worker.ts` that can be folded into this phase or deferred to Phase 8.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCHEMA-01 | Accounts: add `user_id` column | Verified: no backfill needed (D-01), `NOT NULL` directly, FK to `"user"(id)` |
| SCHEMA-02 | Categories: add `user_id` column | Same pattern as SCHEMA-01 |
| SCHEMA-03 | Transactions: add `user_id` column | Same pattern as SCHEMA-01 |
| SCHEMA-04 | Monthly opening balances: add `user_id` column | Same pattern as SCHEMA-01 |
| SCHEMA-05 | Assets: add `user_id` column | Same pattern as SCHEMA-01 |
| SCHEMA-06 | Import jobs: add `user_id` column | Same pattern as SCHEMA-01 |
| SCHEMA-07 | Existing data assignment | **Deferred** — DB wiped before onboarding (D-01), no action needed |
| SCHEMA-08 | Per-user unique names | Drop `UNIQUE(name)` on categories + assets, add `UNIQUE(user_id, name)` |
| SCHEMA-09 | Per-user unique import hashes | Drop `UNIQUE(import_hash)` on transactions, add `UNIQUE(user_id, import_hash)` |
| SCHEMA-10 | Per-user unique opening balance months | Drop `UNIQUE(year, month)` on monthly_opening_balances, add `UNIQUE(user_id, year, month)` |
| SCHEMA-11 | Composite indexes for per-user query patterns | Per D-04: only indexes needed are those created by UNIQUE constraints above + existing indexes left intact |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema column additions | Database | — | `ALTER TABLE ... ADD COLUMN` is a pure PostgreSQL DDL operation |
| Constraint changes | Database | — | `DROP CONSTRAINT` / `ADD CONSTRAINT` is pure DDL |
| Index management | Database | — | Index creation/drop is pure DDL |
| `schema.sql` synchronization | Application | Database | The declarative schema file is a source file in the application repo that must match migration final state |
| `computeImportHash` update | Application (worker) | — | Code change in `src/workers/import-worker.ts` — schema-adjacent but not DDL |
| Seed data adaptation | Application | Database | `seed.sql` referenced by `apply.ts` — may need `user_id` handling after Phase 7 seed strategy is finalized |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| PostgreSQL | 15+ (locally hosted) | Database | Existing project stack — all queries use `postgres.js` tagged templates |
| `node-pg-migrate` | 8.0.4 | Migration runner | Existing project stack — `migrate.ts` uses it with `migrationFileLanguage: 'sql'` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `postgres.js` (sql) | 3.4.9 | DB client | Existing project stack — tagged template `postgres` style |
| `pg` (Pool) | — | Better Auth connection | Only for `auth.ts` — not used in migration code |

**Version verification:**

```bash
# node-pg-migrate 8.0.4 — verified on npm registry
npm view node-pg-migrate@8.0.4 version
# postgres.js 3.4.9 — verified on npm registry
npm view postgres@3.4.9 version
```

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SQL-based node-pg-migrate (current) | TypeScript-based pgm API | Current setup is SQL-based with `migrationFileLanguage: 'sql'`. TypeScript would need different file pattern but produces equivalent SQL. Stick with established pattern. |

## Package Legitimacy Audit

> This phase does NOT install any new npm packages. All required libraries (`node-pg-migrate`, `postgres.js`, `pg`) are already project dependencies verified in v1.0. No slopcheck needed.

**No new packages — skipping audit.**

## Architecture Patterns

### Migration File Pattern (node-pg-migrate SQL)

Established convention from existing migrations (`001_initial_schema.sql`, `007_setup_pgmq.sql`):

```sql
-- NNN_description.sql

-- Up Migration
ALTER TABLE ...

-- Down Migration
ALTER TABLE ...;
```

**Key points:**
- `migrationFileLanguage: 'sql'` enables marker-based parsing — `-- Up Migration` / `-- Down Migration` markers split the file [CITED: node-pg-migrate docs — migration-loading-strategies.md]
- If no markers present, whole file is treated as up migration with no down migration
- Next available number is **008** (001 through 007 exist)
- Files live in `src/infrastructure/db/migrations/`

### D-03: Split by Concern into Three Migration Files

| # | File | Purpose | Down Migration |
|---|------|---------|----------------|
| 008 | `008_add_user_id_columns.sql` | `ALTER TABLE ... ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE` on all 6 tables | `ALTER TABLE ... DROP COLUMN user_id` on all 6 |
| 009 | `009_update_uniques.sql` | Drop old global UNIQUE constraints, add per-user composite UNIQUE constraints | Drop new per-user constraints, restore old global ones |
| 010 | `010_add_indexes.sql` | Add minimal composite indexes per D-04 (if any needed beyond constraint auto-created indexes) | `DROP INDEX IF EXISTS ...` for new indexes |

### Recommended Project Structure

```
src/infrastructure/db/
├── client.ts                  # postgres.js client (unchanged)
├── migrate.ts                 # node-pg-migrate runner (unchanged)
├── apply.ts                   # schema.sql/seed.sql applier (unchanged)
├── schema.sql                 # UPDATE to reflect final state after all migrations
├── seed.sql                   # May need update depending on Phase 7 seed strategy
└── migrations/
    ├── 001_initial_schema.sql
    ├── 003_allow_category_update.sql
    ├── 004_insights_table.sql
    ├── 005_rename_arval_to_auto.sql
    ├── 006_create_assets_table.sql
    ├── 007_setup_pgmq.sql
    ├── 008_add_user_id_columns.sql    # NEW
    ├── 009_update_uniques.sql         # NEW
    └── 010_add_indexes.sql            # NEW
```

### Pattern 1: ALTER TABLE ADD COLUMN with FK

**What:** Add `user_id` as a NOT NULL column with foreign key reference.

**When to use:** For each of the 6 domain tables.

**Example:**
```sql
-- Up Migration
ALTER TABLE accounts
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE categories
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

-- ...etc for all 6 tables
```

**Why `TEXT` not `UUID`:** The `"user"(id)` column is `TEXT` (Better Auth convention), so the FK reference must match. [VERIFIED: src/infrastructure/db/schema.sql line 72]

### Pattern 2: Drop & Recreate UNIQUE Constraints

**What:** Drop global UNIQUE constraints, add per-user composite UNIQUE constraints.

**When to use:** For categories (name), assets (name), transactions (import_hash), monthly_opening_balances (year, month).

**Example:**
```sql
-- Up Migration
ALTER TABLE categories DROP CONSTRAINT categories_name_key;
ALTER TABLE categories ADD CONSTRAINT categories_user_id_name_key UNIQUE(user_id, name);

ALTER TABLE assets DROP CONSTRAINT assets_name_key;
ALTER TABLE assets ADD CONSTRAINT assets_user_id_name_key UNIQUE(user_id, name);

ALTER TABLE transactions DROP CONSTRAINT transactions_import_hash_key;
ALTER TABLE transactions ADD CONSTRAINT transactions_user_id_import_hash_key UNIQUE(user_id, import_hash);

ALTER TABLE monthly_opening_balances DROP CONSTRAINT monthly_opening_balances_year_month_key;
ALTER TABLE monthly_opening_balances ADD CONSTRAINT monthly_opening_balances_user_id_year_month_key UNIQUE(user_id, year, month);

-- Down Migration
ALTER TABLE monthly_opening_balances DROP CONSTRAINT monthly_opening_balances_user_id_year_month_key;
ALTER TABLE monthly_opening_balances ADD CONSTRAINT monthly_opening_balances_year_month_key UNIQUE(year, month);

-- ...etc
```

**Constraint name discovery:** PostgreSQL auto-generates constraint names as `{table}_{column(s)}_key`. [VERIFIED: PostgreSQL documentation — auto-generated constraint naming]

### Anti-Patterns to Avoid

- **Adding column as nullable then backfilling:** D-01 says DB is wiped — add `NOT NULL` directly. Adding nullable and then doing `UPDATE ... SET user_id = ...` is unnecessary complexity.
- **Mixing concerns in one migration file:** D-03 says split by concern (add columns, constraints, indexes). This makes migrations easier to review and down-migrations cleaner.
- **Forgetting to update `schema.sql`:** The declarative schema file must match post-migration state. If `schema.sql` is used for fresh DB setup (via `apply.ts`), it must include all column additions, constraint changes, and index changes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Migration runner | Custom SQL versioning script | `node-pg-migrate` | Already in project, tracks applied migrations in `pgmigrations` table, supports up/down, handles ordering |
| DB client connection | Raw pg driver | `postgres.js` | Already in project, provides tagged template literals with parameterized queries |
| Immutable triggers | Custom PL/pgSQL from scratch | Existing `block_immutable_change()` function | Already exists in schema.sql, used by transactions and insights tables |

## Runtime State Inventory

> Not applicable — this is a greenfield schema change with no existing production data (DB will be wiped). See D-01.

**Nothing found:** All 5 categories verified as not requiring state migration:
- **Stored data:** DB will be wiped before onboarding — no data to migrate
- **Live service config:** No external services store schema definitions
- **OS-registered state:** No OS registrations affected by schema changes
- **Secrets/env vars:** No secrets affected by schema changes
- **Build artifacts:** No build artifacts affected by schema changes

## Common Pitfalls

### Pitfall 1: Constraint Name Mismatch
**What goes wrong:** `ALTER TABLE categories DROP CONSTRAINT categories_name_key` fails because PostgreSQL auto-generated a different constraint name.
**Why it happens:** PostgreSQL names inline UNIQUE constraints as `{table}_{column}_key` (e.g., `categories_name_key`), but table-level `UNIQUE (col1, col2)` gets a name like `{table}_col1_col2_key`. If the table was created with explicit `CONSTRAINT name ... UNIQUE(...)`, the name matches exactly.
**How to avoid:** Verify constraint names by querying `SELECT conname FROM pg_constraint WHERE conrelid = 'table_name'::regclass`. Use `ALTER TABLE ... DROP CONSTRAINT IF EXISTS` for safety.
**Warning signs:** Migration fails with `constraint "xxx" of relation "yyy" does not exist`.

### Pitfall 2: FK Type Mismatch
**What goes wrong:** Adding `user_id UUID REFERENCES "user"(id)` fails because `user.id` is `TEXT`.
**Why it happens:** The Better Auth `"user"` table uses `TEXT` for `id`, not `UUID`.
**How to avoid:** The `user_id` column must be `TEXT` to match the referenced column type. [VERIFIED: src/infrastructure/db/schema.sql lines 72-78]
**Warning signs:** `ERROR: foreign key constraint ... cannot be implemented`.

### Pitfall 3: UNIQUE Constraint on Nullable Columns
**What goes wrong:** The `UNIQUE(import_hash)` constraint allows multiple NULLs (standard SQL behavior), but `UNIQUE(user_id, import_hash)` changes the behavior for NULL handling.
**Why it happens:** PostgreSQL treats NULLs as distinct in UNIQUE constraints (per SQL standard). Multiple rows with `user_id = 'abc'` and `import_hash = NULL` will be allowed. This is actually the desired behavior — manual entries have no hash.
**How to avoid:** Confirm the behavior is correct by testing. The existing pattern `import_hash TEXT UNIQUE` already handles NULLs this way.
**Warning signs:** Unexpected `ON CONFLICT` behavior when import_hash is NULL.

### Pitfall 4: schema.sql Drift
**What goes wrong:** After running 3 migrations, `schema.sql` still has old declarations. Fresh DB setup via `apply.ts` creates tables without `user_id`.
**Why it happens:** `schema.sql` is the declarative reference — it's used for fresh DB setup but also serves as documentation. It's easy to forget to update it after migrations.
**How to avoid:** Update `schema.sql` as the LAST step of this phase, after all 3 migrations are committed. Verify it matches the post-migration state.
**Warning signs:** `apply.ts` creates tables that don't match migration state.

### Pitfall 5: node-pg-migrate SQL Marker Format
**What goes wrong:** `-- Up Migration` / `-- Down Migration` markers are case-sensitive and must match exactly. Misspelling or wrong case causes the file to be treated as up-only.
**Why it happens:** node-pg-migrate searches for the exact string `-- Up Migration` to split the file [CITED: node-pg-migrate docs].
**How to avoid:** Use exact marker text. Follow the pattern from `001_initial_schema.sql` and `007_setup_pgmq.sql`.
**Warning signs:** Down migration silently not applied — migration still reports success.

## Code Examples

### Example 1: Full Migration File (008_add_user_id_columns.sql)

```sql
-- 008_add_user_id_columns: Add user_id FK to all domain tables

-- Up Migration

ALTER TABLE accounts
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE categories
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE transactions
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE monthly_opening_balances
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE assets
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE import_jobs
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

-- Down Migration

ALTER TABLE accounts DROP COLUMN user_id;
ALTER TABLE categories DROP COLUMN user_id;
ALTER TABLE transactions DROP COLUMN user_id;
ALTER TABLE monthly_opening_balances DROP COLUMN user_id;
ALTER TABLE assets DROP COLUMN user_id;
ALTER TABLE import_jobs DROP COLUMN user_id;
```

### Example 2: Full Migration File (009_update_uniques.sql)

```sql
-- 009_update_uniques: Drop global UNIQUE → Add per-user composite UNIQUE

-- Up Migration

-- Categories: name uniqueness scoped to user
ALTER TABLE categories DROP CONSTRAINT categories_name_key;
ALTER TABLE categories ADD CONSTRAINT categories_user_id_name_key UNIQUE(user_id, name);

-- Assets: name uniqueness scoped to user
ALTER TABLE assets DROP CONSTRAINT assets_name_key;
ALTER TABLE assets ADD CONSTRAINT assets_user_id_name_key UNIQUE(user_id, name);

-- Transactions: import_hash uniqueness scoped to user
ALTER TABLE transactions DROP CONSTRAINT transactions_import_hash_key;
ALTER TABLE transactions ADD CONSTRAINT transactions_user_id_import_hash_key UNIQUE(user_id, import_hash);

-- Monthly opening balances: (year, month) uniqueness scoped to user
ALTER TABLE monthly_opening_balances DROP CONSTRAINT monthly_opening_balances_year_month_key;
ALTER TABLE monthly_opening_balances ADD CONSTRAINT monthly_opening_balances_user_id_year_month_key UNIQUE(user_id, year, month);

-- Down Migration

ALTER TABLE monthly_opening_balances DROP CONSTRAINT monthly_opening_balances_user_id_year_month_key;
ALTER TABLE monthly_opening_balances ADD CONSTRAINT monthly_opening_balances_year_month_key UNIQUE(year, month);

ALTER TABLE transactions DROP CONSTRAINT transactions_user_id_import_hash_key;
ALTER TABLE transactions ADD CONSTRAINT transactions_import_hash_key UNIQUE(import_hash);

ALTER TABLE assets DROP CONSTRAINT assets_user_id_name_key;
ALTER TABLE assets ADD CONSTRAINT assets_name_key UNIQUE(name);

ALTER TABLE categories DROP CONSTRAINT categories_user_id_name_key;
ALTER TABLE categories ADD CONSTRAINT categories_name_key UNIQUE(name);
```

### Example 3: Full Migration File (010_add_indexes.sql)

```sql
-- 010_add_indexes: Add minimal composite indexes for per-user query patterns

-- Up Migration

-- Note: UNIQUE constraints in 009 already create btree indexes on:
--   categories(user_id, name)
--   assets(user_id, name)
--   transactions(user_id, import_hash)
--   monthly_opening_balances(user_id, year, month)
-- No additional composite indexes needed per D-04.

-- However, consider dropping the now-redundant idx_mob_year_month index
-- since the new UNIQUE(user_id, year, month) creates a covering index.
-- This is discretionary — only drop if the old index is confirmed redundant.

-- Down Migration

-- Nothing to drop if no indexes were added above.
```

### Example 4: schema.sql Update Pattern

The final `schema.sql` for each affected table should change from:

```sql
-- Categories (before)
name TEXT NOT NULL UNIQUE,

-- Categories (after)
name TEXT NOT NULL,
user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
-- Plus at table level (or inline):
-- UNIQUE(user_id, name) -- handled by constraint below
-- But actually PostgreSQL doesn't allow per-column inline UNIQUE with two columns,
-- so add table-level constraint:
-- CREATE TABLE IF NOT EXISTS categories (
--   ...
--   UNIQUE(user_id, name)
-- );
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Global UNIQUE(name) on categories and assets | Per-user UNIQUE(user_id, name) | Phase 6 | Multiple users can have same-named categories/assets |
| Global UNIQUE(import_hash) on transactions | Per-user UNIQUE(user_id, import_hash) | Phase 6 | Import dedup scoped per user — prevents cross-user hash collisions |
| Global UNIQUE(year, month) on monthly_opening_balances | Per-user UNIQUE(user_id, year, month) | Phase 6 | Each user has their own opening balance months |
| No user_id on domain tables | user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE | Phase 6 | Row-level user ownership for all 6 domain tables |
| Backfill-needed assumption (original SCHEMA-07) | DB wiped — no backfill (D-01) | Phase 6 discuss | Simplifies migration: no NULL→value UPDATE needed, NULL→NOT NULL transition is a no-op |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Postgres generates constraint names as `{table}_{column}_key` | Architecture Patterns | ALTER TABLE DROP CONSTRAINT could fail if auto-generated name differs. Mitigation: use `SELECT conname FROM pg_constraint` first, or use `IF EXISTS` |
| A2 | PG 15+ installed locally | Environment | Minor version differences in DDL support — unlikely for basic ALTER TABLE operations |
| A3 | No existing production data to preserve | Summary | If DB is NOT wiped (D-01 reversed), the `NOT NULL` constraint without a default will block ALTER TABLE. Mitigation: this is a locked decision (D-01) |

**Note on D-06 (computeImportHash update):** The CONTEXT.md marks this as "researcher/planner flexibility" — it's a code change to `src/workers/import-worker.ts`, not a schema migration. The planner can fold it into this phase or defer to Phase 8 (Worker Isolation). This research assumes it's deferred to Phase 8 for focus.

## Open Questions

1. **Should the existing `idx_mob_year_month` index on `monthly_opening_balances` be dropped?**
   - What we know: The new UNIQUE(user_id, year, month) constraint implicitly creates a btree index on these columns. The old `idx_mob_year_month(year, month)` index becomes partially redundant — but since user_id is the leading column in the new index, queries that filter only by year/month won't benefit from it.
   - What's unclear: Whether Phase 7 query scoping will always include user_id in opening balance queries. If yes, the old index is indeed redundant.
   - Recommendation: Drop the old index in migration 010 only if Phase 7 confirms all queries are user_id-scoped. Otherwise, keep both.

2. **Does `seed.sql` need an update?**
   - What we know: Seed categories and accounts currently insert with no user_id. After the migration, these INSERTs will fail because user_id is NOT NULL.
   - What's unclear: The seed strategy for Phase 7 (SEED-01, SEED-02, SEED-03) specifies lazy seeding on first `GET /categories` — which may replace the current seed.sql approach entirely.
   - Recommendation: Defer seed.sql changes to Phase 7, but note in the plan that `apply.ts` will fail if run before Phase 7 implements the new seed strategy.

3. **Migration number gap — 002 is missing**
   - What we know: Migrations are numbered 001, 003, 004, 005, 006, 007. File `002_setup_pgmq.sql` seems to have been renamed to `007_setup_pgmq.sql` at some point (the content says `-- 002_setup_pgmq`).
   - What's unclear: Whether this causes any issues with node-pg-migrate's tracking table.
   - Recommendation: Node-pg-migrate tracks by file name stem, not number. The gap is cosmetic. Next file should be `008_` to continue the visual sequence.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Running migrations | ✓ | 22.22.2 | — |
| Bun | Running migrations via `bun src/infrastructure/db/migrate.ts` | ✓ | 1.3.14 | — |
| PostgreSQL | Database for migrations | Not verified in this session | — | Must be running locally with `DATABASE_URL` env var set |
| `psql` | Manual verification | ✗ | — | Use `bun src/infrastructure/db/migrate.ts` or direct SQL queries from application code |

**Missing dependencies with no fallback:**
- PostgreSQL — the migration runner requires a running PostgreSQL instance. The planner must ensure DB is accessible.

**Note:** The environment check was done during research-only mode. PostgreSQL may be running outside this session. The `db:migrate` command (`bun src/infrastructure/db/migrate.ts`) works with `DATABASE_URL` environment variable.

## Validation Architecture

> workflow.nyquist_validation key is absent from config.json — treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `bun:test` (built-in Bun test runner) |
| Config file | none — Bun uses convention (`tests/*.test.ts`) |
| Quick run command | `bun test --filter "dedup" tests/import-dedup.test.ts` |
| Full suite command | `bun test` |

Current tests are in `tests/` directory using `describe/it/expect` from `bun:test`. The import-dedup test (`tests/import-dedup.test.ts`) is directly relevant — it tests `ON CONFLICT (import_hash)` behavior which will break when the constraint changes to `UNIQUE(user_id, import_hash)`.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCHEMA-01–06 | Columns exist with correct type and FK | integration | `bun test --filter "schema"` | ❌ Wave 0 |
| SCHEMA-08–10 | Per-user UNIQUE constraints enforced | integration | `bun test --filter "unique"` | ❌ Wave 0 |
| SCHEMA-11 | Composite indexes exist | integration | `bun test --filter "index"` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bun test --filter "dedup|schema"`
- **Per wave merge:** `bun test`
- **Phase gate:** `bun test` green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `tests/schema-migration.test.ts` — covers SCHEMA-01 through SCHEMA-11
- [ ] `tests/conftest.ts` or a `beforeAll` setup — may need to establish DB state for testing

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 6 is schema-only — auth already handled by Better Auth in Phase 2 |
| V3 Session Management | No | Schema layer — no session handling |
| V4 Access Control | Partial | `user_id` FK with `ON DELETE CASCADE` enforces referential integrity. Row-level access scoping is Phase 7. |
| V5 Input Validation | No | Schema-only — input validation is application layer (Zod) |
| V6 Cryptography | No | No cryptographic operations in schema migrations |

### Known Threat Patterns for PostgreSQL DDL

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| FK constraint bypassing via direct DB access | Tampering | `ON DELETE CASCADE` ensures user deletion cascades to domain rows. Application-layer scoping (Phase 7) is the actual access control — schema constraints enforce referential integrity, not authorization. |
| Constraint naming collision | — | Use `DROP CONSTRAINT IF EXISTS` for safety. Verify existing constraint names via `pg_constraint` catalog query before hardcoding. |

## Sources

### Primary (HIGH confidence)
- [VERIFIED] `src/infrastructure/db/migrate.ts` — node-pg-migrate runner configuration
- [VERIFIED] `src/infrastructure/db/schema.sql` — Current declarative schema with table definitions
- [VERIFIED] `src/infrastructure/db/migrations/001_initial_schema.sql` through `007_setup_pgmq.sql` — Existing migration patterns
- [VERIFIED] `src/workers/import-worker.ts` — `computeImportHash` function (line 92-96)
- [CITED: npm registry] node-pg-migrate@8.0.4 — confirmed package version

### Secondary (MEDIUM confidence)
- [CITED: salsita/node-pg-migrate docs] — SQL migration file format with `-- Up Migration` / `-- Down Migration` markers
- [CITED: PostgreSQL docs] — `ALTER TABLE ... ADD COLUMN`, `DROP CONSTRAINT`, `ADD CONSTRAINT` syntax
- [CITED: PostgreSQL docs] — Auto-generated constraint naming convention

### Tertiary (LOW confidence)
- None — all claims are based on verified file reads or cited docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `node-pg-migrate` + `postgres.js` are verified in codebase
- Architecture: HIGH — 3-migration split pattern is locked decision (D-03), migration file format verified from existing files
- Pitfalls: HIGH — constraint naming, FK type matching, schema.sql drift are documented PostgreSQL/ORM issues

**Research date:** 2026-06-07
**Valid until:** 2026-07-07 (stable stack — no fast-moving dependencies in this phase)
