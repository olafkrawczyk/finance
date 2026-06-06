import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import {
  ListInsightsQuerySchema,
  DismissInsightSchema,
  GenerateInsightsSchema,
} from '../../application/schemas/insights';
import {
  listInsights,
  dismissInsight,
  enqueueAnalysisJob,
  getInsightsForDashboard,
} from '../../core/insights/use-cases';
import { requireAuth } from './auth';

const uuidSchema = z.uuid();

export const insightsRoutes = new Hono();

// GET /insights
insightsRoutes.get(
  '/',
  requireAuth,
  zValidator('query', ListInsightsQuerySchema, (result, c) => {
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
      const user = c.get('user');
      if (!user) {
        return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
      }

      const { rows, total } = await listInsights({
        userId: user.id,
        type: query.type,
        dismissed: query.dismissed,
        page: query.page,
        per_page: query.per_page,
      });

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

// GET /insights/dashboard
insightsRoutes.get('/dashboard', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) {
      return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
    }

    const rows = await getInsightsForDashboard(user.id, 3);
    return c.json(
      { data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

// GET /insights/forecast
insightsRoutes.get('/forecast', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) {
      return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
    }

    // fetch forecast-type insights for the current user
    const { rows } = await listInsights({
      userId: user.id,
      type: 'forecast',
      dismissed: false,
      page: 1,
      per_page: 10,
    });

    return c.json(
      { data: rows, error: null, meta: { total: rows.length } },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

// PATCH /insights/:id/dismiss
insightsRoutes.patch(
  '/:id/dismiss',
  requireAuth,
  zValidator('json', DismissInsightSchema, (result, c) => {
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
          { data: null, error: { message: 'Invalid insight id' }, meta: null },
          400
        );
      }
      const id = parseResult.data;
      const user = c.get('user');
      if (!user) {
        return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
      }

      const updated = await dismissInsight(id, user.id);
      if (!updated) {
        return c.json(
          { data: null, error: { message: 'Insight not found' }, meta: null },
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

// POST /insights/generate
insightsRoutes.post(
  '/generate',
  requireAuth,
  zValidator('json', GenerateInsightsSchema, (result, c) => {
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
      if (!user) {
        return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
      }

      const { msg_id } = await enqueueAnalysisJob(user.id);
      return c.json(
        { data: { msg_id }, error: null, meta: { message: 'Analysis job enqueued' } },
        202
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);
