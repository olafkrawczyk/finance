import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { CreateTransactionSchema, ListTransactionsQuerySchema, AssignCategorySchema, UpdateTransactionSchema } from '../../application/schemas/ledger';
import { createTransaction, listTransactions, getMonthlySummary, getTransaction, updateTransaction, deleteTransaction, assignCategory } from '../../core/ledger/use-cases';
import { requireAuth } from './auth';

const uuidSchema = z.uuid();

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
      const user = c.get('user');
      const input = c.req.valid('json');
      const tx = await createTransaction({ ...input, userId: user.id });
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
      const user = c.get('user');
      const query = c.req.valid('query');
      const { rows, total } = await listTransactions({ ...query, userId: user.id });
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
    const user = c.get('user');
    const rows = await getMonthlySummary(user.id);
    return c.json(
      { data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

// GET /transactions/:id — single transaction (for edit form prefill)
ledgerRoutes.get(
  '/:id',
  requireAuth,
  async (c) => {
    try {
      const rawId = c.req.param('id');
      const parseResult = uuidSchema.safeParse(rawId);
      if (!parseResult.success) {
        return c.json({ data: null, error: { message: 'Invalid transaction id' }, meta: null }, 400);
      }
      const id = parseResult.data;
      const user = c.get('user');
      const tx = await getTransaction(id, user.id);
      if (!tx) {
        return c.json({ data: null, error: { message: 'Transaction not found' }, meta: null }, 404);
      }
      return c.json({ data: tx, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);

// PUT /transactions/:id — update all fields (no re-analysis enqueue per D-04)
ledgerRoutes.put(
  '/:id',
  requireAuth,
  zValidator('json', UpdateTransactionSchema, (result, c) => {
    if (!result.success) {
      return c.json(
        { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
        400
      );
    }
  }),
  async (c) => {
    try {
      const rawId = c.req.param('id');
      const parseResult = uuidSchema.safeParse(rawId);
      if (!parseResult.success) {
        return c.json({ data: null, error: { message: 'Invalid transaction id' }, meta: null }, 400);
      }
      const id = parseResult.data;
      const user = c.get('user');
      const input = c.req.valid('json');
      const tx = await updateTransaction(id, input, user.id);
      return c.json({ data: tx, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      if (message.includes('not found')) {
        return c.json({ data: null, error: { message }, meta: null }, 404);
      }
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);

// DELETE /transactions/:id — atomic hard delete with hash clearing + insight cleanup
ledgerRoutes.delete(
  '/:id',
  requireAuth,
  async (c) => {
    try {
      const rawId = c.req.param('id');
      const parseResult = uuidSchema.safeParse(rawId);
      if (!parseResult.success) {
        return c.json({ data: null, error: { message: 'Invalid transaction id' }, meta: null }, 400);
      }
      const id = parseResult.data;
      const user = c.get('user');
      await deleteTransaction(id, user.id);
      return c.json({ data: { success: true }, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);

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
      const rawId = c.req.param('id');
      const parseResult = uuidSchema.safeParse(rawId);
      if (!parseResult.success) {
        return c.json(
          { data: null, error: { message: 'Invalid transaction id' }, meta: null },
          400
        );
      }
      const id = parseResult.data;
      const user = c.get('user');
      const { category_id } = c.req.valid('json');
      const updated = await assignCategory(id, category_id, user.id);
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
