import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

const TEST_EMAIL = 'seeding-test@example.com';
const TEST_PASSWORD = 'testpass123';
let sessionCookie: string;
let userId: string;

beforeAll(async () => {
  // Clean up from previous runs
  await sql`DELETE FROM "user" WHERE email = ${TEST_EMAIL}`;

  // Sign up new user via auth.api.signUpEmail — triggers the signup hook
  const res = await auth.api.signUpEmail({
    body: {
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      name: 'Seeding Test User',
    },
    asResponse: true,
  });
  const setCookie = res.headers.get('set-cookie');
  if (!setCookie) {
    throw new Error('Failed to get session cookie for seeding test');
  }
  sessionCookie = setCookie;

  // Get user ID from database
  const [user] = await sql`SELECT id FROM "user" WHERE email = ${TEST_EMAIL}`;
  if (!user) {
    throw new Error('User not found in database after signup');
  }
  userId = user.id;
});

afterAll(async () => {
  await sql`DELETE FROM "user" WHERE email = ${TEST_EMAIL}`;
});

// ── Group 1: SEED-01 — Default categories ────────────────────────────────

describe('SEED-01: Default categories seeded for new user', () => {
  it('creates 25 default categories for new user', async () => {
    const rows = await sql`
      SELECT * FROM categories WHERE user_id = ${userId}
    `;
    expect(rows.length).toBe(25);
  });

  it('default categories have llm_description populated', async () => {
    const rows = await sql`
      SELECT * FROM categories WHERE user_id = ${userId} AND llm_description IS NULL
    `;
    expect(rows.length).toBe(0);
  });

  it('default categories include known names (biedronka, ZUS, etc.)', async () => {
    const rows = await sql`
      SELECT name FROM categories WHERE user_id = ${userId} ORDER BY name
    `;
    const names = rows.map(r => r.name);
    expect(names).toContain('biedronka');
    expect(names).toContain('ZUS');
    expect(names).toContain('paliwo');
  });

  it('default categories are accessible via GET /categories', async () => {
    const res = await app.request('/categories', {
      headers: { Cookie: sessionCookie },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(25);
  });
});

// ── Group 2: SEED-02 — Default accounts ──────────────────────────────────

describe('SEED-02: Default accounts created for new user', () => {
  it('creates 2 default accounts for new user', async () => {
    const rows = await sql`
      SELECT * FROM accounts WHERE user_id = ${userId}
    `;
    expect(rows.length).toBe(2);
  });

  it('default accounts include ING Business and IPKO Personal', async () => {
    const rows = await sql`
      SELECT name FROM accounts WHERE user_id = ${userId} ORDER BY name
    `;
    const names = rows.map(r => r.name);
    expect(names).toContain('ING Business');
    expect(names).toContain('IPKO Personal');
  });

  it('default accounts are accessible via GET /accounts', async () => {
    const res = await app.request('/accounts', {
      headers: { Cookie: sessionCookie },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(2);
  });
});

// ── Group 3: SEED-03 — Signup hook seeding happens per user ──────────────

describe('SEED-03: Signup hook seeds per user registration', () => {
  it('seeding happens exactly once — second user gets fresh defaults', async () => {
    const email2 = 'seeding-test-2@example.com';
    await sql`DELETE FROM "user" WHERE email = ${email2}`;

    const res2 = await auth.api.signUpEmail({
      body: { email: email2, password: 'testpass456', name: 'Seeding Test 2' },
      asResponse: true,
    });

    // Get user2 ID from database
    const [user2] = await sql`SELECT id FROM "user" WHERE email = ${email2}`;
    expect(user2).toBeDefined();
    const userId2 = user2.id;

    const rows = await sql`
      SELECT * FROM categories WHERE user_id = ${userId2}
    `;
    expect(rows.length).toBe(25);

    // Cleanup
    await sql`DELETE FROM "user" WHERE email = ${email2}`;
  });
});

// ── Group 4: Unauthenticated access rejected ─────────────────────────────

describe('Unauthenticated access is rejected', () => {
  it('rejects unauthenticated GET /categories', async () => {
    const res = await app.request('/categories');
    expect(res.status).toBe(401);
  });

  it('rejects unauthenticated GET /accounts', async () => {
    const res = await app.request('/accounts');
    expect(res.status).toBe(401);
  });
});
