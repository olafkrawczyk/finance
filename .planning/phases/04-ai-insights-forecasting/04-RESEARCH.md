# Phase 4: AI Insights & Forecasting - Research

**Researched:** 2026-06-06
**Domain:** AI-powered financial analysis (OpenRouter, prompt engineering, PGMQ workers)
**Confidence:** HIGH

## Summary

Phase 4 adds AI-powered spending analysis, forecasting, and recommendations on top of the existing ledger and views. It integrates OpenRouter with a two-tier model setup: Claude Sonnet 4 (`anthropic/claude-sonnet-4`) for narrative financial insights and DeepSeek R1 (`deepseek/deepseek-r1` or `deepseek/deepseek-r1:free` for free tier) for numerical forecasting. A new PGMQ worker consumes the existing `analysis_queue`, runs nightly batch analysis and on-demand generation. Results are persisted in a new `insights` DB table with dedup and dismiss tracking, displayed via a dedicated `/insights` page and a compact dashboard widget.

The codebase already has robust patterns for this: the import-worker (`src/workers/import-worker.ts`) demonstrates the exact OpenRouter integration pattern (structured JSON schema output, temperature 0.1, few-shot prompting, Zod validation), PGMQ polling loop, retry logic, and batch processing. The Hono route patterns, Zod schemas, API envelope format, and frontend dark-theme card patterns are all established and should be reused verbatim.

