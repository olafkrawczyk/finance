import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { requireAuth } from './auth';
import { listAccounts, listCategories, createAccount, updateAccount, deleteAccount } from '../../core/reference/use-cases';
import { CreateAccountSchema, UpdateAccountSchema } from '../../application/schemas/accounts';

export const referenceRoutes = new Hono();

export const accountsRoutes = new Hono();

accountsRoutes.use('*', requireAuth);

// POST /accounts
accountsRoutes.post(
  '/',
  zValidator('json', CreateAccountSchema, (result, c) => {
    if (!result.success) {
      return c.json({ data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null }, 400);
    }
  }),
  async (c) => {
    try {
      const user = c.get('user');
      const input = c.req.valid('json');
      const row = await createAccount(input.name, input.type, input.currency, input.starting_balance, input.starting_balance_date, user.id);
      return c.json({ data: row, error: null, meta: null }, 201);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      const status = message.includes('unique') || message.includes('duplicate') ? 409 : 500;
      return c.json({ data: null, error: { message }, meta: null }, status);
    }
  }
);

// PUT /accounts/:id
accountsRoutes.put(
  '/:id',
  zValidator('json', UpdateAccountSchema, (result, c) => {
    if (!result.success) {
      return c.json({ data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null }, 400);
    }
  }),
  async (c) => {
    try {
      const id = c.req.param('id');
      const user = c.get('user');
      const input = c.req.valid('json');
      const row = await updateAccount(id, input.name, input.starting_balance, input.starting_balance_date, user.id);
      if (!row) {
        return c.json({ data: null, error: { message: 'Not found' }, meta: null }, 404);
      }
      return c.json({ data: row, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      const status = message.includes('unique') || message.includes('duplicate') ? 409 : 500;
      return c.json({ data: null, error: { message }, meta: null }, status);
    }
  }
);

// DELETE /accounts/:id
accountsRoutes.delete('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const user = c.get('user');
    await deleteAccount(id, user.id);
    return c.newResponse(null, 204);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    if (message.includes('Cannot delete account')) {
      return c.json({ data: null, error: { message }, meta: null }, 409);
    }
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

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
