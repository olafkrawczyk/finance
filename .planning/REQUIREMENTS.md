# Requirements: Financial Planning App

## Core Objective
Deliver a robust, ledger-first financial planning application that provides users with accurate tracking, budgeting, and AI-driven insights while maintaining high data integrity.

## Functional Requirements

### 1. Ledger & Transaction Management

- **REQ-1.1 Transaction model:** Each transaction stores: `category`, `amount` (always positive), `description` (raw bank text), `date`, `type` (income | expense | transfer), `account_id`.
- **REQ-1.2 Immutable records:** Transactions cannot be deleted or updated; corrections via new compensating entries only.
- **REQ-1.3 Multi-account:** Two accounts at minimum — ING business ("Konto Direct dla Firmy") and IPKO personal. Both tracked as a unified picture.
- **REQ-1.4 Transfer type:** Transfers between own accounts (e.g., "Wplata wlasna" ING→PKO) must be marked `type=transfer` and excluded from income/expense totals.
- **REQ-1.5 Single currency:** PLN only for MVP; schema supports `currency` field for future extension.

### 2. Category System

- **REQ-2.1 Category list:** Seed the following 26 categories on first run: `biedronka`, `żabka`, `paliwo`, `taxi`, `fun`, `VAT`, `PIT36`, `ZUS`, `auto`, `biuro`, `mieszkanie`, `przejazdy`, `kawa`, `kredyt`, `lidl`, `ubrania`, `rossman`, `apteka`, `lekarz`, `kluska`, `krypto`, `inwestycje`, `prezenty`, `restauracje`, `foto`.
- **REQ-2.2 Fixed cost flag:** Categories have an `is_fixed_cost` boolean. Fixed: `ZUS`, `PIT36`, `VAT`, `mieszkanie`, `kredyt`. Used to compute "wydatki bez kosztów stałych".
- **REQ-2.3 Uncategorized:** Imported transactions arrive with `category_id = NULL`; user categorizes via UI.

### 3. Views (matching budget.xlsx exactly)

- **REQ-3.1 Zbiorczy (summary view):** One row per month: `month`, `wydatki` (total expenses), `przychody` (total income), `stan konta` (running balance), `wydatki bez kosztów stałych` (expenses minus fixed-cost categories), `zaoszczędzone` (income − expenses), `zaoszczędzone_log` (log₁₀ of savings when positive).
- **REQ-3.2 Monthly view:** Per-month transaction list sorted by date desc: `category`, `amount`, `description`, `date`. Sidebar: income sources with amounts, opening balance, fixed costs breakdown by category (SUMIF-equivalent).
- **REQ-3.3 Dashboard charts:** (a) account balance over time, (b) expenses + income + balance + prediction line, (c) savings over time, (d) savings log-scale.

### 4. Bank CSV Import (LLM-powered)

- **REQ-4.1 Async endpoint:** `POST /import` accepts CSV file upload + `account_id`. Enqueues job to PGMQ. Returns `{ job_id }` immediately.
- **REQ-4.2 PGMQ worker:** Worker dequeues job, calls OpenRouter with few-shot prompt, receives structured JSON `[{date, amount, description, raw_type}]`, inserts transactions with `category_id = NULL`.
- **REQ-4.3 ING format:** Semicolon-delimited. Encoding: ISO-8859-2 / Windows-1250. Skip first ~20 metadata rows until the row starting with `"Data transakcji"`. Amount uses comma decimal (e.g. `246,00`). Negative = expense.
- **REQ-4.4 IPKO format:** Comma-quoted UTF-8. First row is header. Skip rows where `Typ transakcji = "Blokada"` (pending transactions with no date). Amount is pre-signed (negative = expense).
- **REQ-4.5 Deduplication:** Each imported transaction gets an `import_hash` (SHA-256 of date+amount+description). Duplicate hashes are silently skipped.
- **REQ-4.6 Few-shot prompt:** OpenRouter prompt includes 3–5 example rows from each bank format with their expected structured output. Model must return valid JSON array. Use `structured_outputs` / JSON mode.
- **REQ-4.7 Historical bulk import:** Import must handle thousands of transactions (xlsx has data from July 2020). Worker must process in batches.

### 5. Manual Entry

- **REQ-5.1** Users can manually add a transaction via form: category, amount, description, date, type, account.

### 6. Authentication & Security
- **OAuth/SSO:** Integration with providers (Google/GitHub) via Better Auth.
- **Secure Data Storage:** Encryption of sensitive user data at rest.

### 5. Authentication & Security
- **OAuth/SSO:** Integration with providers (Google/GitHub) via Better Auth.
- **Secure Data Storage:** Encryption of sensitive user data at rest.

## Technical Requirements

### 1. Database
- **Postgres:** Primary data store.
- **Numeric Precision:** Use `NUMERIC(19, 4)` for all currency fields to avoid floating-point errors.
- **PGMQ Extension:** Must be installed and configured for background tasks.
- **Core tables:** `accounts`, `categories`, `transactions`, `monthly_opening_balances`.
- **No double-entry:** Simple income/expense/transfer model (not accounting double-entry). Transfer type links `account_id` and `transfer_to_account_id`.

### 2. Backend
- **Bun + Hono:** High-performance runtime and framework.
- **Zod:** Strict schema validation for all API inputs and outputs.
- **Better Auth:** Framework for managing authentication sessions.

### 3. Frontend
- **React + Tailwind CSS:** For a responsive and modern user interface.
- **State Management:** (e.g., TanStack Query for data fetching).

## Non-Functional Requirements
- **Data Integrity:** Zero-sum transaction verification at the database level.
- **Performance:** Sub-100ms API response times for standard queries.
- **Reliability:** Background jobs must be idempotent and retryable.
