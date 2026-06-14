import { describe, it, expect } from 'bun:test';
import {
  computeMonthlySummary,
  computeBaselineByMonth,
  assetValueForMonth,
  buildSnapshotsByAsset,
  toMonth,
  type SummaryMathInput,
} from '../src/core/ledger/summary-math';

// Helper to build a minimal input with overridable parts.
function input(partial: Partial<SummaryMathInput>): SummaryMathInput {
  return {
    aggregates: [],
    accounts: [],
    legacyOpeningBalances: [],
    assetSnapshots: [],
    ...partial,
  };
}

describe('toMonth', () => {
  it('extracts YYYY-MM from a string date', () => {
    expect(toMonth('2026-05-10')).toBe('2026-05');
  });

  it('extracts YYYY-MM from a Date (UTC)', () => {
    expect(toMonth(new Date('2026-05-10T00:00:00Z'))).toBe('2026-05');
  });

  it('returns null for null/undefined', () => {
    expect(toMonth(null)).toBeNull();
    expect(toMonth(undefined)).toBeNull();
  });
});

describe('computeMonthlySummary — legacy (monthly_opening_balances) path', () => {
  it('computes derived fields and stan_konta for a single month', () => {
    const rows = computeMonthlySummary(
      input({
        aggregates: [
          {
            month: '2026-06',
            wydatki: '120.5000',
            przychody: '5000.0000',
            fixed_cost_total: '120.5000',
          },
        ],
        legacyOpeningBalances: [{ year: 2026, month: 6, opening_balance: '15000.0000' }],
      })
    );

    expect(rows).toHaveLength(1);
    const r = rows[0];
    expect(r.month).toBe('2026-06');
    expect(r.przychody).toBe('5000.0000');
    expect(r.wydatki).toBe('120.5000');
    expect(r.fixed_cost_total).toBe('120.5000');
    expect(r.wydatki_bez_stalych).toBe('0.0000'); // 120.50 - 120.50
    expect(r.zaoszczedzone).toBe('4879.5000'); // 5000 - 120.50
    expect(r.zaoszczedzone_log).toBe(Math.log10(4879.5).toFixed(6));
    expect(parseFloat(r.zaoszczedzone_log)).toBeCloseTo(3.688375, 5);
    // stan_konta = opening (15000) + zaoszczedzone (4879.50)
    expect(r.stan_konta).toBe('19879.5000');
    // no assets → wartosc_netto == stan_konta
    expect(r.wartosc_netto).toBe('19879.5000');
  });

  it('carries the ending balance forward to a month with no opening balance, newest first', () => {
    const rows = computeMonthlySummary(
      input({
        aggregates: [
          { month: '2026-05', wydatki: '500.0000', przychody: '3000.0000', fixed_cost_total: '0' },
          { month: '2026-06', wydatki: '1000.0000', przychody: '4000.0000', fixed_cost_total: '0' },
        ],
        legacyOpeningBalances: [{ year: 2026, month: 5, opening_balance: '10000.0000' }],
      })
    );

    expect(rows).toHaveLength(2);
    // reverse-chronological
    expect(rows[0].month).toBe('2026-06');
    expect(rows[1].month).toBe('2026-05');

    // May: 10000 + 2500
    expect(rows[1].zaoszczedzone).toBe('2500.0000');
    expect(rows[1].stan_konta).toBe('12500.0000');
    // June inherits May's ending balance: 12500 + 3000
    expect(rows[0].zaoszczedzone).toBe('3000.0000');
    expect(rows[0].stan_konta).toBe('15500.0000');
  });
});

describe('computeMonthlySummary — hasStartingBalances path', () => {
  it('uses per-account baseline + cumulative changes, honoring starting_balance_date', () => {
    const rows = computeMonthlySummary(
      input({
        accounts: [
          { starting_balance: '10000.0000', starting_balance_date: '2026-05-01' },
          { starting_balance: '5000.0000', starting_balance_date: '2026-06-15' },
        ],
        aggregates: [
          { month: '2026-05', wydatki: '500.0000', przychody: '3000.0000', fixed_cost_total: '0' },
          { month: '2026-06', wydatki: '1000.0000', przychody: '4000.0000', fixed_cost_total: '0' },
        ],
      })
    );

    // May: baseline = 10000 (A only); cumulative = 2500 → 12500
    expect(rows[1].month).toBe('2026-05');
    expect(rows[1].stan_konta).toBe('12500.0000');
    // June: baseline = 15000 (A + B); cumulative = 2500 + 3000 = 5500 → 20500
    expect(rows[0].month).toBe('2026-06');
    expect(rows[0].stan_konta).toBe('20500.0000');
  });

  it('treats a null starting_balance_date as effective from the earliest month', () => {
    const rows = computeMonthlySummary(
      input({
        accounts: [{ starting_balance: '8000.0000', starting_balance_date: null }],
        aggregates: [
          { month: '2026-03', wydatki: '0', przychody: '1000.0000', fixed_cost_total: '0' },
          { month: '2026-04', wydatki: '200.0000', przychody: '0', fixed_cost_total: '0' },
        ],
      })
    );

    // baseline 8000 applies from earliest month (2026-03)
    // March: 8000 + 1000 = 9000
    expect(rows[1].month).toBe('2026-03');
    expect(rows[1].stan_konta).toBe('9000.0000');
    // April: 8000 + (1000 - 200) = 8800
    expect(rows[0].month).toBe('2026-04');
    expect(rows[0].stan_konta).toBe('8800.0000');
  });

  it('ignores accounts with a non-positive starting_balance', () => {
    const rows = computeMonthlySummary(
      input({
        accounts: [
          { starting_balance: '8000.0000', starting_balance_date: '2026-03-01' },
          { starting_balance: '0', starting_balance_date: '2026-03-01' },
          { starting_balance: '-50.0000', starting_balance_date: '2026-03-01' },
        ],
        aggregates: [
          { month: '2026-03', wydatki: '0', przychody: '0', fixed_cost_total: '0' },
        ],
      })
    );
    // baseline is only the 8000 account
    expect(rows[0].stan_konta).toBe('8000.0000');
  });
});

