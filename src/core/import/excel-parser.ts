import { createHash } from 'crypto';
import * as XLSX from 'xlsx';

// ---------------------------------------------------------------------------
// Text normalization
// ---------------------------------------------------------------------------

/**
 * Normalizes text for case/diacritic-insensitive comparisons:
 * lowercases, strips combining diacritics (NFD), and maps Polish ł/Ł -> l.
 */
// Combining diacritical marks U+0300-U+036F (matches plan spec /[̀-ͯ]/g)
const COMBINING_DIACRITICS_RE = new RegExp('[\\u0300-\\u036f]', 'g');

export function normalizeText(str: string): string {
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(COMBINING_DIACRITICS_RE, '')
    .replace(/ł/g, 'l')
    .replace(/Ł/g, 'l')
    .trim();
}

// ---------------------------------------------------------------------------
// Sheet chronological sorting
// ---------------------------------------------------------------------------

export const HELPER_SHEETS = ['zbiorczy', 'kategorie'];

const MONTH_NAME_TO_NUMBER: Record<string, number> = {
  styczen: 1,
  luty: 2,
  marzec: 3,
  kwiecien: 4,
  maj: 5,
  czerwiec: 6,
  lipiec: 7,
  sierpien: 8,
  wrzesien: 9,
  pazdziernik: 10,
  listopad: 11,
  grudzien: 12,
};

// Legacy sheets (no year suffix): lipiec..grudzien -> 2020, styczen -> 2021
const LEGACY_NO_YEAR_TO_YEAR: Record<string, number> = {
  lipiec: 2020,
  sierpien: 2020,
  wrzesien: 2020,
  pazdziernik: 2020,
  listopad: 2020,
  grudzien: 2020,
  styczen: 2021,
};

export interface SheetMeta {
  sheetName: string;
  month: number; // 1-12
  year: number;
}

/**
 * Resolves a sheet name to its { month, year }, or null if the sheet should
 * be skipped (helper sheets, or names that don't match a recognized month).
 */
export function resolveSheetMeta(sheetName: string): SheetMeta | null {
  const normalized = normalizeText(sheetName);

  if (HELPER_SHEETS.some((helper) => normalized.includes(helper))) {
    return null;
  }

  // Find the month name within the normalized sheet name
  let matchedMonth: string | null = null;
  for (const monthName of Object.keys(MONTH_NAME_TO_NUMBER)) {
    if (normalized.includes(monthName)) {
      matchedMonth = monthName;
      break;
    }
  }

  if (!matchedMonth) {
    return null;
  }

  const month = MONTH_NAME_TO_NUMBER[matchedMonth];

  // Look for an explicit 4-digit year in the sheet name
  const yearMatch = normalized.match(/(20\d{2})/);
  let year: number;
  if (yearMatch) {
    year = parseInt(yearMatch[1], 10);
  } else {
    const legacyYear = LEGACY_NO_YEAR_TO_YEAR[matchedMonth];
    if (legacyYear === undefined) {
      // Month name present but no year and not a known legacy month -> skip
      return null;
    }
    year = legacyYear;
  }

  return { sheetName, month, year };
}

/**
 * Filters out helper/unrecognized sheets and sorts the remaining sheets
 * chronologically (oldest first).
 */
export function sortSheetsChronologically(sheetNames: string[]): SheetMeta[] {
  const metas = sheetNames
    .map((name) => resolveSheetMeta(name))
    .filter((meta): meta is SheetMeta => meta !== null);

  return metas.sort((a, b) => a.year - b.year || a.month - b.month);
}

// ---------------------------------------------------------------------------
// Excel date parsing (timezone-safe)
// ---------------------------------------------------------------------------

const ISO_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})/;
const DOTTED_DATE_RE = /^(\d{1,2})\.(\d{1,2})\.(\d{4})/;

