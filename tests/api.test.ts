import { describe, it, expect, beforeAll } from 'bun:test';
import { app } from '../index';
import sql from '../src/infrastructure/db/client';

let accountId: string;
let categoryId: string;
let transactionId: string;
let openingBalanceId: string;

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
  if (categories.length === 0) {
    throw new Error('No seeded categories found');
  }
  categoryId = categories[0].id;
});

describe('HTTP API Endpoints Integration Tests', () => {
  it('GET /health returns server status', async () => {
    const res = await app.request('/health');
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json).toEqual({ data: { ok: true }, error: null, meta: null });
  });

  it('GET /health/db returns database and queue status', async () => {
    const res = await app.request('/health/db');
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toEqual({ db: true, pgmq: true });
    expect(json.error).toBeNull();
    expect(json.meta).toBeNull();
  });

  it('GET /accounts returns reference accounts', async () => {
    const res = await app.request('/accounts');
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toHaveLength(2);
    expect(json.meta).toEqual({ total: 2, page: 1, per_page: 2 });
  });

  it('GET /categories returns 25 reference categories', async () => {
    const res = await app.request('/categories');
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toHaveLength(25);
    expect(json.meta).toEqual({ total: 25, page: 1, per_page: 25 });
  });

  it('POST /transactions rejects invalid body', async () => {
    const res = await app.request('/transactions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        account_id: 'not-a-uuid',
        type: 'expense',
        amount: '-10.00',
        date: 'invalid-date',
      }),
    });
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.data).toBeNull();
    expect(json.error.message).toBe('Validation failed');
    expect(json.meta).toBeNull();
  });

  it('POST /transactions creates a transaction and enqueues atomically', async () => {
    const res = await app.request('/transactions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        account_id: accountId,
        category_id: categoryId,
        type: 'expense',
        amount: '150.0000',
        date: '2026-06-05',
        description: 'Monthly ZUS bill',
      }),
    });
    expect(res.status).toBe(201);
    const json = await res.json();
    expect(json.data.id).toBeDefined();
    expect(json.data.amount).toBe('150.0000');
    expect(json.error).toBeNull();
    expect(json.meta).toBeNull();
    transactionId = json.data.id;
  });

  it('GET /transactions returns a paginated list', async () => {
    const res = await app.request('/transactions?page=1&per_page=10');
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toHaveLength(1);
    expect(json.meta).toEqual({ total: 1, page: 1, per_page: 10 });
    expect(json.data[0].id).toBe(transactionId);
  });

  it('POST /opening-balance creates global monthly balance', async () => {
    const res = await app.request('/opening-balance', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        year: 2026,
        month: 6,
        opening_balance: '12500.0000',
        notes: 'June net worth start',
      }),
    });
    expect(res.status).toBe(201);
    const json = await res.json();
    expect(json.data.id).toBeDefined();
    expect(json.data.opening_balance).toBe('12500.0000');
    openingBalanceId = json.data.id;
  });

  it('POST /opening-balance rejects duplicates', async () => {
    const res = await app.request('/opening-balance', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        year: 2026,
        month: 6,
        opening_balance: '13000.0000',
      }),
    });
    expect(res.status).toBe(409);
  });

  it('PUT /opening-balance/:id updates the balance', async () => {
    const res = await app.request(`/opening-balance/${openingBalanceId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        opening_balance: '13500.0000',
        notes: 'Adjusted net worth',
      }),
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.opening_balance).toBe('13500.0000');
    expect(json.data.notes).toBe('Adjusted net worth');
  });

  it('GET /opening-balance returns matching entries', async () => {
    const res = await app.request('/opening-balance?year=2026&month=6');
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toHaveLength(1);
    expect(json.data[0].id).toBe(openingBalanceId);
  });

  it('GET /summary returns monthly aggregates', async () => {
    const res = await app.request('/transactions/summary');
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toHaveLength(1);
    const summary = json.data[0];
    expect(summary.month).toBe('2026-06');
    expect(summary.wydatki).toBe('150.0000');
    expect(summary.przychody).toBe('0.0000');
    // stan_konta = opening_balance (13500) + net (0 - 150) = 13350
    expect(summary.stan_konta).toBe('13350.0000');
  });
});
