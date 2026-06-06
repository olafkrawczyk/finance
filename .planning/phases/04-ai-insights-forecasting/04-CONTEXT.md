# Phase 4: AI Insights & Forecasting - Context

**Gathered:** 2026-06-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add AI-powered spending analysis, forecasting, and recommendations on top of the existing ledger and views. Integrate OpenRouter for two model tiers: Claude Sonnet 4 for narrative financial insights (privacy-safe, Anthropic's no-training API policy) and DeepSeek R1 for numerical forecasting (receives anonymized aggregates only, free tier). A new PGMQ worker reads from the existing `analysis_queue` (already enqueued per new transaction), runs nightly batch analysis plus on-demand generation. Results are persisted in a new `insights` DB table with dedup and dismiss tracking, displayed via a dedicated `/insights` page and a compact dashboard widget.

</domain>

<decisions>
## Implementation Decisions

### Insight Content
- **D-01:** Full financial advisor — monthly spending summaries, category-level anomaly detection, savings tips, budget threshold alerts, and forward-looking recommendations.
- **D-02:** Context-driven from 3-month rolling data window + year-over-year comparison. No user profile learning — each run is self-contained from the transaction data.
- **D-03:** Exhaustive generation — the AI generates all detected insights. Frontend filters and deduplicates. No cap on number of insights per run.
- **D-04:** Insights link to specific transactions/categories as evidence. Users can dismiss individual insights (persisted in DB, dismissed insights don't reappear).

### Triggers & Scheduling
- **D-05:** Hybrid trigger — nightly batch PGMQ worker processes all queued messages from `analysis_queue`, plus on-demand generation triggered from the UI (enqueues a manual job).
- **D-06:** The existing `analysis_queue` (receives `{ transaction_id }` per new transaction) drives the worker. Transaction details are fetched from DB at processing time, not embedded in the queue message.

### Display & UI
- **D-07:** Dedicated `/insights` page with cards grouped by type tabs: Alerts, Trends, Tips, Forecasts. Each card shows icon + insight text + linked transactions + timestamp. Uses existing dark theme card pattern.
- **D-08:** Dashboard widget — horizontal row of 3 compact insight cards above the 4 existing charts. Each card: priority icon (red/yellow/blue) + first line of insight text + relative timestamp + link to `/insights`.

### Model Strategy
- **D-09:** Two-tier model setup:
  - **Claude Sonnet 4** (`OPENROUTER_INSIGHTS_MODEL` env var) — narrative insights, tips, alerts, summaries. Receives full raw transaction list. Chosen for Anthropic's strong API data privacy policy (no training on API data, SOC 2).
  - **DeepSeek R1** (`OPENROUTER_FORECAST_MODEL` env var) — numerical forecasting, spending predictions, trend analysis. Receives ONLY anonymized numerical aggregates (category totals, percentages, no transaction details). Free tier on OpenRouter.
- **D-10:** Both models use the same structured JSON output + few-shot prompting pattern as the import-worker (`src/workers/import-worker.ts`). Temperature 0.1, `response_format: json_schema`, strict Zod validation.
- **D-11:** Models are env-var configurable for easy swapping. Defaults: Claude Sonnet 4 for insights, DeepSeek R1 for forecasting.

### Data Scope
- **D-12:** 3-month rolling transaction window + same months from previous year for YoY comparison.
- **D-13:** Raw transactions sent to Claude (full detail for accurate analysis). Only anonymized numerical aggregates sent to R1 (category totals, percentages, trend values — no individual transaction text).
- **D-14:** Insights persisted in new `insights` DB table: `id, type (alert|tip|trend|forecast), priority (high|medium|low), title, content, linked_transaction_ids[], linked_category_ids[], dismissed (boolean), created_at`. Worker deduplicates against similar recent insights before insert.

### Forecasting
- **D-15:** Category-level spending forecast — AI predicts next month's spending per category + 3-month savings trajectory. Complements the existing linear regression prediction line.
- **D-16:** Dual prediction lines on the dashboard ComboChart: keep existing LR line, add new AI forecast line (different color/dash pattern). Users can visually compare "math says X" vs "AI says Y".
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing OpenRouter + Worker Pattern
- `src/workers/import-worker.ts` — Existing OpenRouter integration: `callOpenRouter()` function, structured JSON schema output, PGMQ polling loop, retry logic, batch processing. The insights worker follows this exact pattern.
- `tests/import-llm.test.ts` — Import worker test patterns using Bun mock server.

### Queue Infrastructure
- `src/infrastructure/db/seed.sql` — `analysis_queue` creation (already exists)
- `src/core/ledger/use-cases.ts` — `analysis_queue` enqueue per new transaction (line 21: `pgmq.send('analysis_queue', ...)`)
- `tests/queue.test.ts` — PGMQ queue test patterns
- `src/infrastructure/db/health.ts` — Queue health check pattern

### Backend API Patterns
- `src/interface-adapters/api/ledger.ts` — Hono route patterns, Zod validation, auth middleware, response envelope
- `src/application/schemas/ledger.ts` — Zod schema patterns for request/response validation
- `index.ts` — Route mounting pattern, Better Auth session middleware

### Frontend Patterns
- `frontend/src/App.tsx` — Client-side router (pushState + popstate), header nav bar, route matching. Integration point for `/insights` route and Insights nav button.
- `frontend/src/api.ts` — API client: `fetch()` with `credentials: 'include'`, envelope unwrapping (`json.data`). Pattern for new insights endpoints.
- `frontend/src/components/ImportStatus.tsx` — Polling pattern (useful for on-demand insight generation status)
- `frontend/src/charts/ComboChart.tsx` — The combo chart showing expenses + income + balance + LR prediction line. Integration point for AI forecast line (D-16).

### Styling & Component Patterns
- `frontend/src/components/ImportUpload.tsx` — Dark theme Tailwind classes: slate-950 bg, slate-800 borders, blue/indigo gradients, rounded-2xl cards. Reuse for insights components.
- `frontend/src/lib/linearRegression.ts` — Existing linear regression utility. Complement, don't replace (D-16).

### Project Requirements & Research
- `.planning/REQUIREMENTS.md` — Overall project requirements, REQ-4.x (LLM-powered CSV import pattern to follow)
- `.planning/ROADMAP.md` — Phase 4 goal and tasks
- `.planning/PROJECT.md` — Tech stack: Bun + Hono + Postgres + PGMQ + OpenRouter + React + Tailwind
- `.planning/research/SUMMARY.md` — DeepSeek-R1 for mathematical forecasting, Claude for narrative insights recommendation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`callOpenRouter()` in import-worker.ts** — Fully implemented: OpenRouter API calls with structured JSON schema, temperature 0.1, error handling, Zod response validation. Copy this pattern for both Claude and R1 calls in the insights worker.
- **PGMQ polling loop in import-worker.ts** — Infinite polling loop with `pgmq.read()`, visibility timeout, retry logic, `pgmq.archive()`/`pgmq.delete()`. Copy for insights worker reading from `analysis_queue`.
- **Frontend card pattern** — DashboardPage cards use `rounded-2xl`, `bg-slate-800/50`, border styling. Reuse for insight cards and dashboard widget.
- **Recharts chart components** — ComboChart, BalanceChart patterns. Extend ComboChart for dual prediction lines.
- **API client pattern** — `api.ts` fetch wrapper. Add `getInsights()`, `dismissInsight()`, `generateInsights()`.
- **Zod validation patterns** — `src/application/schemas/` patterns for request/response validation.

### Established Patterns
- **API response envelope:** `{ data, error, meta }` — all new endpoints must follow.
- **Auth middleware:** `requireAuth` on all routes.
- **Structured JSON + few-shot prompting** — import-worker's approach: few-shot examples in system prompt, `response_format: json_schema`, strict Zod parse. Proven reliable for this codebase.
- **Env var configuration** — OPENROUTER_API_KEY, OPENROUTER_MODEL pattern. Extend with INSIGHTS_MODEL and FORECAST_MODEL.
- **Tailwind dark theme** — No custom CSS beyond `@import "tailwindcss"`.
- **Client-side routing** — pushState + popstate listener in App.tsx.

### Integration Points
- **`analysis_queue`** — Already created in seed.sql, enqueued per transaction in use-cases.ts. Ready for worker consumption.
- **App.tsx nav bar** — Add "Insights" button alongside existing nav items (Dashboard, Zbiorczy, Kategoryzuj, Dodaj, Import CSV).
- **App.tsx `renderContent()`** — Add `/insights` route match.
- **DashboardPage** — Add compact insight widget above existing 4 charts.
- **ComboChart** — Extend with second prediction line (AI forecast) in a different color/dash pattern.
- **Vite config** — Add proxy for new `/insights` API routes.

</code_context>

<specifics>
## Specific Ideas

- **Dual prediction lines (LR vs AI):** The existing ComboChart has a linear regression prediction line. Add a second prediction line from the AI forecast in a different color + dash pattern (e.g., LR = dashed blue, AI = dashed green). Add a small comparison note: "LR predicts +5%, AI predicts +8%" when forecasts diverge significantly.
- **Import-worker reliability:** The user explicitly wants the insights mechanism to be as reliable as the import-worker's few-shot + structured JSON approach. Copy the exact prompt structure pattern (system prompt with few-shot examples, `response_format: json_schema`, strict Zod validation).
- **Data privacy tiering:** Claude gets full transaction context (trusted provider with no-training policy). R1 gets only numbers — category totals, percentage changes, trend direction — not individual transaction descriptions. This is a hard boundary enforced in the worker code before data reaches R1.
</specifics>

<deferred>
## Deferred Ideas

- Worker architecture details — separate process, cron scheduling, whether to share process with import-worker. The agent decides.
- Error handling and fallback UX for OpenRouter downtime.
- Nav bar badge count for new/unread insights.
- Frontend filtering controls (search, date range) on `/insights` page.
- Notification/push for new insights discoveries.

</deferred>

---

*Phase: 04-ai-insights-forecasting*
*Context gathered: 2026-06-06*
