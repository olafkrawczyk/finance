# Design: Unlock Transaction Deletes & Updates for Migration

**Date:** 2026-06-12

## Context

The Excel migration endpoint (`POST /migration/excel`) wipes all user data before re-importing from an XLSX file. It correctly scopes every DELETE to the authenticated user (`WHERE user_id = ${user.id}`), but the operation fails at runtime with:

> "Transactions are immutable. Deletes are not permitted."

This is caused by `trg_transactions_no_delete`, a `BEFORE DELETE` trigger installed by migration `003_allow_category_update.sql`. The same migration also restricts updates to only `category_id` changes, which breaks the `deleteTransaction` use-case (which first clears `import_hash` via UPDATE before hard-deleting).

`schema.sql` already documents the intended final state — both immutability constraints removed — but no migration file applies those changes to the live database. This design closes that gap.

## Scope

A single new SQL migration file. No application code changes required; the migration endpoint and ledger delete logic are already correct.

## Design

### New file: `015_allow_transaction_deletes_and_updates.sql`

```sql
-- Allow all transaction updates (remove category-only restriction)
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

- The `trg_transactions_no_update` trigger stays registered but its function body now returns `NEW` unconditionally — all updates pass through.
- The `trg_transactions_no_delete` trigger and its `block_delete()` function are dropped entirely.
- User scoping remains application-enforced: every query filters by `user_id` extracted from the authenticated session.

## What this unlocks

| Operation | Before | After |
|---|---|---|
| `DELETE FROM transactions WHERE user_id = ?` (migration wipe) | Blocked by trigger | Works |
| `UPDATE transactions SET import_hash = NULL` (delete use-case step 1) | Blocked by trigger | Works |
| `DELETE FROM transactions WHERE id = ? AND user_id = ?` (ledger delete) | Blocked by trigger | Works |
| `ON CONFLICT ... DO NOTHING` inserts (normal import) | Unaffected | Unaffected |

## User isolation guarantee

The existing `migration.ts` already wraps all DELETEs in a transaction scoped to `user.id`:

```ts
await sql`DELETE FROM transactions WHERE user_id = ${user.id}`;
```

No changes needed here — the auth middleware (`requireAuth`) ensures `user.id` comes from the verified session token.

## Verification

1. Run `bun run db:migrate` to apply migration 015.
2. Upload an XLSX via the migration endpoint: `POST /api/migration/excel`.
3. Confirm the job reaches `completed` status via `GET /api/import/:job_id`.
4. Confirm transactions table is repopulated with the user's data.
5. Confirm another user's data is untouched (multi-user smoke test or manual DB check).
6. Test single-transaction delete via the ledger DELETE endpoint — should return 200.
