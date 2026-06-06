import { describe, it, expect, beforeAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';
import {
  createTransaction,
  listTransactions,
  getMonthlySummary,
  createOpeningBalance,
  updateOpeningBalance,
  listOpeningBalances,
} from '../src/core/ledger/use-cases';

let accountId: string;
let categoryId: string | null = null;

beforeAll(async () => {
  await sql`TRUNCATE transactions CASCADE`;
  await sql`DELETE FROM monthly_opening_balances`;
  await sql`DELETE FROM pgmq.q_analysis_queue`;

  const accounts = await sql`SELECT id FROM accounts LIMIT 1`;
  if (accounts.length === 0) {
    throw new Error('No seeded accounts found');
  }
  accountId = accounts[0].id;

  const categories = await sql`SELECT id FROM categories WHERE name = 'ZUS' LIMIT 1`;
  if (categories.length > 0) {
    categoryId = categories[0].id;
  }
});

describe('Ledger Use Cases & Database Integration', () => {
  it('creates transaction and enqueues to analysis_queue atomically', async () => {
    const tx = await createTransaction({
      account_id: accountId,
      category_id: categoryId,
      type: 'expense',
      amount: '120.5000',
      date: '2026-06-01',
      description: 'ZUS payment',
    });

    expect(tx.id).toBeDefined();
    expect(tx.amount).toBe('120.5000');

    // Verify it enqueued to analysis_queue
    const readResult = await sql`
      SELECT * FROM pgmq.read('analysis_queue', 30, 1)
    `;
    expect(readResult).toHaveLength(1);
    const payload = typeof readResult[0].message === 'string'
      ? JSON.parse(readResult[0].message)
      : readResult[0].message;
    expect(payload.transaction_id).toBe(tx.id);

    // Clean up queue message
    await sql`SELECT pgmq.delete('analysis_queue', ${Number(readResult[0].msg_id)}::bigint)`;
  });

  it('lists transactions with pagination and filters', async () => {
    // Add another transaction
    await createTransaction({
      account_id: accountId,
      type: 'income',
      amount: '5000.0000',
      date: '2026-06-02',
      description: 'Salary',
    });

    const result = await listTransactions({ page: 1, per_page: 1 });
    expect(result.rows).toHaveLength(1);
    expect(result.total).toBe(2); // total unfiltered count in the system

    const resultFilter = await listTransactions({
      page: 1,
      per_page: 10,
      type: 'income',
    });
    expect(resultFilter.rows).toHaveLength(1);
    expect(resultFilter.rows[0].type).toBe('income');
  });

  it('calculates monthly summary correctly and excludes transfers', async () => {
    // Current state in 2026-06:
    // - expense: 120.5000 (ZUS, fixed cost is true)
    // - income: 5000.0000
    // Let's add a transfer of 1000.0000
    await createTransaction({
      account_id: accountId,
      type: 'transfer',
      amount: '1000.0000',
      date: '2026-06-03',
      description: 'Transfer to savings',
    });

    // Seed opening balance for 2026-06
    await createOpeningBalance({
      year: 2026,
      month: 6,
      opening_balance: '15000.0000',
      notes: 'Initial capital',
    });

    const summaries = await getMonthlySummary();
    expect(summaries).toHaveLength(1);
    
    const summary = summaries[0];
    expect(summary.month).toBe('2026-06');
    expect(summary.przychody).toBe('5000.0000');
    expect(summary.wydatki).toBe('120.5000');
    expect(summary.fixed_cost_total).toBe('120.5000'); // ZUS is a fixed cost
    expect(summary.wydatki_bez_stalych).toBe('0.0000'); // 120.50 - 120.50
    expect(summary.zaoszczedzone).toBe('4879.5000'); // 5000 - 120.50
    
    // zaoszczedzone_log: log10(4879.50) = 3.688375...
    expect(parseFloat(summary.zaoszczedzone_log)).toBeCloseTo(Math.log10(4879.50), 4);
    
    // stan_konta = opening_balance (15000) + zaoszczedzone (4879.50) = 19879.50
    expect(summary.stan_konta).toBe('19879.5000');
  });

  it('enforces opening balance uniqueness on year/month', async () => {
    // 2026-06 is already seeded in the previous test. A duplicate insert must fail.
    let threw = false;
    try {
      await createOpeningBalance({
        year: 2026,
        month: 6,
        opening_balance: '20000.0000',
      });
    } catch (err) {
      threw = true;
    }
    expect(threw).toBe(true);
  });

  it('updates opening balance fields', async () => {
    const list = await listOpeningBalances({ year: 2026, month: 6 });
    expect(list).toHaveLength(1);
    const ob = list[0];

    const updated = await updateOpeningBalance(ob.id, {
      opening_balance: '16000.0000',
      notes: 'Updated capital',
    });

    expect(updated).toBeDefined();
    expect(updated?.opening_balance).toBe('16000.0000');
    expect(updated?.notes).toBe('Updated capital');
  });

  it('enforces transaction immutability (DB trigger validation)', async () => {
    const list = await listTransactions({ page: 1, per_page: 1 });
    expect(list.rows).toHaveLength(1);
    const tx = list.rows[0];

    let threwUpdate = false;
    try {
      await sql`UPDATE transactions SET amount = 999.00 WHERE id = ${tx.id}`;
    } catch (err: any) {
      threwUpdate = true;
      expect(err.message).toContain('immutable');
    }
    expect(threwUpdate).toBe(true);

    let threwDelete = false;
    try {
      await sql`DELETE FROM transactions WHERE id = ${tx.id}`;
    } catch (err: any) {
      threwDelete = true;
      expect(err.message).toContain('immutable');
    }
    expect(threwDelete).toBe(true);
  });
});
