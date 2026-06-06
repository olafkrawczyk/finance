# Phase 4: AI Insights & Forecasting - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 23 (16 new + 7 modified)
**Analogs found:** 23 / 23

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `src/workers/insights-worker.ts` | worker | event-driven (PGMQ polling) | `src/workers/import-worker.ts` | exact |
| `src/core/insights/entities.ts` | model | — | `src/core/import/entities.ts` | exact |
| `src/core/insights/use-cases.ts` | service | CRUD + batch | `src/core/import/use-cases.ts` | role-match |
| `src/application/schemas/insights.ts` | config (Zod schemas) | — | `src/application/schemas/import.ts` | exact |
| `src/interface-adapters/api/insights.ts` | controller | request-response | `src/interface-adapters/api/ledger.ts` | exact |
| `src/infrastructure/db/migrations/004_insights_table.sql` | migration | — | `src/infrastructure/db/migrations/003_allow_category_update.sql` | role-match |
| `frontend/src/pages/InsightsPage.tsx` | page component | request-response | `frontend/src/pages/DashboardPage.tsx` | role-match |
| `frontend/src/components/InsightCard.tsx` | component | — | `frontend/src/components/ImportUpload.tsx` | partial |
| `frontend/src/components/InsightsWidget.tsx` | component | request-response (polling) | `frontend/src/components/ImportStatus.tsx` | role-match |
| `frontend/src/components/InsightsTabs.tsx` | component | — | `frontend/src/App.tsx` (nav buttons) | partial |
| `frontend/src/lib/insights.ts` | utility | — | `frontend/src/lib/linearRegression.ts` | role-match |
| `tests/insights-schemas.test.ts` | test | — | `tests/import-schemas.test.ts` | exact |
| `tests/insights-api.test.ts` | test | — | `tests/api.test.ts` | exact |
| `tests/insights-worker.test.ts` | test | — | `tests/import-worker.test.ts` | exact |
| `tests/insights-llm.test.ts` | test | — | `tests/import-llm.test.ts` | exact |
| `tests/insights-ui.test.ts` | test | — | `tests/ui-components.test.ts` | exact |
| `src/infrastructure/db/schema.sql` *modified* | schema | — | itself (existing CREATE TABLE) | exact |
| `frontend/src/api.ts` *modified* | API client | request-response | itself (existing fetch pattern) | exact |
| `frontend/src/App.tsx` *modified* | router | — | itself (existing route/nav pattern) | exact |
| `frontend/src/pages/DashboardPage.tsx` *modified* | page | request-response | itself (existing card/grid pattern) | exact |
| `frontend/src/charts/ComboChart.tsx` *modified* | chart | — | itself (existing Line pattern) | exact |
| `vite.config.ts` *modified* | config | — | itself (existing proxy pattern) | exact |
| `index.ts` *modified* | route mount | — | itself (app.route() pattern) | exact |

---

## Pattern Assignments

### 1. `src/workers/insights-worker.ts` (worker, event-driven PGMQ polling)

**Analog:** `src/workers/import-worker.ts`

**Imports pattern** (lines 1-4):
```typescript
import { createHash } from 'crypto';
import sql from '../infrastructure/db/client';
import { ParsedTransactionSchema } from '../application/schemas/import';
import type { ParsedTransaction } from '../core/import/entities';
```
*For insights:* Replace with insight-specific imports from `../application/schemas/insights` and `../core/insights/entities`.

**Constants pattern** (lines 6-10):
```typescript
const QUEUE_NAME = 'import_queue';
const VISIBILITY_TIMEOUT = 300; // 5 minutes
const POLL_INTERVAL_MS = 5000;
const MAX_RETRIES = 3;
const BATCH_SIZE = 50;
```
*For insights:* Set `QUEUE_NAME = 'analysis_queue'`.

**OpenRouter call pattern** (lines 123-206) — `callOpenRouter()`:
```typescript
export async function callOpenRouter(csvRows: string, format: 'ing' | 'ipko'): Promise<ParsedTransaction[]> {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey && process.env.NODE_ENV !== 'test') {
    throw new Error('OPENROUTER_API_KEY not set');
  }
  const baseUrl = process.env.OPENROUTER_BASE_URL ?? 'https://openrouter.ai/api/v1';
  const model = process.env.OPENROUTER_MODEL ?? 'openai/gpt-4o-mini';
  const prompt = buildFewShotPrompt(format, csvRows);

  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey || 'dummy-key'}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://github.com/olafkrawczyk/finance',
      'X-Title': 'Financial Ingestion App',
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: prompt }],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'transactions_response',
          strict: true,
          schema: {
            type: 'object',
            properties: { /* ... */ },
            required: ['/* ... */'],
            additionalProperties: false,
          },
        },
      },
      temperature: 0.1,
      max_tokens: 4096,
    }),
  });
  // ... error handling and Zod validation ...
}
```
*For insights:* Create TWO callers (Claude + R1) using separate env vars:
- `OPENROUTER_INSIGHTS_MODEL` / `OPENROUTER_FORECAST_MODEL`
- Claude: system prompt with financial advisor few-shot examples, receives full `TransactionData[]`
- R1: system prompt with numerical forecasting few-shot examples, receives `CategoryAggregate[]` only

