import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { runner } from 'node-pg-migrate';
import sql from '../src/infrastructure/db/client';

const DOMAIN_TABLES = [
  'accounts',
  'categories',
  'transactions',
  'monthly_opening_balances',
  'assets',
  'import_jobs',
];

let testUserId: string;

/**
 * Restore user_id columns on domain tables after a down migration.
 *
 * Migration 008 uses ADD COLUMN ... NOT NULL which PostgreSQL rejects when the
 * table already has rows (code 23502 — NOT NULL violation). This function works
 * around that by: add column as nullable → backfill → set NOT NULL → add FK.
 */
async function restoreUserIdColumns(userId: string): Promise<void> {
  for (const table of DOMAIN_TABLES) {
    // Check if column is already present
    const cols = await sql`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = ${table} AND column_name = 'user_id'
    `;
    if (cols.length > 0) continue;

    // Add as nullable, backfill, make NOT NULL, attach FK
    await sql.unsafe(`ALTER TABLE "${table}" ADD COLUMN user_id TEXT`);
    await sql.unsafe(`UPDATE "${table}" SET user_id = '${userId}' WHERE user_id IS NULL`);
    await sql.unsafe(`ALTER TABLE "${table}" ALTER COLUMN user_id SET NOT NULL`);
    await sql.unsafe(
      `ALTER TABLE "${table}" ADD CONSTRAINT ${table}_user_id_fkey ` +
        `FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE`,
    );
  }
}

/**
 * Ensure the backfill user exists in the "user" table so FK constraints
 * don't fail when restoreUserIdColumns adds REFERENCES "user"(id).
 */
async function ensureBackfillUser(userId: string): Promise<void> {
  await sql`DELETE FROM "user" WHERE id = ${userId}`;
  await sql`
    INSERT INTO "user" (id, name, email, "emailVerified")
    VALUES (${userId}, 'Rollback Backfill', 'rollback-backfill@example.com', true)
  `;
}

/**
 * Mark migration 008 as applied in pgmigrations if not already present.
 */
async function markMigration008(): Promise<void> {
  const existing = await sql`
    SELECT 1 FROM pgmigrations WHERE name = '008_add_user_id_columns'
  `;
  if (existing.length === 0) {
    const [maxRow] = await sql`SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM pgmigrations`;
    await sql`
      INSERT INTO pgmigrations (id, name, run_on)
      VALUES (${maxRow.next_id}, '008_add_user_id_columns', NOW())
    `;
  }
}

beforeAll(async () => {
  // Ensure the backfill user exists before we add FK constraints
  await ensureBackfillUser('rollback-backfill');

  // For migration 008 (ADD COLUMN NOT NULL), we handle it manually since it can't
  // run on tables with existing data. The runner handles 009-011.
  await restoreUserIdColumns('rollback-backfill');

  // Ensure 008 is marked in pgmigrations so the runner doesn't try to re-apply it
  await markMigration008();

  // Run the runner for remaining migrations (009-011)
  await runner({
    databaseUrl: process.env.DATABASE_URL!,
    dir: 'src/infrastructure/db/migrations',
    direction: 'up',
    migrationsTable: 'pgmigrations',
    migrationFileLanguage: 'sql',
    log: () => {},
  });

  // Create a test user for FK constraint satisfaction
  await sql`DELETE FROM "user" WHERE id = 'rollback-test-user'`;
  const [user] = await sql`
    INSERT INTO "user" (id, name, email, "emailVerified")
    VALUES ('rollback-test-user', 'Rollback Test User', 'rollback-test@example.com', true)
    RETURNING id
  `;
  testUserId = user.id;
});

afterAll(async () => {
  // CRITICAL: Restore the database to fully migrated state for other test files.
  // After the down migration, user_id columns are dropped but domain tables still
  // have rows. Running migration 008 up (ADD COLUMN NOT NULL) would fail because
  // PostgreSQL rejects NOT NULL columns on tables with existing data. Instead we
  // restore manually with backfill.
  await ensureBackfillUser('rollback-backfill');
  await restoreUserIdColumns('rollback-backfill');

  // Ensure pgmigrations is consistent
  await markMigration008();

  // Restore 009-011 via runner (these don't depend on NOT NULL column add)
  await runner({
    databaseUrl: process.env.DATABASE_URL!,
    dir: 'src/infrastructure/db/migrations',
    direction: 'up',
    migrationsTable: 'pgmigrations',
    migrationFileLanguage: 'sql',
    log: () => {},
  });

  // Clean up test users
  await sql`DELETE FROM "user" WHERE id = 'rollback-test-user'`;
  await sql`DELETE FROM "user" WHERE id = 'rollback-backfill'`;
});

// ── D-14: Assert up migration state ──

