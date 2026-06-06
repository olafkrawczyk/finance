# Phase 1: foundation-core-ledger-db - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-06
**Phase:** 01-foundation-core-ledger-db
**Areas discussed:** Opening balance setup, auto fixed-cost flag, API response format

---

## Opening Balance Setup

### Q1: How should the initial balance be established?

| Option | Description | Selected |
|--------|-------------|----------|
| Manual seed endpoint | POST /accounts/:id/opening-balance in Phase 1 | |
| Hardcoded seed script | SQL file with hardcoded July 2020 balances | |
| Defer to Phase 2 | Leave empty, stan konta starts from 0 | |

**User's choice:** Free-text — "this has to be editable for each month. at the start of the month we need to set the total balance of the previous. i think its need to be manual bc we can have some money in cash, silver, ETF, etc. bank accounts aren't only the source of truth for income."

**Notes:** User clarified that monthly_opening_balances tracks total net worth, not just bank balance. Opened follow-up questions.

### Q2: Does stan konta show bank balance or total net worth?

| Option | Description | Selected |
|--------|-------------|----------|
| Bank balance only | stan konta = running bank balance from transactions | |
| Total net worth | stan konta = total assets including non-bank holdings | ✓ |
| Two separate things | Bank transactions + separate net worth tracker | |

**User's choice:** Total net worth — "from my xlsx stan konta is the total net worth, it's named like this bc it started as bank balance"

### Q3: How should total net worth be tracked monthly?

| Option | Description | Selected |
|--------|-------------|----------|
| Manual monthly snapshot | One global row per month, user sets total net worth manually | ✓ |
| Per-account + net_worth_extra | Keep per-account + separate non_bank_assets table | |
| Bank-only, manual corrections | Bank transactions + adjustment transaction type | |

**User's choice:** Manual monthly snapshot — global table, no account_id.

### Q4: Include CRUD endpoint in Phase 1?

| Option | Description | Selected |
|--------|-------------|----------|
| Include full CRUD endpoint | GET + POST + PUT /opening-balance in Plan 03 | ✓ |
| Schema only | Table change in Plan 02, endpoint deferred to Phase 3 | |
| Move to next area | Leave endpoint details to planner | |

**User's choice:** Include full CRUD endpoint.

---

## auto Fixed-Cost Flag

### Q1: Should auto category have is_fixed_cost = true?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, auto = fixed cost | Arval lease is a fixed monthly commitment | |
| No, keep auto = false | auto covers all car expenses, not just lease | |
| Split the category | Create arval (fixed) + auto (variable) | |

**User's choice:** Free-text — "arval lease is fixed cost as it tracks monthly payments, maybe we could change arval to auto-payments as it's separate thing"

**Notes:** User revealed that `auto` category specifically tracks Arval lease payments, not general car costs.

### Q2: Rename auto → arval, what about general car expenses?

| Option | Description | Selected |
|--------|-------------|----------|
| Rename auto → arval, add new paliwo for fuel (already exists) | arval = fixed lease, paliwo for fuel | ✓ |
| Rename auto → arval, keep auto as new general car category | Two categories: arval + auto | |
| Rename auto → arval only, no new category | Other car costs go to existing categories | |

**User's choice:** Rename auto → arval, fuel uses existing paliwo category.

---

## API Response Format

### Q1: Standard envelope or bare JSON?

| Option | Description | Selected |
|--------|-------------|----------|
| Standard envelope | { data, error, meta } on all responses | ✓ |
| Bare JSON | Return objects/arrays directly, HTTP status for errors | |
| You decide | Leave choice to planner | |

**User's choice:** Standard envelope — "yeah standard, and we want to add metadata for creation date for example etc"

### Q2: What should the envelope look like?

| Option | Description | Selected |
|--------|-------------|----------|
| { data, error, meta } with resource-level metadata | meta = { total, page, per_page } for lists | ✓ |
| { data, error } only | Timestamps on data objects, no extra wrapper | |
| { data, error, request_id, timestamp } | Observability fields on every response | |

**User's choice:** { data, error, meta } with pagination metadata in meta for lists.

---

## Claude's Discretion

- Error code format (string codes vs just message) — either `{ message }` or `{ code, message }` acceptable
- Default pagination page size — planner decides (50 or 100 suggested)

## Deferred Ideas

- Individual non-bank asset tracking (ETF positions, silver holdings, cash on hand as separate entities) — captured in monthly opening balance total for now
- Cursor-based pagination — add if dataset size warrants it (thousands of transactions from July 2020)
