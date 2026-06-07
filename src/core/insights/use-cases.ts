import sql from '../../infrastructure/db/client';
import type { Insight, CategoryAggregate, TransactionData } from './entities';
import type { InsightType } from './entities';

async function getLatestTransactionDate(userId: string): Promise<string> {
  const [row] = await sql`
    SELECT MAX(date)::text AS latest FROM transactions WHERE user_id = ${userId}
  `;
  return row?.latest ?? new Date().toISOString().slice(0, 10);
}

// 1. getInsightDataWindow: Fetch transactions from the last 3 months + same months from previous year,
// anchored to the latest transaction date so historical seed data is always usable.
export async function getInsightDataWindow(userId: string): Promise<TransactionData[]> {
  const anchor = await getLatestTransactionDate(userId);
  const rows = await sql`
    SELECT t.*, c.name as category_name
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE (t.date >= (${anchor}::date - interval '3 months')
       OR (EXTRACT(MONTH FROM t.date) = EXTRACT(MONTH FROM ${anchor}::date - interval '12 months')
           AND t.date >= ${anchor}::date - interval '15 months'
           AND t.date < ${anchor}::date - interval '11 months'))
      AND t.user_id = ${userId}
    ORDER BY t.date DESC
  `;
  return rows as TransactionData[];
}

// 2. getCategoryAggregates: Aggregate transaction data by category (ONLY numerical aggregates)
export async function getCategoryAggregates(transactionIds: string[]): Promise<CategoryAggregate[]> {
  if (transactionIds.length === 0) return [];

  const anchor = await getLatestTransactionDate();
  const rows = await sql`
    WITH txs AS (
      SELECT
        t.id,
        t.amount,
        t.date,
        c.name as category_name,
        CASE WHEN t.date >= (${anchor}::date - interval '3 months') THEN 'recent' ELSE 'yoy' END as period
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.id = ANY(${transactionIds}) AND t.type = 'expense'
    ),
    totals AS (
      SELECT
        category_name,
        period,
        SUM(amount) as period_spent
      FROM txs
      WHERE category_name IS NOT NULL
      GROUP BY category_name, period
    ),
    category_list AS (
      SELECT DISTINCT category_name FROM totals
    ),
    period_pivoted AS (
      SELECT
        cl.category_name,
        COALESCE(r.period_spent, 0) as recent_spent,
        COALESCE(y.period_spent, 0) as yoy_spent
      FROM category_list cl
      LEFT JOIN totals r ON cl.category_name = r.category_name AND r.period = 'recent'
      LEFT JOIN totals y ON cl.category_name = y.category_name AND y.period = 'yoy'
    ),
    grand_total AS (
      SELECT SUM(recent_spent) as total_recent_spent FROM period_pivoted
    )
    SELECT
      p.category_name,
      p.recent_spent::text as total_spent,
      (CASE WHEN gt.total_recent_spent > 0 THEN (p.recent_spent / gt.total_recent_spent * 100) ELSE 0 END)::text as percentage_of_total,
      (CASE WHEN p.recent_spent > p.yoy_spent THEN 'up' WHEN p.recent_spent < p.yoy_spent THEN 'down' ELSE 'flat' END)::text as trend_direction,
      (CASE WHEN p.yoy_spent > 0 THEN ((p.recent_spent - p.yoy_spent) / p.yoy_spent * 100) ELSE 0 END)::text as trend_percent,
      (CASE WHEN p.yoy_spent > 0 THEN ((p.recent_spent - p.yoy_spent) / p.yoy_spent * 100) ELSE 0 END)::text as yoy_change_percent
    FROM period_pivoted p
    CROSS JOIN grand_total gt
  `;
  return rows as CategoryAggregate[];
}

// 3. listInsights: Paginated list query filterable by type, dismissed status
export async function listInsights(params: {
  userId: string;
  type?: InsightType;
  dismissed?: boolean;
  page: number;
  per_page: number;
}): Promise<{ rows: Insight[]; total: number }> {
  const { userId, type, dismissed, page, per_page } = params;
  const offset = (page - 1) * per_page;

  const rows = await sql`
    SELECT * FROM insights
    WHERE user_id = ${userId}
      ${type ? sql`AND type = ${type}` : sql``}
      ${dismissed !== undefined ? sql`AND dismissed = ${dismissed}` : sql``}
    ORDER BY created_at DESC
    LIMIT ${per_page} OFFSET ${offset}
  `;

  const [{ count }] = await sql`
    SELECT COUNT(*) AS count FROM insights
    WHERE user_id = ${userId}
      ${type ? sql`AND type = ${type}` : sql``}
      ${dismissed !== undefined ? sql`AND dismissed = ${dismissed}` : sql``}
  `;

  return { rows: rows as Insight[], total: Number(count) };
}

// 4. dismissInsight: Set dismissed = true on insight by id+userId
export async function dismissInsight(id: string, userId: string): Promise<Insight | null> {
  const [row] = await sql`
    UPDATE insights
    SET dismissed = true
    WHERE id = ${id} AND user_id = ${userId}
    RETURNING *
  `;
  return (row as Insight) || null;
}

// 5. enqueueAnalysisJob: Enqueue manual generation job to analysis_queue
export async function enqueueAnalysisJob(userId: string): Promise<{ msg_id: number }> {
  const [row] = await sql`
    SELECT pgmq.send(
      'analysis_queue',
      ${JSON.stringify({ user_id: userId, triggered_by: 'manual' })}::jsonb
    ) as msg_id
  `;
  return { msg_id: Number(row.msg_id) };
}

// 6. getInsightsForDashboard: Top N undismissed insights for dashboard widget
export async function getInsightsForDashboard(userId: string, limit: number = 3): Promise<Insight[]> {
  const rows = await sql`
    SELECT * FROM insights
    WHERE user_id = ${userId} AND dismissed = false
    ORDER BY created_at DESC
    LIMIT ${limit}
  `;
  return rows as Insight[];
}

// 7. insertInsightBatch: Batch insert with ON CONFLICT dedup
export async function insertInsightBatch(
  insights: Array<{
    user_id: string;
    type: string;
    priority: string;
    title: string;
    content: string;
    linked_transaction_ids?: string[];
    linked_category_ids?: string[];
    dedup_hash: string;
  }>
): Promise<number> {
  if (insights.length === 0) return 0;

  let insertedCount = 0;
  for (const insight of insights) {
    const [row] = await sql`
      INSERT INTO insights (
        user_id, type, priority, title, content,
        linked_transaction_ids, linked_category_ids, dedup_hash
      )
      VALUES (
        ${insight.user_id}, ${insight.type}, ${insight.priority}, ${insight.title}, ${insight.content},
        ${insight.linked_transaction_ids ?? []}, ${insight.linked_category_ids ?? []}, ${insight.dedup_hash}
      )
      ON CONFLICT (dedup_hash) DO NOTHING
      RETURNING id
    `;
    if (row) {
      insertedCount++;
    }
  }
  return insertedCount;
}
