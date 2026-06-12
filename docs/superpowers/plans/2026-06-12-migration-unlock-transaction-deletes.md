# Migration: Unlock Transaction Deletes & Updates

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Write a single SQL migration that removes the database-level immutability guards blocking the Excel migration wipe and single-transaction deletes.

**Architecture:** Migration `003_allow_category_update.sql` installed a `BEFORE DELETE` trigger (`block_delete`) and a restrictive `BEFORE UPDATE` trigger (`block_immutable_change`) on the `transactions` table. These block the `DELETE FROM transactions WHERE user_id = ?` call in the migration endpoint and the `import_hash = NULL` update in the ledger delete use-case. A new migration file replaces the update function with a pass-through and drops the delete trigger entirely, matching the target state already documented in `schema.sql`.

**Tech Stack:** PostgreSQL (triggers/functions), node-pg-migrate (SQL migrations), Bun test runner

---

### Task 1: Write the migration file

**Files:**
- Create: `src/infrastructure/db/migrations/015_allow_transaction_deletes_and_updates.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- Allow all transaction updates (remove category-only restriction from 003)
CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RETURN NEW;
END;
$$;

-- Remove delete block — hard deletes now allowed
DROP TRIGGER IF EXISTS trg_transactions_no_delete ON transactions;
DROP FUNCTION IF EXISTS block_delete();
```

Save to `src/infrastructure/db/migrations/015_allow_transaction_deletes_and_updates.sql`.

- [ ] **Step 2: Verify the file exists with correct content**

```bash
cat src/infrastructure/db/migrations/015_allow_transaction_deletes_and_updates.sql
```

Expected output: the SQL above, no truncation.

---

### Task 2: Verify with existing tests

The existing `tests/migration-api.test.ts` already has a test (`accepts a multipart upload … wipes destructive tables`) that seeds a transaction and asserts it's gone after `POST /api/migration/excel`. This test currently fails because of `block_delete`. Running it after applying the migration to the test DB confirms the fix.

The `tests/ledger.test.ts` tests `deleteTransaction` which also needs the delete trigger gone.

- [ ] **Step 1: Apply the migration to the test database**

```bash
bun run db:migrate
```

Expected output ends with:
```
[migrate] Migrating "015_allow_transaction_deletes_and_updates"
Migrations complete.
```

- [ ] **Step 2: Run the migration API tests**

```bash
bun test tests/migration-api.test.ts --timeout 30000
```

Expected: all tests pass, including `accepts a multipart upload, returns 202 with a job_id, enqueues a PGMQ message, wipes destructive tables, and writes a pending import_jobs row`.

- [ ] **Step 3: Run the ledger tests**

```bash
bun test tests/ledger.test.ts --timeout 30000
```

Expected: all tests pass, including any `deleteTransaction` tests.

- [ ] **Step 4: Run the full test suite to catch regressions**

```bash
bun test --timeout 30000
```

Expected: all tests pass.

---

### Task 3: Commit

- [ ] **Step 1: Stage and commit**

```bash
git add src/infrastructure/db/migrations/015_allow_transaction_deletes_and_updates.sql
git commit -m "feat(migration): add migration 015 to allow transaction deletes and updates

Removes trg_transactions_no_delete (block_delete function) and relaxes
block_immutable_change to pass-through. Unblocks the Excel migration wipe
(DELETE FROM transactions WHERE user_id) and the ledger deleteTransaction
use-case (UPDATE import_hash + hard DELETE). Matches the target state
already documented in schema.sql."
```
