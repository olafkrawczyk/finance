# Transaction CRUD

## Requirements

- Must not corrupt the audit trail (analysis_queue, monthly calculations)
- Use Approach C for edit/delete: modify triggers to allow updates, drop delete trigger, add updated_at column
- Edit/delete should trigger re-analysis via PGMQ analysis_queue

## How to Build It

### Backend (spike 002)

1. **Schema migration** (in `src/infrastructure/db/schema.sql`):
   - Add `updated_at TIMESTAMPTZ` column to transactions table
   - Replace `block_immutable_change()` function — change to `RETURN NEW` (allow all updates)
   - Drop `block_delete()` function and `trg_transactions_no_delete` trigger
   - Add `update_transaction_timestamp()` trigger for `updated_at`

2. **New API endpoints** (in `src/interface-adapters/api/ledger.ts`):
   - `PUT /transactions/:id` — full update of all fields
   - `DELETE /transactions/:id` — delete transaction
   - `GET /transactions/:id` — get single transaction for edit form prefill

3. **New use-case functions** (in `src/core/ledger/use-cases.ts`):
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

4. **Validation schema** — `UpdateTransactionSchema = CreateTransactionSchema` (same fields)

### Frontend (spike 003)

1. Add edit (pencil) and delete (trash) buttons to the transaction table rows, visible on hover
2. Edit opens a modal with all fields prefilled (same fields as AddTransaction form)
3. Delete shows a confirmation dialog before removing
4. On success: show toast notification, refetch transaction list

### Re-analysis on edit

Editing a transaction should re-enqueue to PGMQ `analysis_queue` so the insights worker recalculates. The worker fetches a 3-month window, so a single-tx re-analysis naturally pulls the full window.

## What to Avoid

- **Soft delete** — adds significant query filtering complexity (`deleted_at IS NULL` everywhere). Not worth it for a single-user app
- **Full audit log table** — overengineered. The `updated_at` column and PGMQ re-enqueue provide sufficient tracking
- **Leaving the DELETE trigger in place** — must be dropped, not modified

## Constraints

- Deleting a transfer doesn't affect the counterparty — transfers are single rows with `transfer_to_account_id`, not pairs
- Insights may reference deleted transaction IDs in `linked_transaction_ids` array — no FK constraint, won't break DB, but UI may show stale references

## Origin

Synthesized from spikes: 002, 003
Source files available in: sources/002-backend-edit-delete-triggers/, sources/003-frontend-edit-delete-ui/
