# Import & Dedup

## Requirements

- Import dedup hash should include account_id to prevent cross-account collisions
- Hash currently used: SHA-256 of `date|amount|description`

## How to Build It

The dedup mechanism lives in `src/workers/import-worker.ts`:

1. **Hash computation** — `computeImportHash(date, amount, description)` produces SHA-256 hex from `date|amount|description`
2. **Storage** — `import_hash TEXT UNIQUE` column on transactions table
3. **Insert** — `ON CONFLICT (import_hash) DO NOTHING` in `insertBatch()`
4. **Trigger** — `createTransaction()` in `src/core/ledger/use-cases.ts` enqueues to PGMQ `analysis_queue`

When adding `account_id` to the hash, update `computeImportHash` to include it: `date|amount|description|account_id`. This scopes dedup per-account so the same CSV imported to two accounts won't collide.

## What to Avoid

- **Not including `account_id` in the hash** — same CSV imported to two different accounts causes the second import to skip all rows
- **Fragile hash inputs** — LLM output inconsistency in amount format (1234.5 vs 1234.50) or whitespace padding changes the hash, causing missed dedups
- **Hash collision from identical same-day same-amount purchases** — two separate 15 PLN coffees at the same shop get the same LLM-parsed description and thus the same hash; second one silently dropped

## Constraints

- `import_hash` is nullable — multiple NULLs allowed in UNIQUE constraint
- Hash is computed ONLY for imported transactions (manual entries have no hash)
- LLM must produce consistent amount format and no extra whitespace

## Origin

Synthesized from spikes: 001
Source files available in: sources/001-import-dedup-analysis/
