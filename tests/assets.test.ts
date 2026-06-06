import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

let sessionCookie: string;

beforeAll(async () => {
  // Clear the assets table
  await sql`TRUNCATE assets CASCADE`;
  // Clean up user sessions to avoid conflicts
  await sql`TRUNCATE "session", "account", "user", "verification" CASCADE`;

  // Set up session cookie for the integration tests
  const res = await auth.api.signUpEmail({
    body: {
      email: 'assets-test@example.com',
      password: 'testpassword123',
      name: 'Assets Test User',
    },
    asResponse: true,
  });
  const setCookie = res.headers.get('set-cookie');
  if (!setCookie) {
    throw new Error('Failed to get session cookie for integration tests');
  }
  sessionCookie = setCookie;
});

afterAll(async () => {
  // Clean up assets table at the end
  await sql`TRUNCATE assets CASCADE`;
  await sql`TRUNCATE "session", "account", "user", "verification" CASCADE`;
});

describe('Assets API', () => {
  it('rejects requests without authentication with 401', async () => {
    const res = await app.request('/assets');
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.data).toBeNull();
    expect(json.error.message).toBe('Unauthorized');
  });

  it('lists assets initially as empty array', async () => {
    const res = await app.request('/assets', {
      headers: { Cookie: sessionCookie },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toEqual([]);
    expect(json.error).toBeNull();
  });

  let createdAssetId: string;

  it('creates a new asset with 201', async () => {
    const res = await app.request('/assets', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: sessionCookie,
      },
      body: JSON.stringify({
        name: 'Bitcoin',
        value: 125000.50,
      }),
    });
    expect(res.status).toBe(201);
    const json = await res.json();
    expect(json.data.id).toBeDefined();
    expect(json.data.name).toBe('Bitcoin');
    // Postgres numeric returns as string
    expect(json.data.value).toBe('125000.5000');
    expect(json.error).toBeNull();
    createdAssetId = json.data.id;
  });

  it('rejects duplicate asset name with 409', async () => {
    const res = await app.request('/assets', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: sessionCookie,
      },
      body: JSON.stringify({
        name: 'Bitcoin',
        value: 5000.00,
      }),
    });
    expect(res.status).toBe(409);
    const json = await res.json();
    expect(json.data).toBeNull();
    expect(json.error.message).toBeDefined();
  });

  it('rejects creation with invalid validation fields with 400', async () => {
    const res = await app.request('/assets', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: sessionCookie,
      },
      body: JSON.stringify({
        name: '',
        value: -10,
      }),
    });
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.data).toBeNull();
    expect(json.error.message).toBe('Validation failed');
  });

  it('lists assets with the newly created asset', async () => {
    const res = await app.request('/assets', {
      headers: { Cookie: sessionCookie },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data).toHaveLength(1);
    expect(json.data[0].id).toBe(createdAssetId);
    expect(json.data[0].name).toBe('Bitcoin');
  });

  it('updates the asset details with 200', async () => {
    const res = await app.request(`/assets/${createdAssetId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Cookie: sessionCookie,
      },
      body: JSON.stringify({
        name: 'Gold ETF',
        value: 130000.00,
      }),
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.id).toBe(createdAssetId);
    expect(json.data.name).toBe('Gold ETF');
    expect(json.data.value).toBe('130000.0000');
  });

  it('returns 404 for updating non-existent asset ID', async () => {
    const res = await app.request('/assets/00000000-0000-0000-0000-000000000000', {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Cookie: sessionCookie,
      },
      body: JSON.stringify({
        name: 'Nonexistent',
        value: 100.00,
      }),
    });
    expect(res.status).toBe(404);
  });

  it('deletes the asset with 200', async () => {
    const res = await app.request(`/assets/${createdAssetId}`, {
      method: 'DELETE',
      headers: { Cookie: sessionCookie },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.data.success).toBe(true);

    // Verify it is gone
    const listRes = await app.request('/assets', {
      headers: { Cookie: sessionCookie },
    });
    const listJson = await listRes.json();
    expect(listJson.data).toEqual([]);
  });
});
