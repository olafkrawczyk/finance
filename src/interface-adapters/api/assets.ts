import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { requireAuth } from './auth';
import { CreateAssetSchema, UpdateAssetSchema } from '../../application/schemas/assets';
import { listAssets, createAsset, getAsset, updateAsset, deleteAsset, listAssetSnapshots } from '../../core/assets/use-cases';

export const assetsRoutes = new Hono();

// GET /assets/:id/snapshots — asset value snapshot history
assetsRoutes.get('/:id/snapshots', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id');
    // Verify the asset belongs to the current user
    const asset = await getAsset(id, user.id);
    if (!asset) {
      return c.json({ data: null, error: { message: 'Not found' }, meta: null }, 404);
    }
    const snapshots = await listAssetSnapshots(id);
    return c.json({ data: snapshots, error: null, meta: { total: snapshots.length } });
  } catch (err) {
    return c.json({ data: null, error: { message: err instanceof Error ? err.message : 'Internal error' }, meta: null }, 500);
  }
});

// GET /assets
assetsRoutes.get('/', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const rows = await listAssets(user.id);
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
      const user = c.get('user');
      const input = c.req.valid('json');
      const row = await createAsset(input.name, input.value, user.id);
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
      const user = c.get('user');
      const input = c.req.valid('json');
      const row = await updateAsset(id, input.name, input.value, user.id);
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
    const user = c.get('user');
    const deleted = await deleteAsset(id, user.id);
    if (!deleted) {
      return c.json({ data: null, error: { message: 'Asset not found' }, meta: null }, 404);
    }
    return c.json({ data: { success: true }, error: null, meta: null }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});
