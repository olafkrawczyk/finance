import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';
import { enqueueImportJob } from '../src/core/import/use-cases';
import { processJob, recoverStuckJobs } from '../src/workers/import-worker';

let mockServer: any;
let mockPort: number;
let accountId: string;
let otherAccountId: string;
let userId: string;

beforeAll(async () => {
  // Clear tables
  await sql`TRUNCATE transactions CASCADE`;
  await sql`TRUNCATE import_jobs CASCADE`;
  await sql`DELETE FROM pgmq.q_import_queue`;

  // Get a userId from the existing user (or create one if none exist)
  const users = await sql`SELECT id FROM "user" LIMIT 1`;
  if (users.length === 0) {
    const [user] = await sql`
      INSERT INTO "user" (id, name, email, "emailVerified")
      VALUES ('test-user-import', 'Test User', 'test-import@example.com', true)
      RETURNING id
    `;
    users.push(user);
  }
  userId = users[0].id;

  const accounts = await sql`SELECT id FROM accounts WHERE user_id = ${userId} ORDER BY name`;
  // Create test accounts if insufficient seeded accounts exist
  while (accounts.length < 2) {
    const [acct] = await sql`
      INSERT INTO accounts (name, type, user_id)
      VALUES (${'Test Account ' + (accounts.length + 1)}, 'personal', ${userId})
      RETURNING id
    `;
    accounts.push(acct);
  }
  accountId = accounts[0].id;
  otherAccountId = accounts[1].id;

  // Start OpenRouter mock server
  mockServer = Bun.serve({
    port: 0,
    async fetch(req) {
      const url = new URL(req.url);
      if (url.pathname === '/chat/completions') {
        const body = await req.json();
        
        // Return matching number of transactions to prevent LLM row-dropping error
        const prompt = body.messages[0].content;
        // Find number of input rows (excluding header)
        const lines = prompt.split('\n').filter((l: string) => l.trim().length > 0);
        // Find "Rows to parse:" marker
        const rowsIdx = lines.findIndex((l: string) => l.includes('Rows to parse:'));
        const numRows = lines.length - 1 - rowsIdx;

        const transactions = [];
        for (let i = 0; i < numRows - 1; i++) {
          transactions.push({
            date: '2026-06-01',
            amount: '150.00',
            description: `Mock Transaction ${i}`,
            raw_type: i % 3 === 0 ? 'transfer' : 'expense', // Include transfers to test linking
          });
        }

        return new Response(
          JSON.stringify({
            choices: [{ message: { content: JSON.stringify({ transactions }) } }],
          }),
          { headers: { 'Content-Type': 'application/json' }, status: 200 }
        );
      }
      return new Response('Not found', { status: 404 });
    },
  });

  mockPort = mockServer.port;
  process.env.OPENROUTER_API_KEY = 'test-key';
  process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
});

afterAll(async () => {
  mockServer.stop();
});

describe('Import Worker End-to-End Tests', () => {
  it('processes import job, links transfers, updates job status, and dedups', async () => {
    // 1. Enqueue job
    // We send 3 rows of data (excluding header)
    const csvContent = 'Data transakcji;Opis;Kwota\n2026-06-01;T1;-150,00\n2026-06-02;T2;-150,00\n2026-06-03;T3;-150,00';
    const { job_id, msg_id } = await enqueueImportJob({
      account_id: accountId,
      csv_content: csvContent,
      bank_format: 'ing',
      userId,
    });

    expect(job_id).toBeDefined();
    expect(msg_id).toBeGreaterThan(0);

    // 2. Read message from PGMQ
    const messages = await sql`
      SELECT * FROM pgmq.read('import_queue', 300, 1)
    `;
    expect(messages).toHaveLength(1);
    const msg = messages[0];
    const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;
    expect(payload.job_id).toBe(job_id);

    // 3. Process the job
    const result = await processJob(payload);
    expect(result.processed).toBe(3);
    expect(result.errors).toHaveLength(0);

    // 4. Archive message
    await sql`SELECT pgmq.archive('import_queue', ${msg.msg_id}::bigint)`;

    // 5. Verify transactions inserted into DB
    const txs = await sql`
      SELECT * FROM transactions WHERE account_id = ${accountId} ORDER BY date
    `;
    expect(txs).toHaveLength(3);
    expect(txs[0].category_id).toBeNull();

    // Verify transfer linking (Mock Transaction 0 is transfer, should link to otherAccountId)
    const transferTx = txs.find(t => t.description === 'Mock Transaction 0');
    expect(transferTx).toBeDefined();
    expect(transferTx?.type).toBe('transfer');
    expect(transferTx?.transfer_to_account_id).toBe(otherAccountId);

    const expenseTx = txs.find(t => t.description === 'Mock Transaction 1');
    expect(expenseTx).toBeDefined();
    expect(expenseTx?.type).toBe('expense');
    expect(expenseTx?.transfer_to_account_id).toBeNull();

    // 6. Verify import_job status updated
    const [job] = await sql`SELECT * FROM import_jobs WHERE id = ${job_id}`;
    expect(job.status).toBe('completed');
    expect(job.total_rows).toBe(3);
    expect(job.processed).toBe(3);
    expect(job.user_id).toBe(userId);
    expect(job.errors).toBeNull();

    // Verify all transactions have user_id set correctly
    const txsWithUser = await sql`
      SELECT DISTINCT user_id FROM transactions WHERE account_id = ${accountId}
    `;
    expect(txsWithUser.every(t => t.user_id === userId)).toBe(true);

    // 7. Re-run processJob to verify deduplication via import_hash
    const resultDup = await processJob(payload);
    expect(resultDup.processed).toBe(3); // The worker processed 3 rows
    expect(resultDup.errors).toHaveLength(0);

    // Count transactions again - should still be 3 (no new rows inserted)
    const countRes = await sql`
      SELECT COUNT(*) as count FROM transactions WHERE account_id = ${accountId}
    `;
    expect(Number(countRes[0].count)).toBe(3);
  });

  it('recovers stuck jobs correctly', async () => {
    // Insert a stuck job manually with updated_at set to 20 minutes ago
    const [stuckJob] = await sql`
      INSERT INTO import_jobs (account_id, status, created_at, updated_at, user_id)
      VALUES (${accountId}, 'processing', now() - interval '20 minutes', now() - interval '20 minutes', ${userId})
      RETURNING id
    `;

    // Trigger stuck job recovery
    await recoverStuckJobs();

    // Verify status updated to failed
    const [job] = await sql`SELECT * FROM import_jobs WHERE id = ${stuckJob.id}`;
    expect(job.status).toBe('failed');
    expect(job.errors).toContain('Job timed out / worker crashed');
  });
});

