# Phase 11: Account CRUD & Starting Balances — Specification

**Created:** 2026-06-10
**Ambiguity score:** 0.14 (gate: ≤ 0.20)
**Requirements:** 6 locked

## Goal

Users can create, rename, and delete accounts from the UI, and set a starting balance per account at creation time; the balance-over-time chart uses per-account starting balances (aggregated) as the baseline instead of the global monthly_opening_balances single value.

## Background

The `accounts` table exists (`id, name, type, currency, user_id, created_at`) but is **read-only** — only `listAccounts` exists in the backend (`src/core/reference/use-cases.ts`). Two seed accounts (ING Business, IPKO Personal) are created automatically on user signup via `src/auth.ts`. The frontend only fetches accounts for dropdown selectors (ImportUpload, AddTransaction).

The `monthly_opening_balances` table is **global per user** (no `account_id` foreign key) — it stores a single opening balance per `(user_id, year, month)`. Backend has full CRUD (POST/PUT), but the frontend only **displays** the current value in MonthSidebar — there is no UI to create or edit opening balances.

The balance-over-time chart (`getMonthlySummary` in `src/core/ledger/use-cases.ts`) computes:
`running_balance = opening_balance + monthly_savings(income - expenses)`

This uses the global `monthly_opening_balances` as baseline. There is no per-account starting balance mechanism today.

Assets (`assets` table) have full CRUD but are **not connected** to the balance computation — they appear as a static sum on the dashboard only.

**What does NOT exist today (the delta):**
- No `createAccount`, `updateAccount`, `deleteAccount` use-cases
- No POST/PUT/DELETE routes for accounts
- No account management UI (list, create, rename, delete)
- No `starting_balance` or `starting_balance_date` columns on accounts
- No UI to set starting balances per account
- Balance computation uses global opening balance, not per-account data

## Requirements

1. **Account CRUD — backend**: Create, update (rename), and delete accounts with user-scoped ownership validation.
   - Current: Only `listAccounts(userId)` exists in `src/core/reference/use-cases.ts`. Accounts are only created via the signup hook in `src/auth.ts`.
   - Target: `createAccount(params)`, `updateAccount(id, params)`, `deleteAccount(id)` in `src/core/reference/use-cases.ts`; `POST /accounts`, `PUT /accounts/:id`, `DELETE /accounts/:id` routes in `src/interface-adapters/api/reference.ts`; all operations validate `user_id` from session.
   - Acceptance: POST /accounts with valid body creates account and returns it; PUT /accounts/:id renames account; DELETE /accounts/:id deletes account (if no transactions reference it); all return 401 without auth; User B gets 404 for User A's account.

2. **Account CRUD — frontend**: UI to list, create, rename, and delete accounts.
   - Current: No account management UI exists. Accounts are only shown in dropdown selectors on ImportUpload and AddTransaction pages.
   - Target: Account management page or section listing all accounts with create form (name, type, currency), inline rename, and delete with confirmation dialog.
   - Acceptance: Page loads existing accounts; create form adds account and it appears in list; rename updates in-place in list; delete with 0 transactions succeeds with success toast; delete with existing transactions shows error toast ("Cannot delete account with transactions").

3. **Per-account starting balance — schema & migration**: New columns on accounts table for starting balance.
   - Current: Accounts have no balance column. Starting balances are stored globally in `monthly_opening_balances` (no `account_id`).
   - Target: Migration adds `starting_balance NUMERIC(19,4) NOT NULL DEFAULT 0` and `starting_balance_date DATE` to accounts. Existing accounts get `starting_balance=0` and `starting_balance_date=NULL`.
   - Acceptance: Migration runs cleanly up and down (reversible); existing accounts have `starting_balance=0` after migration; new accounts created with `starting_balance=5000` store the value correctly.

4. **Per-account starting balance — UI**: Form to set starting balance during account creation and optionally edit it later.
   - Current: No starting balance input exists anywhere in the frontend.
   - Target: Account create form includes `starting_balance` (numeric) and `starting_balance_date` (date picker) fields. Account detail/edit view allows updating starting balance and date.
   - Acceptance: Creating account with starting_balance=5000 and date=2024-01-01 stores both values; editing account updates starting_balance; empty starting_balance defaults to 0.

5. **Balance computation update**: `getMonthlySummary` uses per-account starting balances as the baseline.
   - Current: Running balance = `monthly_opening_balances.opening_balance + monthly_savings`. Single global value per month.
   - Target: `getMonthlySummary` sums all accounts' `starting_balance` values where `starting_balance_date <= month_start` and uses that sum as the initial baseline for the running balance calculation. The `monthly_opening_balances` table is deprecated (no new UI for it) but existing data remains readable as fallback.
   - Acceptance: User with 2 accounts (starting_balance 5000 and 3000) sees baseline 8000 at the starting_balance_date month; chart values are consistent with old global behavior for accounts with starting_balance=0; existing `monthly_opening_balances` data is preserved.