**Dedup hash pattern** (lines 67-71):
```typescript
export function computeImportHash(date: string, amount: string, description: string): string {
  return createHash('sha256')
    .update(`${date}|${amount}|${description}`)
    .digest('hex');
}
```
*For insights:* Compute dedup hash as `createHash('sha256').update(`${type}|${title}|${content}`).digest('hex')`.

**Worker polling loop pattern** (lines 347-389):
```typescript
async function workerLoop(): Promise<void> {
  console.log('Import worker starting. Recovering stuck jobs...');
  await recoverStuckJobs();
  while (true) {
    try {
      const messages = await sql`
        SELECT * FROM pgmq.read(${QUEUE_NAME}, ${VISIBILITY_TIMEOUT}, 1)
      `;
      if (messages.length === 0) {
        await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
        continue;
      }
      const msg = messages[0];
      const readCount = Number(msg.read_ct);
      const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;
      try {
        // process message...
        await sql`SELECT pgmq.archive(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
      } catch (err) {
        console.error(`Job ${msg.msg_id} failed (attempt ${readCount}):`, err);
        if (readCount >= MAX_RETRIES) {
          await sql`SELECT pgmq.delete(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        }
      }
    } catch (err) {
      console.error('Worker loop error:', err);
      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    }
  }
}

if (import.meta.main) {
  workerLoop();
}
```
*For insights:* Copy exactly. Replace queue name with `'analysis_queue'`. Add nightly batch check (`new Date().getHours() === 2` to trigger batched processing).

**Payload processing pattern** (lines 252-342) — `processJob()`:
- Reads `{ transaction_id }` from queue message
- Fetches transaction details from DB (D-06)
- Computes 3-month window + YoY data
- Calls Claude + R1 sequentially
- Zod-validates output
- Deduplicates against recent insights (14-day window)
- Inserts into `insights` table

---

### 2. `src/core/insights/entities.ts` (model/entity types)

**Analog:** `src/core/import/entities.ts`

**Pattern** (entire file, 20 lines):
```typescript
// NUMERIC(19,4) columns are typed as string — postgres.js returns them as strings.
// Never use number for monetary fields.

export interface ImportJob {
  id: string;                          // UUID
  account_id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  total_rows: number | null;
  processed: number;
  errors: string[] | null;
  created_at: string;                  // TIMESTAMPTZ as ISO string
  updated_at: string;                  // TIMESTAMPTZ as ISO string
}

export interface ParsedTransaction {
  date: string;                        // DATE as ISO string
  amount: string;                      // positive decimal string
  description: string;
  raw_type: 'income' | 'expense' | 'transfer';
}
```
*For insights:* Define `Insight`, `InsightType`, `Priority`, `CategoryAggregate`, `ForecastResult`:
```typescript
export type InsightType = 'alert' | 'tip' | 'trend' | 'forecast';
export type Priority = 'high' | 'medium' | 'low';

export interface Insight {
  id: string;
  type: InsightType;
  priority: Priority;
  title: string;
  content: string;
  linked_transaction_ids: string[];
  linked_category_ids: string[];
  dismissed: boolean;
  dedup_hash: string;
  created_at: string;
}

export interface CategoryAggregate {
  category_name: string;
  total_spent: string;
  percentage_of_total: string;
  trend_direction: 'up' | 'down' | 'flat';
  trend_percent: string;
  yoy_change_percent: string;
}
```

---

### 3. `src/core/insights/use-cases.ts` (service, CRUD + batch)

**Analogs:** `src/core/import/use-cases.ts` (enqueue pattern) + `src/core/ledger/use-cases.ts` (list/query pattern)

**Enqueue pattern** from `src/core/import/use-cases.ts` (lines 20-45):
```typescript
export async function enqueueImportJob(payload: { ... }): Promise<{ job_id: string; msg_id: number }> {
  return await sql.begin(async (sql) => {
    const [job] = await sql`
      INSERT INTO import_jobs (account_id, status)
      VALUES (${payload.account_id}, 'pending')
      RETURNING id
    `;
    const [sendResult] = await sql`
      SELECT pgmq.send('import_queue', ${JSON.stringify({ ... })}::jsonb) as msg_id
    `;
    return { job_id: job.id, msg_id: Number(sendResult.msg_id) };
  });
}
```
*For insights:* Create `enqueueAnalysisJob()` that sends `{ transaction_id }` to `analysis_queue`.

**List query pattern** from `src/core/ledger/use-cases.ts` (lines 28-61):
```typescript
export async function listTransactions(params: { ... }): Promise<{ rows: Transaction[]; total: number }> {
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
  const [{ count }] = await sql`SELECT COUNT(*) AS count FROM transactions ...`;
  return { rows: rows as Transaction[], total: Number(count) };
}
```
*For insights:* Create `listInsights()` (filterable by type, dismissed, date range), `dismissInsight(id)`, `getInsightsForDashboard(limit=3)`.

**Atomic PGMQ send pattern** from `src/core/ledger/use-cases.ts` (line 21):
```typescript
await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({ transaction_id: tx.id })}::jsonb)`;
```
*Note:* This already exists and enqueues per new transaction. The worker consumes this.

---

### 4. `src/application/schemas/insights.ts` (Zod schemas)

**Analog:** `src/application/schemas/import.ts` (lines 1-21)

**Pattern:**
```typescript
import * as z from 'zod';

export const ImportUploadSchema = z.object({
  account_id: z.uuid(),
  bank_format: z.enum(['ing', 'ipko']).optional(),
});

export const ParsedTransactionSchema = z.object({
  date: z.iso.date(),
  amount: z.string().regex(/^\d+(\.\d{1,4})?$/, 'Amount must be a positive decimal with up to 4 places'),
  description: z.string().min(1).max(2000),
  raw_type: z.enum(['income', 'expense', 'transfer']),
});

export type ImportUploadInput = z.infer<typeof ImportUploadSchema>;
export type ParsedTransaction = z.infer<typeof ParsedTransactionSchema>;
```
*For insights:* Create schemas for:
```typescript
// LLM output validation schemas (for filtering invalid LLM responses)
export const ClaudeInsightSchema = z.object({
  type: z.enum(['alert', 'tip', 'trend']),
  priority: z.enum(['high', 'medium', 'low']),
  title: z.string().min(1).max(500),
  content: z.string().min(1).max(2000),
});
export const ClaudeInsightsResponseSchema = z.object({
  insights: z.array(ClaudeInsightSchema),
});

export const R1ForecastSchema = z.object({
  category_name: z.string().min(1),
  predicted_spending: z.string().regex(/^\d+(\.\d{1,4})?$/),
  confidence: z.string().regex(/^\d+(\.\d{1,2})?$/),
  trend: z.enum(['up', 'down', 'flat']),
});
export const R1ForecastResponseSchema = z.object({
  forecasts: z.array(R1ForecastSchema),
});

// API schemas
export const ListInsightsQuerySchema = z.object({
  type: z.enum(['alert', 'tip', 'trend', 'forecast']).optional(),
  dismissed: z.coerce.boolean().optional(),
  page: z.coerce.number().int().min(1).default(1),
  per_page: z.coerce.number().int().min(1).max(100).default(20),
});
export const DismissInsightSchema = z.object({
  dismissed: z.literal(true),
});
export const GenerateInsightsSchema = z.object({
  user_id: z.string().optional(), // from auth context
});
```

---

### 5. `src/interface-adapters/api/insights.ts` (controller, request-response)

**Analog:** `src/interface-adapters/api/ledger.ts` (lines 1-124)

**Route setup pattern** (lines 1-11):
```typescript
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { CreateTransactionSchema, ListTransactionsQuerySchema } from '../../application/schemas/ledger';
import { createTransaction, listTransactions } from '../../core/ledger/use-cases';
import { requireAuth } from './auth';
import sql from '../../infrastructure/db/client';

export const ledgerRoutes = new Hono();
```

**GET route with query validation pattern** (lines 39-67):
```typescript
ledgerRoutes.get(
  '/',
  requireAuth,
  zValidator('query', ListTransactionsQuerySchema, (result, c) => {
    if (!result.success) {
      return c.json(
        { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
        400
      );
    }
  }),
  async (c) => {
    try {
      const query = c.req.valid('query');
      const { rows, total } = await listTransactions(query);
      return c.json(
        { data: rows, error: null, meta: { total, page: query.page, per_page: query.per_page } },
        200
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);
```

**PATCH route with param validation pattern** (lines 84-124):
```typescript
ledgerRoutes.patch(
  '/:id/category',
  requireAuth,
  zValidator('json', AssignCategorySchema, (result, c) => { /* ... */ }),
  async (c) => {
    try {
      const rawId = c.req.param('id');
      const parseResult = uuidSchema.safeParse(rawId);
      if (!parseResult.success) {
        return c.json({ data: null, error: { message: 'Invalid transaction id' }, meta: null }, 400);
      }
      const id = parseResult.data;
      // ... DB operation ...
      return c.json({ data: updated, error: null, meta: null }, 200);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error';
      return c.json({ data: null, error: { message }, meta: null }, 500);
    }
  }
);
```

*For insights:* Create `insightsRoutes` with:
- `GET /insights` → `listInsights()` — filterable by type, dismissed, date range
- `PATCH /insights/:id/dismiss` → `dismissInsight(id)` — sets dismissed=true
- `POST /insights/generate` → `enqueueAnalysisJob()` — enqueues manual generation
- `GET /insights/forecast` → returns AI forecast data for chart

**Auth middleware reuse** from `src/interface-adapters/api/auth.ts` (lines 1-12):
```typescript
import { createMiddleware } from 'hono/factory';
import { auth } from '../../auth';

export const requireAuth = createMiddleware(async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  if (!session) {
    return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
  }
  c.set('user', session.user);
  c.set('session', session.session);
  await next();
});
```
*Usage:* Import and use `requireAuth` on all insights routes exactly as ledger routes do.

---

### 6. `src/infrastructure/db/migrations/004_insights_table.sql` (migration)

**Analog:** `src/infrastructure/db/migrations/003_allow_category_update.sql` (lines 1-37)

**Pattern** — numbered SQL file with comment header:
```sql
-- 003_allow_category_update: Relax immutability trigger to allow category assignment
-- Changes: Allow UPDATE where only category_id changes from NULL to a non-null value
-- All other fields must remain unchanged

CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- ...
END;
$$;
```

*For insights:* Create `004_insights_table.sql`:
```sql
-- 004_insights_table: Add AI-generated insights storage
-- Creates the insights table for persisting LLM-generated financial insights
-- with dedup hash and dismiss tracking.

CREATE TABLE IF NOT EXISTS insights (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  type                   TEXT NOT NULL CHECK (type IN ('alert', 'tip', 'trend', 'forecast')),
  priority               TEXT NOT NULL CHECK (priority IN ('high', 'medium', 'low')),
  title                  TEXT NOT NULL,
  content                TEXT NOT NULL,
  linked_transaction_ids UUID[] NOT NULL DEFAULT '{}',
  linked_category_ids    UUID[] NOT NULL DEFAULT '{}',
  dismissed              BOOLEAN NOT NULL DEFAULT false,
  dedup_hash             TEXT NOT NULL,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for query patterns
CREATE INDEX IF NOT EXISTS idx_insights_user_type   ON insights(user_id, type);
CREATE INDEX IF NOT EXISTS idx_insights_user_dismiss ON insights(user_id, dismissed);
CREATE INDEX IF NOT EXISTS idx_insights_created_at   ON insights(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_insights_dedup        ON insights(dedup_hash, created_at);

-- Prevent update of immutable fields (only dismissed can change)
CREATE OR REPLACE FUNCTION block_insight_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Only allow changing the dismissed flag
  IF OLD.type = NEW.type
     AND OLD.priority = NEW.priority
     AND OLD.title = NEW.title
     AND OLD.content = NEW.content
     AND OLD.dedup_hash = NEW.dedup_hash
     AND OLD.user_id = NEW.user_id
     AND OLD.linked_transaction_ids = NEW.linked_transaction_ids
     AND OLD.linked_category_ids = NEW.linked_category_ids
     AND (OLD.dismissed IS DISTINCT FROM NEW.dismissed) THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'Insights are mostly immutable. Only the dismissed flag can be changed.';
END;
$$;

DROP TRIGGER IF EXISTS trg_insights_no_update ON insights;
CREATE TRIGGER trg_insights_no_update
  BEFORE UPDATE ON insights FOR EACH ROW
  EXECUTE FUNCTION block_insight_immutable_change();
```

---

### 7. `frontend/src/pages/InsightsPage.tsx` (page component)

**Analog:** `frontend/src/pages/DashboardPage.tsx` (lines 1-128)

**State/loading/error pattern** (lines 14-72):
```typescript
export default function DashboardPage({ onMonthClick }: DashboardPageProps) {
  const [data, setData] = useState<NormalizedSummaryRow[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getMonthlySummary()
      .then((rows) => {
        // process data...
        setData(normalized);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'Failed to load summary data');
        setLoading(false);
      });
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
        <p className="text-slate-400 mt-4 text-sm">Loading dashboard...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-lg mx-auto p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
        {error}
      </div>
    );
  }
  // ...
}
```

**Card grid pattern** (lines 93-125):
```typescript
<div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
  <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
    <h3 className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider">
      Stan konta z upływem czasu
    </h3>
    <BalanceChart data={data} onMonthClick={onMonthClick} />
  </div>
  {/* ... more cards ... */}
</div>
```

*For InsightsPage:* Use same card pattern. Group cards by type tabs. Add dismiss button per card. Use `getInsights()` from API.

---

### 8. `frontend/src/components/InsightCard.tsx` (UI component)

**Analog:** `frontend/src/components/ImportUpload.tsx` (dark theme card pattern, lines 92-101, 103-107, 206-211)

**Card wrapper pattern:**
```typescript
<div className="max-w-lg w-full mx-auto bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl shadow-2xl p-8 transition-all duration-300">
```

**Error alert pattern** (lines 103-107):
```typescript
{error && (
  <div role="alert" className="mb-6 p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
    {error}
  </div>
)}
```

**Button pattern** (lines 206-211):
```typescript
<button
  onClick={handleUpload}
  disabled={!file || !selectedAccount || isUploading}
  className={`w-full py-4 px-6 rounded-xl font-bold text-white shadow-lg transition-all duration-300 ${
    !file || !selectedAccount || isUploading
      ? 'bg-slate-800 text-slate-500 cursor-not-allowed shadow-none'
      : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 hover:shadow-blue-500/20 active:scale-95'
  }`}
>
```

*For InsightCard:* A compact card with: priority icon (red/yellow/blue dot), type badge, title, content (first 2 lines), linked transactions list, relative timestamp, dismiss button.

---

### 9. `frontend/src/components/InsightsWidget.tsx` (dashboard widget, 3 compact cards)

**Analog:** `frontend/src/components/ImportStatus.tsx` (polling pattern + card pattern, lines 21-60, 124-128)

**Polling pattern with timeout** (lines 26-60):
```typescript
useEffect(() => {
  let intervalId: any;
  const startTime = Date.now();
  const TIMEOUT_MS = 5 * 60 * 1000;

  const fetchStatus = () => {
    if (Date.now() - startTime > TIMEOUT_MS) {
      setError('Polling timed out...');
      clearInterval(intervalId);
      return;
    }
    getImportStatus(jobId)
      .then((data) => {
        setJob(data);
        if (data.status === 'completed' || data.status === 'failed') {
          clearInterval(intervalId);
        }
      })
      .catch((err) => {
        setError(err.message || 'Failed to poll job status');
        clearInterval(intervalId);
      });
  };

  intervalId = setInterval(fetchStatus, 2000);
  fetchStatus();
  return () => clearInterval(intervalId);
}, [jobId]);
```

*For InsightsWidget:* 
- Use `getInsights({ per_page: 3, dismissed: false })` on mount
- Optionally poll every 60s for new insights (lightweight auto-refresh)
- Render 3 compact cards horizontally above charts
- Each card: priority icon + first line of text + relative timestamp + link to `/insights`

**Status badge pattern** (lines 92-119) — useful for type badges:
```typescript
const statusConfig = {
  pending: { text: 'Pending', bgClass: 'bg-yellow-500/10 border-yellow-500/20 text-yellow-400', description: '...' },
  processing: { text: 'Processing', bgClass: 'bg-blue-500/10 border-blue-500/20 text-blue-400', description: '...' },
  completed: { text: 'Completed', bgClass: 'bg-green-500/10 border-green-500/20 text-green-400', description: '...' },
  failed: { text: 'Failed', bgClass: 'bg-red-500/10 border-red-500/20 text-red-400', description: '...' },
};
```

---

### 10. `frontend/src/components/InsightsTabs.tsx` (tab bar)

**Analog:** `frontend/src/App.tsx` (nav button pattern, lines 99-149)

**Active button pattern:**
```typescript
<button
  onClick={() => navigateTo('/dashboard')}
  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
    currentPath === '/dashboard' || currentPath === '/'
      ? 'bg-slate-900 text-blue-400'
      : 'text-slate-400 hover:text-slate-200'
  }`}
>
  Dashboard
</button>
```

*For InsightsTabs:* Tab bar with buttons for Alerts, Trends, Tips, Forecasts. Each button has a count badge. Active tab uses `bg-slate-900 text-blue-400`, inactive uses `text-slate-400 hover:text-slate-200`.

---

### 11. `frontend/src/lib/insights.ts` (utility)

**Analog:** `frontend/src/lib/linearRegression.ts`

**Pattern:** A single-file utility that exports pure functions. For insights, this would export formatting helpers:
- `formatRelativeTime(createdAt: string): string` — "2 hours ago", "3 days ago"
- `getPriorityColor(priority: 'high' | 'medium' | 'low'): string` — returns Tailwind color classes
- `getTypeIcon(type: 'alert' | 'tip' | 'trend' | 'forecast'): string` — returns icon component name
- `getTypeLabel(type: InsightType): string` — Polish labels (Alert, Porada, Trend, Prognoza)

---

### 12. `tests/insights-schemas.test.ts` (Zod schema tests)

**Analog:** `tests/import-schemas.test.ts` (lines 1-81)

**Pattern:**
```typescript
import { describe, it, expect } from 'bun:test';
import { ParsedTransactionSchema } from '../src/application/schemas/import';

describe('Import Schema Tests', () => {
  describe('ParsedTransactionSchema', () => {
    it('accepts a valid parsed transaction', () => {
      const result = ParsedTransactionSchema.safeParse({ ... });
      expect(result.success).toBe(true);
    });
    it('rejects negative amounts', () => {
      const result = ParsedTransactionSchema.safeParse({ amount: '-246.00', ... });
      expect(result.success).toBe(false);
    });
    it('rejects invalid raw_types', () => {
      const result = ParsedTransactionSchema.safeParse({ raw_type: 'refund', ... });
      expect(result.success).toBe(false);
    });
  });
});
```

*For insights:* Test:
- `ClaudeInsightSchema` — accepts valid insight, rejects missing title, rejects invalid type
- `R1ForecastSchema` — accepts valid forecast, rejects negative confidence
- `ListInsightsQuerySchema` — validates pagination defaults, rejects invalid type filter
- `DismissInsightSchema` — accepts true, rejects false

---

### 13. `tests/insights-api.test.ts` (API endpoint tests)

**Analog:** `tests/api.test.ts` (lines 1-315)

**Setup pattern** (lines 12-44):
```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

beforeAll(async () => {
  await sql`TRUNCATE transactions CASCADE`;
  await sql`DELETE FROM pgmq.q_analysis_queue`;
  // ... setup session cookie ...
  const res = await auth.api.signUpEmail({ body: { ... }, asResponse: true });
  const setCookie = res.headers.get('set-cookie');
  sessionCookie = setCookie;
});
```

**Auth test pattern** (lines 246-255):
```typescript
it('rejects PATCH request without auth', async () => {
  const res = await app.request(`/transactions/${txId}/category`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ category_id: categoryId }),
  });
  expect(res.status).toBe(401);
});
```

**CRUD test pattern** (lines 104-127):
```typescript
it('POST /transactions creates a transaction', async () => {
  const res = await app.request('/transactions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Cookie: sessionCookie },
    body: JSON.stringify({ ... }),
  });
  expect(res.status).toBe(201);
  const json = await res.json();
  expect(json.data.id).toBeDefined();
  expect(json.error).toBeNull();
  expect(json.meta).toBeNull();
});
```

*For insights:* Test:
- `GET /insights` — returns paginated list with correct envelope
- `GET /insights?type=alert` — filters by type
- `PATCH /insights/:id/dismiss` — sets dismissed=true, returns 200
- `POST /insights/generate` — enqueues job, returns 202
- All routes protected by auth (401 without session cookie)

---

### 14. `tests/insights-worker.test.ts` (worker tests)

**Analog:** `tests/import-worker.test.ts` (lines 1-155)

**Mock server pattern** (lines 24-64):
```typescript
mockServer = Bun.serve({
  port: 0,
  async fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === '/chat/completions') {
      const body = await req.json();
      // return mock LLM response matching the prompt structure
      return new Response(
        JSON.stringify({
          choices: [{ message: { content: JSON.stringify({ transactions: [...] }) } }],
        }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      );
    }
    return new Response('Not found', { status: 404 });
  },
});
mockPort = mockServer.port;
process.env.OPENROUTER_API_KEY = 'test-key';
process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
```

**Worker test pattern** (lines 71-137):
```typescript
it('processes import job, links transfers, updates job status, and dedups', async () => {
  // 1. Enqueue job
  const { job_id, msg_id } = await enqueueImportJob({ ... });
  // 2. Read message from PGMQ
  const messages = await sql`SELECT * FROM pgmq.read('import_queue', 300, 1)`;
  // 3. Process the job
  const result = await processJob(payload);
  // 4. Archive message
  await sql`SELECT pgmq.archive('import_queue', ${msg.msg_id}::bigint)`;
  // 5. Verify DB state
  const txs = await sql`SELECT * FROM transactions WHERE ...`;
  expect(txs).toHaveLength(3);
});
```

*For insights:* Test:
- Full round-trip: enqueue → worker reads → calls mock LLM → inserts to insights → archives
- Dedup: insert same insight twice → verify only one row
- Privacy boundary: verify R1 prompt does NOT contain transaction descriptions
- Queue lifecycle: read → process → archive on success, read → retry → delete on max retries

---

### 15. `tests/insights-llm.test.ts` (LLM integration tests)

**Analog:** `tests/import-llm.test.ts` (lines 1-109)

**Mock server + Zod filtering test pattern** (lines 86-96):
```typescript
it('successfully fetches and filters transactions using Zod schema', async () => {
  const parsed = await callOpenRouter('dummy csv rows', 'ing');
  // Expecting only the 1 valid transaction, other 2 should be filtered out by Zod
  expect(parsed).toHaveLength(1);
  expect(parsed[0].date).toBe('2026-06-01');
  expect(parsed[0].amount).toBe('120.00');
});
```

**Error handling pattern** (lines 98-108):
```typescript
it('throws an error when the OpenRouter API returns an error status', async () => {
  process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}/error`;
  expect(callOpenRouter('dummy csv rows', 'ing')).rejects.toThrow('OpenRouter error: 500');
  process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
});
```

*For insights:* Test Claude caller and R1 caller separately:
- Claude caller returns valid Insight array, filters invalid items
- R1 caller returns valid Forecast array, filters invalid items
- Both handle API errors (500, 429) correctly
- Both handle empty response content gracefully

---

### 16. `tests/insights-ui.test.ts` (frontend component tests)

**Analog:** `tests/ui-components.test.ts` (lines 1-29)

**Pattern:**
```typescript
import { describe, it, expect } from 'bun:test';
import React from 'react';
import { renderToString } from 'react-dom/server';
import ImportUpload from '../frontend/src/components/ImportUpload';

describe('UI Component Rendering Tests', () => {
  it('renders ImportUpload component without crashing', () => {
    const html = renderToString(
      React.createElement(ImportUpload, { onImportStarted: () => {} })
    );
    expect(html).toContain('Import Transactions');
    expect(html).toContain('Select Account');
    expect(html).toContain('Upload Statement');
  });
});
```

*For insights:* Test:
- `InsightCard` renders with title, content, priority indicator
- `InsightsWidget` renders 3 compact cards
- `InsightsTabs` renders all 4 tab buttons
- `ComboChart` renders two prediction lines (LR + AI) with distinct colors

**Build test pattern** from `tests/ui-build.test.ts` (lines 1-17):
```typescript
it('compiles the Vite + React + Tailwind production build successfully', () => {
  const result = spawnSync('bun', ['run', 'build:web'], { ... });
  expect(result.status).toBe(0);
});
```

---

### 17-23. Modified Files (self-analog patterns)

#### 17. `src/infrastructure/db/schema.sql` — Add insights table

**Analog:** itself — follow existing CREATE TABLE pattern from lines 19-30 (transactions table):
```sql
CREATE TABLE IF NOT EXISTS transactions (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id             UUID NOT NULL REFERENCES accounts(id),
  category_id            UUID REFERENCES categories(id),
  type                   TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  amount                 NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
  description            TEXT,
  date                   DATE NOT NULL,
  transfer_to_account_id UUID REFERENCES accounts(id),
  import_hash            TEXT UNIQUE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
```
Follow the same `CREATE TABLE IF NOT EXISTS`, `CHECK` constraints, index creation, and `CREATE OR REPLACE FUNCTION` patterns.

#### 18. `frontend/src/api.ts` — Add insight API functions

**Analog:** itself — follow existing function pattern (lines 1-135):
```typescript
export async function getMonthlySummary() {
  const res = await fetch('/transactions/summary', { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch summary: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}
```
Add:
```typescript
export async function getInsights(params?: { type?: string; dismissed?: boolean; page?: number; per_page?: number }) {
  const searchParams = new URLSearchParams();
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.set(key, String(value));
    });
  }
  const qs = searchParams.toString();
  const res = await fetch(`/insights${qs ? '?' + qs : ''}`, { credentials: 'include' });
  if (!res.ok) throw new Error(`Failed to fetch insights: ${res.statusText}`);
  const json = await res.json();
  return { data: json.data, meta: json.meta };
}

export async function dismissInsight(insightId: string) {
  const res = await fetch(`/insights/${insightId}/dismiss`, {
    method: 'PATCH',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ dismissed: true }),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to dismiss insight: ${res.statusText}`);
  }
  return res.json();
}

export async function generateInsights() {
  const res = await fetch('/insights/generate', {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to generate insights: ${res.statusText}`);
  }
  return res.json();
}

