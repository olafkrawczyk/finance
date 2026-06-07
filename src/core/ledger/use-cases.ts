import sql from '../../infrastructure/db/client';
import type { Transaction, MonthlyOpeningBalance, MonthlySummaryRow } from './entities';
import type {
  CreateTransactionInput,
  CreateOpeningBalanceInput,
  UpdateOpeningBalanceInput,
  UpdateTransactionInput,
} from '../../application/schemas/ledger';

// createTransaction: atomic insert + PGMQ enqueue
export async function createTransaction(input: CreateTransactionInput): Promise<Transaction> {
  const row = await sql.begin(async (sql) => {
    const [tx] = await sql`
      INSERT INTO transactions
        (account_id, category_id, type, amount, description, date, transfer_to_account_id)
      VALUES
        (${input.account_id}, ${input.category_id ?? null}, ${input.type},
         ${input.amount}, ${input.description ?? null}, ${input.date},
         ${input.transfer_to_account_id ?? null})
      RETURNING *
    `;
    await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({ transaction_id: tx.id })}::jsonb)`;
    return tx;
  });
  return row as Transaction;
}

// listTransactions: paginated, filtered
export async function listTransactions(params: {
  page: number;
  per_page: number;
  account_id?: string;
  type?: string;
  date_from?: string;
  date_to?: string;
  uncategorized?: boolean;
}): Promise<{ rows: Transaction[]; total: number }> {
  const { page, per_page, account_id, type, date_from, date_to, uncategorized } = params;
  const offset = (page - 1) * per_page;

  const rows = await sql`
    SELECT * FROM transactions
    WHERE true
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
      ${account_id ? sql`AND account_id = ${account_id}` : sql``}
      ${type ? sql`AND type = ${type}` : sql``}
      ${date_from ? sql`AND date >= ${date_from}` : sql``}
      ${date_to ? sql`AND date <= ${date_to}` : sql``}
      ${uncategorized ? sql`AND category_id IS NULL` : sql``}
  `;
  return { rows: rows as Transaction[], total: Number(count) };
}

// getMonthlySummary: SQL aggregation + app-layer derived fields
export async function getMonthlySummary(): Promise<MonthlySummaryRow[]> {
  const agg = await sql`
    SELECT
      TO_CHAR(t.date, 'YYYY-MM') AS month,
      SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END)::text AS wydatki,
      SUM(CASE WHEN t.type = 'income'  THEN t.amount ELSE 0 END)::text AS przychody,
      SUM(CASE WHEN t.type = 'expense' AND c.is_fixed_cost = true THEN t.amount ELSE 0 END)::text AS fixed_cost_total
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE t.type != 'transfer'
    GROUP BY TO_CHAR(t.date, 'YYYY-MM')
    ORDER BY month ASC
  `;
  const balances = await sql`SELECT year, month, opening_balance FROM monthly_opening_balances ORDER BY year, month`;
  const balanceMap = new Map(
    balances.map((b: { year: number; month: number; opening_balance: string }) => [
      `${b.year}-${String(b.month).padStart(2, '0')}`,
      b.opening_balance,
    ])
  );

  let currentRunningBalance = 0;
  return agg.map((row: { month: string; wydatki: string; przychody: string; fixed_cost_total: string }) => {
    const wydatki = parseFloat(row.wydatki);
    const przychody = parseFloat(row.przychody);
    const fixedCost = parseFloat(row.fixed_cost_total);
    const wydatkiBezStalych = wydatki - fixedCost;
    const zaoszczedzone = przychody - wydatki;
    const zaoszczedzone_log = zaoszczedzone > 0 ? Math.log10(zaoszczedzone) : 0;
    
    const openingBalance = balanceMap.get(row.month);
    if (openingBalance != null) {
      currentRunningBalance = parseFloat(openingBalance) + zaoszczedzone;
    } else {
      currentRunningBalance += zaoszczedzone;
    }

    return {
      month: row.month,
      wydatki: wydatki.toFixed(4),
      przychody: przychody.toFixed(4),
      fixed_cost_total: fixedCost.toFixed(4),
      wydatki_bez_stalych: wydatkiBezStalych.toFixed(4),
      zaoszczedzone: zaoszczedzone.toFixed(4),
      zaoszczedzone_log: zaoszczedzone_log.toFixed(6),
      stan_konta: currentRunningBalance.toFixed(4),
    };
  });
}

// createOpeningBalance: insert global monthly opening balance
export async function createOpeningBalance(input: CreateOpeningBalanceInput): Promise<MonthlyOpeningBalance> {
  const [row] = await sql`
    INSERT INTO monthly_opening_balances (year, month, opening_balance, notes)
    VALUES (${input.year}, ${input.month}, ${input.opening_balance}, ${input.notes ?? null})
    RETURNING *
  `;
  return row as MonthlyOpeningBalance;
}

// updateOpeningBalance: update fields of opening balance
export async function updateOpeningBalance(
  id: string,
  input: UpdateOpeningBalanceInput
): Promise<MonthlyOpeningBalance | undefined> {
  const fields = Object.entries(input).reduce((acc, [key, val]) => {
    if (val !== undefined) acc[key] = val;
    return acc;
  }, {} as any);

  if (Object.keys(fields).length === 0) {
    const [row] = await sql`SELECT * FROM monthly_opening_balances WHERE id = ${id}`;
    return row as MonthlyOpeningBalance | undefined;
  }

  const [row] = await sql`
    UPDATE monthly_opening_balances
    SET ${sql(fields)}
    WHERE id = ${id}
    RETURNING *
  `;
  return row as MonthlyOpeningBalance | undefined;
}

// getTransaction: fetch single transaction by ID (for edit form prefill)
export async function getTransaction(id: string): Promise<Transaction | undefined> {
  const [row] = await sql`SELECT * FROM transactions WHERE id = ${id}`;
  return row as Transaction | undefined;
}

// updateTransaction: update all fields, no PGMQ enqueue (D-04)
export async function updateTransaction(id: string, input: UpdateTransactionInput): Promise<Transaction> {
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
  if (!tx) throw new Error('Transaction not found');
  return tx as Transaction;
  // NOTE: No PGMQ enqueue per D-04 (explicitly no re-analysis on edit)
}

// deleteTransaction: atomic multi-step — clear hash, clean insights, hard delete
export async function deleteTransaction(id: string): Promise<void> {
  await sql.begin(async (sql) => {
    // Step 1 (D-05): Clear import_hash so same CSV row can be re-imported
    await sql`UPDATE transactions SET import_hash = NULL WHERE id = ${id}`;
    // Step 2 (D-06): Remove ID from insight linked_transaction_ids
    await sql`
      UPDATE insights
      SET linked_transaction_ids = array_remove(linked_transaction_ids, ${id})
      WHERE ${id} = ANY(linked_transaction_ids)
    `;
    // Step 3 (D-07): Hard delete
    await sql`DELETE FROM transactions WHERE id = ${id}`;
  });
}

// listOpeningBalances: fetch all opening balances with year/month filters
export async function listOpeningBalances(params?: { year?: number; month?: number }): Promise<MonthlyOpeningBalance[]> {
  const year = params?.year;
  const month = params?.month;

  const rows = await sql`
    SELECT * FROM monthly_opening_balances
    WHERE true
      ${year ? sql`AND year = ${year}` : sql``}
      ${month ? sql`AND month = ${month}` : sql``}
    ORDER BY year ASC, month ASC
  `;
  return rows as MonthlyOpeningBalance[];
}
