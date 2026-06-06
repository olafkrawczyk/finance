import { describe, it, expect, beforeAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

let sessionCookie: string;
let userId: string;
let categoryId: string;
let insightId: string;

beforeAll(async () => {
  await sql`TRUNCATE insights CASCADE`;
  await sql`DELETE FROM pgmq.q_analysis_queue`;
  await sql`TRUNCATE "session", "account", "user", "verification" CASCADE`;

  const categories = await sql`SELECT id FROM categories LIMIT 1`;
  if (categories.length === 0) {
    throw new Error('No categories found for seeding');
  }
  categoryId = categories[0].id;

  // Sign up user
  const res = await auth.api.signUpEmail({
    body: {
      email: 'api-insights-test@example.com',
      password: 'testpassword123',
      name: 'API Insights Test User',
    },
    asResponse: true,
  });

  const setCookie = res.headers.get('set-cookie');
  if (!setCookie) {
    throw new Error('Failed to get session cookie for integration tests');
  }
  sessionCookie = setCookie;

  const users = await sql`SELECT id FROM "user" WHERE email = 'api-insights-test@example.com'`;
  userId = users[0].id;

  // Seed one base insight
  const [seeded] = await sql`
    INSERT INTO insights (user_id, type, priority, title, content, dedup_hash, dismissed)
    VALUES (
      ${userId}, 'alert', 'high', 'Test Alert Title', 'Test Alert Content',
      'test-dedup-hash-1', false
    )
    RETURNING id
  `;
  insightId = seeded.id;
});

describe('HTTP Insights API Endpoints Integration Tests', () => {
  it('GET /insights without auth returns 401', async () => {
    const res = await app.request('/insights');
    expect(res.status).toBe(401);
  });

  it('GET /insights with auth returns 200 with envelope', async () => {
    const res = await app.request('/insights', {
      headers: { Cookie: sessionCookie }
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toBeArray();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    expect(json.data[0].title).toBe('Test Alert Title');
    expect(json.meta.total).toBeGreaterThanOrEqual(1);
    expect(json.meta.page).toBe(1);
    expect(json.meta.per_page).toBe(20);
  });

  it('GET /insights?type=alert returns only alert insights', async () => {
    // Seed a tip insight
    await sql`
      INSERT INTO insights (user_id, type, priority, title, content, dedup_hash, dismissed)
      VALUES (${userId}, 'tip', 'medium', 'Test Tip Title', 'Test Tip Content', 'test-dedup-hash-2', false)
    `;

    const res = await app.request('/insights?type=alert', {
      headers: { Cookie: sessionCookie }
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.every((i: any) => i.type === 'alert')).toBe(true);
  });

  it('GET /insights?dismissed=true returns none when all are false', async () => {
    const res = await app.request('/insights?dismissed=true', {
      headers: { Cookie: sessionCookie }
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toHaveLength(0);
  });

  it('GET /insights with pagination works', async () => {
    for (let i = 0; i < 10; i++) {
      const title = `Title ${i}`;
      const content = `Content ${i}`;
      const hash = `hash-${i}`;
      await sql`
        INSERT INTO insights (user_id, type, priority, title, content, dedup_hash, dismissed)
        VALUES (${userId}, 'tip', 'low', ${title}, ${content}, ${hash}, false)
      `;
    }

    const res = await app.request('/insights?per_page=5', {
      headers: { Cookie: sessionCookie }
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBe(5);
    expect(json.meta.per_page).toBe(5);
    expect(json.meta.total).toBeGreaterThanOrEqual(12);
  });

  it('PATCH /insights/:id/dismiss without auth returns 401', async () => {
    const res = await app.request(`/insights/${insightId}/dismiss`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ dismissed: true }),
    });
    expect(res.status).toBe(401);
  });

  it('PATCH /insights/:id/dismiss with auth returns 200 and sets dismissed: true', async () => {
    const res = await app.request(`/insights/${insightId}/dismiss`, {
      method: 'PATCH',
      headers: {
        Cookie: sessionCookie,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ dismissed: true }),
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.dismissed).toBe(true);

    // Verify it is excluded from default list (which shows undismissed)
    const listRes = await app.request('/insights', {
      headers: { Cookie: sessionCookie }
    });
    const listJson = await listRes.json();
    expect(listJson.data.some((i: any) => i.id === insightId)).toBe(false);
  });

  it('PATCH /insights/non-existent-uuid/dismiss returns 404', async () => {
    const res = await app.request('/insights/88888888-8888-8888-8888-888888888888/dismiss', {
      method: 'PATCH',
      headers: {
        Cookie: sessionCookie,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ dismissed: true }),
    });
    expect(res.status).toBe(404);
  });

  it('POST /insights/generate without auth returns 401', async () => {
    const res = await app.request('/insights/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    expect(res.status).toBe(401);
  });

  it('POST /insights/generate with auth returns 202 and enqueues job', async () => {
    const res = await app.request('/insights/generate', {
      method: 'POST',
      headers: {
        Cookie: sessionCookie,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({}),
    });
    expect(res.status).toBe(202);
    const json = await res.json();
    expect(json.data.msg_id).toBeGreaterThan(0);
    expect(json.meta.message).toContain('enqueued');

    // Clean up queue message
    await sql`DELETE FROM pgmq.q_analysis_queue`;
  });

  it('GET /insights/dashboard returns top 3 undismissed insights', async () => {
    const res = await app.request('/insights/dashboard', {
      headers: { Cookie: sessionCookie }
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeLessThanOrEqual(3);
    expect(json.data.every((i: any) => !i.dismissed)).toBe(true);
  });

  it('GET /insights/forecast returns forecast-type only', async () => {
    // Seed a forecast insight
    await sql`
      INSERT INTO insights (user_id, type, priority, title, content, dedup_hash, dismissed)
      VALUES (${userId}, 'forecast', 'low', 'Forecast Groceries', 'Spending forecast groceries', 'test-forecast-hash', false)
    `;

    const res = await app.request('/insights/forecast', {
      headers: { Cookie: sessionCookie }
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.length).toBeGreaterThanOrEqual(1);
    expect(json.data.every((i: any) => i.type === 'forecast')).toBe(true);
  });
});
