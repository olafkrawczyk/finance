import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

const USER_A_EMAIL = 'concurrent-a@test.com';
const USER_B_EMAIL = 'concurrent-b@test.com';
const USER_A_PASSWORD = 'testpass123';
const USER_B_PASSWORD = 'testpass456';

let userASession: string;
let userBSession: string;
let userAAccountId: string;
let userBAccountId: string;
let userAId: string;
let userBId: string;

beforeAll(async () => {
  await sql`ALTER TABLE transactions DISABLE TRIGGER trg_transactions_no_delete`;
  await sql`DELETE FROM "user" WHERE email IN (${USER_A_EMAIL}, ${USER_B_EMAIL})`;
  await sql`ALTER TABLE transactions ENABLE TRIGGER trg_transactions_no_delete`;

  // Create User A — signup hook creates default categories + accounts
  const resA = await auth.api.signUpEmail({
    body: { email: USER_A_EMAIL, password: USER_A_PASSWORD, name: 'Concurrent User A' },
    asResponse: true,
  });
  const cookieA = resA.headers.get('set-cookie');
  if (!cookieA) throw new Error('No session cookie for User A');
  userASession = cookieA;

  // Create User B
  const resB = await auth.api.signUpEmail({
    body: { email: USER_B_EMAIL, password: USER_B_PASSWORD, name: 'Concurrent User B' },
    asResponse: true,
  });
  const cookieB = resB.headers.get('set-cookie');
  if (!cookieB) throw new Error('No session cookie for User B');
  userBSession = cookieB;

  // Fetch user IDs and default account IDs
  userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;
  userBId = (await sql`SELECT id FROM "user" WHERE email = ${USER_B_EMAIL}`)[0].id;

  const aAccounts = await sql`
    SELECT id FROM accounts WHERE user_id = ${userAId} ORDER BY name LIMIT 1
  `;
  if (aAccounts.length === 0) throw new Error('User A has no accounts');
  userAAccountId = aAccounts[0].id;

  const bAccounts = await sql`
    SELECT id FROM accounts WHERE user_id = ${userBId} ORDER BY name LIMIT 1
  `;
  if (bAccounts.length === 0) throw new Error('User B has no accounts');
  userBAccountId = bAccounts[0].id;
});

afterAll(async () => {
  await sql`ALTER TABLE transactions DISABLE TRIGGER trg_transactions_no_delete`;
  await sql`DELETE FROM "user" WHERE email IN (${USER_A_EMAIL}, ${USER_B_EMAIL})`;
  await sql`ALTER TABLE transactions ENABLE TRIGGER trg_transactions_no_delete`;
});

// ── Concurrent User Isolation (TEST-04, D-05, D-06) ──

describe('Concurrent User Isolation — D-05, D-06', () => {
  const N = 10; // 10 transactions per user

  it('parallel POST inserts by two users maintain full data isolation', async () => {
    // Build parallel requests with per-promise error handling
    // to prevent one failure from killing all results (RESEARCH.md Pitfall 3)
    const userARequests = Array.from({ length: N }, (_, i) =>
      app.request('/transactions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Cookie: userASession },
        body: JSON.stringify({
          account_id: userAAccountId,
          type: 'expense',
          amount: `${i + 1}.0000`,
          date: '2026-06-01',
          description: `Concurrent A ${i}`,
        }),
      }).then(async res => ({
        status: res.status,
        id: ((await res.json()) as any).data?.id,
        index: i,
        user: 'A',
      }))
    );

    const userBRequests = Array.from({ length: N }, (_, i) =>
      app.request('/transactions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Cookie: userBSession },
        body: JSON.stringify({
          account_id: userBAccountId,
          type: 'income',
          amount: `${(i + 1) * 100}.0000`,
          date: '2026-06-15',
          description: `Concurrent B ${i}`,
        }),
      }).then(async res => ({
        status: res.status,
        id: ((await res.json()) as any).data?.id,
        index: i,
        user: 'B',
      }))
    );

    const allResults = await Promise.all([...userARequests, ...userBRequests]);

    // D-06: All should succeed (201 Created)
    const failures = allResults.filter(r => r.status !== 201);
    expect(failures).toHaveLength(0);
    expect(allResults).toHaveLength(N * 2);

    // Extract created IDs by user
    const aIds = allResults.filter(r => r.user === 'A').map(r => r.id).filter(Boolean);
    const bIds = allResults.filter(r => r.user === 'B').map(r => r.id).filter(Boolean);
    expect(aIds).toHaveLength(N);
    expect(bIds).toHaveLength(N);

    // D-06: Verify per-user row counts via SQL
    const [aCount] = await sql`
      SELECT COUNT(*)::int AS count FROM transactions
      WHERE user_id = ${userAId} AND description LIKE 'Concurrent A %'
    `;
    expect(aCount.count).toBe(N);

    const [bCount] = await sql`
      SELECT COUNT(*)::int AS count FROM transactions
      WHERE user_id = ${userBId} AND description LIKE 'Concurrent B %'
    `;
    expect(bCount.count).toBe(N);

    // D-06: Cross-user 404 check — User A cannot see User B's new transactions
    for (const id of bIds) {
      const res = await app.request(`/transactions/${id}`, {
        headers: { Cookie: userASession },
      });
      expect(res.status).toBe(404);
    }

    // D-06: User B cannot see User A's new transactions
    for (const id of aIds) {
      const res = await app.request(`/transactions/${id}`, {
        headers: { Cookie: userBSession },
      });
      expect(res.status).toBe(404);
    }
  });

  it('GET list after concurrent inserts shows only own transactions', async () => {
    // Verify list endpoints also maintain isolation after concurrent inserts
    const resA = await app.request('/transactions?page=1&per_page=50', {
      headers: { Cookie: userASession },
    });
    expect(resA.status).toBe(200);
    const jsonA = await resA.json() as any;

    // User A sees only their own concurrently created transactions
    const aDescriptions = jsonA.data.map((t: any) => t.description);
    const hasBData = aDescriptions.some((d: string) => d.startsWith('Concurrent B'));
    expect(hasBData).toBe(false);

    // User A's concurrently created items appear
    const hasAData = aDescriptions.some((d: string) => d.startsWith('Concurrent A'));
    expect(hasAData).toBe(true);

    // Same for User B
    const resB = await app.request('/transactions?page=1&per_page=50', {
      headers: { Cookie: userBSession },
    });
    expect(resB.status).toBe(200);
    const jsonB = await resB.json() as any;

    const bDescriptions = jsonB.data.map((t: any) => t.description);
    const hasADataInB = bDescriptions.some((d: string) => d.startsWith('Concurrent A'));
    expect(hasADataInB).toBe(false);
  });
});
