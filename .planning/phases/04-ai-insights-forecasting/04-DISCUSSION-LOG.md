# Phase 4: AI Insights & Forecasting - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-06
**Phase:** 04-ai-insights-forecasting
**Areas discussed:** Insight categories & triggers, Display format & placement, Model strategy, Data scope & persistence, Forecasting specifics

---

## Insight Categories & Triggers

| Option | Description | Selected |
|--------|-------------|----------|
| Full financial advisor | Monthly summaries, anomaly detection, savings tips, budget alerts, recommendations | ✓ |
| Focused: anomalies + alerts only | Detect unusual spending, budget alerts, category trends only | |
| Focused: forecast + recommendations | Future predictions, savings trajectory, recommendations only | |

**User's choice:** Full financial advisor
**Notes:** Import-worker's few-shot + structured JSON pattern must be reused for reliability.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid: nightly batch + on-demand | Nightly PGMQ worker + manual trigger from UI | ✓ |
| Nightly batch only | Worker runs once per night | |
| Real-time + batch | Process each transaction as it arrives | |

**User's choice:** Hybrid — nightly batch + on-demand

---

| Option | Description | Selected |
|--------|-------------|----------|
| Context-driven from data window | Each analysis is self-contained from transaction data, no user profile | ✓ |
| Personalized with user profile | System learns habits over time, stores behavior profile | |

**User's choice:** Context-driven — simpler, more private, consistent with import-worker pattern

---

| Option | Description | Selected |
|--------|-------------|----------|
| Exhaustive — generate everything | Generate all detected insights, filter/deduplicate on frontend | ✓ |
| Top highlights with priority | 5-7 insights per run, tagged with priority level | |
| Configurable cap | Max insights as env var, default 5 | |

**User's choice:** Exhaustive — generate everything

---

| Option | Description | Selected |
|--------|-------------|----------|
| Linked + dismissable | Insights reference transactions/categories, users can dismiss | ✓ |
| Static only | Read-only text blocks, no links or dismiss | |
| Linked only | Links to transactions, no dismiss action | |

**User's choice:** Linked + dismissable

---

## Display Format & Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated /insights page + dashboard widget | Full page + compact widget on dashboard | ✓ |
| Dedicated /insights page only | Single page, no dashboard clutter | |
| Dashboard widget only | All insights inline on dashboard | |
| Inline per-view | Insights contextual to each existing view | |

**User's choice:** Dedicated page + dashboard widget

---

| Option | Description | Selected |
|--------|-------------|----------|
| Cards grouped by type | Tabs/sections: Alerts, Trends, Tips, Forecasts | ✓ |
| Chronological feed | Vertical timeline, newest first | |
| Dashboard-style tiles | Grid of tiles with mixed charts and text | |

**User's choice:** Cards grouped by type tabs

---

| Option | Description | Selected |
|--------|-------------|----------|
| Compact insight cards row | 3-card horizontal row above charts with priority icons + text + timestamp | ✓ |
| Auto-rotating banner | Single banner cycling through insights | |
| Expandable section | Collapsible section, collapsed by default | |

**User's choice:** Compact insight cards row (3 cards)

---

## Model Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Two-tier: Claude Sonnet 4 + DeepSeek R1 | Claude for narrative, R1 for forecasting | ✓ |
| DeepSeek Chat only | Single model for everything ($0.27/$1.10) | |
| Keep gpt-4o-mini | Same model as import-worker | |

**User's choice:** Two-tier — Claude Sonnet 4 (narrative, privacy-safe) + DeepSeek R1 (forecasting, free)
**Notes:** User concerned about data privacy for financial spending data. Researched OpenRouter pricing — R1 is free, Claude Sonnet 4 is $3/$15 per 1M tokens (~$0.01-0.05 per nightly run). Anthropic's no-training API policy is the key privacy factor.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Two-tier: Claude (privacy-safe) + R1 (anonymized aggregates) | Claude gets full context, R1 gets only numbers | ✓ |
| Claude Sonnet 4 for all insights | One model, best privacy | |
| Keep gpt-4o-mini for everything | Already integrated, cheaper | |

**User's choice:** Two-tier with privacy tiering — Claude gets full transactions, R1 gets anonymized aggregates only

**Notes:** Models must be env-var configurable for easy swapping: `OPENROUTER_INSIGHTS_MODEL`, `OPENROUTER_FORECAST_MODEL`.

---

## Data Scope & Persistence

| Option | Description | Selected |
|--------|-------------|----------|
| 3-month rolling window + YoY | Last 3 months + same months previous year | ✓ |
| All-time transactions | Full history from July 2020+ | |
| Last month only | Current month only | |

**User's choice:** 3-month rolling window + YoY

---

| Option | Description | Selected |
|--------|-------------|----------|
| Raw transaction list | Send all transactions as JSON array to Claude | ✓ |
| Pre-computed aggregates + top transactions | Backend computes summaries first | |
| Mix — aggregates for Claude, raw for R1 | Inverts the privacy model | |

**User's choice:** Raw transaction list (full detail to Claude)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Persist in DB with dedup | insights table: id, type, priority, title, content, linked_tx, dismissed, created_at | ✓ |
| Generate fresh each request | No DB persistence | |
| DB table without dedup | Simple append-only table | |

**User's choice:** Persist in DB with dedup

---

## Forecasting Specifics

| Option | Description | Selected |
|--------|-------------|----------|
| Category-level spending forecast | Next month per-category + savings trajectory 1-3 months | ✓ |
| Single bottom-line forecast | Total spend, income, savings only | |
| Full financial projection | 6-month forward: spending by category, income, savings, balance | |

**User's choice:** Category-level spending forecast

---

| Option | Description | Selected |
|--------|-------------|----------|
| Keep LR line + add AI forecast line | Both prediction lines on ComboChart for comparison | ✓ |
| Replace LR with AI forecast | AI replaces linear regression entirely | |
| AI forecast on insights page only | Remove prediction from dashboard | |

**User's choice:** Keep LR line, add AI forecast line — compare "math vs AI"
**Notes:** User wants to visually see if LR and LLM agree on the forecast. Different colors/dash patterns.

---

| Option | Description | Selected |
|--------|-------------|----------|
| 1 month ahead | Next month only | |
| 3 months ahead | Quarterly projection | ✓ |
| 6 months ahead | Half-year projection | |

**User's choice:** 3 months ahead

---

## the agent's Discretion

- OpenRouter prompt templates for each insight type (few-shot examples, output schema)
- Worker architecture — separate process, cron scheduling approach
- Insights DB table schema details (indexes, dedup strategy, TTL/cleanup)
- API endpoint design: route structure, Zod schemas
- Error handling and retry strategy (reuse import-worker patterns)
- Frontend filtering controls on /insights page
- On-demand trigger integration with PGMQ worker
- Insight dedup logic — exact vs fuzzy/semantic
- Dashboard widget auto-refresh strategy
- Nav bar badge count and route placement
- Forecast prompt engineering for accuracy
- Dual prediction line chart styling

## Deferred Ideas

- Worker process architecture details
- Error handling UX for OpenRouter downtime
- Nav bar notification badge for new insights
- Frontend filtering/search on /insights page
- Push notifications for insights