export async function getInsightsForecast() {
  const res = await fetch('/insights/forecast', { credentials: 'include' });
  if (!res.ok) throw new Error(`Failed to fetch forecast: ${res.statusText}`);
  const json = await res.json();
  return json.data;
}
```

#### 19. `frontend/src/App.tsx` — Add /insights route + nav button

**Analog:** itself — follow existing nav pattern (lines 99-149) and route rendering (lines 30-84):

**Nav button** (follow lines 99-109):
```typescript
<button
  onClick={() => navigateTo('/insights')}
  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
    currentPath.startsWith('/insights')
      ? 'bg-slate-900 text-blue-400'
      : 'text-slate-400 hover:text-slate-200'
  }`}
>
  Insights
</button>
```

**Route rendering** (follow lines 30-33):
```typescript
if (currentPath.startsWith('/insights')) {
  return <InsightsPage />;
}
```

#### 20. `frontend/src/pages/DashboardPage.tsx` — Add insight widget above charts

**Analog:** itself — insert InsightsWidget before the chart grid (before line 93):
```typescript
{/* AI Insights Widget */}
<InsightsWidget />

<div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
  {/* existing charts... */}
</div>
```

#### 21. `frontend/src/charts/ComboChart.tsx` — Add AI forecast line

**Analog:** itself — follow existing Line pattern (lines 76-84):
```typescript
<Line
  type="monotone"
  dataKey="prediction"
  stroke="#f59e0b"
  strokeWidth={2}
  strokeDasharray="8 4"
  connectNulls
  name="Predykcja"
/>
```
Add AI forecast line:
```typescript
<Line
  type="monotone"
  dataKey="aiForecast"
  stroke="#06b6d4"        // cyan — distinct from LR amber
  strokeWidth={2}
  strokeDasharray="4 4"   // different dash pattern
  connectNulls
  name="Predykcja (AI)"
/>
```
Update `mergedData` to include `aiForecast` from props.

