import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { CreateOpeningBalanceSchema, UpdateOpeningBalanceSchema } from '../../application/schemas/ledger';
import { createOpeningBalance, updateOpeningBalance, listOpeningBalances } from '../../core/ledger/use-cases';

export const openingBalanceRoutes = new Hono();

// GET /opening-balance
openingBalanceRoutes.get('/', async (c) => {
  try {
    const year = c.req.query('year');
    const month = c.req.query('month');
    const rows = await listOpeningBalances({
      year: year ? Number(year) : undefined,
      month: month ? Number(month) : undefined,
    });
    return c.json(
      { data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

// POST /opening-balance
openingBalanceRoutes.post(
  '/',
  zValidator('json', CreateOpeningBalanceSchema, (result, c) => {
    if (!result.success) {
      return c.json({ data: null, error: { message: 'Validation failed' }, meta: null }, 400);
    }
  }),
  async (c) => {
    try {
      const input = c.req.valid('json');
      const row = await createOpeningBalance(input);
      return c.json({ data: row, error: null, meta: null }, 201);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      const status = message.includes('unique') || message.includes('duplicate') ? 409 : 500;
      return c.json({ data: null, error: { message }, meta: null }, status);
    }
  }
);

// PUT /opening-balance/:id
openingBalanceRoutes.put(
  '/:id',
  zValidator('json', UpdateOpeningBalanceSchema, (result, c) => {
    if (!result.success) {
      return c.json({ data: null, error: { message: 'Validation failed' }, meta: null }, 400);
    }
  }),
  async (c) => {
    try {
      const id = c.req.param('id');
      const input = c.req.valid('json');
      const row = await updateOpeningBalance(id, input);
      if (!row) {
        return c.json({ data: null, error: { message: 'Not found' }, meta: null }, 404);
      }
      return c.json({ data: row, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);
