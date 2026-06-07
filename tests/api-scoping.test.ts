import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

const USER_A_EMAIL = 'scope-user-a@test.com';
const USER_B_EMAIL = 'scope-user-b@test.com';
const USER_A_PASSWORD = 'testpass123';
const USER_B_PASSWORD = 'testpass456';

let userASession: string;
let userBSession: string;
let userAAccountId: string;
let userBCategoryId: string;
let userATransactionId: string;
let userBOpeningBalanceId: string;
let userAAssetId: string;
let userBAccountId: string;

beforeAll(async () => {
  // Clean up any existing test users from prior runs
  await sql`DELETE FROM "user" WHERE email IN (${USER_A_EMAIL}, ${USER_B_EMAIL})`;

  // Create User A via signUpEmail — triggers signup hook, creating default categories + accounts
  const resA = await auth.api.signUpEmail({
    body: { email: USER_A_EMAIL, password: USER_A_PASSWORD, name: 'Scope User A' },
    asResponse: true,
  });
  const cookieA = resA.headers.get('set-cookie');
  if (!cookieA) throw new Error('No session cookie for User A');
  userASession = cookieA;

  // Create User B
  const resB = await auth.api.signUpEmail({
    body: { email: USER_B_EMAIL, password: USER_B_PASSWORD, name: 'Scope User B' },
    asResponse: true,
  });
  const cookieB = resB.headers.get('set-cookie');
  if (!cookieB) throw new Error('No session cookie for User B');
  userBSession = cookieB;

  // Fetch User A's default account (first one from signup hook)
  const aAccounts = await sql`
    SELECT id FROM accounts WHERE user_id = (
      SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}
    ) ORDER BY name LIMIT 1
  `;
  if (aAccounts.length === 0) throw new Error('User A has no accounts');
  userAAccountId = aAccounts[0].id;

  // Fetch User B's first category
  const bCats = await sql`
    SELECT id FROM categories WHERE user_id = (
      SELECT id FROM "user" WHERE email = ${USER_B_EMAIL}
    ) LIMIT 1
  `;
  if (bCats.length === 0) throw new Error('User B has no categories');
  userBCategoryId = bCats[0].id;

  // Fetch User B's default account
  const bAccounts = await sql`
    SELECT id FROM accounts WHERE user_id = (
      SELECT id FROM "user" WHERE email = ${USER_B_EMAIL}
    ) ORDER BY name LIMIT 1
  `;
  if (bAccounts.length === 0) throw new Error('User B has no accounts');
  userBAccountId = bAccounts[0].id;
});

afterAll(async () => {
  await sql`DELETE FROM "user" WHERE email IN (${USER_A_EMAIL}, ${USER_B_EMAIL})`;
});

// ── Group 1: User A creates resources (SCOPE-02) ──────────────────────────

describe('Group 1: User A creates resources (SCOPE-02)', () => {
  it('creates a transaction for User A (POST /transactions) → 201', async () => {
    const res = await app.request('/transactions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userASession,
      },
      body: JSON.stringify({
        account_id: userAAccountId,
        type: 'expense',
        amount: '100.0000',
        date: '2026-06-01',
        description: 'User A transaction',
      }),
    });
    expect(res.status).toBe(201);
    const json = await res.json();
    expect(json.data.id).toBeDefined();
    userATransactionId = json.data.id;

    // Verify user_id via SQL
    const [row] = await sql`
      SELECT user_id FROM transactions WHERE id = ${userATransactionId}
    `;
    const userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;
    expect(row.user_id).toBe(userAId);
  });

  it('creates an asset for User A (POST /assets) → 201', async () => {
    const res = await app.request('/assets', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userASession,
      },
      body: JSON.stringify({
        name: 'User A Asset',
        value: 50000,
      }),
    });
    expect(res.status).toBe(201);
    const json = await res.json();
    expect(json.data.id).toBeDefined();
    userAAssetId = json.data.id;
  });

  it('creates an opening balance for User A (POST /opening-balance) → 201', async () => {
    const res = await app.request('/opening-balance', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userASession,
      },
      body: JSON.stringify({
        year: 2026,
        month: 6,
        opening_balance: '10000.0000',
        notes: 'User A opening balance',
      }),
    });
    expect(res.status).toBe(201);
  });
});

// ── Group 2: User A reads own resources (SCOPE-01) ────────────────────────