function pad2(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

/**
 * Builds the default date string (1st of the month) for a sheet.
 */
export function defaultSheetDate(meta: { year: number; month: number }): string {
  return `${meta.year}-${pad2(meta.month)}-01`;
}

/**
 * Safely converts an Excel cell value to a YYYY-MM-DD date string.
 * - Numbers are treated as Excel serial dates (parsed via XLSX.SSF.parse_date_code,
 *   which is timezone-safe — no Date object / local-TZ conversion involved).
 * - Strings matching YYYY-MM-DD or DD.MM.YYYY are parsed and normalized.
 * - Anything else (or invalid) defaults to the 1st of the sheet's month.
 */
export function parseExcelDate(value: unknown, sheetMeta: { year: number; month: number }): string {
  const fallback = defaultSheetDate(sheetMeta);

  if (value === null || value === undefined || value === '') {
    return fallback;
  }

  if (typeof value === 'number') {
    const parsed = XLSX.SSF.parse_date_code(value);
    if (parsed && parsed.y && parsed.m && parsed.d) {
      return `${parsed.y}-${pad2(parsed.m)}-${pad2(parsed.d)}`;
    }
    return fallback;
  }

  if (typeof value === 'string') {
    const trimmed = value.trim();

    const isoMatch = trimmed.match(ISO_DATE_RE);
    if (isoMatch) {
      return `${isoMatch[1]}-${isoMatch[2]}-${isoMatch[3]}`;
    }

    const dottedMatch = trimmed.match(DOTTED_DATE_RE);
    if (dottedMatch) {
      const [, d, m, y] = dottedMatch;
      return `${y}-${pad2(parseInt(m, 10))}-${pad2(parseInt(d, 10))}`;
    }
  }

  return fallback;
}

// ---------------------------------------------------------------------------
// Opening balance cell selector
// ---------------------------------------------------------------------------

export const OPENING_BALANCE_ROW_INDEX = 2; // Row 3 (0-indexed)
const OPENING_BALANCE_COL_G = 6;
const OPENING_BALANCE_COL_H = 7;

/**
 * Returns the column index (0-based) holding the opening balance for the
 * given sheet's year/month:
 *  - Jul-Oct 2020 (year 2020, month <= 10) -> Column G (index 6)
 *  - Nov 2020 onwards                       -> Column H (index 7)
 */
export function resolveOpeningBalanceColumnIndex(meta: { year: number; month: number }): number {
  if (meta.year === 2020 && meta.month <= 10) {
    return OPENING_BALANCE_COL_G;
  }
  return OPENING_BALANCE_COL_H;
}

// ---------------------------------------------------------------------------
// Category resolver
// ---------------------------------------------------------------------------

export const LEGACY_CATEGORY_TRANSLATIONS: Record<string, string> = {
  dentysta: 'lekarz',
  mpk: 'przejazdy',
  kawka: 'kawa',
};

export const FALLBACK_CATEGORY_NAME = 'fun';

export interface CategoryRecord {
  id: string;
  name: string;
}

export interface ResolvedCategory {
  id: string | null;
  name: string;
}

/**
 * Resolves a raw spreadsheet category string against the database's seeded
 * categories, applying legacy translations first and falling back to `fun`
 * when no match is found.
 */
export function resolveCategory(rawCategory: string | null | undefined, dbCategories: CategoryRecord[]): ResolvedCategory {
  const normalizedDbByName = new Map(dbCategories.map((c) => [normalizeText(c.name), c]));

  const fallback = normalizedDbByName.get(normalizeText(FALLBACK_CATEGORY_NAME));
  const fallbackResolved: ResolvedCategory = fallback
    ? { id: fallback.id, name: fallback.name }
    : { id: null, name: FALLBACK_CATEGORY_NAME };

  if (!rawCategory || !rawCategory.trim()) {
    return fallbackResolved;
  }

  const normalizedRaw = normalizeText(rawCategory);
  const translated = LEGACY_CATEGORY_TRANSLATIONS[normalizedRaw] ?? normalizedRaw;
  const normalizedTranslated = normalizeText(translated);

  const match = normalizedDbByName.get(normalizedTranslated);
  if (match) {
    return { id: match.id, name: match.name };
  }

  return fallbackResolved;
}

// ---------------------------------------------------------------------------
// Account router
// ---------------------------------------------------------------------------

export const ING_BUSINESS_ACCOUNT_NAME = 'Konto Direct dla Firmy';
export const PKO_PERSONAL_ACCOUNT_NAME = 'IPKO';

const ING_CATEGORY_KEYWORDS = ['vat', 'zus', 'pit', 'paliwo'];
const ING_DESCRIPTION_KEYWORDS = ['ppe', 'orange', 'play'];
const AUTO_CATEGORY_NAME = 'auto';
const AUTO_AMOUNT_THRESHOLD = 2000;

export type RoutedAccount = 'ing_business' | 'pko_personal';

/**
 * Determines whether a transaction should be routed to ING Business or
 * PKO Personal, based on the *raw* spreadsheet category, the transaction
 * amount, and its description.
 */
export function routeAccount(params: {
  rawCategory: string | null | undefined;
  amount: number;
  description: string | null | undefined;
}): RoutedAccount {
  const normalizedCategory = params.rawCategory ? normalizeText(params.rawCategory) : '';
  const normalizedDescription = params.description ? normalizeText(params.description) : '';

  if (ING_CATEGORY_KEYWORDS.some((kw) => normalizedCategory.includes(kw))) {
    return 'ing_business';
  }

  if (normalizedCategory === AUTO_CATEGORY_NAME && params.amount > AUTO_AMOUNT_THRESHOLD) {
    return 'ing_business';
  }

  if (ING_DESCRIPTION_KEYWORDS.some((kw) => normalizedDescription.includes(kw))) {
    return 'ing_business';
  }

  return 'pko_personal';
}

// ---------------------------------------------------------------------------
// Import hash
// ---------------------------------------------------------------------------

/**
 * Builds the unique import hash for a migrated row:
 * SHA-256 of `${sheetName}|${rowNumber}|${date}|${amount}|${description}`.
 * Including the sheet name and row number guarantees uniqueness across the
 * entire historical ledger, even for legitimately-identical transactions.
 */
export function buildMigrationImportHash(params: {
  sheetName: string;
  rowNumber: number;
  date: string;
  amount: string;
  description: string | null;
}): string {
  const description = params.description ?? '';
  return createHash('sha256')
    .update(`${params.sheetName}|${params.rowNumber}|${params.date}|${params.amount}|${description}`)
    .digest('hex');
}

// ---------------------------------------------------------------------------
// Transaction parsing
// ---------------------------------------------------------------------------

export interface ParsedMigrationTransaction {
  type: 'income' | 'expense';
  amount: string; // positive decimal string
  description: string | null;
  date: string; // YYYY-MM-DD
  rawCategory: string | null;
  category: ResolvedCategory | null; // null for incomes
  routedAccount: RoutedAccount;
  importHash: string;
  rowNumber: number;
  sheetName: string;
}

const IGNORED_COLUMN_START_INDEX = 17; // R = index 17

const MODERN_FIRST_YEAR_MONTH = { year: 2021, month: 2 };

function isModernSheet(meta: { year: number; month: number }): boolean {
  return meta.year > MODERN_FIRST_YEAR_MONTH.year ||
    (meta.year === MODERN_FIRST_YEAR_MONTH.year && meta.month >= MODERN_FIRST_YEAR_MONTH.month);
}

function toAmountString(value: unknown): string | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.abs(value).toFixed(2);
  }
  if (typeof value === 'string') {
    const cleaned = value.replace(/\s/g, '').replace(',', '.');
    const num = parseFloat(cleaned);
    if (Number.isFinite(num)) {
      return Math.abs(num).toFixed(2);
    }
  }
  return null;
}

