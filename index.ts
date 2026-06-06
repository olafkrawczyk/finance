import { Hono } from 'hono';
import { ledgerRoutes } from './src/interface-adapters/api/ledger';
import { openingBalanceRoutes } from './src/interface-adapters/api/opening-balance';
import { referenceRoutes } from './src/interface-adapters/api/reference';
import { healthDb } from './src/infrastructure/db/health';

import { cors } from 'hono/cors';
import { auth } from './src/auth';

const app = new Hono<{
  Variables: {
    user: typeof auth.$Infer.Session.user | null;
    session: typeof auth.$Infer.Session.session | null;
  };
}>();

// CORS for auth routes
app.use(
  '/api/auth/*',
  cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    allowHeaders: ['Content-Type', 'Authorization'],
    allowMethods: ['POST', 'GET', 'OPTIONS'],
    credentials: true,
  })
);

// Mount Better Auth handler
app.on(['POST', 'GET'], '/api/auth/*', (c) => auth.handler(c.req.raw));

// Session middleware for all routes
app.use('*', async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  c.set('user', session?.user ?? null);
  c.set('session', session?.session ?? null);
  await next();
});

// Health
app.get('/health', (c) => c.json({ data: { ok: true }, error: null, meta: null }));
app.get('/health/db', async (c) => {
  const result = await healthDb();
  return c.json({ data: result, error: null, meta: null });
});

import { importRoutes } from './src/interface-adapters/api/import';
import { insightsRoutes } from './src/interface-adapters/api/insights';

// Domain routes
app.route('/transactions', ledgerRoutes);
app.route('/opening-balance', openingBalanceRoutes);
app.route('/import', importRoutes);
app.route('/insights', insightsRoutes);
app.route('/', referenceRoutes);

// Export for test suites
export { app };

// Bun-native server export — no @hono/node-server
export default {
  port: Number(process.env.PORT) || 3000,
  fetch: app.fetch,
};