#### 22. `vite.config.ts` — Add /insights proxy

**Analog:** itself — follow existing proxy pattern (lines 10-33):
```typescript
proxy: {
  '/insights': {
    target: 'http://localhost:3000',
    changeOrigin: true,
  },
  // ... existing proxies ...
}
```

#### 23. `index.ts` — Mount insights routes

**Analog:** itself — follow existing route mounting pattern (lines 46-52):
```typescript
import { importRoutes } from './src/interface-adapters/api/import';

// Domain routes
app.route('/transactions', ledgerRoutes);
app.route('/opening-balance', openingBalanceRoutes);
app.route('/import', importRoutes);
app.route('/', referenceRoutes);
```
Add:
```typescript
import { insightsRoutes } from './src/interface-adapters/api/insights';
// ...
app.route('/insights', insightsRoutes);
```

---

## Shared Patterns

### Authentication
**Source:** `src/interface-adapters/api/auth.ts` (lines 1-12)
**Apply to:** `src/interface-adapters/api/insights.ts` (all routes)
```typescript
import { requireAuth } from './auth';
// Use: requireAuth as first middleware on ALL routes
```

### API Response Envelope
**Source:** `src/interface-adapters/api/ledger.ts` (lines 29, 55-60, 121)
**Apply to:** All API responses
```typescript
// Success: { data, error: null, meta }
return c.json({ data: tx, error: null, meta: null }, 201);
return c.json({ data: rows, error: null, meta: { total, page, per_page } }, 200);

// Error: { data: null, error: { message }, meta: null }
return c.json({ data: null, error: { message }, meta: null }, 500);
return c.json({ data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null }, 400);
```

