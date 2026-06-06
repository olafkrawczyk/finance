# Plan 02-04 Summary: Import Worker

Completed on 2026-06-06.

## Deliverables
- [x] **preprocessIngCsv**: Preprocesses ING exports by stripping metadata lines and leaving only transaction rows (exactly 83 rows in our sample).
- [x] **preprocessIpkoCsv**: Preprocesses IPKO exports by filtering out the 3 `"Blokada"` rows, leaving 252 valid transactions.
- [x] **callOpenRouter**: Communicates with OpenRouter using strict `json_schema` response format. Implements Zod validation filtering (`ParsedTransactionSchema`) to reject invalid data from the LLM.
- [x] **insertBatch**: Inserts parsed transactions using database transactions (`sql.begin`) and `ON CONFLICT (import_hash) DO NOTHING`. Dynamically resolves the destination account ID for transfer rows to link them correctly.
- [x] **processJob & workerLoop**: Dequeues jobs from `import_queue` using PGMQ (with a 300s visibility timeout), batches rows by 50, asserts that returned transaction count matches input count (to prevent silent LLM drops), updates status incrementally, and handles retries.
- [x] **recoverStuckJobs**: Automatically marks any processing jobs older than 15 minutes as failed on startup.
- [x] **tests/import-parse.test.ts**: Tests the pre-processing logic, row counts, and verifies that Polish character encodings are preserved correctly.
- [x] **tests/import-llm.test.ts**: Tests the OpenRouter completions caller using a local `Bun.serve` mock.
- [x] **tests/import-worker.test.ts**: Tests the worker end-to-end, validating database inserts, transfer linking, PGMQ archiving, deduplication, and stuck job recovery.

## Verification Results
- `bun test tests/import-parse.test.ts tests/import-llm.test.ts tests/import-worker.test.ts` runs 100% green.