function cellToString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const str = String(value).trim();
  return str.length > 0 ? str : null;
}

/**
 * Parses all expense and income rows from a single worksheet (already
 * resolved to its chronological metadata), applying category resolution,
 * account routing, and import-hash computation.
 *
 * `rows` is the worksheet converted to an array-of-arrays via
 * `XLSX.utils.sheet_to_json(sheet, { header: 1 })`.
 */
export function parseSheetTransactions(
  rows: unknown[][],
  meta: SheetMeta,
  dbCategories: CategoryRecord[]
): ParsedMigrationTransaction[] {
  const results: ParsedMigrationTransaction[] = [];
  const modern = isModernSheet(meta);
  const sheetDefaultDate = defaultSheetDate(meta);

  // Determine income column indices for legacy sheets
  let legacyIncomeNameCol = 4; // E
  let legacyIncomeAmountCol = 5; // F
  if (!modern) {
    if (meta.year === 2020 && meta.month >= 7 && meta.month <= 10) {
      legacyIncomeNameCol = 3; // D
      legacyIncomeAmountCol = 4; // E
    } else {
      legacyIncomeNameCol = 4; // E
      legacyIncomeAmountCol = 5; // F
    }
  }

  for (let rowIdx = 0; rowIdx < rows.length; rowIdx++) {
    const row = rows[rowIdx];
    if (!row || row.length === 0) continue;
    const rowNumber = rowIdx + 1;

    // Filter out redundant columns R-U by truncating the row for our purposes
    const usableRow = row.slice(0, IGNORED_COLUMN_START_INDEX);

    if (modern) {
      // --- Expenses: Cols A-D (kategoria, kwota, opis, data) ---
      const rawCategory = cellToString(usableRow[0]);
      const amount = toAmountString(usableRow[1]);
      const description = cellToString(usableRow[2]);
      const dateCell = usableRow[3];

      if (rawCategory && amount && !isHeaderValue(rawCategory)) {
        const date = parseExcelDate(dateCell, meta);
        const category = resolveCategory(rawCategory, dbCategories);
        const routedAccount = routeAccount({ rawCategory, amount: parseFloat(amount), description });
        results.push({
          type: 'expense',
          amount,
          description,
          date,
          rawCategory,
          category,
          routedAccount,
          importHash: buildMigrationImportHash({ sheetName: meta.sheetName, rowNumber, date, amount, description }),
          rowNumber,
          sheetName: meta.sheetName,
        });
      }

      // --- Incomes: Cols E-F (nazwa, kwota) ---
      const incomeName = cellToString(usableRow[4]);
      const incomeAmount = toAmountString(usableRow[5]);
      if (incomeName && incomeAmount && !isHeaderValue(incomeName)) {
        const date = sheetDefaultDate;
        results.push({
          type: 'income',
          amount: incomeAmount,
          description: incomeName,
          date,
          rawCategory: null,
          category: null,
          routedAccount: routeAccount({ rawCategory: null, amount: parseFloat(incomeAmount), description: incomeName }),
          importHash: buildMigrationImportHash({ sheetName: meta.sheetName, rowNumber, date, amount: incomeAmount, description: incomeName }),
          rowNumber,
          sheetName: meta.sheetName,
        });
      }
    } else {
      // --- Legacy expenses: Cols A-B (kategoria, kwota); description NULL, date defaults to 1st ---
      const rawCategory = cellToString(usableRow[0]);
      const amount = toAmountString(usableRow[1]);

      if (rawCategory && amount && !isHeaderValue(rawCategory)) {
        const date = sheetDefaultDate;
        const description: string | null = null;
        const category = resolveCategory(rawCategory, dbCategories);
        const routedAccount = routeAccount({ rawCategory, amount: parseFloat(amount), description });
        results.push({
          type: 'expense',
          amount,
          description,
          date,
          rawCategory,
          category,
          routedAccount,
          importHash: buildMigrationImportHash({ sheetName: meta.sheetName, rowNumber, date, amount, description }),
          rowNumber,
          sheetName: meta.sheetName,
        });
      }

      // --- Legacy incomes ---
      const incomeName = cellToString(usableRow[legacyIncomeNameCol]);
      const incomeAmount = toAmountString(usableRow[legacyIncomeAmountCol]);
      if (incomeName && incomeAmount && !isHeaderValue(incomeName)) {
        const date = sheetDefaultDate;
        results.push({
          type: 'income',
          amount: incomeAmount,
          description: incomeName,
          date,
          rawCategory: null,
          category: null,
          routedAccount: routeAccount({ rawCategory: null, amount: parseFloat(incomeAmount), description: incomeName }),
          importHash: buildMigrationImportHash({ sheetName: meta.sheetName, rowNumber, date, amount: incomeAmount, description: incomeName }),
          rowNumber,
          sheetName: meta.sheetName,
        });
      }
    }
  }

  return results;
}

