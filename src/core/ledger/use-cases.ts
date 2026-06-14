import sql from '../../infrastructure/db/client';
import type { Transaction, MonthlyOpeningBalance, MonthlySummaryRow } from './entities';
import type {
  CreateTransactionInput,
  CreateOpeningBalanceInput,
  UpdateOpeningBalanceInput,
  UpdateTransactionInput,
} from '../../application/schemas/ledger';
import { listAccounts } from '../reference/use-cases';
import {
  computeMonthlySummary,
  type AggregateRow,
  type AccountBaseline,
  type LegacyOpeningBalance,
  type SnapshotRow,
} from './summary-math';

// createTransaction: atomic insert + PGMQ enqueue
export async function createTransaction(input: CreateTransactionInput & { userId: string }): Promise<Transaction> {
  const row = await sql.begin(async (sql) => {
    const [tx] = await sql`
      INSERT INTO transactions
        (account_id, category_id, type, amount, description, date, transfer_to_account_id, user_id)
      VALUES
        (${input.account_id}, ${input.category_id ?? null}, ${input.type},
         ${input.amount}, ${input.description ?? null}, ${input.date},
         ${input.transfer_to_account_id ?? null}, ${input.userId})
      RETURNING *
    `;
    await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({
      transaction_id: tx.id,
      user_id: input.userId,
    })}::jsonb)`;
    return tx;
  });
  return row as Transaction;
}

// listTransactions: paginated, filtered
export async function listTransactions(params: {
  userId: string;
  page: number;
  per_page: number;
  account_id?: string;
  type?: string;
  date_from?: string;
  date_to?: string;
  uncategorized?: boolean;
}): Promise<{ rows: Transaction[]; total: number }> {
  const { userId, page, per_page, account_id, type, date_from, date_to, uncategorized } = params;
  const offset = (page - 1) * per_page;

  const rows = await sql`
    SELECT * FROM transactions
    WHERE true
      AND user_id = ${userId}
      ${account_id ? sql`AND account_id = ${account_id}` : sql``}
      ${type ? sql`AND type = ${type}` : sql``}
      ${date_from ? sql`AND date >= ${date_from}` : sql``}
      ${date_to ? sql`AND date <= ${date_to}` : sql``}
      ${uncategorized ? sql`AND category_id IS NULL` : sql``}
    ORDER BY date DESC, created_at DESC
    LIMIT ${per_page} OFFSET ${offset}
  `;
  const [{ count }] = await sql`
    SELECT COUNT(*) AS count FROM transactions
    WHERE true
      AND user_id = ${userId}
      ${account_id ? sql`AND account_id = ${account_id}` : sql``}
      ${type ? sql`AND type = ${type}` : sql``}
      ${date_from ? sql`AND date >= ${date_from}` : sql``}
      ${date_to ? sql`AND date <= ${date_to}` : sql``}
      ${uncategorized ? sql`AND category_id IS NULL` : sql``}
  `;
  return { rows: rows as Transaction[], total: Number(count) };
}

// getMonthlySummary: fetch from DB, then delegate the math to the pure
// computeMonthlySummary module (src/core/ledger/summary-math.ts).
export async function getMonthlySummary(userId: string): Promise<MonthlySummaryRow[]> {
  const agg = await sql`
    SELECT
      TO_CHAR(t.date, 'YYYY-MM') AS month,
      SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END)::text AS wydatki,
      SUM(CASE WHEN t.type = 'income'  THEN t.amount ELSE 0 END)::text AS przychody,
      SUM(CASE WHEN t.type = 'expense' AND c.is_fixed_cost = true THEN t.amount ELSE 0 END)::text AS fixed_cost_total
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE t.type != 'transfer'
      AND t.user_id = ${userId}
    GROUP BY TO_CHAR(t.date, 'YYYY-MM')
    ORDER BY month ASC
  `;

  const accounts = await listAccounts(userId);

  // Fetched unconditionally so the pure layer owns the hasStartingBalances branch.
  const legacyOpeningBalances = await sql`
    SELECT year, month, opening_balance
    FROM monthly_opening_balances
    WHERE user_id = ${userId}
    ORDER BY year, month
  `;

  const assetSnapshots = await sql`
    SELECT asset_id, value, date FROM asset_value_snapshots
    WHERE asset_id IN (SELECT id FROM assets WHERE user_id = ${userId})
    ORDER BY date ASC, created_at ASC
  `;

  return computeMonthlySummary({
    aggregates: agg as unknown as AggregateRow[],
    accounts: accounts as unknown as AccountBaseline[],
    legacyOpeningBalances: legacyOpeningBalances as unknown as LegacyOpeningBalance[],
    assetSnapshots: assetSnapshots as unknown as SnapshotRow[],
  });
}

// createOpeningBalance: insert monthly opening balance
export async function createOpeningBalance(input: CreateOpeningBalanceInput & { userId: string }): Promise<MonthlyOpeningBalance> {
  const [row] = await sql`
    INSERT INTO monthly_opening_balances (year, month, opening_balance, notes, user_id)
    VALUES (${input.year}, ${input.month}, ${input.opening_balance}, ${input.notes ?? null}, ${input.userId})
    RETURNING *
  `;
  return row as MonthlyOpeningBalance;
}

// updateOpeningBalance: update fields of opening balance
export async function updateOpeningBalance(
  id: string,
  input: UpdateOpeningBalanceInput,
  userId: string
): Promise<MonthlyOpeningBalance | undefined> {
  const fields = Object.entries(input).reduce((acc, [key, val]) => {
    if (val !== undefined) acc[key] = val;
    return acc;
  }, {} as any);

  if (Object.keys(fields).length === 0) {
    const [row] = await sql`SELECT * FROM monthly_opening_balances WHERE id = ${id} AND user_id = ${userId}`;
    return row as MonthlyOpeningBalance | undefined;
  }

  const [row] = await sql`
    UPDATE monthly_opening_balances
    SET ${sql(fields)}
    WHERE id = ${id} AND user_id = ${userId}
    RETURNING *
  `;
  return row as MonthlyOpeningBalance | undefined;
}

// getTransaction: fetch single transaction by ID (for edit form prefill)
export async function getTransaction(id: string, userId: string): Promise<Transaction | undefined> {
  const [row] = await sql`SELECT * FROM transactions WHERE id = ${id} AND user_id = ${userId}`;
  return row as Transaction | undefined;
}

// updateTransaction: update all fields, no PGMQ enqueue (D-04)
export async function updateTransaction(id: string, input: UpdateTransactionInput, userId: string): Promise<Transaction> {
  const [tx] = await sql`
    UPDATE transactions SET
      account_id = ${input.account_id},
      category_id = ${input.category_id ?? null},
      type = ${input.type},
      amount = ${input.amount},
      description = ${input.description ?? null},
      date = ${input.date},
      transfer_to_account_id = ${input.transfer_to_account_id ?? null}
    WHERE id = ${id} AND user_id = ${userId}
    RETURNING *
  `;
  if (!tx) throw new Error('Transaction not found');
  return tx as Transaction;
  // NOTE: No PGMQ enqueue per D-04 (explicitly no re-analysis on edit)
}

// deleteTransaction: atomic multi-step — clear hash, clean insights, hard delete
export async function deleteTransaction(id: string, userId: string): Promise<boolean> {
  const result = await sql.begin(async (sql) => {
    // Step 1 (D-05): Clear import_hash so same CSV row can be re-imported
    const [updateResult] = await sql`
      UPDATE transactions SET import_hash = NULL WHERE id = ${id} AND user_id = ${userId} RETURNING id
    `;
    if (!updateResult) return { deleted: false };

    // Step 2 (D-06): Remove ID from insight linked_transaction_ids
    await sql`
      UPDATE insights
      SET linked_transaction_ids = array_remove(linked_transaction_ids, ${id})
      WHERE ${id} = ANY(linked_transaction_ids) AND user_id = ${userId}
    `;
    // Step 3 (D-07): Hard delete
    const [delResult] = await sql`
      DELETE FROM transactions WHERE id = ${id} AND user_id = ${userId} RETURNING id
    `;
    return { deleted: !!delResult };
  });
  return result.deleted;
}

// listOpeningBalances: fetch all opening balances with year/month filters
export async function listOpeningBalances(params?: { userId?: string; year?: number; month?: number }): Promise<MonthlyOpeningBalance[]> {
  const userId = params?.userId;
  const year = params?.year;
  const month = params?.month;

  const rows = await sql`
    SELECT * FROM monthly_opening_balances
    WHERE true
      ${userId ? sql`AND user_id = ${userId}` : sql``}
      ${year ? sql`AND year = ${year}` : sql``}
      ${month ? sql`AND month = ${month}` : sql``}
    ORDER BY year ASC, month ASC
  `;
  return rows as MonthlyOpeningBalance[];
}

// assignCategory: scoped PATCH /transactions/:id/category extracted from inline SQL
export async function assignCategory(
  transactionId: string,
  categoryId: string,
  userId: string
): Promise<Transaction | null> {
  const [updated] = await sql`
    UPDATE transactions SET category_id = ${categoryId}
    WHERE id = ${transactionId}
      AND category_id IS NULL
      AND user_id = ${userId}
    RETURNING *
  `;
  return (updated as Transaction) || null;
}
