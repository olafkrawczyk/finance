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

beforeAll(async () => {
  // Ensure all migrations are applied (safety — in case prior test left state dirty)
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
  // CRITICAL: Restore all migrations for other test files
  await runner({
    databaseUrl: process.env.DATABASE_URL!,
    dir: 'src/infrastructure/db/migrations',
    direction: 'up',
    migrationsTable: 'pgmigrations',
    migrationFileLanguage: 'sql',
    log: () => {},
  });

  // Clean up test user
  await sql`DELETE FROM "user" WHERE id = 'rollback-test-user'`;
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
