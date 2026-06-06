import { describe, it, expect, beforeAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

let accountId: string;
let sessionCookie: string;

beforeAll(async () => {
  await sql`TRUNCATE import_jobs CASCADE`;
  await sql`DELETE FROM pgmq.q_import_queue`;
  await sql`TRUNCATE "session", "account", "user", "verification" CASCADE`;

  const accounts = await sql`SELECT id FROM accounts LIMIT 1`;
  if (accounts.length === 0) {
    throw new Error('No seeded accounts found');
  }
  accountId = accounts[0].id;

  const res = await auth.api.signUpEmail({
    body: {
      email: 'import-test@example.com',
      password: 'testpassword123',
      name: 'Import Test User',
    },
    asResponse: true,
  });
  const setCookie = res.headers.get('set-cookie');
  if (!setCookie) {
    throw new Error('Failed to get session cookie for import tests');
  }
  sessionCookie = setCookie;
});

describe('Import API Integration Tests', () => {
  it('POST /import without session returns 401', async () => {
    const res = await app.request('/import', {
      method: 'POST',
    });
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error.message).toBe('Unauthorized');
  });

  it('POST /import with session but no csv file returns 400', async () => {
    const formData = new FormData();
    formData.append('account_id', accountId);

    const res = await app.request('/import', {
      method: 'POST',
      headers: { Cookie: sessionCookie },
      body: formData,
    });
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error.message).toBe('CSV file required');
  });

  it('POST /import with session + invalid account_id returns 400', async () => {
    const formData = new FormData();
    formData.append('account_id', 'not-a-uuid');
    const blob = new Blob(['dummy csv'], { type: 'text/csv' });
    formData.append('csv', blob, 'test.csv');

    const res = await app.request('/import', {
      method: 'POST',
      headers: { Cookie: sessionCookie },
      body: formData,
    });
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error.message).toBe('Validation failed');
  });

  it('POST /import with session + valid CSV and account_id returns 202 and enqueues job', async () => {
    const formData = new FormData();
    formData.append('account_id', accountId);
    // Include Polish characters to verify windows-1250 / latin1 decode flow
    const csvContent = 'Data transakcji;Opis\n2026-06-01;Konto dla Firmy - zażółć gęślą jaźń';
    const blob = new Blob([csvContent], { type: 'text/csv' });
    formData.append('csv', blob, 'ing.csv');

    const res = await app.request('/import', {
      method: 'POST',
      headers: { Cookie: sessionCookie },
      body: formData,
    });
    expect(res.status).toBe(202);
    const json = await res.json();
    expect(json.data.job_id).toBeDefined();
    expect(json.error).toBeNull();

    // Verify GET /import/:job_id returns 200
    const jobRes = await app.request(`/import/${json.data.job_id}`, {
      headers: { Cookie: sessionCookie },
    });
    expect(jobRes.status).toBe(200);
    const jobJson = await jobRes.json();
    expect(jobJson.data.status).toBe('pending');
    expect(jobJson.data.account_id).toBe(accountId);
  });

  it('GET /import/:job_id with non-existent UUID returns 404', async () => {
    const res = await app.request('/import/4c8d1844-0b1a-4712-8bb4-098522a105c3', {
      headers: { Cookie: sessionCookie },
    });
    expect(res.status).toBe(404);
    const json = await res.json();
    expect(json.error.message).toBe('Job not found');
  });
});
