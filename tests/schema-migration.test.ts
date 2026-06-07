import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';

const TEST_USER = 'test-user-schema';
const TEST_USER_2 = 'test-user-schema-2';
let testUserId: string;

let accountId: string;
let altAccountId: string;

beforeAll(async () => {
  // Clean up from previous runs
  await sql`DELETE FROM "user" WHERE id IN (${TEST_USER}, ${TEST_USER_2})`;

  // Create test users for FK constraint satisfaction
  await sql`
    INSERT INTO "user" (id, name, email, "emailVerified")
    VALUES (${TEST_USER}, 'Schema Test User', 'schema-test@example.com', true)
  `;
  await sql`
    INSERT INTO "user" (id, name, email, "emailVerified")
    VALUES (${TEST_USER_2}, 'Schema Test User 2', 'schema-test-2@example.com', true)
  `;

  testUserId = TEST_USER;

  // Fetch or create a test account for the first user
  const accounts = await sql`SELECT id FROM accounts LIMIT 1`;
  if (accounts.length > 0) {
    accountId = accounts[0].id;
  } else {
    const result = await sql`
      INSERT INTO accounts (name, type, user_id)
      VALUES ('Test Account', 'personal', ${TEST_USER})
      RETURNING id
    `;
    accountId = result[0].id;
  }

  // Also get/create account for cross-user tests
  const altAccounts = await sql`
    SELECT id FROM accounts
    WHERE user_id = ${TEST_USER_2}
    LIMIT 1
  `;
  if (altAccounts.length > 0) {
    altAccountId = altAccounts[0].id;
  } else {
    altAccountId = accountId;
  }
});

afterAll(async () => {
  // Clean up test data
  await sql`DELETE FROM "user" WHERE id IN (${TEST_USER}, ${TEST_USER_2})`;
});

