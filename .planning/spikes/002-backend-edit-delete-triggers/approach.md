# Spike 002: Backend Edit/Delete — Approach Analysis

## Current State

- `block_immutable_change()` trigger blocks UPDATE except category_id NULL→UUID
- `block_delete()` trigger blocks all DELETE
- PGMQ `analysis_queue` enqueued only on INSERT (via `createTransaction` in ledger/use-cases.ts)
- No `updated_at` column on transactions table

## Approach Comparison

| Approach | Trigger Change | Audit | Complexity | Risk |
|----------|---------------|-------|------------|------|
| A: Replace triggers, allow full UPDATE/DELETE, enqueue re-analysis | Drop both, replace with permissive trigger | None — no audit trail | Low | Missing edit history, insights stale |
| B: Soft delete + full edit | Modify UPDATE trigger to always pass, replace DELETE with `deleted_at` SET | Soft delete preserves rows | Medium | Need to filter everywhere |
| C: Add `updated_at`, enqueue re-analysis on edit | Modify UPDATE trigger to always pass, drop DELETE trigger, add `updated_at` trigger | `updated_at` tracks last change | Low | No who-changed-what audit |
| D: Full audit log table | Create `transaction_audit_log` table, record all changes, keep immutability | Full audit trail | High | Overengineered for single-user |

## Chosen Approach: C — Practical Edits

**Rationale:** Single-user finance app. No regulatory audit requirement. Soft delete adds complexity (need to filter `deleted_at IS NULL` everywhere). Full audit log is overkill. Simple approach:

### Schema Changes

```sql
-- 1. Add updated_at column
ALTER TABLE transactions ADD COLUMN updated_at TIMESTAMPTZ;

-- 2. Auto-update updated_at on change
CREATE OR REPLACE FUNCTION update_transaction_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_transactions_updated_at ON transactions;
CREATE TRIGGER trg_transactions_updated_at
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION update_transaction_timestamp();

-- 3. Replace block_immutable_change — allow all updates (but keep the same function signature for safety)
CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RETURN NEW;  -- Allow all updates
END;
$$;

-- 4. Remove delete block
DROP TRIGGER IF EXISTS trg_transactions_no_delete ON transactions;
DROP FUNCTION IF EXISTS block_delete();
```

### API Endpoints

```
PUT /transactions/:id    — Full update (all fields)
DELETE /transactions/:id — Delete transaction
GET  /transactions/:id   — Get single transaction (needed for edit form prefill)
```

### Impact on PGMQ / Insights

- **On edit:** Enqueue a message to `analysis_queue` so insights recalculate
- **On delete:** Insights may reference deleted transaction IDs. Not a DB constraint issue (UUIDs are stored in `linked_transaction_ids UUID[]`, no FK). Insights will show stale references but won't break.

### Use-Case Updates

New functions in `src/core/ledger/use-cases.ts`:

```typescript
export async function updateTransaction(id: string, input: UpdateTransactionInput): Promise<Transaction> {
  return await sql.begin(async (sql) => {
    const [tx] = await sql`
      UPDATE transactions SET
        account_id = ${input.account_id},
        category_id = ${input.category_id ?? null},
        type = ${input.type},
        amount = ${input.amount},
        description = ${input.description ?? null},
        date = ${input.date},
        transfer_to_account_id = ${input.transfer_to_account_id ?? null}
      WHERE id = ${id}
      RETURNING *
    `;
    await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({ transaction_id: tx.id })}::jsonb)`;
    return tx;
  });
}

export async function deleteTransaction(id: string): Promise<void> {
  await sql`DELETE FROM transactions WHERE id = ${id}`;
}

export async function getTransaction(id: string): Promise<Transaction | undefined> {
  const [row] = await sql`SELECT * FROM transactions WHERE id = ${id}`;
  return row as Transaction | undefined;
}
```

### Validation Schema

```typescript
export const UpdateTransactionSchema = CreateTransactionSchema; // same fields
```

### Edge Cases

- **Deleting a transfer:** The counterparty transaction (if any) is unaffected — transfers are represented by a single row with `transfer_to_account_id`, not pairs
- **Re-enqueue on edit:** The `transaction_id` in the analysis message allows the insights worker to refetch. Currently the worker fetches a window of 3 months, so a single-tx re-analysis would naturally pull the full window
- **Category assignment + edit:** The existing PATCH `/transactions/:id/category` is now redundant but harmless. Keep for backward compatibility or deprecate