describe('Group 2: User A reads own resources (SCOPE-01)', () => {
  it('GET /transactions returns User A transactions', async () => {
    const res = await app.request('/transactions?page=1&per_page=50', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    expect(json.data.some((t: any) => t.id === userATransactionId)).toBe(true);
  });

  it('GET /assets returns User A assets', async () => {
    const res = await app.request('/assets', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    expect(json.data.some((a: any) => a.id === userAAssetId)).toBe(true);
  });

  it('GET /opening-balance returns User A balances', async () => {
    const res = await app.request('/opening-balance?year=2026&month=6', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
  });

  it('GET /accounts returns User A accounts (2 from signup hook)', async () => {
    const res = await app.request('/accounts', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(2);
  });

  it('GET /categories returns User A categories (25 from signup hook)', async () => {
    const res = await app.request('/categories', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(25);
  });
});

// ── Group 3: User B cannot access User A's resources (SCOPE-01/SCOPE-05 — 404) ──

describe('Group 3: Cross-user isolation — User B gets 404 on User A resources (SCOPE-01/SCOPE-05)', () => {
  it('GET /transactions/:id with User A transaction + User B cookie → 404', async () => {
    const res = await app.request(`/transactions/${userATransactionId}`, {
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(404);
  });

  it('PUT /transactions/:id with User A transaction + User B cookie → 404', async () => {
    const res = await app.request(`/transactions/${userATransactionId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userBSession,
      },
      body: JSON.stringify({
        account_id: userAAccountId,
        type: 'expense',
        amount: '200.0000',
        date: '2026-06-02',
        description: 'User B trying to edit',
      }),
    });
    expect(res.status).toBe(404);
  });

  it('DELETE /transactions/:id with User A transaction + User B cookie → 404', async () => {
    const res = await app.request(`/transactions/${userATransactionId}`, {
      method: 'DELETE',
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(404);
  });

  it('PATCH /transactions/:id/category with User A transaction + User B cookie → 404', async () => {
    const res = await app.request(`/transactions/${userATransactionId}/category`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userBSession,
      },
      body: JSON.stringify({ category_id: userBCategoryId }),
    });
    expect(res.status).toBe(404);
  });

  it('GET /assets/:id with User A asset + User B cookie → 404', async () => {
    const res = await app.request(`/assets/${userAAssetId}`, {
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(404);
  });

  it('PUT /assets/:id with User A asset + User B cookie → 404', async () => {
    const res = await app.request(`/assets/${userAAssetId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userBSession,
      },
      body: JSON.stringify({ name: 'Hacked Asset', value: 1 }),
    });
    expect(res.status).toBe(404);
  });

  it('DELETE /assets/:id with User A asset + User B cookie → 404', async () => {
    const res = await app.request(`/assets/${userAAssetId}`, {
      method: 'DELETE',
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(404);
  });

  it('GET /opening-balance with User B balance ID + User A cookie → 404', async () => {
    // Create an opening balance for User B first, then try to access it with User A
    const resB = await app.request('/opening-balance', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userBSession,
      },
      body: JSON.stringify({
        year: 2026,
        month: 7,
        opening_balance: '20000.0000',
        notes: 'User B opening balance',
      }),
    });
    expect(resB.status).toBe(201);
    const bJson = await resB.json();
    userBOpeningBalanceId = bJson.data.id;

    // User A tries to access User B's opening balance
    const resA = await app.request(`/opening-balance/${userBOpeningBalanceId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userASession,
      },
      body: JSON.stringify({
        opening_balance: '99999.0000',
      }),
    });
    expect(resA.status).toBe(404);
  });
});

// ── Group 4: User B operates within own data (positive isolation) ─────────

describe('Group 4: User B operates within own data (positive isolation)', () => {
  it('User B creates own transaction → 201', async () => {
    const res = await app.request('/transactions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: userBSession,
      },
      body: JSON.stringify({
        account_id: userBAccountId,
        type: 'income',
        amount: '5000.0000',
        date: '2026-06-15',
        description: 'User B income',
      }),
    });
    expect(res.status).toBe(201);
  });

  it('User B lists own transactions — only User B transactions returned', async () => {
    const res = await app.request('/transactions?page=1&per_page=50', {
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    // User B should only see their own transaction, not User A's
    const allB = json.data.every((t: any) =>
      t.description === 'User B income'
    );
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    // User A's transaction should NOT appear
    const hasUserATx = json.data.some((t: any) => t.id === userATransactionId);
    expect(hasUserATx).toBe(false);
  });

  it('User B lists own accounts — 2 accounts (from signup hook)', async () => {
    const res = await app.request('/accounts', {
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(2);
  });

  it('User B lists own categories — 25 categories (from signup hook)', async () => {
    const res = await app.request('/categories', {
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(25);
  });
});

// ── Group 5: Auth-required routes reject unauthenticated (SCOPE-06) ───────

describe('Group 5: Unauthenticated requests return 401 (SCOPE-06)', () => {
  it('POST /transactions without cookie → 401', async () => {
    const res = await app.request('/transactions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        account_id: userAAccountId,
        type: 'expense',
        amount: '10.0000',
        date: '2026-06-01',
      }),
    });
    expect(res.status).toBe(401);
  });

  it('GET /transactions without cookie → 401', async () => {
    const res = await app.request('/transactions');
    expect(res.status).toBe(401);
  });

  it('POST /assets without cookie → 401', async () => {
    const res = await app.request('/assets', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Evil', value: 100 }),
    });
    expect(res.status).toBe(401);
  });

  it('POST /import without cookie → 401', async () => {
    const res = await app.request('/import', { method: 'POST' });
    expect(res.status).toBe(401);
  });

  it('POST /opening-balance without cookie → 401', async () => {
    const res = await app.request('/opening-balance', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ year: 2026, month: 1, opening_balance: '1000' }),
    });
    expect(res.status).toBe(401);
  });

  it('GET /accounts without cookie → 401', async () => {
    const res = await app.request('/accounts');
    expect(res.status).toBe(401);
  });

  it('GET /categories without cookie → 401', async () => {
    const res = await app.request('/categories');
    expect(res.status).toBe(401);
  });
});

// ── Group 6: Pagination and Offset — D-02 ──────────────────────────────────

describe('Group 6: Pagination and Offset — D-02', () => {
  beforeAll(async () => {
    const userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;

    // Insert 11 transactions for User A with incrementing dates
    for (let i = 1; i <= 11; i++) {
      const date = `2026-06-${String(i).padStart(2, '0')}`;
      await sql`
        INSERT INTO transactions (account_id, type, amount, description, date, user_id)
        VALUES (${userAAccountId}, 'expense', ${(i * 10).toFixed(4)}, ${`Page test A ${i}`}, ${date}, ${userAId})
      `;
    }
  });

  it('GET /transactions?page=1&per_page=5 returns 5 User A transactions', async () => {
    const res = await app.request('/transactions?page=1&per_page=5', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(5);
    for (const item of json.data) {
      expect(item.description).toMatch(/^Page test A /);
    }
  });

  it('GET /transactions?page=2&per_page=5 returns remaining User A transactions', async () => {
    const res = await app.request('/transactions?page=2&per_page=5', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(5);
    for (const item of json.data) {
      expect(item.description).toMatch(/^Page test A /);
    }
  });

  it('GET /transactions?page=3&per_page=5 returns remaining User A transactions (no cross-user data)', async () => {
    const res = await app.request('/transactions?page=3&per_page=5', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    // 11 (Group 6) + 1 (Group 1) = 12 User A transactions; pages 1+2 consume 10; 2 remaining
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    // Verify all items belong to User A (no cross-user data)
    const userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;
    for (const item of json.data) {
      expect(item.user_id).toBe(userAId);
    }
  });

  it('GET /transactions?page=999&per_page=50 returns empty array (beyond last page)', async () => {
    const res = await app.request('/transactions?page=999&per_page=50', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toHaveLength(0);
  });

  it('User B cannot see any User A paginated transactions', async () => {
    const res = await app.request('/transactions?page=1&per_page=50', {
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    const hasUserAPageData = json.data.some((t: any) =>
      t.description?.startsWith('Page test A')
    );
    expect(hasUserAPageData).toBe(false);
  });

  afterAll(async () => {
    await sql`DELETE FROM transactions WHERE description LIKE 'Page test A %'`;
  });
});

// ── Group 7: Filtered Query Isolation — D-03 ───────────────────────────────

describe('Group 7: Filtered Query Isolation — D-03', () => {
  beforeAll(async () => {
    const userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;
    const userBId = (await sql`SELECT id FROM "user" WHERE email = ${USER_B_EMAIL}`)[0].id;

    // Insert mixed transactions for User A
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, user_id)
      VALUES (${userAAccountId}, 'expense', '50.0000', 'Filtered test expense', '2026-06-15', ${userAId})
    `;
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, user_id)
      VALUES (${userAAccountId}, 'income', '2000.0000', 'Filtered test income', '2026-06-20', ${userAId})
    `;
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, user_id, category_id)
      VALUES (${userAAccountId}, 'expense', '30.0000', 'Filtered test uncategorized', '2026-06-10', ${userAId}, NULL)
    `;
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, user_id)
      VALUES (${userAAccountId}, 'expense', '25.0000', 'Filtered test future', '2027-01-15', ${userAId})
    `;

    // Insert a User B transaction that should NOT appear in User A's filtered queries
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, user_id)
      VALUES (${userBAccountId}, 'income', '9999.0000', 'User B filtered data', '2026-06-15', ${userBId})
    `;
  });

  it('?type=expense returns only User A expense transactions', async () => {
    const res = await app.request('/transactions?type=expense&page=1&per_page=50', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    // All returned items are expenses
    for (const item of json.data) {
      expect(item.type).toBe('expense');
    }
    // User B's data should not appear
    const hasUserBData = json.data.some((t: any) => t.description === 'User B filtered data');
    expect(hasUserBData).toBe(false);
  });

  it('?date_from&date_to respects user boundary', async () => {
    const res = await app.request('/transactions?date_from=2026-06-01&date_to=2026-12-31&page=1&per_page=50', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    // User B's data should not appear
    const hasUserBData = json.data.some((t: any) => t.description === 'User B filtered data');
    expect(hasUserBData).toBe(false);
  });

  it('?uncategorized=true returns only User A uncategorized transactions', async () => {
    const res = await app.request('/transactions?uncategorized=true&page=1&per_page=50', {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    // All returned items have null category_id
    for (const item of json.data) {
      expect(item.category_id).toBeNull();
    }
    // User B's data should not appear
    const hasUserBData = json.data.some((t: any) => t.description === 'User B filtered data');
    expect(hasUserBData).toBe(false);
  });

  it('?account_id returns only that account transactions', async () => {
    const res = await app.request(`/transactions?account_id=${userAAccountId}&page=1&per_page=50`, {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    // All returned items belong to User A's account
    for (const item of json.data) {
      expect(item.account_id).toBe(userAAccountId);
    }
    // User B's data should not appear
    const hasUserBData = json.data.some((t: any) => t.description === 'User B filtered data');
    expect(hasUserBData).toBe(false);
  });

  afterAll(async () => {
    await sql`DELETE FROM transactions WHERE description LIKE 'Filtered test %'`;
    await sql`DELETE FROM transactions WHERE description = 'User B filtered data'`;
  });
});

// ── Group 8: Bulk/Multi-Create User Tagging — D-04 ─────────────────────────

describe('Group 8: Bulk/Multi-Create User Tagging — D-04', () => {
  const userABulkIds: string[] = [];

  it('sequentially create 3 transactions for User A, all tagged with user_id', async () => {
    const userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;

    for (let i = 1; i <= 3; i++) {
      const res = await app.request('/transactions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Cookie: userASession,
        },
        body: JSON.stringify({
          account_id: userAAccountId,
          type: 'expense',
          amount: `${(i * 100).toFixed(4)}`,
          date: '2026-07-01',
          description: `Bulk test A ${i}`,
        }),
      });
      expect(res.status).toBe(201);
      const json = await res.json();
      expect(json.data.id).toBeDefined();
      userABulkIds.push(json.data.id);
    }

    expect(userABulkIds).toHaveLength(3);

    // Verify all are tagged to User A via SQL SELECT
    for (const id of userABulkIds) {
      const [row] = await sql`
        SELECT user_id FROM transactions WHERE id = ${id}
      `;
      expect(row.user_id).toBe(userAId);
    }
  });

  it('User B cannot access User A bulk-created transactions', async () => {
    expect(userABulkIds.length).toBeGreaterThan(0);

    for (const id of userABulkIds) {
      const res = await app.request(`/transactions/${id}`, {
        headers: { Cookie: userBSession },
      });
      expect(res.status).toBe(404);
    }
  });

  it('User B own bulk-created transactions are tagged to User B', async () => {
    const userBId = (await sql`SELECT id FROM "user" WHERE email = ${USER_B_EMAIL}`)[0].id;
    const bIds: string[] = [];

    for (let i = 1; i <= 2; i++) {
      const res = await app.request('/transactions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Cookie: userBSession,
        },
        body: JSON.stringify({
          account_id: userBAccountId,
          type: 'income',
          amount: `${(i * 500).toFixed(4)}`,
          date: '2026-07-15',
          description: `Bulk test B ${i}`,
        }),
      });
      expect(res.status).toBe(201);
      const json = await res.json();
      expect(json.data.id).toBeDefined();
      bIds.push(json.data.id);
    }

    expect(bIds).toHaveLength(2);

    // Verify all are tagged to User B via SQL SELECT
    for (const id of bIds) {
      const [row] = await sql`
        SELECT user_id FROM transactions WHERE id = ${id}
      `;
      expect(row.user_id).toBe(userBId);
    }
  });

  afterAll(async () => {
    await sql`DELETE FROM transactions WHERE description LIKE 'Bulk test %'`;
  });
});