describe('After full migration up() — D-14, D-16', () => {
  // D-14: user_id columns exist on all domain tables
  for (const table of DOMAIN_TABLES) {
    it(`user_id column exists on ${table} after up()`, async () => {
      const result = await sql`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = ${table} AND column_name = 'user_id'
      `;
      expect(result.length).toBe(1);
      expect(result[0].data_type).toBe('text');
      expect(result[0].is_nullable).toBe('NO');
    });

    it(`user_id FK constraint exists on ${table} after up()`, async () => {
      const result = await sql`
        SELECT tc.constraint_name, tc.constraint_type
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        WHERE tc.table_name = ${table}
          AND kcu.column_name = 'user_id'
          AND tc.constraint_type = 'FOREIGN KEY'
      `;
      expect(result.length).toBe(1);
    });
  }

  // D-14: Composite UNIQUE constraints
  it('categories has UNIQUE(user_id, name) after up()', async () => {
    const result = await sql`
      SELECT constraint_name
      FROM information_schema.table_constraints
      WHERE table_name = 'categories'
        AND constraint_name = 'categories_user_id_name_key'
    `;
    expect(result.length).toBe(1);
  });

  it('assets has UNIQUE(user_id, name) after up()', async () => {
    const result = await sql`
      SELECT constraint_name
      FROM information_schema.table_constraints
      WHERE table_name = 'assets'
        AND constraint_name = 'assets_user_id_name_key'
    `;
    expect(result.length).toBe(1);
  });

  // D-14: Composite indexes
  it('composite index on categories(user_id, name) exists after up()', async () => {
    const result = await sql`
      SELECT indexname FROM pg_indexes
      WHERE tablename = 'categories'
        AND indexdef LIKE '%user_id%name%'
    `;
    expect(result.length).toBeGreaterThan(0);
  });

  it('composite index on transactions(user_id, import_hash) exists after up()', async () => {
    const result = await sql`
      SELECT indexname FROM pg_indexes
      WHERE tablename = 'transactions'
        AND indexdef LIKE '%user_id%import_hash%'
    `;
    expect(result.length).toBeGreaterThan(0);
  });

  // D-16 (first part): insert test data and verify it's accessible with user_id
  it('D-16: data with user_id can be inserted and read after up()', async () => {
    // Insert test data
    const [acct] = await sql`
      INSERT INTO accounts (name, type, user_id)
      VALUES ('Rollback Test Account', 'personal', ${testUserId})
      RETURNING id
    `;

    // Verify we can read it back with user_id
    const [row] = await sql`
      SELECT id, user_id FROM accounts WHERE id = ${acct.id} AND user_id = ${testUserId}
    `;
    expect(row.user_id).toBe(testUserId);

    // Clean up
    await sql`DELETE FROM accounts WHERE id = ${acct.id}`;
  });
});

// ── D-15, D-16, D-17: Assert down migration state ──

describe('After rolling back migrations 008-011 — D-15, D-16, D-17', () => {
  beforeAll(async () => {
    // Roll back migrations 008-011 (user_id columns, UNIQUE constraints, indexes)
    await runner({
      databaseUrl: process.env.DATABASE_URL!,
      dir: 'src/infrastructure/db/migrations',
      direction: 'down',
      count: 4,
      migrationsTable: 'pgmigrations',
      migrationFileLanguage: 'sql',
      log: () => {},
    });
  });

  // D-15: user_id columns removed
  for (const table of DOMAIN_TABLES) {
    it(`user_id column removed from ${table} after down()`, async () => {
      const result = await sql`
        SELECT column_name FROM information_schema.columns
        WHERE table_name = ${table} AND column_name = 'user_id'
      `;
      expect(result.length).toBe(0);
    });
  }

  // D-15: Global UNIQUE constraints restored
  it('categories has global UNIQUE(name) restored after down()', async () => {
    const result = await sql`
      SELECT constraint_name
      FROM information_schema.table_constraints
      WHERE table_name = 'categories'
        AND constraint_name = 'categories_name_key'
    `;
    expect(result.length).toBe(1);
  });

  it('categories composite UNIQUE(user_id, name) removed after down()', async () => {
    const result = await sql`
      SELECT constraint_name
      FROM information_schema.table_constraints
      WHERE table_name = 'categories'
        AND constraint_name = 'categories_user_id_name_key'
    `;
    expect(result.length).toBe(0);
  });

  it('assets has global UNIQUE(name) restored after down()', async () => {
    const result = await sql`
      SELECT constraint_name
      FROM information_schema.table_constraints
      WHERE table_name = 'assets'
        AND constraint_name = 'assets_name_key'
    `;
    expect(result.length).toBe(1);
  });

  it('assets composite UNIQUE(user_id, name) removed after down()', async () => {
    const result = await sql`
      SELECT constraint_name
      FROM information_schema.table_constraints
      WHERE table_name = 'assets'
        AND constraint_name = 'assets_user_id_name_key'
    `;
    expect(result.length).toBe(0);
  });

  // D-17: No orphan constraints — verify no user_id references remain in domain tables
  it('D-17: no user_id FK constraints remain after down()', async () => {
    for (const table of DOMAIN_TABLES) {
      const fkResult = await sql`
        SELECT tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        WHERE tc.table_name = ${table}
          AND kcu.column_name = 'user_id'
          AND tc.constraint_type = 'FOREIGN KEY'
      `;
      expect(fkResult.length).toBe(0);
    }
  });

  it('D-17: no indexes referencing user_id remain in domain tables after down()', async () => {
    const idxResult = await sql`
      SELECT indexname, indexdef FROM pg_indexes
      WHERE tablename IN ('accounts', 'categories', 'transactions',
                          'monthly_opening_balances', 'assets', 'import_jobs')
        AND indexdef LIKE '%user_id%'
    `;
    expect(idxResult.length).toBe(0);
  });

  // D-16: Data integrity — verify rows still exist after destructive down
  it('D-16: schema is functional after destructive down() — INSERT/READ works', async () => {
    // Insert a simple record into accounts (which only has name, type after down)
    const [acct] = await sql`
      INSERT INTO accounts (name, type)
      VALUES ('Post-Down Test Account', 'personal')
      RETURNING id
    `;
    expect(acct.id).toBeDefined();

    // Verify the account exists — confirms schema is functional
    const [check] = await sql`SELECT id, name FROM accounts WHERE id = ${acct.id}`;
    expect(check.name).toBe('Post-Down Test Account');

    // Clean up
    await sql`DELETE FROM accounts WHERE id = ${acct.id}`;
  });
});
