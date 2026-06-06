import { describe, it, expect, beforeAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';

beforeAll(async () => {
  await sql`DELETE FROM pgmq.q_analysis_queue`;
});

describe('PGMQ queue operations', () => {
  it.skipIf(!process.env.DATABASE_URL)('round-trips a message through the analysis_queue', async () => {
    // Send a message
    const sendResult = await sql`
      SELECT pgmq.send('analysis_queue', '{"test": "hello"}') as msg_id
    `;
    expect(sendResult).toHaveLength(1);
    const msgId = Number(sendResult[0].msg_id);
    expect(msgId).toBeGreaterThan(0);

    // Read the message
    const readResult = await sql`
      SELECT * FROM pgmq.read('analysis_queue', 30, 1)
    `;
    expect(readResult).toHaveLength(1);
    expect(Number(readResult[0].msg_id)).toBe(msgId);
    expect(readResult[0].message).toEqual({ test: 'hello' });

    // Delete the message
    const deleteResult = await sql`
      SELECT pgmq.delete('analysis_queue', ${msgId}::bigint) as success
    `;
    expect(deleteResult).toHaveLength(1);
    expect(deleteResult[0].success).toBe(true);
  });
});
