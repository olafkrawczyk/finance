import { Hono } from 'hono';
import { requireAuth } from './auth';
import { listAccounts, listCategories } from '../../core/reference/use-cases';

export const referenceRoutes = new Hono();

referenceRoutes.get('/accounts', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const rows = await listAccounts(user.id);
    return c.json(
      { data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

referenceRoutes.get('/categories', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const rows = await listCategories(user.id);
    return c.json(
      { data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});
