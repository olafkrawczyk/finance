---
phase: 4
slug: ai-insights-forecasting
status: completed
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-06
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bun test (built-in) |
| **Config file** | `bunfig.toml` — timeout: 30000 |
| **Quick run command** | `bun test tests/insights-schemas.test.ts` |
| **Full suite command** | `bun test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bun test tests/insights-schemas.test.ts`
- **After every plan wave:** Run `bun test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | D-10 | — | Claude returns valid insight objects validated by Zod schema | unit | `bun test tests/insights-llm.test.ts -t "Claude"` | ✅ yes | ✅ green |
| 04-01-02 | 01 | 1 | D-10 | — | R1 returns valid forecast objects validated by Zod schema | unit | `bun test tests/insights-llm.test.ts -t "R1"` | ✅ yes | ✅ green |
| 04-01-03 | 01 | 1 | D-14 | — | Insight dedup hash prevents duplicate inserts within dedup window | unit | `bun test tests/insights-worker.test.ts -t "dedup"` | ✅ yes | ✅ green |
| 04-01-04 | 01 | 1 | D-05 | — | PGMQ message round-trip through analysis_queue — send, read, archive | integration | `bun test tests/insights-worker.test.ts -t "queue"` | ✅ yes | ✅ green |
| 04-02-01 | 02 | 2 | D-04 | — | PATCH /insights/:id/dismiss sets dismissed=true, dismissed excluded from GET | integration | `bun test tests/insights-api.test.ts -t "dismiss"` | ✅ yes | ✅ green |
| 04-02-02 | 02 | 2 | D-07 | — | GET /insights returns cards grouped by type, filtered by tab | integration | `bun test tests/insights-api.test.ts -t "list"` | ✅ yes | ✅ green |
| 04-02-03 | 02 | 2 | D-14 | — | POST /insights/generate enqueues job to analysis_queue | integration | `bun test tests/insights-api.test.ts -t "generate"` | ✅ yes | ✅ green |
| 04-03-01 | 03 | 3 | D-16 | — | ComboChart renders two prediction lines (LR + AI) with distinct colors | frontend | `bun test tests/ui-components.test.ts -t "combo"` | ✅ yes | ✅ green |
| 04-03-02 | 03 | 3 | D-08 | — | DashboardPage renders 3 compact insight cards above existing charts | frontend | `bun test tests/ui-build.test.ts` | ✅ yes | ✅ green |
| 04-01-05 | 01 | 1 | D-09 | T-04-03 | R1 prompt does NOT contain any raw transaction descriptions (privacy boundary) | unit | `bun test tests/insights-worker.test.ts -t "privacy"` | ✅ yes | ✅ green |
| 04-01-06 | 01 | 1 | — | T-04-01 | Transaction descriptions sanitized — non-printable characters stripped before prompt build | unit | `bun test tests/insights-worker.test.ts -t "sanitize"` | ✅ yes | ✅ green |
| 04-02-04 | 02 | 2 | — | T-04-02 | API error responses do not leak API key or raw LLM response content | integration | `bun test tests/insights-api.test.ts -t "error"` | ✅ yes | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/insights-schemas.test.ts` — Zod schema validation for insight types, forecast types, and API request/response schemas
- [x] `tests/insights-llm.test.ts` — OpenRouter mock tests following `tests/import-llm.test.ts` pattern (Bun mock server)
- [x] `tests/insights-worker.test.ts` — Worker unit tests: dedup logic, privacy boundary enforcement, queue lifecycle, prompt sanitization
- [x] `tests/insights-api.test.ts` — API endpoint integration tests: CRUD, dismiss, generate, error handling
- [x] `tests/ui-components.test.ts` — ComboChart dual-line test extending existing UI test patterns
- [x] `tests/ui-build.test.ts` — Frontend build verification with new insight components and routes

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| DeepSeek R1 free tier availability | D-09 | Free tier model availability cannot be mocked — must verify live API | Run worker once, confirm 200 response from deepseek/deepseek-r1:free |
| AI forecast line visually distinct from LR line on ComboChart | D-16 | Color/rendering requires visual inspection | Load dashboard, confirm amber dashed LR line and cyan dashed AI line are both visible and distinct |
| Insights page card grouping by type tabs | D-07 | Layout verification requires visual inspection | Navigate to /insights, verify Alerts/Trends/Tips/Forecasts tabs work |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** completed

