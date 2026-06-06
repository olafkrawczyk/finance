---
date: "2026-06-06 14:00"
promoted: false
---

## Design Decisions from xlsx + CSV exploration

### Data model (from budget.xlsx analysis)

Transaction record: category, amount, description (raw bank text), date, type (income/expense/transfer), account_id

Categories (~26, derived from xlsx): biedronka, żabka, paliwo, taxi, fun, VAT, PIT36, ZUS, auto, biuro, mieszkanie, przejazdy, kawa, kredyt, lidl, ubrania, rossman, apteka, lekarz, kluska, krypto, inwestycje, prezenty, restauracje, foto

Fixed costs (koszty stałe) = category-level flag. Fixed: ZUS, PIT36/PPE, VAT, mieszkanie, kredyt, auto (Arval lease). These are subtracted separately in Zbiorczy view.

Accounts: ING (business "Konto Direct dla Firmy") + IPKO/PKO (personal). Both tracked as unified picture.

Transfers: "Wplata wlasna" ING→PKO = transfer type, NOT counted as income/expense. Must detect and exclude from totals.

Income: named sources - sml (SoftwareMill), sml prezent (bonus), skąd? (other/unknown)

### Views to implement (exact match to xlsx)

Zbiorczy (summary): month | wydatki | przychody | stan konta | wydatki bez kosztów stałych | zaoszczędzone | zaoszczędzone log(10)

Monthly view: category | kwota | opis | data — transactions sorted desc by date. Sidebar: income sources + amounts, opening balance, fixed costs breakdown by category (SUMIF equivalent).

Dashboard charts: balance over time, expenses+income+balance+prediction, savings, savings log scale.

### Import architecture

Async endpoint: POST /import → receives CSV file + account_id → enqueue to PGMQ → return job_id

PGMQ worker: dequeue job → call OpenRouter with few-shot prompt → receive structured JSON → insert transactions as uncategorized

Few-shot prompt includes:
- ING format: semicolon-delimited, ~20-row metadata header, ISO-8859-2 encoding, columns: date;booking_date;counterparty;title;account_no;bank;details;tx_no;amount;currency;...;account_name;balance;currency
- IPKO format: comma-quoted, first row is header, columns: date,value_date,type,amount,currency,balance,description,...
- IPKO "Blokada" (pending) rows have no date → SKIP these
- Expected output: [{date, amount, description, account_name, raw_type}]

After LLM parse: transactions inserted with category_id=NULL (uncategorized), import_hash for dedup.

### CSV format quirks to handle

ING:
- File encoding: ISO-8859-2 / Windows-1250 (Polish characters corrupted in UTF-8)
- First ~20 rows: bank metadata, account info, summary — skip until header row
- Header row: starts with "Data transakcji"
- Amount column: uses comma as decimal separator (246,00) and negative = expense
- Multiple accounts may be in one export (Konto Direct + Rachunek VAT) — use "Konto" column

IPKO:
- Clean UTF-8 quoted CSV
- Skip rows where Typ transakcji = "Blokada" (pending/blocked)
- Amount already negative for debits
- Description is in "Opis transakcji" column (first sub-column)

### DB schema (simplified, NOT double-entry)

accounts: id, name, type (personal/business), currency, created_at
categories: id, name, is_fixed_cost, created_at
transactions: id, account_id, category_id (nullable), type (income/expense/transfer), amount (NUMERIC(19,4), always positive), description, date, transfer_to_account_id (nullable), import_hash (unique, for dedup), created_at
monthly_opening_balances: id, account_id, year, month, opening_balance — UNIQUE(account_id, year, month)

Historical data: xlsx goes back to July 2020 — import path must handle bulk historical data.