### Zod Validation (Hono validator)
**Source:** `src/interface-adapters/api/ledger.ts` (lines 17-24, 42-49)
**Apply to:** All POST/PATCH/PUT handlers
```typescript
zValidator('json', SomeSchema, (result, c) => {
  if (!result.success) {
    return c.json(
      { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
      400
    );
  }
})
```

### Structured JSON Output (OpenRouter)
**Source:** `src/workers/import-worker.ts` (lines 123-206)
**Apply to:** Both Claude and R1 caller functions
- `response_format: { type: 'json_schema', json_schema: { name: '...', strict: true, schema: {...} } }`
- Temperature: 0.1
- `JSON.parse(content)` then `ZodSchema.safeParse()` per item
- Filter invalid items, warn, don't throw

### PGMQ Polling Loop
**Source:** `src/workers/import-worker.ts` (lines 347-389)
**Apply to:** `src/workers/insights-worker.ts`
- `pgmq.read(queue, visibilityTimeout, 1)` in infinite loop
- Retry: track `read_ct`, delete after `MAX_RETRIES`
- Archive on success, delete on permanent failure
- Poll interval: 5000ms
- `if (import.meta.main) { workerLoop(); }`

### Dedup Hash
**Source:** `src/workers/import-worker.ts` (lines 67-71)
**Apply to:** Insight dedup logic
```typescript
import { createHash } from 'crypto';
const hash = createHash('sha256')
  .update(`${type}|${title}|${content}`)
  .digest('hex');
```
Query before insert: `SELECT 1 FROM insights WHERE dedup_hash = $hash AND created_at > now() - interval '14 days'`

