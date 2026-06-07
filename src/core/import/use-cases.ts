import sql from '../../infrastructure/db/client';
import type { ImportJob } from './entities';

/**
 * Detects the bank format from the CSV content.
 * Returns 'ing' if the headers match ING, else 'ipko'.
 */
export function detectFormat(content: string): 'ing' | 'ipko' {
  // Polish bank ING CSVs typically contain Polish headers/content like 'Data transakcji'
  if (content.includes('Data transakcji')) {
    return 'ing';
  }
  return 'ipko';
}

/**
 * Enqueues an import job atomically.
 * Creates a job record in import_jobs and puts a message in pgmq import_queue.
 */
export async function enqueueImportJob(payload: {
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
  userId: string;
}): Promise<{ job_id: string; msg_id: number }> {
  return await sql.begin(async (sql) => {
    // 1. Insert pending job
    const [job] = await sql`
      INSERT INTO import_jobs (account_id, user_id, status)
      VALUES (${payload.account_id}, ${payload.userId}, 'pending')
      RETURNING id
    `;

    // 2. Enqueue the work item
    const [sendResult] = await sql`
      SELECT pgmq.send('import_queue', ${JSON.stringify({
        job_id: job.id,
        account_id: payload.account_id,
        csv_content: payload.csv_content,
        bank_format: payload.bank_format,
        user_id: payload.userId,
      })}::jsonb) as msg_id
    `;

    return { job_id: job.id, msg_id: Number(sendResult.msg_id) };
  });
}

/**
 * Gets the status of an import job.
 */
export async function getImportStatus(jobId: string, userId: string): Promise<ImportJob | undefined> {
  const [row] = await sql`
    SELECT * FROM import_jobs WHERE id = ${jobId} AND user_id = ${userId}
  `;
  return row as ImportJob | undefined;
}
