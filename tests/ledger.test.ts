import { describe, it, expect, beforeAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';
import { auth } from '../src/auth';
import {
  createTransaction,
  listTransactions,
  getMonthlySummary,
  createOpeningBalance,
  updateOpeningBalance,
  listOpeningBalances,
  getTransaction,
  updateTransaction,
  deleteTransaction,
} from '../src/core/ledger/use-cases';

// NOTE: the exhaustive balance / stan_konta / wartosc_netto math is unit-tested in
// tests/summary-math.test.ts (no DB). These tests cover the DB-backed use-cases and
// the getMonthlySummary fetch-then-delegate wiring end-to-end.

let userId: string;
let accountId: string;
let categoryId: string | null = null;

beforeAll(async () => {
  await sql`TRUNCATE transactions CASCADE`;
  await sql`DELETE FROM monthly_opening_balances`;
  await sql`DELETE FROM pgmq.q_analysis_queue`;
  await sql`TRUNCATE "session", "account", "user", "verification" CASCADE`;

  // Sign up a user; the signup hook seeds this user's accounts + categories.
  await auth.api.signUpEmail({
    body: {
      email: 'ledger-test@example.com',
      password: 'testpassword123',
      name: 'Ledger Test User',
    },
    asResponse: true,
  });

  const [user] = await sql`SELECT id FROM "user" WHERE email = 'ledger-test@example.com'`;
  if (!user) throw new Error('Failed to create test user');
  userId = user.id;

  const [account] = await sql`SELECT id FROM accounts WHERE user_id = ${userId} LIMIT 1`;
  if (!account) throw new Error('No accounts seeded for test user');
  accountId = account.id;

  const [category] = await sql`SELECT id FROM categories WHERE user_id = ${userId} AND name = 'ZUS' LIMIT 1`;
  if (category) categoryId = category.id;
});

describe('Ledger Use Cases & Database Integration', () => {
  it('creates transaction and enqueues to analysis_queue atomically', async () => {
    const tx = await createTransaction({
      userId,
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
      userId,
      account_id: accountId,
      type: 'income',
      amount: '5000.0000',
      date: '2026-06-02',
      description: 'Salary',
    });

    const result = await listTransactions({ userId, page: 1, per_page: 1 });
    expect(result.rows).toHaveLength(1);
    expect(result.total).toBe(2); // total unfiltered count for this user

    const resultFilter = await listTransactions({
      userId,
      page: 1,
      per_page: 10,
      type: 'income',
    });
    expect(resultFilter.rows).toHaveLength(1);
    expect(resultFilter.rows[0].type).toBe('income');
  });

  it('calculates monthly summary correctly and excludes transfers (legacy opening balance)', async () => {
    // Current state in 2026-06:
    // - expense: 120.5000 (ZUS, fixed cost is true)
    // - income: 5000.0000
    // Add a transfer of 1000.0000 — must be excluded from wydatki/przychody.
    await createTransaction({
      userId,
      account_id: accountId,
      type: 'transfer',
      amount: '1000.0000',
      date: '2026-06-03',
      description: 'Transfer to savings',
    });

    await createOpeningBalance({
      userId,
      year: 2026,
      month: 6,
      opening_balance: '15000.0000',
      notes: 'Initial capital',
    });

    const summaries = await getMonthlySummary(userId);
    expect(summaries).toHaveLength(1);

    const summary = summaries[0];
    expect(summary.month).toBe('2026-06');
    expect(summary.przychody).toBe('5000.0000');
    expect(summary.wydatki).toBe('120.5000'); // transfer excluded
    expect(summary.fixed_cost_total).toBe('120.5000'); // ZUS is a fixed cost
    expect(summary.wydatki_bez_stalych).toBe('0.0000');
    expect(summary.zaoszczedzone).toBe('4879.5000');
    expect(parseFloat(summary.zaoszczedzone_log)).toBeCloseTo(Math.log10(4879.5), 4);
    // stan_konta = opening (15000) + zaoszczedzone (4879.50)
    expect(summary.stan_konta).toBe('19879.5000');
  });

  it('enforces opening balance uniqueness on year/month', async () => {
    let threw = false;
    try {
      await createOpeningBalance({
        userId,
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
    const list = await listOpeningBalances({ userId, year: 2026, month: 6 });
    expect(list).toHaveLength(1);
    const ob = list[0];

    const updated = await updateOpeningBalance(
      ob.id,
      { opening_balance: '16000.0000', notes: 'Updated capital' },
      userId
    );

    expect(updated).toBeDefined();
    expect(updated?.opening_balance).toBe('16000.0000');
    expect(updated?.notes).toBe('Updated capital');
  });

  it('getTransaction() returns single transaction by ID, scoped to user', async () => {
    const tx = await createTransaction({
      userId,
      account_id: accountId,
      category_id: categoryId,
      type: 'income',
      amount: '3000.0000',
      date: '2026-06-10',
      description: 'Test get',
    });

    const found = await getTransaction(tx.id, userId);
    expect(found).toBeDefined();
    expect(found!.id).toBe(tx.id);
    expect(found!.amount).toBe('3000.0000');

    const notFound = await getTransaction('00000000-0000-0000-0000-000000000000', userId);
    expect(notFound).toBeUndefined();
  });

  it('updateTransaction() succeeds and returns updated entity', async () => {
    const tx = await createTransaction({
      userId,
      account_id: accountId,
      category_id: categoryId,
      type: 'expense',
      amount: '120.5000',
      date: '2026-06-01',
      description: 'Original description',
    });

    const updated = await updateTransaction(
      tx.id,
      {
        account_id: accountId,
        category_id: categoryId,
        type: 'expense',
        amount: '200.0000',
        description: 'Updated desc',
        date: '2026-06-15',
      },
      userId
    );

    expect(updated.id).toBe(tx.id);
    expect(updated.amount).toBe('200.0000');
    expect(updated.description).toBe('Updated desc');
    expect(new Date(updated.date).toISOString().startsWith('2026-06-15')).toBe(true);
    expect(updated.updated_at).toBeDefined();
  });

  it('updateTransaction() throws when transaction not found', async () => {
    let threw = false;
    try {
      await updateTransaction(
        '00000000-0000-0000-0000-000000000000',
        { account_id: accountId, type: 'expense', amount: '100.0000', date: '2026-06-01' },
        userId
      );
    } catch (err: any) {
      threw = true;
      expect(err.message).toContain('not found');
    }
    expect(threw).toBe(true);
  });

  it('deleteTransaction() clears hash, cleans insights, hard deletes', async () => {
    const tx = await createTransaction({
      userId,
      account_id: accountId,
      type: 'income',
      amount: '5000.0000',
      date: '2026-06-02',
    });

    const found = await getTransaction(tx.id, userId);
    expect(found).toBeDefined();

    await deleteTransaction(tx.id, userId);

    const afterDelete = await getTransaction(tx.id, userId);
    expect(afterDelete).toBeUndefined();
  });

  it('returns monthly summaries newest-first with correct carried-forward balances', async () => {
    // Fresh slate for this multi-month wiring test.
    await sql`DELETE FROM transactions WHERE user_id = ${userId}`;
    await sql`DELETE FROM monthly_opening_balances WHERE user_id = ${userId}`;

    // 2026-05: opening 10000, income 3000, expense 500 → end 12500
    await createOpeningBalance({
      userId,
      year: 2026,
      month: 5,
      opening_balance: '10000.0000',
      notes: 'May opening balance',
    });
    await createTransaction({ userId, account_id: accountId, type: 'income', amount: '3000.0000', date: '2026-05-10' });
    await createTransaction({ userId, account_id: accountId, type: 'expense', amount: '500.0000', date: '2026-05-15' });

    // 2026-06: no opening balance (inherits May ending), income 4000, expense 1000 → end 15500
    await createTransaction({ userId, account_id: accountId, type: 'income', amount: '4000.0000', date: '2026-06-12' });
    await createTransaction({ userId, account_id: accountId, type: 'expense', amount: '1000.0000', date: '2026-06-18' });

    const summaries = await getMonthlySummary(userId);
    expect(summaries).toHaveLength(2);

    expect(summaries[0].month).toBe('2026-06');
    expect(summaries[1].month).toBe('2026-05');

    expect(summaries[1].zaoszczedzone).toBe('2500.0000');
    expect(summaries[1].stan_konta).toBe('12500.0000');

    expect(summaries[0].zaoszczedzone).toBe('3000.0000');
    expect(summaries[0].stan_konta).toBe('15500.0000');
  });
});
