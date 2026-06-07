import { Hono } from 'hono';
import { mkdir } from 'fs/promises';
import path from 'path';
import { requireAuth } from './auth';
import sql from '../../infrastructure/db/client';

export const migrationRoutes = new Hono();

const MAX_FILE_SIZE_BYTES = 20 * 1024 * 1024; // 20MB
const UPLOADS_DIR = path.resolve(process.cwd(), 'scratch', 'uploads');
const PKO_PERSONAL_ACCOUNT_NAME = 'IPKO';
const QUEUE_NAME = 'import_queue';

migrationRoutes.post('/excel', requireAuth, async (c) => {
  try {
    const formData = await c.req.formData();
    const file = formData.get('file') ?? formData.get('excel');

    if (!file || !(file instanceof File)) {
      return c.json({ data: null, error: { message: 'Excel file required (field "file" or "excel")' }, meta: null }, 400);
    }

    if (file.size > MAX_FILE_SIZE_BYTES) {
      return c.json({ data: null, error: { message: 'File exceeds the 20MB size limit' }, meta: null }, 413);
    }

    // Extract userId from session — never trust client-provided ID (SCOPE-06)
    const user = c.get('user');

    // Generate a server-side random UUID — never trust client-provided IDs (T-MIG-04)
    const jobId = crypto.randomUUID();

    await mkdir(UPLOADS_DIR, { recursive: true });
    const filePath = path.join(UPLOADS_DIR, `${jobId}.xlsx`);

    // Stream the upload to disk asynchronously to protect server memory (T-MIG-02)
    const arrayBuffer = await file.arrayBuffer();
    await Bun.write(filePath, arrayBuffer);

    const result = await sql.begin(async (sql) => {
      await sql`DELETE FROM import_jobs WHERE user_id = ${user.id}`;
      await sql`DELETE FROM transactions WHERE user_id = ${user.id}`;
      await sql`DELETE FROM monthly_opening_balances WHERE user_id = ${user.id}`;
      await sql`DELETE FROM insights WHERE user_id = ${user.id}`;

      // PKO Personal survives the cascade truncate (it's an `accounts` row) and
      // serves as the placeholder account reference for the migration job record.
      const [ipkoAccount] = await sql`
        SELECT id FROM accounts WHERE name = ${PKO_PERSONAL_ACCOUNT_NAME} LIMIT 1
      `;
      if (!ipkoAccount) {
        throw new Error(`Seeded account "${PKO_PERSONAL_ACCOUNT_NAME}" not found`);
      }

      const [job] = await sql`
        INSERT INTO import_jobs (id, account_id, user_id, status)
        VALUES (${jobId}, ${ipkoAccount.id}, ${user.id}, 'pending')
        RETURNING id
      `;

      const [sendResult] = await sql`
        SELECT pgmq.send(${QUEUE_NAME}, ${JSON.stringify({
          job_id: jobId,
          type: 'excel_migration',
          file_path: filePath,
          user_id: user.id,
        })}::jsonb) as msg_id
      `;

      return { jobId: job.id, msgId: Number(sendResult.msg_id) };
    });

    return c.json({ data: { job_id: result.jobId }, error: null, meta: null }, 202);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});
