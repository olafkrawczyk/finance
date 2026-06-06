import sql from './client';

export async function healthDb(): Promise<{ db: boolean; pgmq: boolean; import_queue: boolean }> {
  try {
    await sql`SELECT 1`
    const queues = await sql`SELECT queue_name FROM pgmq.list_queues()`
    const pgmqReady = queues.some((q: any) => q.queue_name === 'analysis_queue')
    const importQueueReady = queues.some((q: any) => q.queue_name === 'import_queue')
    return { db: true, pgmq: pgmqReady, import_queue: importQueueReady }
  } catch {
    return { db: false, pgmq: false, import_queue: false }
  }
}