### Dark Theme Tailwind Classes
**Source:** `frontend/src/components/ImportUpload.tsx` (lines 92-101, 124-128, 150-160)
**Apply to:** All new frontend components
```tsx
// Card wrapper
className="bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl shadow-2xl p-8"

// Card in grid
className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6"

// Section heading
className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider"

// Error alert
className="p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm"

// Input/select
className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"

// Primary button (active)
className="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white rounded-xl font-bold"

// Secondary button
className="bg-slate-950 border border-slate-800 hover:bg-slate-900 text-slate-200 rounded-xl font-bold"
```

---

## No Analog Found

None — all 23 files have strong analogs in the existing codebase. This phase is a textbook case of "copy existing patterns to a new domain."

| File | Reason pattern exists |
|------|----------------------|
| (none) | All files have exact or role-match analogs |

---

## Metadata

**Analog search scope:** `src/workers/`, `src/core/`, `src/application/schemas/`, `src/interface-adapters/api/`, `src/infrastructure/db/`, `frontend/src/`, `tests/`
**Files scanned:** 25 analog files read
**Pattern extraction date:** 2026-06-06
**Key insight:** The import-worker already solved every hard problem: OpenRouter integration with structured JSON output, PGMQ polling with retry, Zod validation of LLM output, batch processing, and dedup hashing. The insights worker is a specialized variant — different queue (`analysis_queue`), two models instead of one, different output schemas, but identical architecture.
