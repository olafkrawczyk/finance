---
phase: 11-account-crud-starting-balances
plan: 03
subsystem: api, database
tags: postgres, asset-snapshots, net-worth

# Dependency graph
requires:
  - phase: 11-01-backend-account-crud
    provides: accounts table with starting_balance columns, listAccounts reference function
provides:
  - asset_value_snapshots migration (014) with FK to assets
  - Auto-snapshot on asset value change (old value captured before update)
  - GET /assets/:id/snapshots API endpoint
  - getMonthlySummary rewrite: per-account starting balance aggregation + forward-filled asset snapshots
affects:
  - 11-04-combined-net-worth-chart (net worth data source)
  - Dashboard net worth computation (wartosc_netto field)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-account starting balance aggregation: baseline = sum(starting_balance) where starting_balance_date <= month"
    - "Forward-fill: last asset snapshot on or before month end carries forward for months without explicit snapshots"
    - "Cumulative change tracking for starting balances (unlike monthly_opening_balances which pre-accumulate)"

key-files:
  created:
    - src/infrastructure/db/migrations/014_add_asset_value_snapshots.sql
  modified:
    - src/core/assets/use-cases.ts
    - src/interface-adapters/api/assets.ts
    - src/core/ledger/use-cases.ts
    - src/core/ledger/entities.ts
    - src/infrastructure/db/schema.sql

key-decisions:
  - "getMonthlySummary uses cumulative change tracking (baseline + cumulativeChanges) for starting balances instead of the monthly_opening_balances pattern — because starting_balances are static baselines that don't pre-accumulate across months"
  - "Asset value forward-fill sums the last-known value per asset on or before each month end, returning 0 for assets with no prior snapshots"

patterns-established:
  - "snapshot recording is transparent: updateAsset auto-captures old value without caller awareness"
  - "forward-fill asset grouping by asset_id with date-sorted snapshots enables O(n) single-pass lookup per month"

requirements-completed:
  - BAL-02

# Metrics
duration: 4min
completed: 2026-06-10
---

# Phase 11 Plan 03: Asset Snapshots + Balance Computation

**Asset value history snapshots with per-account starting balance aggregation for net worth computation, including migration, auto-snapshot on update, snapshot read endpoint, and rewritten getMonthlySummary**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-10T21:21:22Z
- **Completed:** 2026-06-10T21:25:01Z
- **Tasks:** 5 (5 total, 3 executed in this continuation)
- **Files modified:** 6

## Accomplishments

- Created migration 014 (`asset_value_snapshots` table) with FK → assets(id) ON DELETE CASCADE and (asset_id, date) index
- Added `createAssetSnapshot` and `listAssetSnapshots` functions in assets/use-cases
- Modified `updateAsset` to auto-capture snapshot of old value before overwriting (transparent to caller)
- Added `GET /assets/:id/snapshots` endpoint with asset ownership validation (404 if not found)
- Rewrote `getMonthlySummary` to aggregate per-account starting balances (baseline = sum where starting_balance_date ≤ month) with forward-filled asset snapshot values for `wartosc_netto`
- Legacy fallback to `monthly_opening_balances` when no starting_balances are set
- Added `wartosc_netto?: string` to `MonthlySummaryRow` type
- Updated `schema.sql` with `asset_value_snapshots` table definition

## Task Commits

Each task was committed atomically:

1. **Task 1: Create migration 014 — asset_value_snapshots table** - `b9f09c2` (feat)
2. **Task 2: Add snapshot functions to assets/use-cases.ts and modify updateAsset** - `20c40be` (feat)
3. **Task 3: Add asset snapshot read endpoint** - `ad1ddda` (feat)
4. **Task 4: Rewrite getMonthlySummary with per-account starting balances + combined net worth** - `ea467ad` (feat)
5. **Task 5: Update schema.sql with asset_value_snapshots table** - `676cbd9` (feat)

## Files Created/Modified

