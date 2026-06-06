import { Hono } from 'hono';
import sql from '../../infrastructure/db/client';

export const referenceRoutes = new Hono();

referenceRoutes.get('/accounts', async (c) => {
  try {
    const rows = await sql`SELECT * FROM accounts ORDER BY name`;
    return c.json(
      { data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

referenceRoutes.get('/categories', async (c) => {
  try {
    const rows = await sql`SELECT * FROM categories ORDER BY name`;
    return c.json(
      { data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});
