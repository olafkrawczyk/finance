---
phase: 11-account-crud-starting-balances
plan: 04
subsystem: "frontend"
tags: ["balance-chart", "net-worth", "recharts", "dashboard", "toggle"]
dependency-graph:
  requires:
    - "11-03 (getMonthlySummary returns wartosc_netto field)"
  provides:
    - "Combined net worth chart line with toggle"
  affects:
    - "frontend/src/pages/DashboardPage.tsx"
    - "frontend/src/charts/BalanceChart.tsx"
tech-stack:
  added: []
  patterns:
    - "Recharts Legend with custom content renderer"
    - "Conditional Line rendering based on toggle state"
    - "Local React useState for UI-only toggle (no server persistence)"
key-files:
  created: []
  modified:
    - "frontend/src/charts/BalanceChart.tsx"
    - "frontend/src/pages/DashboardPage.tsx"
decisions:
  - "Toggle state managed locally via React useState on DashboardPage (no server persistence)"
  - "Default toggle state: true (both lines visible)"
  - "Custom Legend renderer with text-xs text-slate-400 styling per dark theme"
  - "wartosc_netto Line uses dot={false} (different from stan_konta activeDot rendering)"
metrics:
  duration: "~4 minutes"
  completed: "2026-06-10"
  tasks: 2
  files_modified: 2
---

# Phase 11 Plan 04: Combined Net Worth Chart Summary

Updated BalanceChart to render a combined net worth line (purple, `wartosc_netto`) alongside the existing bank balance line (blue, `stan_konta`), with a Legend and toggle checkbox. DashboardPage manages the toggle state locally via React `useState` and passes it through.

## What Was Built

### 1. BalanceChart — Combined net worth line with legend and toggle

**File:** `frontend/src/charts/BalanceChart.tsx` (134 lines, +57 net)

**Changes:**
- Extended `BalanceDataPoint` interface with optional `wartosc_netto?: number | null` field
- Extended `BalanceChartProps` with `showNetWorth?: boolean` and `onToggleNetWorth?: () => void`
- Added conditional `Line` for `wartosc_netto` data key with purple stroke (`#a855f7`), `strokeWidth={2}`, name "Wartość netto", `dot={false}`, `connectNulls={false}` — rendered only when `showNetWorth` is true
- Added `Legend` component from Recharts with custom content renderer: colored dots + line names in `text-xs text-slate-400`
- Added toggle checkbox section above the chart with labels: "Pokaż wartość netto" / "Ukryj wartość netto"
- Updated `filteredData` to conditionally filter: when showNetWorth is true, rows where either `stan_konta` or `wartosc_netto` is non-null; when false, existing behavior (stan_konta only)
- Empty state (`filteredData.length < 2`) now accounts for both data keys

**Preserved unchanged:**
- `stan_konta` Line (blue `#3b82f6`, `strokeWidth={2}`, `activeDot={{ r: 6 }}`)
- Tooltip formatting (generic name-based formatter handles both data keys)
- Chart container sizing, ResponsiveContainer, margins
- `onMonthClick` handler, XAxis/YAxis configuration
- Dark theme background, grid, and border styling

### 2. DashboardPage — Toggle state management

**File:** `frontend/src/pages/DashboardPage.tsx` (278 lines, +11 net)

**Changes:**
- Added `useState` and `useCallback` to React imports
- Added `const [showNetWorth, setShowNetWorth] = useState(true)` — default: both lines visible
- Added `handleToggleNetWorth` callback wrapped in `useCallback` with empty dependency array
- Passed `showNetWorth={showNetWorth}` and `onToggleNetWorth={handleToggleNetWorth}` to BalanceChart

**Preserved unchanged:**
- All query hooks (`useMonthlySummary`, `useAssets`, `useInsightsForecast`)
- All `useMemo` computations (`normalizedData`, `chartData`, `aiForecast`, `totalBankBalance`, etc.)
- All rendering: Summary tiles, ComboChart, SavingsChart, SavingsLogChart, InsightsWidget
- Loading skeleton, error state, empty state
- The `wartosc_netto` field flows through existing data pipeline from `getMonthlySummary` (Plan 11-03)

## Key Decisions

1. **Local toggle state:** The net worth line visibility is managed via local React `useState` on DashboardPage — no server persistence needed. This matches the threat model (T-11-13: "Local React useState only — no persistence or server communication").
2. **Default visible:** Both lines visible by default (`useState(true)`) — users see the full picture immediately and can hide the net worth line if desired.
3. **Custom Legend styling:** Custom render function produces colored dots with `text-xs text-slate-400` labels, matching the dark theme palette.
4. **No new API calls:** The `wartosc_netto` field arrives via the existing `useMonthlySummary()` hook (data computed in Plan 11-03 backend changes to `getMonthlySummary`).

## Deviations from Plan

None — plan executed exactly as specified.

## Known Stubs

None identified.

## Threat Flags

None. No new network endpoints, auth paths, or file access patterns introduced. Toggle state is local only.

## Verification Results

- `npx vite build` — ✅ builds successfully (production build in 663ms)
- `grep -c "wartosc_netto" BalanceChart.tsx` — ✅ 3 occurrences
- `grep -c "showNetWorth" BalanceChart.tsx` — ✅ 6 occurrences
- `grep -c "showNetWorth" DashboardPage.tsx` — ✅ 2 occurrences
- `grep -c "handleToggleNetWorth" DashboardPage.tsx` — ✅ 2 occurrences
- `grep -c "onToggleNetWorth" DashboardPage.tsx` — ✅ 1 occurrence

## Self-Check: PASSED

- [x] Created files exist: BalanceChart.tsx (134 lines), DashboardPage.tsx (278 lines)
- [x] Commits exist: a4272c0, 1f21722
- [x] `npx vite build` passes
- [x] No stub patterns or placeholder content
- [x] No new threat surface
