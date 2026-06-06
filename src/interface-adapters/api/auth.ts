import { createMiddleware } from 'hono/factory';
import { auth } from '../../auth';

export const requireAuth = createMiddleware(async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  if (!session) {
    return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
  }
  c.set('user', session.user);
  c.set('session', session.session);
  await next();
});