6. **Delete guard & name uniqueness**: Prevent data loss and confusion.
   - Current: No delete mechanism exists. No UNIQUE constraint on account names per user.
   - Target: DELETE /accounts/:id checks for existing transactions referencing `account_id` or `transfer_to_account_id` — returns 409 with message if any exist. Migration adds `UNIQUE(user_id, name)` to accounts. Seed accounts (already unique per user) are unaffected.
   - Acceptance: Delete with transactions returns 409; delete without transactions returns 204 and account is removed; creating second account with same name returns validation error.

## Boundaries

**In scope:**
- Backend account CRUD use-cases (create, read, update, delete) + routes
- Frontend account management page (list, create form, rename, delete with confirmation)
- Migration: add `starting_balance` and `starting_balance_date` to accounts table
- Migration: add `UNIQUE(user_id, name)` to accounts table
- Starting balance input in account create form
- Starting balance edit in account detail view
- `getMonthlySummary` updated to use per-account aggregated starting balances
- Delete guard (409 on accounts with transactions)
- Zod validation schemas for account CRUD

**Out of scope:**
- Assets (aktywa) integration into balance-over-time chart — requires value-snapshot-over-time model (asset values change monthly); separate phase
- Modifying `monthly_opening_balances` table schema (adding account_id) — replaced by per-account starting balance approach instead
- Transfers between accounts — separate feature for future phase
- Account reconciliation / balance verification — future enhancement
- Account archiving (soft-delete) — future enhancement
- Historical starting balance editing for past dates — only set at creation time
- Multiple currencies / exchange rate handling — no currency conversion in scope

## Constraints

- Migration must be backward-compatible: existing accounts get `starting_balance=0`, `starting_balance_date=NULL`
- Account name uniqueness per user: migration must handle potential duplicates (unlikely with seed accounts but should fail gracefully)
- Delete guard at minimum at application level (SELECT before DELETE); database-level FK with ON DELETE RESTRICT preferred
- Balance computation must handle accounts with `starting_balance_date=NULL` (treat starting_balance as 0)
- Frontend must follow existing patterns: React Query hooks with per-user key scoping (Phase 10), Tailwind CSS, shadcn/ui components where appropriate
- No new external dependencies

## Acceptance Criteria

- [ ] POST /accounts with name, type, currency creates account and returns 201 with account object
- [ ] POST /accounts with starting_balance=5000 and starting_balance_date=2024-01-01 stores both values
- [ ] PUT /accounts/:id updates account name; returns 404 for non-existent account
- [ ] DELETE /accounts/:id returns 409 if transactions reference the account; returns 204 otherwise
- [ ] Account management page lists all accounts for the authenticated user
- [ ] Create account form includes name (required), type (required), currency (default PLN), starting_balance (default 0), starting_balance_date
- [ ] Rename updates account name in-place and refetches the list
- [ ] Delete with 0 transactions shows confirmation dialog and success toast on completion
- [ ] Delete with transactions shows error toast "Cannot delete account with X transaction(s)"
- [ ] Migration 012 runs: adds `starting_balance NUMERIC(19,4) NOT NULL DEFAULT 0` and `starting_balance_date DATE` to accounts
- [ ] Migration 013 runs: adds `UNIQUE(user_id, name)` to accounts
- [ ] Existing accounts have `starting_balance=0` after migration (verified in test)
- [ ] `getMonthlySummary` returns correct baseline = sum of all accounts' starting_balance (where date <= month)
- [ ] Creating account with duplicate name (same user) returns validation error
- [ ] User B cannot access User A's accounts via any CRUD endpoint (404 on direct ID access)

## Ambiguity Report

| Dimension          | Score | Min  | Status | Notes                              |
|--------------------|-------|------|--------|------------------------------------|
| Goal Clarity       | 0.95  | 0.75 | ✓      | Account CRUD + starting balance UI |
| Boundary Clarity   | 0.90  | 0.70 | ✓      | In/out scope explicitly listed     |
| Constraint Clarity | 0.75  | 0.65 | ✓      | Migration compat, delete guard     |
| Acceptance Criteria| 0.75  | 0.70 | ✓      | 15 pass/fail criteria              |
| **Ambiguity**      | 0.14  | ≤0.20| ✓      |                                    |

Status: ✓ = met minimum

## Interview Log

| Round | Perspective     | Question summary                                           | Decision locked                                              |
|-------|-----------------|------------------------------------------------------------|--------------------------------------------------------------|
| 1     | Researcher      | What exists for accounts/starting balances today?          | Accounts are read-only; monthly_opening_balances is global; no starting balance UI |
| 2     | Simplifier      | Minimum viable scope?                                      | Irreducible core: account CRUD + starting balance at creation time. Assets integration deferred |
| 3     | Boundary Keeper | What's explicitly NOT in this phase?                       | Asset integration, transfers, reconciliation, archiving out of scope |
| 4     | Failure Analyst | What edge cases invalidate requirements?                   | Delete guard (409), name uniqueness, backward-compatible migration |

---

*Phase: 11-account-crud-starting-balances*
*Spec created: 2026-06-10*
*Next step: /gsd-discuss-phase 11 — implementation decisions (how to build what's specified above)*
