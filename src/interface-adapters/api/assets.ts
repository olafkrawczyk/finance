import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { requireAuth } from './auth';
import { CreateAssetSchema, UpdateAssetSchema } from '../../application/schemas/assets';
import { listAssets, createAsset, updateAsset, deleteAsset } from '../../core/assets/use-cases';

export const assetsRoutes = new Hono();

// GET /assets
assetsRoutes.get('/', requireAuth, async (c) => {
  try {
    const rows = await listAssets();
    return c.json({ data: rows, error: null, meta: null }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

// POST /assets
assetsRoutes.post(
  '/',
  requireAuth,
  zValidator('json', CreateAssetSchema, (result, c) => {
    if (!result.success) {
      return c.json({ data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null }, 400);
    }
  }),
  async (c) => {
    try {
      const input = c.req.valid('json');
      const row = await createAsset(input.name, input.value);
      return c.json({ data: row, error: null, meta: null }, 201);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      const status = message.includes('unique') || message.includes('duplicate') ? 409 : 500;
      return c.json({ data: null, error: { message }, meta: null }, status);
    }
  }
);

// PUT /assets/:id
assetsRoutes.put(
  '/:id',
  requireAuth,
  zValidator('json', UpdateAssetSchema, (result, c) => {
    if (!result.success) {
      return c.json({ data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null }, 400);
    }
  }),
  async (c) => {
    try {
      const id = c.req.param('id');
      const input = c.req.valid('json');
      const row = await updateAsset(id, input.name, input.value);
      if (!row) {
        return c.json({ data: null, error: { message: 'Asset not found' }, meta: null }, 404);
      }
      return c.json({ data: row, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      const status = message.includes('unique') || message.includes('duplicate') ? 409 : 500;
      return c.json({ data: null, error: { message }, meta: null }, status);
    }
  }
);

// DELETE /assets/:id
assetsRoutes.delete('/:id', requireAuth, async (c) => {
  try {
    const id = c.req.param('id');
    await deleteAsset(id);
    return c.json({ data: { success: true }, error: null, meta: null }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});
