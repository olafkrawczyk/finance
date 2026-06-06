import sql from './client';

export async function healthDb(): Promise<{ db: boolean; pgmq: boolean }> {
  try {
    await sql`SELECT 1`;
    const queues = await sql`SELECT queue_name FROM pgmq.list_queues()`;
    const pgmqReady = queues.some((q: { queue_name: string }) => q.queue_name === 'analysis_queue');
    return { db: true, pgmq: pgmqReady };
  } catch {
    return { db: false, pgmq: false };
  }
}
