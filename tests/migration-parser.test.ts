import { describe, it } from 'bun:test';

/**
 * Wave 0 stubs for the Excel migration parser (src/core/import/excel-parser.ts).
 * These are filled in with real assertions in Task 2 once the parser module exists.
 */
describe('Excel migration parser', () => {
  describe('normalizeText', () => {
    it.todo('lowercases, strips diacritics, and maps Polish ł/Ł to l');
  });

  describe('chronological sheet sorting', () => {
    it.todo('sorts legacy sheets without year suffix using lipiec-grudzien -> 2020, styczen -> 2021');
    it.todo('sorts modern sheets with explicit year suffix by (year, month)');
    it.todo('skips helper sheets like zbiorczy and kategorie');
    it.todo('orders e.g. lipiec 2020 before styczen 2021 before luty 2021');
  });

  describe('Excel serial date conversion', () => {
    it.todo('converts numeric Excel serial dates to YYYY-MM-DD using XLSX.SSF.parse_date_code (timezone-safe)');
    it.todo('parses string dates matching YYYY-MM-DD or DD.MM.YYYY and normalizes to YYYY-MM-DD');
    it.todo('defaults to the 1st of the sheet month when no valid date is present');
  });

  describe('category resolution / translation', () => {
    it.todo('maps dentysta -> lekarz');
    it.todo('maps mpk -> przejazdy');
    it.todo('maps kawka -> kawa');
    it.todo('falls back to fun for unrecognized categories');
  });

  describe('account routing', () => {
    it.todo('routes VAT, ZUS, PIT/PIT36, paliwo categories to ING Business (Konto Direct dla Firmy)');
    it.todo('routes auto category with amount > 2000 PLN to ING Business');
    it.todo('routes descriptions containing PPE, ORANGE, or PLAY (case-insensitive) to ING Business');
    it.todo('routes all other transactions to PKO Personal (IPKO)');
  });

  describe('opening balance column resolution', () => {
    it.todo('resolves Column G (index 6) for July-October 2020 sheets');
    it.todo('resolves Column H (index 7) for November 2020 onwards sheets');
  });
});
