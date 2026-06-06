import { describe, it, expect, beforeAll } from 'bun:test';
import { createHash } from 'crypto';
import sql from '../src/infrastructure/db/client';

let accountId: string;

beforeAll(async () => {
  await sql`TRUNCATE transactions CASCADE`;
  const accounts = await sql`SELECT id FROM accounts LIMIT 1`;
  if (accounts.length === 0) {
    throw new Error('No seeded accounts found');
  }
  accountId = accounts[0].id;
});

describe('Import Deduplication Tests', () => {
  it('skips duplicate transactions by import_hash via ON CONFLICT DO NOTHING', async () => {
    const date = '2026-06-01';
    const amount = '100.0000';
    const description = 'Legitimate Purchase';
    
    // Compute SHA-256 import_hash (REQ-4.5)
    const hash = createHash('sha256')
      .update(`${date}|${amount}|${description}`)
      .digest('hex');

    // First insert
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
      VALUES (${accountId}, 'expense', ${amount}, ${description}, ${date}, ${hash})
    `;

    // Attempt second duplicate insert
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
      VALUES (${accountId}, 'expense', ${amount}, ${description}, ${date}, ${hash})
      ON CONFLICT (import_hash) DO NOTHING
    `;

    // Verify only 1 row exists
    const rows = await sql`
      SELECT COUNT(*) as count FROM transactions WHERE import_hash = ${hash}
    `;
    expect(Number(rows[0].count)).toBe(1);
  });

  it('proves that SHA-256 generation is deterministic', () => {
    const input = '2026-06-01|100.00|Legitimate Purchase';
    
    const hash1 = createHash('sha256').update(input).digest('hex');
    const hash2 = createHash('sha256').update(input).digest('hex');
    
    expect(hash1).toBe(hash2);
    expect(hash1.length).toBe(64);
  });
});
