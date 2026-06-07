import { describe, it, expect } from 'bun:test';
import {
  normalizeText,
  resolveSheetMeta,
  sortSheetsChronologically,
  parseExcelDate,
  defaultSheetDate,
  resolveOpeningBalanceColumnIndex,
  resolveCategory,
  routeAccount,
  buildMigrationImportHash,
  type CategoryRecord,
} from '../src/core/import/excel-parser';

const dbCategories: CategoryRecord[] = [
  { id: 'cat-lekarz', name: 'lekarz' },
  { id: 'cat-przejazdy', name: 'przejazdy' },
  { id: 'cat-kawa', name: 'kawa' },
  { id: 'cat-fun', name: 'fun' },
  { id: 'cat-vat', name: 'VAT' },
];

describe('normalizeText', () => {
  it('lowercases, strips diacritics, and maps Polish ł/Ł to l', () => {
    expect(normalizeText('Łódź')).toBe('lodz');
    expect(normalizeText('KAWKA')).toBe('kawka');
    expect(normalizeText('Pażdziernik')).toBe('pazdziernik');
    expect(normalizeText('  Styczeń  ')).toBe('styczen');
  });
});

describe('chronological sheet sorting', () => {
  it('resolves legacy sheets without year suffix using lipiec-grudzien -> 2020, styczen -> 2021', () => {
    expect(resolveSheetMeta('lipiec')).toEqual({ sheetName: 'lipiec', month: 7, year: 2020 });
    expect(resolveSheetMeta('grudzien')).toEqual({ sheetName: 'grudzien', month: 12, year: 2020 });
    expect(resolveSheetMeta('styczen')).toEqual({ sheetName: 'styczen', month: 1, year: 2021 });
  });

  it('resolves modern sheets with explicit year suffix by (year, month)', () => {
    expect(resolveSheetMeta('luty 2021')).toEqual({ sheetName: 'luty 2021', month: 2, year: 2021 });
    expect(resolveSheetMeta('pazdziernik2025')).toEqual({ sheetName: 'pazdziernik2025', month: 10, year: 2025 });
  });

  it('skips helper sheets like zbiorczy and kategorie', () => {
    expect(resolveSheetMeta('Zbiorczy')).toBeNull();
    expect(resolveSheetMeta('kategorie')).toBeNull();
    expect(resolveSheetMeta('random sheet')).toBeNull();
  });

  it('orders e.g. lipiec 2020 before styczen 2021 before luty 2021', () => {
    const sorted = sortSheetsChronologically(['luty 2021', 'styczen', 'lipiec', 'zbiorczy', 'kategorie']);
    expect(sorted.map((s) => s.sheetName)).toEqual(['lipiec', 'styczen', 'luty 2021']);
  });
});

describe('Excel serial date conversion', () => {
  const meta = { year: 2021, month: 3 };

  it('converts numeric Excel serial dates to YYYY-MM-DD (timezone-safe)', () => {
    // Excel serial 44287 = 2021-04-01 (using 1900 date system)
    expect(parseExcelDate(44287, meta)).toBe('2021-04-01');
  });

  it('parses string dates matching YYYY-MM-DD or DD.MM.YYYY and normalizes to YYYY-MM-DD', () => {
    expect(parseExcelDate('2021-03-15', meta)).toBe('2021-03-15');
    expect(parseExcelDate('05.03.2021', meta)).toBe('2021-03-05');
  });

  it('defaults to the 1st of the sheet month when no valid date is present', () => {
    expect(parseExcelDate(null, meta)).toBe('2021-03-01');
    expect(parseExcelDate('', meta)).toBe('2021-03-01');
    expect(parseExcelDate('not a date', meta)).toBe('2021-03-01');
    expect(defaultSheetDate(meta)).toBe('2021-03-01');
  });
});

