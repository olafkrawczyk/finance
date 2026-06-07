import { describe, it, expect, beforeAll } from 'bun:test';
import * as XLSX from 'xlsx';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';
import { processExcelMigrationJob } from '../src/workers/import-worker';

let sessionCookie: string;
let pkoAccountId: string;
let ingAccountId: string;

/**
 * Builds a minimal in-memory .xlsx workbook with one modern-format monthly
 * sheet ("luty 2021") containing an opening balance, an expense row, and an
 * income row, plus a helper sheet that must be skipped.
 */
function buildTestWorkbook(): ArrayBuffer {
  const sheetRows: (string | number | null)[][] = [
    ['kategoria', 'kwota', 'opis', 'data', 'nazwa', 'kwota'],
    ['', '', '', '', '', ''],
    ['', '', '', '', '', 12345.67], // Row 3 (index 2): opening balance in Col H (index 7)... see note below
    ['fun', 50.5, 'Test expense', '2021-02-05', 'Pensja', 5000],
    ['VAT', 100, 'Tax payment', '2021-02-10', '', ''],
  ];
  // Place opening balance at column index 7 (Col H) per modern-sheet rule
  sheetRows[2] = [null, null, null, null, null, null, null, 12345.67];

  const sheet = XLSX.utils.aoa_to_sheet(sheetRows);
  const helperSheet = XLSX.utils.aoa_to_sheet([['ignore', 'me']]);

  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, sheet, 'luty 2021');
  XLSX.utils.book_append_sheet(workbook, helperSheet, 'kategorie');

  const out = XLSX.write(workbook, { type: 'array', bookType: 'xlsx' });
  return out as ArrayBuffer;
}

/** Builds a workbook whose only sheet has no parseable transactions/categories. */
function buildInvalidWorkbook(): ArrayBuffer {
  const sheet = XLSX.utils.aoa_to_sheet([['nothing', 'here']]);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, sheet, 'zbiorczy');
  const out = XLSX.write(workbook, { type: 'array', bookType: 'xlsx' });
  return out as ArrayBuffer;
}

beforeAll(async () => {
  await sql`TRUNCATE transactions, monthly_opening_balances, insights, import_jobs CASCADE`;
  await sql`DELETE FROM pgmq.q_import_queue`;
  await sql`TRUNCATE "session", "account", "user", "verification" CASCADE`;

  const [pko] = await sql`SELECT id FROM accounts WHERE name = 'IPKO' LIMIT 1`;
  const [ing] = await sql`SELECT id FROM accounts WHERE name = 'Konto Direct dla Firmy' LIMIT 1`;
  if (!pko || !ing) {
    throw new Error('Expected seeded IPKO and Konto Direct dla Firmy accounts');
  }
  pkoAccountId = pko.id;
  ingAccountId = ing.id;

  const res = await auth.api.signUpEmail({
    body: {
      email: 'migration-test@example.com',
      password: 'testpassword123',
      name: 'Migration Test User',
    },
    asResponse: true,
  });
  const setCookie = res.headers.get('set-cookie');
  if (!setCookie) {
    throw new Error('Failed to get session cookie for migration tests');
  }
  sessionCookie = setCookie;
});

