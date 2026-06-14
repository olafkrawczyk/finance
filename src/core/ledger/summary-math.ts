// Pure monthly-summary math — no database access.
//
// All monetary fields are NUMERIC(19,4) and arrive as strings (postgres.js never
// returns numbers for NUMERIC). We parse to float for arithmetic and re-emit with
// fixed precision, matching the original getMonthlySummary behavior.
//
// This module is intentionally DB-free so the balance / stan_konta / wartosc_netto
// math can be unit-tested with hand-built fixtures.

import type { MonthlySummaryRow } from './entities';

export interface AggregateRow {
  month: string; // "YYYY-MM"
  wydatki: string; // total expenses (transfers already excluded upstream)
  przychody: string; // total income
  fixed_cost_total: string; // sum of fixed-cost categories
}

export interface AccountBaseline {
  starting_balance: string;
  starting_balance_date: string | Date | null;
}

export interface LegacyOpeningBalance {
  year: number;
  month: number;
  opening_balance: string;
}

export interface SnapshotRow {
  asset_id: string;
  value: string;
  date: string | Date;
}

export interface SummaryMathInput {
  aggregates: AggregateRow[];
  accounts: AccountBaseline[];
  legacyOpeningBalances: LegacyOpeningBalance[];
  assetSnapshots: SnapshotRow[];
}

// Normalize a DATE (string "YYYY-MM-DD" or a Date) to its "YYYY-MM" month.
// Returns null for null/undefined so callers can fall back to a default month.
export function toMonth(date: string | Date | null | undefined): string | null {
  if (date == null) return null;
  if (date instanceof Date) return date.toISOString().substring(0, 7);
  const s = String(date);
  return s.length >= 7 ? s.substring(0, 7) : null;
}

// D-04 / D-05: sum each account's starting_balance into every month at or after the
// month it becomes effective. A null starting_balance_date is effective from the
// earliest transaction month. Accounts with starting_balance <= 0 are ignored.
export function computeBaselineByMonth(
  accounts: AccountBaseline[],
  months: string[],
  earliestMonth: string | null
): Map<string, number> {
  const baselineByMonth = new Map<string, number>();

  for (const account of accounts) {
    const sb = parseFloat(account.starting_balance || '0');
    if (sb <= 0) continue;

    const effectiveFrom = toMonth(account.starting_balance_date) ?? earliestMonth;
    if (!effectiveFrom) continue;

    for (const month of months) {
      if (month >= effectiveFrom) {
        baselineByMonth.set(month, (baselineByMonth.get(month) || 0) + sb);
      }
    }
  }

  return baselineByMonth;
}

// Group snapshots by asset, preserving the incoming (date-ascending) order.
export function buildSnapshotsByAsset(
  snapshots: SnapshotRow[]
): Map<string, SnapshotRow[]> {
  const byAsset = new Map<string, SnapshotRow[]>();
  for (const snap of snapshots) {
    const arr = byAsset.get(snap.asset_id) || [];
    arr.push(snap);
    byAsset.set(snap.asset_id, arr);
  }
  return byAsset;
}

// D-11 / D-12: forward-fill each asset's value to the given month. An asset
// contributes the value of its latest snapshot dated in `month` or earlier; an
// asset with no such snapshot contributes 0. Comparison is by "YYYY-MM" so the
// result is timezone-independent (a snapshot dated any day of `month` counts).
export function assetValueForMonth(
  snapshotsByAsset: Map<string, SnapshotRow[]>,
  month: string
): number {
  let total = 0;
  for (const snaps of snapshotsByAsset.values()) {
    let lastValue = 0;
    for (const snap of snaps) {
      const snapMonth = toMonth(snap.date);
      if (snapMonth != null && snapMonth <= month) {
        lastValue = parseFloat(snap.value);
      } else if (snapMonth != null && snapMonth > month) {
        break; // snapshots are date-ascending
      }
    }
    total += lastValue;
  }
  return total;
}

export function computeMonthlySummary(input: SummaryMathInput): MonthlySummaryRow[] {
  const { aggregates, accounts, legacyOpeningBalances, assetSnapshots } = input;

  const months = aggregates.map((r) => r.month);
  const earliestMonth = months.length > 0 ? months[0] : null;

  const hasStartingBalances = accounts.some(
    (a) => parseFloat(a.starting_balance || '0') > 0
  );

  let openingBalanceMap: Map<string, string>;
  if (hasStartingBalances) {
    const baselineByMonth = computeBaselineByMonth(accounts, months, earliestMonth);
    openingBalanceMap = new Map(
      months.map((m) => [m, String(baselineByMonth.get(m) || 0)])
    );
  } else {
    openingBalanceMap = new Map(
      legacyOpeningBalances.map((b) => [
        `${b.year}-${String(b.month).padStart(2, '0')}`,
        b.opening_balance,
      ])
    );
  }

  const snapshotsByAsset = buildSnapshotsByAsset(assetSnapshots);

  let currentRunningBalance = 0;
  let cumulativeChanges = 0;

  return aggregates
    .map((row) => {
      const wydatki = parseFloat(row.wydatki);
      const przychody = parseFloat(row.przychody);
      const fixedCost = parseFloat(row.fixed_cost_total);
      const wydatkiBezStalych = wydatki - fixedCost;
      const zaoszczedzone = przychody - wydatki;
      const zaoszczedzone_log = zaoszczedzone > 0 ? Math.log10(zaoszczedzone) : 0;

      cumulativeChanges += zaoszczedzone;

      if (hasStartingBalances) {
        // stan_konta = per-account baseline (static) + cumulative net changes.
        const baseline = parseFloat(openingBalanceMap.get(row.month) || '0');
        currentRunningBalance = baseline + cumulativeChanges;
      } else {
        // Legacy: monthly_opening_balances already pre-accumulate history per month.
        const openingBalance = openingBalanceMap.get(row.month);
        if (openingBalance != null) {
          currentRunningBalance = parseFloat(openingBalance) + zaoszczedzone;
        } else {
          currentRunningBalance += zaoszczedzone;
        }
      }

      const assetValue = assetValueForMonth(snapshotsByAsset, row.month);

      return {
        month: row.month,
        wydatki: wydatki.toFixed(4),
        przychody: przychody.toFixed(4),
        fixed_cost_total: fixedCost.toFixed(4),
        wydatki_bez_stalych: wydatkiBezStalych.toFixed(4),
        zaoszczedzone: zaoszczedzone.toFixed(4),
        zaoszczedzone_log: zaoszczedzone_log.toFixed(6),
        stan_konta: currentRunningBalance.toFixed(4),
        wartosc_netto: (currentRunningBalance + assetValue).toFixed(4),
      };
    })
    .toReversed();
}