describe('category resolution / translation', () => {
  it('maps dentysta -> lekarz', () => {
    expect(resolveCategory('dentysta', dbCategories)).toEqual({ id: 'cat-lekarz', name: 'lekarz' });
  });

  it('maps mpk -> przejazdy', () => {
    expect(resolveCategory('mpk', dbCategories)).toEqual({ id: 'cat-przejazdy', name: 'przejazdy' });
  });

  it('maps kawka -> kawa', () => {
    expect(resolveCategory('kawka', dbCategories)).toEqual({ id: 'cat-kawa', name: 'kawa' });
  });

  it('falls back to fun for unrecognized categories', () => {
    expect(resolveCategory('totally-unknown-category', dbCategories)).toEqual({ id: 'cat-fun', name: 'fun' });
    expect(resolveCategory(null, dbCategories)).toEqual({ id: 'cat-fun', name: 'fun' });
  });

  it('matches existing categories case/diacritic-insensitively', () => {
    expect(resolveCategory('VAT', dbCategories)).toEqual({ id: 'cat-vat', name: 'VAT' });
    expect(resolveCategory('vat', dbCategories)).toEqual({ id: 'cat-vat', name: 'VAT' });
  });
});

describe('account routing', () => {
  it('routes VAT, ZUS, PIT/PIT36, paliwo categories to ING Business', () => {
    expect(routeAccount({ rawCategory: 'VAT', amount: 10, description: '' })).toBe('ing_business');
    expect(routeAccount({ rawCategory: 'ZUS', amount: 10, description: '' })).toBe('ing_business');
    expect(routeAccount({ rawCategory: 'PIT36', amount: 10, description: '' })).toBe('ing_business');
    expect(routeAccount({ rawCategory: 'PIT', amount: 10, description: '' })).toBe('ing_business');
    expect(routeAccount({ rawCategory: 'paliwo', amount: 10, description: '' })).toBe('ing_business');
  });

  it('routes auto category with amount > 2000 PLN to ING Business', () => {
    expect(routeAccount({ rawCategory: 'auto', amount: 2500, description: '' })).toBe('ing_business');
    expect(routeAccount({ rawCategory: 'auto', amount: 2000, description: '' })).toBe('pko_personal');
    expect(routeAccount({ rawCategory: 'auto', amount: 100, description: '' })).toBe('pko_personal');
  });

  it('routes descriptions containing PPE, ORANGE, or PLAY (case-insensitive) to ING Business', () => {
    expect(routeAccount({ rawCategory: 'fun', amount: 10, description: 'Payment to PPE energy' })).toBe('ing_business');
    expect(routeAccount({ rawCategory: 'fun', amount: 10, description: 'orange mobile bill' })).toBe('ing_business');
    expect(routeAccount({ rawCategory: 'fun', amount: 10, description: 'PLAY subscription' })).toBe('ing_business');
  });

  it('routes all other transactions to PKO Personal (IPKO)', () => {
    expect(routeAccount({ rawCategory: 'lekarz', amount: 50, description: 'wizyta' })).toBe('pko_personal');
    expect(routeAccount({ rawCategory: null, amount: 5000, description: 'wyplata' })).toBe('pko_personal');
  });
});

describe('opening balance column resolution', () => {
  it('resolves Column G (index 6) for July-October 2020 sheets', () => {
    expect(resolveOpeningBalanceColumnIndex({ year: 2020, month: 7 })).toBe(6);
    expect(resolveOpeningBalanceColumnIndex({ year: 2020, month: 10 })).toBe(6);
  });

  it('resolves Column H (index 7) for November 2020 onwards sheets', () => {
    expect(resolveOpeningBalanceColumnIndex({ year: 2020, month: 11 })).toBe(7);
    expect(resolveOpeningBalanceColumnIndex({ year: 2021, month: 1 })).toBe(7);
    expect(resolveOpeningBalanceColumnIndex({ year: 2025, month: 10 })).toBe(7);
  });
});

describe('import hash construction', () => {
  it('builds a SHA-256 hash incorporating sheetName, rowNumber, date, amount, and description', () => {
    const a = buildMigrationImportHash({ sheetName: 'lipiec', rowNumber: 5, date: '2020-07-01', amount: '10.00', description: 'test' });
    const b = buildMigrationImportHash({ sheetName: 'lipiec', rowNumber: 6, date: '2020-07-01', amount: '10.00', description: 'test' });
    expect(a).not.toBe(b);
    expect(a).toMatch(/^[a-f0-9]{64}$/);
  });
});