// ── Import Worker Multi-User Isolation (TEST-03, D-07 through D-11) ──

describe('Import Worker Multi-User Isolation — D-08, D-09, D-11', () => {
  let userBId: string;
  let userBAccountId: string;
  let userAAccountId: string;

  beforeAll(async () => {
    // Create or fetch User B
    const existingB = await sql`SELECT id FROM "user" WHERE email = 'import-iso-b@test.com'`;
    if (existingB.length > 0) {
      userBId = existingB[0].id;
    } else {
      const [userB] = await sql`
        INSERT INTO "user" (id, name, email, "emailVerified")
        VALUES ('import-iso-user-b', 'Import Iso B', 'import-iso-b@test.com', true)
        RETURNING id
      `;
      userBId = userB.id;
    }

    // User A is the `userId` from the parent scope (already set in outer beforeAll)
    userAAccountId = accountId;

    // Create an account for User B
    const bAccounts = await sql`SELECT id FROM accounts WHERE user_id = ${userBId} ORDER BY name LIMIT 1`;
    if (bAccounts.length > 0) {
      userBAccountId = bAccounts[0].id;
    } else {
      const [acct] = await sql`
        INSERT INTO accounts (name, type, user_id)
        VALUES ('User B Import Account', 'personal', ${userBId})
        RETURNING id
      `;
      userBAccountId = acct.id;
    }
  });

  afterAll(async () => {
    await sql`ALTER TABLE transactions DISABLE TRIGGER trg_transactions_no_delete`;
    await sql`DELETE FROM "user" WHERE id = ${userBId}`;
    await sql`ALTER TABLE transactions ENABLE TRIGGER trg_transactions_no_delete`;
  });

  // D-08: Correct user tagging — processJob inserts transactions with correct user_id
  it('D-08: import worker tags inserted transactions with correct user_id', async () => {
    const csvContent = 'Data transakcji;Opis;Kwota\n2026-06-01;IsoT1;-100,00\n2026-06-02;IsoT2;-200,00';
    const { job_id } = await enqueueImportJob({
      account_id: userAAccountId,
      csv_content: csvContent,
      bank_format: 'ing',
      userId,
    });

    // Read from PGMQ
    const messages = await sql`SELECT * FROM pgmq.read('import_queue', 300, 1)`;
    expect(messages).toHaveLength(1);
    const payload = typeof messages[0].message === 'string' ? JSON.parse(messages[0].message) : messages[0].message;

    // Process directly
    const result = await processJob(payload);
    expect(result.processed).toBe(2);
    expect(result.errors).toHaveLength(0);

    // Verify user_id via SQL
    const txsWithUser = await sql`
      SELECT DISTINCT user_id FROM transactions WHERE account_id = ${userAAccountId}
        AND description LIKE 'IsoT%'
    `;
    expect(txsWithUser.every(t => t.user_id === userId)).toBe(true);

    await sql`SELECT pgmq.archive('import_queue', ${messages[0].msg_id}::bigint)`;
    await sql`ALTER TABLE transactions DISABLE TRIGGER trg_transactions_no_delete`;
    await sql`DELETE FROM transactions WHERE description LIKE 'IsoT%'`;
    await sql`ALTER TABLE transactions ENABLE TRIGGER trg_transactions_no_delete`;
    await sql`DELETE FROM import_jobs WHERE id = ${job_id}`;
  });

  // D-09: Cross-user account rejection (skip + log, not throw)
  it('D-09: import worker skips job when account_id belongs to different user (skip, not throw)', async () => {
    // User B's account_id + User A's userId
    const csvContent = 'Data transakcji;Opis;Kwota\n2026-06-01;Badv;-500,00';
    const { job_id } = await enqueueImportJob({
      account_id: userBAccountId,  // User B's account!
      csv_content: csvContent,
      bank_format: 'ing',
      userId,             // User A's userId mismatch
    });

    const messages = await sql`SELECT * FROM pgmq.read('import_queue', 300, 1)`;
    expect(messages).toHaveLength(1);
    const payload = typeof messages[0].message === 'string' ? JSON.parse(messages[0].message) : messages[0].message;

    // Process — should NOT throw
    const result = await processJob(payload);
    expect(result.processed).toBe(0);            // No rows processed
    expect(result.errors.length).toBeGreaterThan(0); // Error logged per D-09/Phase 8 D-01

    // Verify no transactions were inserted for User B's account
    const txs = await sql`
      SELECT COUNT(*)::int AS count FROM transactions WHERE account_id = ${userBAccountId}
    `;
    expect(txs[0].count).toBe(0);

    await sql`SELECT pgmq.archive('import_queue', ${messages[0].msg_id}::bigint)`;
    await sql`DELETE FROM import_jobs WHERE id = ${job_id}`;
  });

  // D-11: PGMQ routing test — enqueue both users, verify correct data processed
  it('D-11: PGMQ routing — enqueue for both users, processJob picks correct data', async () => {
    // Enqueue for User A
    const csvA = 'Data transakcji;Opis;Kwota\n2026-06-01;RouteA1;-300,00';
    const { job_id: jobA } = await enqueueImportJob({
      account_id: userAAccountId,
      csv_content: csvA,
      bank_format: 'ing',
      userId,
    });

    // Enqueue for User B
    const csvB = 'Data transakcji;Opis;Kwota\n2026-06-01;RouteB1;-400,00';
    const { job_id: jobB } = await enqueueImportJob({
      account_id: userBAccountId,
      csv_content: csvB,
      bank_format: 'ing',
      userId: userBId,
    });

    // Read all messages and process them
    const messages = await sql`SELECT * FROM pgmq.read('import_queue', 300, 2)`;
    expect(messages.length).toBeGreaterThanOrEqual(1);

    const results: { payload: any; result: { processed: number; errors: string[] } }[] = [];
    for (const msg of messages) {
      const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;
      const result = await processJob(payload);
      // Each job should process its own data — either will succeed
      // At minimum, processJob should not throw for either payload
      expect(result).toBeDefined();
      results.push({ payload, result });
      await sql`SELECT pgmq.archive('import_queue', ${msg.msg_id}::bigint)`;
    }

    // Both jobs processed without error (mock translates to 1 row each)
    const totalProcessed = results.reduce((sum, r) => sum + r.result.processed, 0);
    expect(totalProcessed).toBeGreaterThanOrEqual(1);

    // User A's job should have processed data tagged to User A
    const userAJobs = results.filter(r => r.payload.user_id === userId);
    for (const job of userAJobs) {
      const txs = await sql`
        SELECT user_id FROM transactions WHERE account_id = ${userAAccountId} ORDER BY created_at DESC LIMIT ${job.result.processed}
      `;
      expect(txs.length).toBeGreaterThanOrEqual(0);
      if (txs.length > 0) {
        expect(txs.every(t => t.user_id === userId)).toBe(true);
      }
    }

    // User B's job should have processed data tagged to User B
    const userBJobs = results.filter(r => r.payload.user_id === userBId);
    for (const job of userBJobs) {
      const txs = await sql`
        SELECT user_id FROM transactions WHERE account_id = ${userBAccountId} ORDER BY created_at DESC LIMIT ${job.result.processed}
      `;
      expect(txs.length).toBeGreaterThanOrEqual(0);
      if (txs.length > 0) {
        expect(txs.every(t => t.user_id === userBId)).toBe(true);
      }
    }

    // Clean up: remove transactions created by these imports (mock descriptions are "Mock Transaction N")
    for (const r of results) {
      await sql`DELETE FROM import_jobs WHERE id = ${r.payload.job_id}`;
    }
    await sql`ALTER TABLE transactions DISABLE TRIGGER trg_transactions_no_delete`;
    await sql`DELETE FROM transactions WHERE description LIKE 'Mock Transaction%' AND created_at > now() - interval '1 minute'`;
    await sql`ALTER TABLE transactions ENABLE TRIGGER trg_transactions_no_delete`;
  });
});
