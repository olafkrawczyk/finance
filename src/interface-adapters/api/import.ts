import { Hono } from 'hono';
import { requireAuth } from './auth';
import { enqueueImportJob, getImportStatus, detectFormat } from '../../core/import/use-cases';
import { ImportUploadSchema } from '../../application/schemas/import';
import iconv from 'iconv-lite';

export const importRoutes = new Hono();

importRoutes.post('/', requireAuth, async (c) => {
  try {
    const formData = await c.req.formData();
    const file = formData.get('csv');
    const accountId = formData.get('account_id');

    if (!file || !(file instanceof File)) {
      return c.json({ data: null, error: { message: 'CSV file required' }, meta: null }, 400);
    }

    const validation = ImportUploadSchema.safeParse({
      account_id: accountId,
    });
    if (!validation.success) {
      return c.json(
        { data: null, error: { message: 'Validation failed', details: validation.error.flatten() }, meta: null },
        400
      );
    }

    // Decode as windows-1250 to support Polish banking CSV encoding (02-REVIEWS.md)
    const arrayBuffer = await file.arrayBuffer();
    const csvContent = iconv.decode(Buffer.from(arrayBuffer), 'windows-1250');

    const bank_format = detectFormat(csvContent);

    const user = c.get('user');

    const { job_id } = await enqueueImportJob({
      account_id: accountId as string,
      csv_content: csvContent,
      bank_format,
      userId: user.id,
    });

    return c.json({ data: { job_id }, error: null, meta: null }, 202);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});

importRoutes.get('/:job_id', requireAuth, async (c) => {
  try {
    const jobId = c.req.param('job_id');
    const user = c.get('user');
    const job = await getImportStatus(jobId, user.id);
    if (!job) {
      return c.json({ data: null, error: { message: 'Job not found' }, meta: null }, 404);
    }
    return c.json({ data: job, error: null, meta: null }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});
