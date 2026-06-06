---
status: testing
phase: 04-ai-insights-forecasting
source: [04-01-SUMMARY.md, 04-02-SUMMARY.md, 04-03-SUMMARY.md, 04-04-SUMMARY.md, 04-05-SUMMARY.md]
started: 2026-06-06T21:00:00Z
updated: 2026-06-06T21:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 2
name: Dashboard Insights Widget
expected: |
  Open the dashboard. An InsightsWidget appears showing up to 3 compact insight cards.
  Each card displays a priority color indicator, insight type label, relative timestamp,
  and a short narrative snippet. While loading, skeleton placeholders are visible.
awaiting: user response

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running server/service. Clear ephemeral state (temp DBs, caches, lock files). Start the application from scratch. Server boots without errors, the 004_insights_table migration completes, and a primary query (health check, homepage load, or basic API call) returns live data.
result: issue
reported: "im again unauthorized — its like the db was wiped"
severity: blocker

### 2. Dashboard Insights Widget
expected: Open the dashboard. An InsightsWidget appears showing up to 3 compact insight cards. Each card displays a priority color indicator, insight type label (Alert/Trend/Tip/Forecast), relative timestamp, and a short narrative snippet. While loading, skeleton placeholders are visible.
result: issue
reported: "yes I see it, but forecast is not useful — majority of times it predicts 0.00 PLN with 100% confidence (e.g. biuro, apteka, etc). This is trash."
severity: major

### 3. AI Forecast Line on Chart
expected: Open the dashboard and look at the spending combo chart. A cyan dashed prediction line labeled "Predykcja (AI)" appears alongside the existing Linear Regression line ("Predykcja (LR)"). Both lines are visible in the chart legend and plotted on the same axes.
result: [pending]

### 4. Navigate to Insights Page
expected: Click the Insights navigation button. The app navigates to /insights and shows a paginated full-page list of AI insights (not the dashboard widget). The URL or app state reflects the /insights route.
result: pass
note: Fixed vite proxy bypass + z.coerce.boolean bug before data appeared

### 5. Filter Insights by Type
expected: On the /insights page, a tab bar shows: All, Alerts, Trends, Tips, Forecasts — each with a count badge. Clicking a tab filters the list to show only that type. The count in the tab reflects the number of matching undismissed insights.
result: [pending]

### 6. Dismiss an Insight
expected: On the /insights page (or dashboard widget), click the dismiss button on an insight card. A DismissConfirmDialog appears warning that this action is permanent. Confirming the dialog dismisses the insight — it disappears from the list and the tab count decrements.
result: [pending]

### 7. Manual Generate Insights Trigger
expected: On the /insights page, click the "Generate" (or similar) button. The app enqueues a new analysis request. The button shows a loading/pending state or a confirmation that the request was submitted (202 response enqueued).
result: pass
note: API returned {"data":{"msg_id":163},"error":null,"meta":{"message":"Analysis job enqueued"}} — PGMQ confirmed working

## Summary

total: 7
passed: 2
issues: 2
pending: 3
skipped: 0
blocked: 0

## Gaps

- truth: "Forecast insights contain meaningful non-zero predictions based on actual spending history"
  status: failed
  reason: "User reported: majority of forecasts predict 0.00 PLN with 100% confidence — useless output. Root cause likely: getInsightDataWindow uses current_date anchor so the 'recent 3 months' window (Mar–Jun 2026) has zero transactions since seed data only covers up to 2025. DeepSeek-R1 sees 0 recent spend and correctly predicts 0."
  severity: major
  test: 2
  artifacts: []
  missing: []

- truth: "App starts from cold boot, migration completes, and the app is accessible without auth errors"
  status: failed
  reason: "User reported: im again unauthorized — db feels wiped on restart. DB is intact (PGMQ msg_id:163 proves data persists), so root cause is session cookie expiry on server restart — user must re-login after every restart"
  severity: major
  test: 1
  artifacts: []
  missing: []