describe('computeMonthlySummary — wartosc_netto forward-fill', () => {
  it('forward-fills the latest snapshot value per asset and sums across assets', () => {
    // Keep zaoszczedzone = 0 every month so stan_konta stays 0 and
    // wartosc_netto equals the asset total alone.
    const flatMonths = ['2026-04', '2026-05', '2026-06', '2026-07', '2026-08'].map((month) => ({
      month,
      wydatki: '100.0000',
      przychody: '100.0000',
      fixed_cost_total: '0',
    }));

    const rows = computeMonthlySummary(
      input({
        aggregates: flatMonths,
        assetSnapshots: [
          { asset_id: 'X', value: '1000.0000', date: '2026-05-10' },
          { asset_id: 'Y', value: '200.0000', date: '2026-06-20' },
          { asset_id: 'Y', value: '500.0000', date: '2026-08-01' },
        ],
      })
    );

    // rows are newest-first; index by month for clarity
    const byMonth = Object.fromEntries(rows.map((r) => [r.month, r]));
    expect(byMonth['2026-04'].stan_konta).toBe('0.0000');

    // 04: no snapshots yet
    expect(byMonth['2026-04'].wartosc_netto).toBe('0.0000');
    // 05: X starts (same-month boundary counts), Y none
    expect(byMonth['2026-05'].wartosc_netto).toBe('1000.0000');
    // 06: X forward-filled (1000) + Y (200)
    expect(byMonth['2026-06'].wartosc_netto).toBe('1200.0000');
    // 07: both forward-filled
    expect(byMonth['2026-07'].wartosc_netto).toBe('1200.0000');
    // 08: X (1000) + Y latest (500)
    expect(byMonth['2026-08'].wartosc_netto).toBe('1500.0000');
  });

  it('adds asset value on top of a non-zero stan_konta', () => {
    const rows = computeMonthlySummary(
      input({
        aggregates: [
          { month: '2026-06', wydatki: '0', przychody: '1000.0000', fixed_cost_total: '0' },
        ],
        legacyOpeningBalances: [{ year: 2026, month: 6, opening_balance: '5000.0000' }],
        assetSnapshots: [{ asset_id: 'X', value: '2500.0000', date: '2026-06-01' }],
      })
    );
    // stan_konta = 5000 + 1000 = 6000; wartosc_netto = 6000 + 2500
    expect(rows[0].stan_konta).toBe('6000.0000');
    expect(rows[0].wartosc_netto).toBe('8500.0000');
  });
});

describe('zaoszczedzone_log', () => {
  it('is log10 for positive savings, and "0.000000" for zero or negative', () => {
    const rows = computeMonthlySummary(
      input({
        aggregates: [
          // positive
          { month: '2026-01', wydatki: '120.5000', przychody: '5000.0000', fixed_cost_total: '0' },
          // zero
          { month: '2026-02', wydatki: '100.0000', przychody: '100.0000', fixed_cost_total: '0' },
          // negative
          { month: '2026-03', wydatki: '300.0000', przychody: '100.0000', fixed_cost_total: '0' },
        ],
      })
    );
    const byMonth = Object.fromEntries(rows.map((r) => [r.month, r]));
    expect(byMonth['2026-01'].zaoszczedzone_log).toBe(Math.log10(4879.5).toFixed(6));
    expect(byMonth['2026-02'].zaoszczedzone_log).toBe('0.000000');
    expect(byMonth['2026-03'].zaoszczedzone_log).toBe('0.000000');
  });
});

describe('edge cases', () => {
  it('returns an empty array for no aggregates', () => {
    expect(computeMonthlySummary(input({}))).toEqual([]);
  });
});

describe('computeBaselineByMonth (helper)', () => {
  it('sums starting balances into each month at or after their effective month', () => {
    const months = ['2026-05', '2026-06', '2026-07'];
    const m = computeBaselineByMonth(
      [
        { starting_balance: '100.0000', starting_balance_date: '2026-05-01' },
        { starting_balance: '50.0000', starting_balance_date: '2026-07-10' },
      ],
      months,
      '2026-05'
    );
    expect(m.get('2026-05')).toBe(100);
    expect(m.get('2026-06')).toBe(100);
    expect(m.get('2026-07')).toBe(150);
  });
});

describe('assetValueForMonth (helper)', () => {
  it('returns 0 when an asset has no snapshot on or before the month', () => {
    const byAsset = buildSnapshotsByAsset([
      { asset_id: 'X', value: '1000.0000', date: '2026-06-01' },
    ]);
    expect(assetValueForMonth(byAsset, '2026-05')).toBe(0);
    expect(assetValueForMonth(byAsset, '2026-06')).toBe(1000);
    expect(assetValueForMonth(byAsset, '2026-07')).toBe(1000);
  });
});
