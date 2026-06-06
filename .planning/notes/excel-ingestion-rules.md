# Note: Excel Ingestion Rules
**Date:** 2026-06-07
**Context:** Phase 4.8 Data Ingestion and Excel Migration

This note defines the ingestion, mapping, and routing rules for importing the historical `budget.xlsx` data.

## 1. Sheet Formats & Shifts
The spreadsheet spans years of data across multiple monthly sheets. We must handle two primary layout formats:
* **Modern Sheets (February 2021 to October 2025):**
  * Expenses: Columns A–D (`kategoria`, `kwota`, `opis`, `data`)
  * Incomes: Columns E–F (`Przychody` header, name in E, amount in F)
  * Opening Balance: Column H, Row 3 (value under `Stan konta na początku miesiąca`)
  * Fixed Costs: Columns J–M (`Koszty stałe`)
* **Legacy Sheets (July 2020 to January 2021):**
  * Expenses: Columns A–B (`Wydatki` header, category in A, amount in B). Dates and descriptions are empty/non-existent.
  * Incomes:
    * July 2020 to October 2020: Columns D–E (Name in D, Amount in E)
    * November 2020 to January 2021: Columns E–F (Name in E, Amount in F)
  * Opening Balance: 
    * July 2020 to October 2020: Column G, Row 3
    * November 2020 to January 2021: Column H, Row 3

## 2. Ingestion & Default Handling
* **Redundancy Filter:** Ignore columns R–U in the monthly sheets. They represent previous month's copies and are redundant when parsing all sheets.
* **Dates:** 
  * If a transaction has a valid date in column D, parse and use it.
  * If the sheet lacks date columns (legacy sheets) or the cell is blank, default the transaction date to the **1st of the month** derived from the sheet name (e.g. `lipiec` 2020 -> `2020-07-01`).
* **Descriptions:** Default to `NULL` (or empty string) if the description column (C) is missing or blank.

## 3. Category Mapping
Legacy sheets contain some categories that don't match the application's seeded 25 categories. Resolve them as follows:
* `dentysta` -> map to `lekarz`
* `mpk` -> map to `przejazdy`
* `kawka` -> map to `kawa`
* Any other unrecognized category -> fallback to `fun`

## 4. Account Routing Rules
We must route each transaction to either the **ING Business** account (`Konto Direct dla Firmy`) or the **PKO Personal** account (`IPKO`).
* **Route to ING Business (`Konto Direct dla Firmy`) if:**
  * Category is `VAT`, `ZUS`, `PIT` (or `PIT36`), or `paliwo`.
  * Category is `auto` AND the transaction amount is strictly greater than 2000 PLN.
  * The description contains the words `PPE`, `ORANGE`, or `PLAY` (case-insensitive search).
* **Route to PKO Personal (`IPKO`):**
  * All other transactions (including incomes unless they meet the ING criteria above, though incomes generally go to PKO unless specified).