- `src/infrastructure/db/migrations/014_add_asset_value_snapshots.sql` — Migration: asset_value_snapshots table with FK, index, up/down
- `src/core/assets/use-cases.ts` — Added `createAssetSnapshot`, `listAssetSnapshots`, `AssetValueSnapshot` interface; modified `updateAsset` for auto-snapshot
- `src/interface-adapters/api/assets.ts` — Added `GET /:id/snapshots` route with ownership validation
- `src/core/ledger/use-cases.ts` — Rewritten `getMonthlySummary` with per-account starting balances, forward-filled asset snapshots, fallback compat
- `src/core/ledger/entities.ts` — Added `wartosc_netto?: string` to `MonthlySummaryRow`
- `src/infrastructure/db/schema.sql` — Added `asset_value_snapshots` table definition after assets table

## Decisions Made

- **Cumulative change tracking for starting balances**: Unlike `monthly_opening_balances` which store pre-accumulated totals per month, per-account starting_balances are static baselines. The algorithm uses `currentRunningBalance = baseline + cumulativeChanges` where cumulativeChanges tracks the running sum of net income/expense across all months. If the plan's described algorithm (substituting the map source but keeping the same reset-on-each-month logic) were followed literally, it would incorrectly reset the running balance each month, losing prior months' accumulation.
- **Asset snapshots query scope**: All asset snapshots for the user are fetched in one query and grouped by asset_id for forward-fill computation, rather than querying per asset per month (N+1 prevention).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Cumulative change tracking in getMonthlySummary starting-balance path**
- **Found during:** Task 4 (getMonthlySummary rewrite)
- **Issue:** The plan's described algorithm ("use the computed per-account starting balance map instead of balanceMap.get(row.month)") would replace the map source but keep the same running-balance reset logic. This works for `monthly_opening_balances` (which store pre-accumulated values), but with static per-account starting_balances, the running balance would be reset to `baseline + current_month_change` each month, losing prior months' accumulated net changes.
- **Fix:** Added separate `cumulativeChanges` accumulator that sums net income/expense across all months. For the starting-balance path: `currentRunningBalance = baseline + cumulativeChanges`. Legacy monthly_opening_balances fallback retains the original algorithm.
- **Files modified:** src/core/ledger/use-cases.ts
- **Verification:** Manual trace through test scenario: 3 accounts with starting_balances at different effective dates, 5 months of transactions — cumulative tracking produces correct net worth curve while reset approach would produce incorrect dips.
- **Committed in:** ea467ad (Task 4 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical correctness)
**Impact on plan:** Auto-fix essential for correct balance computation. The plan's described approach would produce incorrect `stan_konta` values (incrementally losing prior net changes). The cumulative tracking fix aligns with the plan's stated acceptance criteria (D-04 baseline + D-11 wartosc_netto).

## Issues Encountered

None — tasks 1-2 were pre-completed by a prior agent, tasks 3-5 executed cleanly.

## Threat Flags

None — all STRIDE items from the threat model are mitigated:

| Threat | Status | Mitigation |
|--------|--------|-----------|
| T-11-08 (Tampering) | Mitigated | `updateAsset` checks `user_id` before reading current value (same pattern as existing code) |
| T-11-09 (Info Disclosure) | Mitigated | GET /assets/:id/snapshots validates asset ownership via `getAsset(id, user.id)` — 404 if not found |
| T-11-10 (Info Disclosure) | Mitigated | All `getMonthlySummary` queries filtered by `user_id` — no cross-user data leakage |
| T-11-11 (Data Loss) | Mitigated | Snapshot inserted before UPDATE — if snapshot fails, updateAsset still proceeds (graceful degradation) |

## Known Stubs

None detected — all new fields are wired to real data sources.

## Self-Check: PASSED

- [x] `migration 014` file exists with CREATE TABLE, FK, CASCADE, index
- [x] `listAssetSnapshots` and `createAssetSnapshot` functions exist in use-cases
- [x] `updateAsset` references `asset_value_snapshots` for auto-snapshot
- [x] `GET /:id/snapshots` route exists in assets.ts
- [x] `listAssetSnapshots` imported in assets.ts
- [x] `wartosc_netto` field in getMonthlySummary return
- [x] `listAccounts` imported from reference/use-cases
- [x] `asset_value_snapshots` referenced in getMonthlySummary
- [x] `asset_value_snapshots` table defined in schema.sql
- [x] All 5 commits recorded in git history

---
*Phase: 11-account-crud-starting-balances*
*Completed: 2026-06-10*
