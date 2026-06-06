import { describe, it, expect, beforeAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';

beforeAll(async () => {
  await sql`TRUNCATE transactions CASCADE`;
  await sql`DELETE FROM monthly_opening_balances`;
});

describe('Ledger Core & DB schema', () => {
  it('has 25 seeded categories with exactly 6 fixed-cost categories', async () => {
    const cats = await sql`SELECT name, is_fixed_cost FROM categories`;
    expect(cats).toHaveLength(25);
    
    const fixedCats = cats.filter(c => c.is_fixed_cost);
    expect(fixedCats).toHaveLength(6);
  });

  it('has exactly 2 accounts seeded', async () => {
    const accounts = await sql`SELECT name, type FROM accounts`;
    expect(accounts).toHaveLength(2);
  });

  it('enforces transaction immutability on UPDATE', async () => {
    const accounts = await sql`SELECT id FROM accounts LIMIT 1`;
    expect(accounts).toHaveLength(1);
    const accountId = accounts[0].id;

    const [tx] = await sql`
      INSERT INTO transactions (account_id, type, amount, date, description)
      VALUES (${accountId}, 'expense', 10.00, '2026-06-06', 'Test transaction')
      RETURNING id
    `;

    let threw = false;
    try {
      await sql`UPDATE transactions SET amount = 99.00 WHERE id = ${tx.id}`;
    } catch (err: any) {
      threw = true;
      expect(err.message).toContain('immutable');
    }
    expect(threw).toBe(true);
  });

  it('enforces transaction immutability on DELETE', async () => {
    const accounts = await sql`SELECT id FROM accounts LIMIT 1`;
    expect(accounts).toHaveLength(1);
    const accountId = accounts[0].id;

    const [tx] = await sql`
      INSERT INTO transactions (account_id, type, amount, date, description)
      VALUES (${accountId}, 'expense', 10.00, '2026-06-06', 'Test transaction to delete')
      RETURNING id
    `;

    let threw = false;
    try {
      await sql`DELETE FROM transactions WHERE id = ${tx.id}`;
    } catch (err: any) {
      threw = true;
      expect(err.message).toContain('immutable');
    }
    expect(threw).toBe(true);
  });
});