**Primary recommendation:** Copy the import-worker's `callOpenRouter()` pattern exactly, creating two specialized callers (one for Claude/narrative, one for R1/numerical) that share the same structured output + Zod validation approach. Build the insights worker as a separate process following the same PGMQ polling loop pattern. No new npm packages are required — all dependencies already exist in the project.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Full financial advisor — monthly spending summaries, category-level anomaly detection, savings tips, budget threshold alerts, and forward-looking recommendations.
- **D-02:** Context-driven from 3-month rolling data window + year-over-year comparison. No user profile learning — each run is self-contained from the transaction data.
- **D-03:** Exhaustive generation — the AI generates all detected insights. Frontend filters and deduplicates. No cap on number of insights per run.
- **D-04:** Insights link to specific transactions/categories as evidence. Users can dismiss individual insights (persisted in DB, dismissed insights don't reappear).
- **D-05:** Hybrid trigger — nightly batch PGMQ worker processes all queued messages from `analysis_queue`, plus on-demand generation triggered from the UI (enqueues a manual job).
- **D-06:** The existing `analysis_queue` (receives `{ transaction_id }` per new transaction) drives the worker. Transaction details are fetched from DB at processing time, not embedded in the queue message.
- **D-07:** Dedicated `/insights` page with cards grouped by type tabs: Alerts, Trends, Tips, Forecasts. Each card shows icon + insight text + linked transactions + timestamp. Uses existing dark theme card pattern.
- **D-08:** Dashboard widget — horizontal row of 3 compact insight cards above the 4 existing charts. Each card: priority icon (red/yellow/blue) + first line of insight text + relative timestamp + link to `/insights`.
- **D-09:** Two-tier model setup: Claude Sonnet 4 (`OPENROUTER_INSIGHTS_MODEL` env var) for narrative insights (receives full raw transaction list), DeepSeek R1 (`OPENROUTER_FORECAST_MODEL` env var) for numerical forecasting (receives ONLY anonymized numerical aggregates).
- **D-10:** Both models use the same structured JSON output + few-shot prompting pattern as the import-worker. Temperature 0.1, `response_format: json_schema`, strict Zod validation.
- **D-11:** Models are env-var configurable for easy swapping. Defaults: Claude Sonnet 4 for insights, DeepSeek R1 for forecasting.
- **D-12:** 3-month rolling transaction window + same months from previous year for YoY comparison.
- **D-13:** Raw transactions sent to Claude (full detail). Only anonymized numerical aggregates sent to R1 (category totals, percentages, trend values — no individual transaction text).
- **D-14:** Insights persisted in new `insights` DB table: `id, type (alert|tip|trend|forecast), priority (high|medium|low), title, content, linked_transaction_ids[], linked_category_ids[], dismissed (boolean), created_at`. Worker deduplicates against similar recent insights before insert.
- **D-15:** Category-level spending forecast — AI predicts next month's spending per category + 3-month savings trajectory.
- **D-16:** Dual prediction lines on the dashboard ComboChart: keep existing LR line, add new AI forecast line (different color/dash pattern).
- **D-17:** Forecast horizon: 3 months ahead (R1 does the math, Claude wraps it in narrative insight).

### the agent's Discretion
- Exact OpenRouter prompt templates for each insight type (few-shot examples, output schema)
- Worker architecture — separate process vs same process as import-worker, cron scheduling approach
- Insights DB table schema details (indexes, dedup query strategy, TTL/cleanup for old insights)
- API endpoint design: route structure, Zod schemas for insight request/response
- Error handling and retry strategy (reuse import-worker's retry/backoff pattern)
- Frontend filtering controls on `/insights` page (type tabs, date range, pagination)
- How the "on-demand generate" UI trigger integrates with the PGMQ worker
- Insight dedup logic — exact matching vs fuzzy/semantic dedup
- Dashboard widget auto-refresh strategy (polling interval, SSE, or manual)
- Nav bar integration — badge count for new insights, route placement
- Forecasting model prompt engineering for financial accuracy
- Exact chart styling for the dual prediction lines (colors, dash patterns, legend labels)

### Deferred Ideas (OUT OF SCOPE)
- Worker architecture details — separate process, cron scheduling, whether to share process with import-worker. The agent decides.
- Error handling and fallback UX for OpenRouter downtime.
- Nav bar badge count for new/unread insights.
- Frontend filtering controls (search, date range) on `/insights` page.
- Notification/push for new insights discoveries.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| AI model orchestration (Claude Sonnet + DeepSeek R1) | API / Backend | — | Worker calls OpenRouter API; no browser involvement |
| PGMQ message consumption from `analysis_queue` | API / Backend (Worker) | — | Worker process polls PGMQ queue in Postgres |
| Insight generation (prompt engineering, JSON parsing) | API / Backend (Worker) | — | Structured output processing happens server-side |
| Data scope computation (3-month window + YoY) | API / Backend | — | SQL queries aggregate transaction data |
| Privacy tier enforcement (Claude=full, R1=aggregates) | API / Backend (Worker) | — | Hard boundary enforced in worker code before data reaches R1 |
| Insight persistence & dedup | Database / Storage | — | Postgres `insights` table with dedup queries |
| Insight retrieval API | API / Backend | — | Hono routes with Zod validation |
| Insights page rendering (cards, tabs, filtering) | Browser / Client | — | React components with Tailwind CSS |
| Dashboard insight widget (compact cards) | Browser / Client | — | React component above existing charts |
| Dual prediction lines (LR + AI forecast) on ComboChart | Browser / Client | — | Recharts extension of existing ComboChart |
| Insight dismissal (UI toggle + DB update) | Browser / Client | API / Backend | Frontend triggers PATCH, backend persists |
| On-demand generation trigger | Browser / Client | API / Backend | Frontend POST enqueues PGMQ job, worker picks up |
| Auth enforcement on all insight routes | API / Backend | — | `requireAuth` middleware reused from existing pattern |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bun | 1.3.14 | Runtime for worker + API server | Already in project; native fetch, built-in crypto, fast startup |
| Hono | 4.12.23 | API framework for insight routes | Already in project; existing route pattern |
| postgres.js | 3.4.9 | Database client (`sql` template tags) | Already in project; used by all data access |
| Zod | 4.4.3 | Schema validation for insights request/response + OpenRouter output parsing | Already in project; D-10 requires strict validation |
| @hono/zod-validator | 0.8.0 | Hono middleware for Zod request validation | Already in project; existing route pattern |
| React | 19.2.7 | Frontend for insights page + dashboard widget | Already in project |
| Recharts | 3.8.1 | Chart library for dual prediction lines on ComboChart | Already in project; ComboChart uses `ComposedChart` from Recharts |
| Tailwind CSS | 4.3.0 | Styling for insight cards and dashboard widget | Already in project; dark theme classes established |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| crypto (Bun built-in) | — | SHA-256 hashing for insight dedup | When computing dedup hashes for new insights |
| fetch (Bun built-in) | — | HTTP calls to OpenRouter API | All OpenRouter API calls (copy pattern from import-worker) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw `fetch()` for OpenRouter | `@openrouter/sdk` (TypeScript SDK) | No new dependency needed; raw fetch already proven in import-worker with retry/error handling. SDK adds dependency weight with no benefit — the fetch-based pattern is well-tested in this codebase |
| Separate npm scheduling lib (node-cron, cron) | Bun built-in `setInterval` or `setTimeout` | The import-worker already uses an infinite polling loop with `setTimeout`. Adding a scheduling library for nightly batch is unnecessary complexity — a simple check against current hour within the polling loop suffices |
| Fuzzy/semantic dedup (embeddings, vector similarity) | Exact content hash dedup | Exact SHA-256 hash of insight type + title + content is simpler, deterministic, and matches the existing `import_hash` pattern. Semantic dedup is overengineered for this scope and would require embedding models |

**Installation:**
```bash
# No new packages required. All dependencies already in package.json.
# Verify:
bun install  # ensures all existing deps are installed
```

**Version verification:** All packages verified via `npm view` and `bun --version` — versions match installed versions in the project.

## Package Legitimacy Audit

> This phase requires **zero new external packages**. All capabilities are built using dependencies already installed in the project.

| Package | Registry | Status | Disposition |
|---------|----------|--------|-------------|
| None | — | — | No new packages required |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*All functionality is built on existing, verified dependencies (hono, zod, postgres, @hono/zod-validator, react, recharts, tailwindcss). No slopcheck audit needed.*

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        BROWSER / CLIENT                         │
│                                                                 │
│  ┌──────────────┐  ┌─────────────────┐  ┌───────────────────┐  │
│  │ /dashboard   │  │ /insights       │  │ ComboChart        │  │
│  │ SlackWidget  │  │ InsightsPage    │  │ (LR + AI lines)  │  │
│  │ (3 cards)    │  │ (tabs, cards)   │  │                   │  │
│  └──────┬───────┘  └───────┬─────────┘  └─────────┬─────────┘  │
│         │                  │                       │            │
│    api.getInsights()  api.dismissInsight()   api.getForecast() │
│    api.generateInsights()                                       │
└─────────┼──────────────────┼───────────────────────┼───────────┘
          │                  │                       │
     ─────┼──────────────────┼───────────────────────┼───────────
          ▼                  ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Bun HTTP Server (Hono)                         │
│                                                                 │
│  GET  /insights         → listInsights()     [requireAuth]      │
│  PATCH /insights/:id    → dismissInsight()   [requireAuth]      │
│  POST /insights/generate → enqueueAnalysisJob() [requireAuth]   │
│  GET  /insights/forecast → getForecastData()  [requireAuth]     │
│                                                                 │
│  Envelope: { data, error, meta }                                 │
└─────────┬──────────────────┬────────────────────────────────────┘
          │                  │
          ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Postgres + PGMQ                             │
│                                                                 │
│  ┌──────────────────┐    ┌────────────────────────────────┐    │
│  │ insights table   │    │ analysis_queue (PGMQ)          │    │
│  │ - id             │    │ ← enqueued per new transaction │    │
│  │ - type           │    │ ← enqueued per manual generate │    │
│  │ - priority       │    └───────────┬────────────────────┘    │
│  │ - title, content │                │                          │
│  │ - linked_tx_ids  │                ▼                          │
│  │ - linked_cat_ids │    ┌────────────────────────────────┐    │
│  │ - dismissed      │    │ Insights Worker (separate proc)│    │
│  │ - dedup_hash     │    │                                │    │
│  │ - created_at     │    │ 1. pgmq.read(analysis_queue)   │    │
│  └──────────────────┘    │ 2. Fetch tx data from DB       │    │
│                          │ 3. Compute 3mo window + YoY    │    │
│                          │ 4. callClaudeSonnet(full data) │    │
│                          │ 5. callDeepSeekR1(aggregates)  │    │
│                          │ 6. Parse + Zod validate         │    │
│                          │ 7. Dedup against recent insights│    │
│                          │ 8. INSERT into insights table   │    │
│                          │ 9. pgmq.archive() or .delete()  │    │
│                          └───────────┬────────────────────┘    │
│                                      │                          │
└──────────────────────────────────────┼──────────────────────────┘
                                       │
                                       ▼
                          ┌────────────────────────┐
                          │   OpenRouter API        │
                          │                         │
                          │  Claude Sonnet 4        │
                          │  (narrative insights)   │
                          │  DeepSeek R1            │
                          │  (numerical forecasts)  │
                          └────────────────────────┘
```

### Recommended Project Structure
```
src/
├── workers/
│   ├── import-worker.ts        # Existing — PGMQ + OpenRouter pattern
│   └── insights-worker.ts      # NEW — copies import-worker polling loop
├── core/
│   ├── import/                 # Existing
│   ├── ledger/                 # Existing
│   └── insights/               # NEW
│       ├── entities.ts         # Insight type definitions
│       └── use-cases.ts        # generateInsights, listInsights, dismissInsight
├── application/
│   └── schemas/
│       ├── import.ts           # Existing
│       ├── ledger.ts           # Existing
│       └── insights.ts         # NEW — insight Zod schemas
├── interface-adapters/
│   └── api/
│       ├── insights.ts         # NEW — Hono routes for /insights
│       └── ...                 # Existing routes
└── infrastructure/
    └── db/
        ├── schema.sql          # MODIFIED — add insights table
        ├── seed.sql            # Existing
        └── migrations/
            └── 004_insights_table.sql  # NEW migration

frontend/src/
├── api.ts                      # MODIFIED — add insights API functions
├── App.tsx                     # MODIFIED — add /insights route + nav button
├── pages/
│   ├── DashboardPage.tsx       # MODIFIED — add insight widget above charts
│   └── InsightsPage.tsx        # NEW — dedicated insights page
├── components/
│   ├── InsightCard.tsx         # NEW — individual insight card
│   ├── InsightsWidget.tsx      # NEW — dashboard compact widget (3 cards)
│   └── InsightsTabs.tsx        # NEW — type tab bar (Alerts/Trends/Tips/Forecasts)
├── charts/
│   └── ComboChart.tsx          # MODIFIED — add AI forecast line
└── lib/
    └── insights.ts             # NEW — insight type helpers, formatting

tests/
├── insights-schemas.test.ts    # NEW — Zod schema validation tests
├── insights-api.test.ts        # NEW — API endpoint integration tests
├── insights-worker.test.ts     # NEW — Worker unit + integration tests
├── insights-llm.test.ts        # NEW — OpenRouter mock tests (like import-llm.test.ts)
└── insights-ui.test.ts         # NEW — Frontend component render tests
```

### Pattern 1: Dual-Model OpenRouter Call (Copy import-worker Pattern)

**What:** Create two specialized OpenRouter caller functions — one for Claude (narrative insights) and one for DeepSeek R1 (numerical forecasting). Both follow the exact same `response_format: json_schema` + Zod validation pattern established in `import-worker.ts:callOpenRouter()`.

**When to use:** Every AI insight generation cycle. Claude gets full transaction data for rich narrative analysis. DeepSeek R1 gets only anonymized numerical aggregates (category totals, percentages, trend values).

**Key differences from import-worker:**
- Different model IDs (env-var configurable)
- Claude: system message with few-shot financial advisor examples
- R1: system message with few-shot numerical forecasting examples
- Different JSON output schemas (narrative insight array vs forecast array)
- Different temperature: both at 0.1 (matching import-worker for deterministic output)

**Example (pattern sketch):**
```typescript
// Source: Pattern derived from src/workers/import-worker.ts:123-206

const INSIGHTS_MODEL = process.env.OPENROUTER_INSIGHTS_MODEL ?? 'anthropic/claude-sonnet-4';
const FORECAST_MODEL = process.env.OPENROUTER_FORECAST_MODEL ?? 'deepseek/deepseek-r1';
const OPENROUTER_BASE_URL = process.env.OPENROUTER_BASE_URL ?? 'https://openrouter.ai/api/v1';

export async function callClaudeForInsights(
  transactions: TransactionData[]
): Promise<Insight[]> {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey && process.env.NODE_ENV !== 'test') {
    throw new Error('OPENROUTER_API_KEY not set');
  }

  const prompt = buildInsightsPrompt(transactions);
  
  const response = await fetch(`${OPENROUTER_BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey || 'dummy-key'}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: INSIGHTS_MODEL,
      messages: [
        { role: 'system', content: buildInsightsSystemPrompt() },
        { role: 'user', content: prompt },
      ],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'insights_response',
          strict: true,
          schema: {
            type: 'object',
            properties: {
              insights: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    type: { type: 'string', enum: ['alert', 'tip', 'trend'] },
                    priority: { type: 'string', enum: ['high', 'medium', 'low'] },
                    title: { type: 'string' },
                    content: { type: 'string' },
                  },
                  required: ['type', 'priority', 'title', 'content'],
                  additionalProperties: false,
                },
              },
            },
            required: ['insights'],
            additionalProperties: false,
          },
        },
      },
      temperature: 0.1,
      max_tokens: 4096,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenRouter error: ${response.status} ${errorText}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('Empty message content from OpenRouter');
  
  const parsed = JSON.parse(content);
  const valid = parsed.insights.filter((i: any) => {
    const validation = InsightSchema.safeParse(i);
    if (!validation.success) {
      console.warn('Filtered invalid insight:', validation.error.format());
    }
    return validation.success;
  });
  return valid;
}
```

### Pattern 2: PGMQ Worker Polling Loop (Copy import-worker Pattern)

**What:** Infinite polling loop using `pgmq.read()` with visibility timeout, retry logic, and stuck job recovery. The insights worker reads from `analysis_queue` (the import-worker reads from `import_queue`).

**Key parameters (copied from import-worker):**
- Visibility timeout: 300 (5 minutes) — sufficient for LLM call latency
- Poll interval: 5000ms (5 seconds)
- Max retries: 3
- Stuck job recovery: mark as failed after 15 minutes

**Differences from import-worker:**
- Queue name: `analysis_queue` (not `import_queue`)
- Message payload: `{ transaction_id: string }` (not full CSV content)
- Processing: Fetch transaction details from DB at processing time (D-06)
- Batching: Accumulate queued transaction_ids, batch-process periodically (nightly) or process on-demand

### Pattern 3: Hono Route + Zod Validation (Copy ledger Routes Pattern)

**What:** New `/insights` route group following the exact same patterns as `src/interface-adapters/api/ledger.ts`:
- `requireAuth` middleware on all routes
- `zValidator` for request body validation
- Response envelope: `{ data, error, meta }`
- Error handling: try/catch → 400/404/500 with structured error

**Routes needed:**
- `GET /insights` — list insights (filterable by type, dismissed, date range)
- `PATCH /insights/:id/dismiss` — dismiss an insight
- `POST /insights/generate` — enqueue on-demand generation job

### Anti-Patterns to Avoid
- **Using the OpenRouter SDK (`@openrouter/sdk`):** This would add a unnecessary dependency. The raw `fetch()` approach in import-worker is proven and well-tested. D-10 explicitly says to copy the import-worker pattern.
- **Combining Claude and R1 calls into one OpenRouter request:** The privacy tiering in D-09 requires Claude receives full transaction data and R1 receives only aggregates. These are separate fetch calls with different payloads.
- **Putting transaction data in queue messages:** D-06 explicitly says transaction details are fetched from DB at processing time. Queue messages only contain `{ transaction_id }`.
- **Hand-rolling JSON parsing without Zod:** The import-worker pattern of strict Zod validation after JSON.parse is essential for reliability. LLMs can and do produce malformed output.
- **Storing full transaction text in insights:** The `insights` table should store linked transaction IDs (foreign key), not duplicate transaction data. This keeps insight storage compact.
- **Using floating-point math for financial calculations:** All financial calculations must use NUMERIC strings. The `amount` field is `NUMERIC(19,4)` and always handled as strings in TypeScript.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OpenRouter API calls | Custom HTTP client | `fetch()` (Bun built-in) + copy import-worker's `callOpenRouter()` pattern | Import-worker already has robust error handling, retry logic, auth headers, response_format configuration. Don't reinvent. |
| JSON schema enforcement for LLM output | `try/catch` on `JSON.parse` + manual validation | `response_format: json_schema` + Zod `safeParse` (import-worker pattern) | OpenRouter's json_schema mode ensures the model outputs valid JSON. Zod catches semantic errors (wrong types, missing fields). Together they eliminate 90% of LLM output issues. |
| PGMQ polling | Custom queue consumer | Copy import-worker's `pgmq.read()` + visibility timeout + retry loop | Production pattern already in codebase — handles stuck jobs, retry limits, archive/delete lifecycle. |
| Financial calculation (sums, percentages, trends) | JavaScript `number` arithmetic | Postgres `NUMERIC(19,4)` + string-based math | Floating-point precision errors accumulate in financial calculations. The project already uses NUMERIC for all money fields. R1 receives string-number aggregates. |
| Insight dedup | Custom dedup engine | SHA-256 hash of (type + title + content) + DB `UNIQUE` constraint | Same pattern as `import_hash` in transactions. Deterministic, fast, prevents exact duplicates. Semantic dedup is out of scope per D-03 ("frontend filters and deduplicates"). |
| Cron scheduling for nightly batch | `node-cron` or external cron | Check `new Date().getHours()` within the polling loop | Avoids external dependency. The worker is already a long-running process with a polling loop. Adding a time-of-day check is trivial. |
| Chart library for dual prediction lines | Custom SVG/Canvas | Recharts `ComposedChart` (already used in ComboChart.tsx) | Recharts supports multiple `Line` elements with different `stroke`, `strokeDasharray`, and `dataKey`. Just add a second `<Line>` for AI forecast. |

**Key insight:** This phase is almost entirely "copy existing patterns to new domain." The import-worker already solved the hard problems: OpenRouter integration with structured output, PGMQ polling with retry, Zod validation of LLM output, and batch processing. The insights worker is a specialized variant of the import-worker — different queue, different prompts, different output schemas, but the same fundamental architecture.

## Common Pitfalls

### Pitfall 1: OpenRouter Model ID Confusion
**What goes wrong:** Using incorrect model ID strings. OpenRouter model IDs follow the format `provider/model-name`. For example, `anthropic/claude-sonnet-4` not `claude-sonnet-4` or `claude-4-sonnet`. DeepSeek R1 free tier uses `deepseek/deepseek-r1:free` (with `:free` suffix).

**Why it happens:** Model IDs are not always obvious from product names. OpenRouter uses different conventions than the providers themselves. New model versions (4.5, 4.6) get new IDs while old ones remain available.

**How to avoid:** Verified via OpenRouter API at research time:
- Claude Sonnet 4: `anthropic/claude-sonnet-4` [VERIFIED: openrouter.ai/api/v1/models]
- DeepSeek R1 (paid): `deepseek/deepseek-r1` [VERIFIED: openrouter.ai/api/v1/models]
- DeepSeek R1 (free): `deepseek/deepseek-r1:free` [CITED: openrouter.ai/docs/guides/routing/routers/free-router]
- These are env-var configurable (D-11) so they can be updated without code changes.

**Warning signs:** OpenRouter returns "model not found" or falls back to a different model. The response will include the actual model used in `response.model`.

### Pitfall 2: Free Tier Rate Limiting on DeepSeek R1
**What goes wrong:** The worker hits OpenRouter rate limits on the free tier of DeepSeek R1, causing forecast generation to fail silently or return errors.

**Why it happens:** Free model variants have strict limits: 20 requests per minute, 50 requests per day (if <10 credits purchased) or 1000 requests/day (if ≥10 credits purchased). [CITED: openrouter.ai/docs/api-reference/limits] A nightly batch that processes many queued messages could exhaust the daily limit.

**How to avoid:**
1. Batch queued transaction_ids into a single forecast request (one OpenRouter call processes all accumulated data)
2. Add exponential backoff on 429 responses (copy import-worker retry pattern)
3. Set `OPENROUTER_FORECAST_MODEL` to the paid variant (`deepseek/deepseek-r1`) in production for reliability
4. Graceful degradation: if R1 forecast fails, Claude can still generate narrative insights without numerical forecast

**Warning signs:** 429 HTTP status codes from OpenRouter. R1 forecast data is `null`/empty but insights still generate from Claude.

### Pitfall 3: LLM Output Not Matching Zod Schema
**What goes wrong:** The LLM occasionally produces output that doesn't match the expected JSON schema — wrong types, missing fields, extra fields, malformed values.

**Why it happens:** Even with `response_format: json_schema` and `strict: true`, LLMs can produce semantically valid but schema-invalid JSON (e.g., an empty string for a required title, `"mediumm"` instead of `"medium"` for priority). The import-worker already handles this with per-item Zod filtering.

**How to avoid:** Follow the import-worker pattern exactly:
1. Use `response_format: json_schema` with `strict: true` and `additionalProperties: false`
2. After `JSON.parse(content)`, iterate through the array and `ZodSchema.safeParse()` each item
3. `console.warn` and filter out invalid items (don't throw — partial output is better than no output)
4. If the entire array is empty after filtering, throw an error

**Warning signs:** Console warnings about filtered insights. OpenRouter responses with valid JSON that Zod rejects.

### Pitfall 4: Privacy Boundary Violation with DeepSeek R1
**What goes wrong:** Full transaction data (descriptions, dates, amounts) accidentally sent to DeepSeek R1 instead of anonymized aggregates only.

**Why it happens:** D-13 establishes a hard boundary: R1 gets only category totals, percentages, trend values. If the worker code mixes up the payloads or reuses the Claude prompt template for R1, full transaction data leaks to the free-tier model.

**How to avoid:** 
1. Two completely separate prompt builder functions: `buildInsightsPrompt()` (Claude, full data) and `buildForecastPrompt()` (R1, aggregates only)
2. The R1 prompt builder should receive only `AggregateData` (numbers, category names), never `TransactionData[]`
3. In tests, verify the R1 prompt string does NOT contain any transaction descriptions
4. Typescript types enforce the boundary: `callDeepSeekForForecast(aggregates: CategoryAggregate[])`, not `callDeepSeekForForecast(transactions: TransactionData[])`

**Warning signs:** R1 output mentions specific transaction descriptions or amounts. This means full data leaked.

### Pitfall 5: Insight Dedup Hash Collisions or Missed Dedup
**What goes wrong:** The worker generates duplicate insights (same advice repeated) or incorrectly deduplicates distinct but similar insights.

**Why it happens:** SHA-256 of (type + title + content) catches exact duplicates but misses semantically similar insights ("You spent more on groceries than last month" vs "Grocery spending increased by 15%"). Conversely, changing the hash input (e.g., including timestamp) prevents dedup entirely.

**How to avoid:**
1. Exact dedup using SHA-256 of stable fields: `${type}|${title}|${content}` 
2. Add a DB query before insert: `SELECT 1 FROM insights WHERE dedup_hash = $hash AND created_at > now() - interval '7 days'`
3. Content normalization before hashing: trim whitespace, lowercase (optional, risks false positives)
4. If exact dedup is too aggressive (blocks similar but distinct insights), the frontend can group similar insights by content similarity — the backend dedup should only block identical outputs

**Warning signs:** Users see the same insight appearing multiple times. The `insights` table has rows with identical content but different timestamps.

### Pitfall 6: Worker Startup and Process Management
**What goes wrong:** The insights worker isn't started, or crashes silently, or conflicts with the import-worker process.

**Why it happens:** Bun workers run as separate processes (`bun run src/workers/insights-worker.ts`). If the deployment doesn't start both workers, insights are never generated. If they share the same database connection pool, they could exhaust connections.

**How to avoid:**
1. Run as a completely separate Bun process (not a child process or thread of the main server)
2. Use the same `import.meta.main` pattern: `if (import.meta.main) { insightsWorkerLoop(); }`
3. Add a startup log: `console.log('Insights worker starting...')`
4. Include the insights worker in the project's startup script/PM2/docker-compose alongside `import-worker.ts`
5. Each worker gets its own Postgres connection pool via a separate `postgres()` call

**Warning signs:** `analysis_queue` messages accumulate without being processed. No "Insights worker starting" in logs.

## Code Examples

Verified patterns from official sources:

### OpenRouter Structured Output with json_schema
```typescript
// Source: https://openrouter.ai/docs/guides/features/structured-outputs [VERIFIED: Context7]
// Pattern already implemented in src/workers/import-worker.ts:134-176

const response = await fetch(`${OPENROUTER_BASE_URL}/chat/completions`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    model: 'anthropic/claude-sonnet-4',
    messages: [{ role: 'user', content: 'Analyze this financial data...' }],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'insights',
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
```

### PGMQ Read + Archive Pattern
```typescript
// Source: src/workers/import-worker.ts:347-389 [VERIFIED: project codebase]
// Worker polling loop — insights worker copies this exactly

const messages = await sql`
  SELECT * FROM pgmq.read('analysis_queue', ${VISIBILITY_TIMEOUT}, 1)
`;
if (messages.length === 0) {
  await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
  continue;
}
const msg = messages[0];
try {
  await processAnalysisMessage(msg);
  await sql`SELECT pgmq.archive('analysis_queue', ${msg.msg_id}::bigint)`;
} catch (err) {
  if (readCount >= MAX_RETRIES) {
    await sql`SELECT pgmq.delete('analysis_queue', ${msg.msg_id}::bigint)`;
  }
}
```

### Hono Route with Zod Validation + Auth
```typescript
// Source: src/interface-adapters/api/ledger.ts:14-36 [VERIFIED: project codebase]

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { requireAuth } from './auth';

export const insightsRoutes = new Hono();

insightsRoutes.get('/', requireAuth, async (c) => {
  try {
    const rows = await listInsights();
    return c.json({ data: rows, error: null, meta: { total: rows.length } }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});
```

### Recharts ComposedChart with Dual Prediction Lines
```typescript
// Source: frontend/src/charts/ComboChart.tsx:48-88 [VERIFIED: project codebase]
// Extended pattern — existing LR line + new AI forecast line

<ComposedChart data={mergedData}>
  {/* ... existing bars and lines ... */}
  
  {/* Existing LR prediction (keep as-is) */}
  <Line
    type="monotone"
    dataKey="prediction"
    stroke="#f59e0b"        // amber
    strokeWidth={2}
    strokeDasharray="8 4"
    connectNulls
    name="Predykcja (LR)"
  />
  
  {/* NEW: AI forecast line */}
  <Line
    type="monotone"
    dataKey="aiForecast"
    stroke="#06b6d4"        // cyan — distinct from LR amber
    strokeWidth={2}
    strokeDasharray="4 4"   // different dash pattern
    connectNulls
    name="Predykcja (AI)"
  />
</ComposedChart>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `openai/gpt-4o-mini` as the only OpenRouter model | Two-tier: `anthropic/claude-sonnet-4` + `deepseek/deepseek-r1` | Phase 4 | Different models for different tasks; privacy tiering |
| Single `response_format: json_schema` for CSV parsing | Same pattern, new schemas for insights + forecasts | Phase 4 | Pattern reuse, no new technology needed |
| PGMQ for CSV import only | PGMQ also for insight generation queue | Already in place (`analysis_queue` created in seed.sql) | Queue already exists, just needs consumer |
| Linear regression only for predictions | LR + AI forecast (dual prediction lines) | Phase 4 | Users can compare statistical vs AI predictions |

**Deprecated/outdated:**
- **Single-model OpenRouter usage:** The import-worker uses a single `OPENROUTER_MODEL` env var. Phase 4 introduces two separate model env vars (`OPENROUTER_INSIGHTS_MODEL`, `OPENROUTER_FORECAST_MODEL`) — don't reuse the old single-var pattern for insights.
- **`openai/gpt-4o-mini` for financial analysis:** The import-worker's default model (`openai/gpt-4o-mini`) is suitable for CSV parsing but not for financial insights. Claude Sonnet 4 is explicitly chosen for its stronger reasoning and Anthropic's data privacy policy.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `deepseek/deepseek-r1:free` is the correct model ID for the free tier of DeepSeek R1 on OpenRouter | Standard Stack | Worker fails to call R1; forecasts unavailable. Fallback: use paid variant `deepseek/deepseek-r1` or skip R1 forecast entirely (Claude can still generate insights) |
| A2 | Nightly batch can be implemented by checking `new Date().getHours()` within the polling loop rather than using an external cron library | Architecture Patterns | If the worker restarts at the wrong time, a nightly batch could be missed. Fallback: add a separate health-check endpoint that triggers batch processing if it hasn't run in >24h |
| A3 | The `analysis_queue` receives only `{ transaction_id }` payloads (as stated in D-06 and verified in `use-cases.ts` line 21) | Architecture Patterns | If some other code path enqueues messages with different payloads, the worker needs to handle multiple message formats |
| A4 | OpenRouter `response_format: json_schema` with `strict: true` is supported by both Claude Sonnet 4 and DeepSeek R1 | Architecture Patterns | If one model doesn't support structured output, the JSON parsing becomes less reliable and Zod validation catches more errors |

## Open Questions

1. **DeepSeek R1 free tier availability**
   - What we know: The OpenRouter API returns `deepseek/deepseek-r1` with `is_free: false`. The free variant `deepseek/deepseek-r1:free` is documented in Context7's free-router guide. The exact availability may change.
   - What's unclear: Whether `:free` variant is always available, or if it's rate-limited to the point of being unusable for this use case.
   - Recommendation: Default to `deepseek/deepseek-r1:free` but make it env-var configurable. If free tier is unreliable, user can switch to `deepseek/deepseek-r1` (paid). The worker should gracefully degrade if R1 is unavailable — Claude can still generate narrative insights without numerical forecasts.

2. **Insight dedup window**
   - What we know: D-14 says "Worker deduplicates against similar recent insights before insert." The time window for "recent" is not specified.
   - What's unclear: Should dedup check the last 7 days, 30 days, or all time? If the user's spending pattern genuinely repeats (e.g., same category overspend two months in a row), should both insights be generated?
   - Recommendation: Use a 14-day dedup window by default. Insights with identical type + title + content hash within 14 days are skipped. After 14 days, the insight can reappear (spending patterns can genuinely repeat). This is configurable as a constant in the worker.

3. **On-demand generation queue priority**
   - What we know: D-05 says nightly batch + on-demand generation from UI. Both go through `analysis_queue`.
   - What's unclear: Should on-demand jobs be processed ahead of accumulated nightly messages? PGMQ doesn't have priority queues.
   - Recommendation: Use a separate queue (`insights_manual_queue`) for on-demand generation. This avoids the on-demand job getting stuck behind a backlog of nightly messages. The worker reads from both queues, prioritizing `insights_manual_queue`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bun | Backend runtime, worker process | ✓ | 1.3.14 | — |
| Node.js | Vite dev server | ✓ | 22.22.2 | — |
| PostgreSQL | Database, PGMQ queues, insights table | ✗* | — | Start local PostgreSQL with PGMQ extension (Docker or native). *Not running at research time but configured in .env. |
| OpenRouter API key | All LLM calls | ✓† | — | †Exists in .env (verified by grep of .env file showing OPENROUTER_API_KEY key present). |

**Missing dependencies with no fallback:**
- **PostgreSQL:** Not running at research time. Must be started before Phase 4 execution. The `.env` file has `DATABASE_URL` configured. The project uses a locally hosted PostgreSQL with PGMQ extension.

**Missing dependencies with fallback:**
- None. All other dependencies are available.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bun test (built-in) |
| Config file | `bunfig.toml` — timeout: 30000 |
| Quick run command | `bun test tests/insights-schemas.test.ts` |
| Full suite command | `bun test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| D-10 | Structured JSON output from Claude returns valid insight objects validated by Zod schema | unit | `bun test tests/insights-llm.test.ts -t "Claude"` | ❌ Wave 0 |
| D-10 | Structured JSON output from R1 returns valid forecast objects validated by Zod schema | unit | `bun test tests/insights-llm.test.ts -t "R1"` | ❌ Wave 0 |
| D-14 | Insight dedup hash prevents duplicate inserts within dedup window | unit | `bun test tests/insights-worker.test.ts -t "dedup"` | ❌ Wave 0 |
| D-05 | PGMQ message round-trip through analysis_queue — send, read, archive | integration | `bun test tests/insights-worker.test.ts -t "queue"` | ❌ Wave 0 |
| D-04 | PATCH /insights/:id/dismiss sets dismissed=true, dismissed insights excluded from GET | integration | `bun test tests/insights-api.test.ts -t "dismiss"` | ❌ Wave 0 |
| D-07 | GET /insights returns cards grouped by type, filtered by tab | integration | `bun test tests/insights-api.test.ts -t "list"` | ❌ Wave 0 |
| D-14 | POST /insights/generate enqueues job to analysis_queue | integration | `bun test tests/insights-api.test.ts -t "generate"` | ❌ Wave 0 |
| D-16 | ComboChart renders two prediction lines (LR + AI) with distinct colors | frontend | `bun test tests/ui-components.test.ts -t "combo"` | ❌ Wave 0 |
| D-08 | DashboardPage renders 3 compact insight cards above existing charts | frontend | `bun test tests/ui-build.test.ts` | ❌ Wave 0 |
| D-09 | R1 prompt does NOT contain any raw transaction descriptions | unit | `bun test tests/insights-worker.test.ts -t "privacy"` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bun test tests/insights-schemas.test.ts` (fast, unit only)
- **Per wave merge:** `bun test` (full suite)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `tests/insights-schemas.test.ts` — Zod schema validation for insight types
- [ ] `tests/insights-llm.test.ts` — OpenRouter mock tests (like import-llm.test.ts pattern)
- [ ] `tests/insights-worker.test.ts` — Worker unit tests (dedup, privacy boundary, queue lifecycle)
- [ ] `tests/insights-api.test.ts` — API endpoint integration tests
- [ ] `tests/ui-components.test.ts` — ComboChart dual-line test (extend existing UI tests)
- [ ] `tests/ui-build.test.ts` — Frontend build verification with new components
- [ ] Framework config: Existing `bunfig.toml` has 30s timeout — sufficient for LLM mock tests

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `requireAuth` middleware on all insight routes (reuse existing pattern) |
| V3 Session Management | yes | Better Auth session cookies (already implemented, reused) |
| V4 Access Control | yes | All insights are user-scoped — worker must filter by user context. Routes use `requireAuth` which sets `c.get('user')` |
| V5 Input Validation | yes | Zod schemas for all insight API inputs and LLM outputs (import-worker pattern) |
| V6 Cryptography | no | No cryptographic operations in this phase (SHA-256 for dedup is hashing, not crypto) |
| V7 Error Handling | yes | Error responses must not leak stack traces or API keys. Follow existing `{ data: null, error: { message }, meta: null }` pattern |

### Known Threat Patterns for OpenRouter + LLM Integration

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Prompt injection via transaction descriptions | Tampering | Transactions are user-owned data — not external input. However, descriptions with control characters could confuse LLM parsing. Sanitize: strip non-printable characters before building prompts |
| API key exposure in error messages | Information Disclosure | Never include API key or raw OpenRouter response in error messages. Log errors with sanitized content only. Follow import-worker pattern (only log status code + message) |
| Data leakage to free-tier model (DeepSeek R1) | Information Disclosure | STRICT code boundary: `callDeepSeekForForecast()` only accepts `CategoryAggregate[]`, never `TransactionData[]`. Enforced by TypeScript types + test |
| LLM hallucination presenting false financial advice | Repudiation | Every insight links to real transaction data as evidence (D-04). Users can verify claims against their own data. Insight cards show linked transactions |
| Rate limit abuse via rapid on-demand generation | Denial of Service | Add cooldown: only one on-demand generation per 5 minutes. Queue deduplication: if a manual generation job is already queued, skip the duplicate |

## Sources

### Primary (HIGH confidence)
- Context7 `/websites/openrouter_ai` — Structured outputs, json_schema, response_format, free models router, rate limits. [VERIFIED: Context7]
- OpenRouter API `/api/v1/models` — Model IDs for Claude Sonnet 4 (`anthropic/claude-sonnet-4`), DeepSeek R1 (`deepseek/deepseek-r1`). [VERIFIED: direct API query]
- `src/workers/import-worker.ts` — callOpenRouter(), PGMQ polling loop, retry logic, Zod validation of LLM output, batch processing. [VERIFIED: project codebase]
- `src/interface-adapters/api/ledger.ts` — Hono route patterns, Zod validation, auth middleware, response envelope. [VERIFIED: project codebase]
- `src/interface-adapters/api/import.ts` — Hono route patterns, requireAuth, multipart handling, error envelope. [VERIFIED: project codebase]
- `src/infrastructure/db/schema.sql` — Existing DB schema, immutability triggers, import_jobs table pattern. [VERIFIED: project codebase]
- `src/infrastructure/db/seed.sql` — analysis_queue creation, seed patterns. [VERIFIED: project codebase]
- `src/core/ledger/use-cases.ts` — analysis_queue enqueue per new transaction (line 21). [VERIFIED: project codebase]

### Secondary (MEDIUM confidence)
- OpenRouter docs `/docs/guides/features/structured-outputs` — json_schema response format specification. [CITED: Context7]
- OpenRouter docs `/docs/api-reference/limits` — Free tier limits (20 req/min, 50-1000 req/day). [CITED: Context7]
- OpenRouter docs `/docs/guides/routing/routers/free-router` — DeepSeek R1 as free model. [CITED: Context7]

### Tertiary (LOW confidence)
- `deepseek/deepseek-r1:free` model ID — The `:free` suffix pattern is documented for free variants but not verified via direct API query. [ASSUMED — flagged as A1 in Assumptions Log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — All dependencies already in project, verified via npm registry and bun version check. No new packages needed. Model IDs verified via OpenRouter API.
- Architecture: HIGH — Patterns are directly copied from existing, well-tested code (import-worker, ledger routes, ComboChart). No architectural invention needed.
- Pitfalls: MEDIUM — LLM output variability and free-tier rate limits are inherently unpredictable. Mitigations documented but real-world behavior may differ from expectations.

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 (30 days — stable ecosystem, but OpenRouter model availability can change)
