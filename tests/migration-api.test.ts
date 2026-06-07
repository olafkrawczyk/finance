import { describe, it } from 'bun:test';

/**
 * Wave 0 stubs for the Excel migration API + worker pipeline
 * (src/interface-adapters/api/migration.ts, src/workers/import-worker.ts).
 * These are filled in with real assertions in Tasks 3-4 once the route and
 * worker integration exist.
 */
describe('POST /api/migration/excel', () => {
  it.todo('requires authentication and returns 401 for anonymous requests');
  it.todo('accepts a multipart upload, returns 202 Accepted with a job_id, enqueues a PGMQ message, and writes a pending import_jobs row');
  it.todo('wipes transactions, monthly_opening_balances, insights, and import_jobs (CASCADE) before writing the new pending job');
});

describe('Excel migration worker processing', () => {
  it.todo('handles excel_migration queue payloads, runs the parser, batch-inserts rows, and marks the job completed');
  it.todo('marks the job failed and records error messages when the workbook structure is invalid');
  it.todo('deletes the temporary uploaded .xlsx file from scratch/uploads/ on completion or failure');
});
