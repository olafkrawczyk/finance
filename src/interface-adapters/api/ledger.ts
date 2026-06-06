import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { CreateTransactionSchema, ListTransactionsQuerySchema, AssignCategorySchema } from '../../application/schemas/ledger';
import { createTransaction, listTransactions, getMonthlySummary } from '../../core/ledger/use-cases';
import { requireAuth } from './auth';
import sql from '../../infrastructure/db/client';

export const ledgerRoutes = new Hono();

// POST /transactions
ledgerRoutes.post(
  '/',
  requireAuth,
  zValidator('json', CreateTransactionSchema, (result, c) => {
    if (!result.success) {
      return c.json(
        { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
        400
      );
    }
  }),
  async (c) => {
    try {
      const input = c.req.valid('json');
      const tx = await createTransaction(input);
      return c.json({ data: tx, error: null, meta: null }, 201);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      const status = message.includes('immutable') ? 409 : 500;
      return c.json({ data: null, error: { message }, meta: null }, status);
    }
  }
);

// GET /transactions
ledgerRoutes.get(
  '/',
  requireAuth,
  zValidator('query', ListTransactionsQuerySchema, (result, c) => {
    if (!result.success) {
      return c.json(
        { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
        400
      );
    }
  }),
  async (c) => {
    try {
      const query = c.req.valid('query');
      const { rows, total } = await listTransactions(query);
      return c.json(
        {
          data: rows,
          error: null,
          meta: { total, page: query.page, per_page: query.per_page },
        },
        200
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);

// GET /summary
ledgerRoutes.get('/summary', requireAuth, async (c) => {
  try {
    const rows = await getMonthlySummary();
    return c.json(
      { data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

// PATCH /transactions/:id/category
ledgerRoutes.patch(
  '/:id/category',
  requireAuth,
  zValidator('json', AssignCategorySchema, (result, c) => {
    if (!result.success) {
      return c.json(
        { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
        400
      );
    }
  }),
  async (c) => {
    try {
      const id = c.req.param('id');
      const { category_id } = c.req.valid('json');
      const [updated] = await sql`
        UPDATE transactions SET category_id = ${category_id}
        WHERE id = ${id} AND category_id IS NULL
        RETURNING *
      `;
      if (!updated) {
        return c.json(
          { data: null, error: { message: 'Transaction not found or already categorized' }, meta: null },
          404
        );
      }
      return c.json({ data: updated, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);
