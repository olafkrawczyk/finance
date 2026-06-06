import { describe, it, expect, beforeAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

let sessionCookie: string;

beforeAll(async () => {
  // Clear any existing session/user data to isolate tests
  await sql`TRUNCATE "session", "account", "user", "verification" CASCADE`;

  // Create a test user via Better Auth
  const res = await auth.api.signUpEmail({
    body: {
      email: 'test@example.com',
      password: 'testpassword123',
      name: 'Test User',
    },
    asResponse: true,
  });

  const setCookie = res.headers.get('set-cookie');
  if (!setCookie) {
    throw new Error('Failed to obtain session cookie from signUpEmail');
  }
  sessionCookie = setCookie;
});

describe('Auth Integration Tests', () => {
  it('POST /transactions returns 401 without session', async () => {
    const res = await app.request('/transactions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error.message).toBe('Unauthorized');
  });

  it('GET /accounts returns 200 with valid session cookie', async () => {
    const res = await app.request('/accounts', {
      headers: {
        Cookie: sessionCookie,
      },
    });
    expect(res.status).toBe(200);
  });

  it('GET /api/auth/get-session returns session details', async () => {
    const res = await app.request('/api/auth/get-session', {
      headers: {
        Cookie: sessionCookie,
      },
    });
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.user).toBeDefined();
    expect(json.user.email).toBe('test@example.com');
  });
});
