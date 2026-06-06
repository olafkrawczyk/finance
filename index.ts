import { Hono } from 'hono';
import { ledgerRoutes } from './src/interface-adapters/api/ledger';
import { openingBalanceRoutes } from './src/interface-adapters/api/opening-balance';
import { referenceRoutes } from './src/interface-adapters/api/reference';
import { healthDb } from './src/infrastructure/db/health';

const app = new Hono();

// Health
app.get('/health', (c) => c.json({ data: { ok: true }, error: null, meta: null }));
app.get('/health/db', async (c) => {
  const result = await healthDb();
  return c.json({ data: result, error: null, meta: null });
});

// Domain routes
app.route('/transactions', ledgerRoutes);
app.route('/opening-balance', openingBalanceRoutes);
app.route('/', referenceRoutes);

// Export for test suites
export { app };

// Bun-native server export — no @hono/node-server
export default {
  port: Number(process.env.PORT) || 3000,
  fetch: app.fetch,
};