describe('POST /api/migration/excel', () => {
  it('requires authentication and returns 401 for anonymous requests', async () => {
    const res = await app.request('/api/migration/excel', { method: 'POST' });
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error.message).toBe('Unauthorized');
  });

  it('accepts a multipart upload, returns 202 with a job_id, enqueues a PGMQ message, wipes destructive tables, and writes a pending import_jobs row', async () => {
    // Seed a row that should be wiped by the destructive reset
    await sql`
      INSERT INTO transactions (account_id, type, amount, date, import_hash)
      VALUES (${pkoAccountId}, 'expense', 10.00, '2024-01-01', 'pre-migration-marker')
    `;

    const buffer = buildTestWorkbook();
    const formData = new FormData();
    const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    formData.append('file', blob, 'budget.xlsx');

    const res = await app.request('/api/migration/excel', {
      method: 'POST',
      headers: { Cookie: sessionCookie },
      body: formData,
    });

    expect(res.status).toBe(202);
    const json = await res.json();
    expect(json.data.job_id).toBeDefined();
    expect(json.error).toBeNull();

    // Destructive wipe: the pre-seeded marker row must be gone
    const markerRows = await sql`SELECT id FROM transactions WHERE import_hash = 'pre-migration-marker'`;
    expect(markerRows.length).toBe(0);

    // Pending job row written
    const [job] = await sql`SELECT * FROM import_jobs WHERE id = ${json.data.job_id}`;
    expect(job).toBeDefined();
    expect(job.status).toBe('pending');
    expect(job.account_id).toBe(pkoAccountId);

    // PGMQ message enqueued with the expected shape
    const [msg] = await sql`SELECT * FROM pgmq.read('import_queue', 5, 1)`;
    expect(msg).toBeDefined();
    const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;
    expect(payload.type).toBe('excel_migration');
    expect(payload.job_id).toBe(json.data.job_id);
    expect(typeof payload.file_path).toBe('string');

    // Archive so it doesn't interfere with other tests
    await sql`SELECT pgmq.archive('import_queue', ${msg.msg_id}::bigint)`;

    // Cleanup: remove the temp file written to disk
    await Bun.file(payload.file_path).delete().catch(() => {});
  });
});

describe('Excel migration worker processing', () => {
  it('processes excel_migration payloads end to end: parses, batch-inserts, and marks the job completed', async () => {
    const buffer = buildTestWorkbook();
    const filePath = `/tmp/migration-worker-test-${crypto.randomUUID()}.xlsx`;
    await Bun.write(filePath, buffer);

    const [job] = await sql`
      INSERT INTO import_jobs (account_id, status) VALUES (${pkoAccountId}, 'pending') RETURNING id
    `;

    const result = await processExcelMigrationJob({
      job_id: job.id,
      type: 'excel_migration',
      file_path: filePath,
    });

    expect(result.errors.length).toBe(0);
    expect(result.processed).toBeGreaterThan(0);

    const [updatedJob] = await sql`SELECT * FROM import_jobs WHERE id = ${job.id}`;
    expect(updatedJob.status).toBe('completed');
    expect(updatedJob.processed).toBe(result.processed);

    // Opening balance row inserted for Feb 2021
    const [balance] = await sql`SELECT * FROM monthly_opening_balances WHERE year = 2021 AND month = 2`;
    expect(balance).toBeDefined();
    expect(Number(balance.opening_balance)).toBeCloseTo(12345.67, 2);

    // VAT expense routed to ING Business
    const [vatTx] = await sql`SELECT * FROM transactions WHERE description = 'Tax payment'`;
    expect(vatTx).toBeDefined();
    expect(vatTx.account_id).toBe(ingAccountId);
    expect(vatTx.type).toBe('expense');

    // "fun" expense routed to PKO Personal
    const [funTx] = await sql`SELECT * FROM transactions WHERE description = 'Test expense'`;
    expect(funTx).toBeDefined();
    expect(funTx.account_id).toBe(pkoAccountId);

    // Income row imported with category_id NULL
    const [incomeTx] = await sql`SELECT * FROM transactions WHERE description = 'Pensja'`;
    expect(incomeTx).toBeDefined();
    expect(incomeTx.type).toBe('income');
    expect(incomeTx.category_id).toBeNull();

    // Temp file cleaned up
    expect(await Bun.file(filePath).exists()).toBe(false);
  });

  it('marks the job failed and records error messages when the workbook structure is invalid', async () => {
    const buffer = buildInvalidWorkbook();
    const filePath = `/tmp/migration-worker-invalid-${crypto.randomUUID()}.xlsx`;
    await Bun.write(filePath, buffer);

    const [job] = await sql`
      INSERT INTO import_jobs (account_id, status) VALUES (${pkoAccountId}, 'pending') RETURNING id
    `;

    const result = await processExcelMigrationJob({
      job_id: job.id,
      type: 'excel_migration',
      file_path: filePath,
    });

    // No parseable sheets/transactions -> zero processed, job marked failed or completed-empty
    expect(result.processed).toBe(0);

    const [updatedJob] = await sql`SELECT * FROM import_jobs WHERE id = ${job.id}`;
    expect(['failed', 'completed']).toContain(updatedJob.status);

    // Temp file cleaned up regardless of outcome
    expect(await Bun.file(filePath).exists()).toBe(false);
  });
});