describe('Schema Migration — SCHEMA-01 through SCHEMA-11', () => {

  // ── Column Existence ──────────────────────────────────────────────────

  describe('Column Existence — SCHEMA-01 through SCHEMA-06', () => {
    const tables = [
      'accounts',
      'categories',
      'transactions',
      'monthly_opening_balances',
      'assets',
      'import_jobs',
    ];

    for (const table of tables) {
      it(`adds user_id column to ${table} table`, async () => {
        const result = await sql`
          SELECT column_name, data_type, is_nullable
          FROM information_schema.columns
          WHERE table_name = ${table} AND column_name = 'user_id'
        `;
        expect(result.length).toBe(1);
        expect(result[0].data_type).toBe('text');
        expect(result[0].is_nullable).toBe('NO');
      });

      it(`adds user_id FK constraint on ${table} table`, async () => {
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
  });

  // ── Per-User UNIQUE Constraints (SCHEMA-08, SCHEMA-09, SCHEMA-10) ────

  describe('Per-User UNIQUE Constraints — SCHEMA-08, SCHEMA-09, SCHEMA-10', () => {
    afterAll(async () => {
      await sql`DELETE FROM categories WHERE name LIKE 'test-cat-%'`;
      await sql`DELETE FROM assets WHERE name LIKE 'test-asset-%'`;
      await sql`TRUNCATE transactions CASCADE`;
      await sql`DELETE FROM monthly_opening_balances WHERE year = 2099`;
    });

    describe('SCHEMA-08: categories — UNIQUE(user_id, name)', () => {
      it('allows inserting unique names for the same user', async () => {
        await sql`
          INSERT INTO categories (name, user_id)
          VALUES ('test-cat-unique-a', ${TEST_USER})
        `;
        await sql`
          INSERT INTO categories (name, user_id)
          VALUES ('test-cat-unique-b', ${TEST_USER})
        `;
      });

      it('prevents duplicate name within the same user', async () => {
        let threw = false;
        try {
          await sql`
            INSERT INTO categories (name, user_id)
            VALUES ('test-cat-unique-a', ${TEST_USER})
          `;
        } catch (err) {
          threw = true;
        }
        expect(threw).toBe(true);
      });

      it('allows the same name for a different user', async () => {
        await sql`
          INSERT INTO categories (name, user_id)
          VALUES ('test-cat-unique-a', ${TEST_USER_2})
        `;
      });
    });

    describe('SCHEMA-08: assets — UNIQUE(user_id, name)', () => {
      it('allows inserting unique asset names for the same user', async () => {
        await sql`
          INSERT INTO assets (name, user_id, value)
          VALUES ('test-asset-unique-a', ${TEST_USER}, 1000)
        `;
        await sql`
          INSERT INTO assets (name, user_id, value)
          VALUES ('test-asset-unique-b', ${TEST_USER}, 2000)
        `;
      });

      it('prevents duplicate asset name within the same user', async () => {
        let threw = false;
        try {
          await sql`
            INSERT INTO assets (name, user_id, value)
            VALUES ('test-asset-unique-a', ${TEST_USER}, 3000)
          `;
        } catch (err) {
          threw = true;
        }
        expect(threw).toBe(true);
      });

      it('allows the same asset name for a different user', async () => {
        await sql`
          INSERT INTO assets (name, user_id, value)
          VALUES ('test-asset-unique-a', ${TEST_USER_2}, 1500)
        `;
      });
    });

    describe('SCHEMA-09: transactions — UNIQUE(user_id, import_hash)', () => {
      it('allows unique import hashes for the same user', async () => {
        await sql`
          INSERT INTO transactions (account_id, user_id, type, amount, description, date, import_hash)
          VALUES (${accountId}, ${TEST_USER}, 'expense', 100, 'test-hash-alpha', '2026-01-01', 'hash-alpha')
        `;
        await sql`
          INSERT INTO transactions (account_id, user_id, type, amount, description, date, import_hash)
          VALUES (${accountId}, ${TEST_USER}, 'expense', 200, 'test-hash-beta', '2026-01-02', 'hash-beta')
        `;
      });

      it('prevents duplicate import_hash within the same user', async () => {
        let threw = false;
        try {
          await sql`
            INSERT INTO transactions (account_id, user_id, type, amount, description, date, import_hash)
            VALUES (${accountId}, ${TEST_USER}, 'expense', 300, 'test-hash-alpha-retry', '2026-01-03', 'hash-alpha')
          `;
        } catch (err) {
          threw = true;
        }
        expect(threw).toBe(true);
      });

      it('allows the same import_hash for a different user', async () => {
        await sql`
          INSERT INTO transactions (account_id, user_id, type, amount, description, date, import_hash)
          VALUES (${altAccountId}, ${TEST_USER_2}, 'expense', 400, 'test-hash-alpha-other-user', '2026-01-04', 'hash-alpha')
        `;
      });
    });

    describe('SCHEMA-10: monthly_opening_balances — UNIQUE(user_id, year, month)', () => {
      it('allows unique (year, month) entries for the same user', async () => {
        await sql`
          INSERT INTO monthly_opening_balances (user_id, year, month, opening_balance)
          VALUES (${TEST_USER}, 2099, 1, 10000)
        `;
        await sql`
          INSERT INTO monthly_opening_balances (user_id, year, month, opening_balance)
          VALUES (${TEST_USER}, 2099, 2, 11000)
        `;
      });

      it('prevents duplicate (year, month) within the same user', async () => {
        let threw = false;
        try {
          await sql`
            INSERT INTO monthly_opening_balances (user_id, year, month, opening_balance)
            VALUES (${TEST_USER}, 2099, 1, 20000)
          `;
        } catch (err) {
          threw = true;
        }
        expect(threw).toBe(true);
      });

      it('allows the same (year, month) for a different user', async () => {
        await sql`
          INSERT INTO monthly_opening_balances (user_id, year, month, opening_balance)
          VALUES (${TEST_USER_2}, 2099, 1, 30000)
        `;
      });
    });
  });

  // ── Composite Indexes (SCHEMA-11) ──────────────────────────────────────

  describe('Composite Indexes — SCHEMA-11', () => {
    it('creates composite index on categories(user_id, name)', async () => {
      const result = await sql`
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE tablename = 'categories'
          AND indexdef LIKE '%user_id%name%'
      `;
      expect(result.length).toBeGreaterThan(0);
    });

    it('creates composite index on assets(user_id, name)', async () => {
      const result = await sql`
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE tablename = 'assets'
          AND indexdef LIKE '%user_id%name%'
      `;
      expect(result.length).toBeGreaterThan(0);
    });

    it('creates composite index on transactions(user_id, import_hash)', async () => {
      const result = await sql`
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE tablename = 'transactions'
          AND indexdef LIKE '%user_id%import_hash%'
      `;
      expect(result.length).toBeGreaterThan(0);
    });

    it('creates composite index on monthly_opening_balances(user_id, year, month)', async () => {
      const result = await sql`
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE tablename = 'monthly_opening_balances'
          AND indexdef LIKE '%user_id%year%month%'
      `;
      expect(result.length).toBeGreaterThan(0);
    });
  });

});