const HEADER_VALUES = ['kategoria', 'kwota', 'opis', 'data', 'nazwa', 'wydatki', 'przychody'];

function isHeaderValue(value: string): boolean {
  return HEADER_VALUES.includes(normalizeText(value));
}

// ---------------------------------------------------------------------------
// Workbook-level extraction
// ---------------------------------------------------------------------------

export interface ExtractedSheet {
  meta: SheetMeta;
  openingBalance: number | null;
  transactions: ParsedMigrationTransaction[];
}

/**
 * Loads a workbook and extracts all monthly sheets in chronological order,
 * including their opening balances and parsed transactions.
 */
export function extractWorkbook(workbook: XLSX.WorkBook, dbCategories: CategoryRecord[]): ExtractedSheet[] {
  const sortedMetas = sortSheetsChronologically(workbook.SheetNames);

  return sortedMetas.map((meta) => {
    const sheet = workbook.Sheets[meta.sheetName];
    const rows: unknown[][] = XLSX.utils.sheet_to_json(sheet, { header: 1, raw: true, defval: null });

    const balanceColIndex = resolveOpeningBalanceColumnIndex(meta);
    const balanceRow = rows[OPENING_BALANCE_ROW_INDEX];
    const rawBalance = balanceRow ? balanceRow[balanceColIndex] : null;
    const openingBalance = toAmountString(rawBalance);

    return {
      meta,
      openingBalance: openingBalance !== null ? parseFloat(openingBalance) * (isNegativeCell(rawBalance) ? -1 : 1) : null,
      transactions: parseSheetTransactions(rows, meta, dbCategories),
    };
  });
}

function isNegativeCell(value: unknown): boolean {
  if (typeof value === 'number') return value < 0;
  if (typeof value === 'string') return value.trim().startsWith('-');
  return false;
}
