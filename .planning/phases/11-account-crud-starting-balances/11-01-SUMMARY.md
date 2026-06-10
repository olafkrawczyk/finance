---
phase: 11-account-crud-starting-balances
plan: 01
subsystem: backend
tags:
  - migrations
  - accounts
  - CRUD
  - zod-schemas
  - api-routes
  - delete-guard
requires: []
provides:
  - Account CRUD backend (create/update/delete)
  - Migration 012 (starting_balance columns)
  - Migration 013 (UNIQUE constraint)
  - Zod validation schemas for accounts
  - POST/PUT/DELETE /accounts routes
affects:
  - src/core/reference/use-cases.ts
  - src/interface-adapters/api/reference.ts
  - src/infrastructure/db/schema.sql
  - index.ts
tech-stack:
  added: []
  patterns:
    - "COALESCE(${param ?? null}, column) for partial update"
    - "SELECT-before-DELETE for account delete guard"
    - "z.iso.date() for Zod 4 ISO date validation"
key-files:
  created:
    - src/infrastructure/db/migrations/012_add_accounts_crud_fields.sql
    - src/infrastructure/db/migrations/013_add_accounts_unique_name.sql
    - src/application/schemas/accounts.ts
  modified:
    - src/core/reference/use-cases.ts
    - src/interface-adapters/api/reference.ts
    - index.ts
    - src/infrastructure/db/schema.sql
decisions: []
metrics:
  duration: 7m
  completed_date: "2026-06-10"
---

# Phase 11 Plan 01: Backend Account CRUD + Migrations

**Backend implementation of account CRUD:** DB migrations for starting balance columns and unique name constraint, Zod validation schemas, use-cases (create, update, delete), and API routes (POST/PUT/DELETE) with delete transaction guard. Provides the backend foundation for the frontend account management page.

## Tasks

| # | Name | Type | Status | Commit |
|---|------|------|--------|--------|
| 1 | Create migration 012 — add starting_balance + starting_balance_date | auto | done | [facc8e8](https://github.com/user/finance/commit/facc8e8) |
| 2 | Create migration 013 — add UNIQUE(user_id, name) | auto | done | [d2f9df5](https://github.com/user/finance/commit/d2f9df5) |
| 3 | Create Zod validation schemas for accounts | auto | done | [5172f90](https://github.com/user/finance/commit/5172f90) |
| 4 | Add account CRUD use-cases | auto | done | [eebcd07](https://github.com/user/finance/commit/eebcd07) |
| 5 | Add account CRUD routes + register in index.ts | auto | done | [2daec46](https://github.com/user/finance/commit/2daec46) |
| 6 | Update schema.sql to reflect post-migration state | auto | done | [fafc071](https://github.com/user/finance/commit/fafc071) |

**Planned:** 6 | **Completed:** 6 | **Blocked:** 0

## What Was Built

### Migration 012: `starting_balance` + `starting_balance_date` columns
- Adds `starting_balance NUMERIC(19,4) NOT NULL DEFAULT 0` with `IF NOT EXISTS` guard
- Adds `starting_balance_date DATE` (nullable, no default)
- Both columns use `IF NOT EXISTS` for idempotent up migration
- Down migration drops both columns with `IF EXISTS`
- Reversible: up adds, down removes

### Migration 013: `UNIQUE(user_id, name)` constraint
- Adds constraint `uq_accounts_user_id_name` using idempotent `DO $$` block with `pg_constraint` check (migration 009 pattern)
- Prevents duplicate account names per user
- Down drops constraint with `IF EXISTS`

### Zod Validation Schemas (`src/application/schemas/accounts.ts`)
- `CreateAccountSchema`: name (1-100 chars), type (business/personal), currency (default PLN), starting_balance (coerce number, min 0, default 0), starting_balance_date (ISO date nullable, Zod 4 `z.iso.date()`)
- `UpdateAccountSchema`: name, starting_balance, starting_balance_date all optional for partial updates
- `CreateAccountParams` and `UpdateAccountParams` TypeScript types inferred

### Account CRUD Use-cases (`src/core/reference/use-cases.ts`)
- `createAccount(name, type, currency, starting_balance, starting_balance_date, userId)`: INSERT with all fields, returns created row
- `updateAccount(id, name, starting_balance, starting_balance_date, userId)`: UPDATE with COALESCE pattern for partial updates, ownership filter via `WHERE id AND user_id`
- `deleteAccount(id, userId)`: SELECT COUNT before DELETE — throws `Error('Cannot delete account with N transaction(s)')` if count > 0, otherwise deletes with `WHERE id AND user_id`
- Existing `listAccounts` and `listCategories` preserved unchanged

### API Routes (`src/interface-adapters/api/reference.ts`)
- `POST /accounts`: Zod validated with `CreateAccountSchema`, userId from session, returns 201 with account object
- `PUT /accounts/:id`: Zod validated partial update, returns 404 for non-existent accounts
- `DELETE /accounts/:id`: Transaction guard, returns 409 with message when transactions exist, 204 on success
- All routes use `requireAuth` middleware and follow standard response shape `{ data, error, meta }`
- `accountsRoutes` exported and registered at `/accounts` in `index.ts`

### Threat Model Compliance
| Threat | Disposition | Implementation |
|--------|-------------|----------------|
| T-11-01 (Spoofing) | Mitigated | userId extracted from `c.get('user').id` (session), never from request body |
| T-11-02 (Repudiation) | Mitigated | `SELECT COUNT(*)` before `DELETE` — count checked before any mutation |
| T-11-03 (Info Disclosure) | Mitigated | `WHERE id = ${id} AND user_id = ${userId}` in all mutations |
| T-11-04 (Tampering) | Mitigated | `UNIQUE(user_id, name)` constraint at DB level |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing] postgres.js `undefined` parameter handling**
- **Found during:** Task 4 (use-cases)
- **Issue:** TypeScript strict typing in postgres.js does not accept `string | undefined` in template literal parameters (`TS2769: No overload matches this call`)
- **Fix:** Converted `undefined` values to `null` using `?? null` before passing to SQL tagged templates (e.g., `${starting_balance_date ?? null}`). Applied to both `createAccount` (starting_balance_date) and `updateAccount` (name, starting_balance, starting_balance_date).
- **Files modified:** `src/core/reference/use-cases.ts`
- **Commit:** [eebcd07](https://github.com/user/finance/commit/eebcd07)

### Adaptation for Zod 4
- Used `z.iso.date()` instead of `z.string().date()` (Zod 3 API) — Zod 4 uses `z.iso.date()` for ISO date string validation. This matches the existing pattern in `src/application/schemas/ledger.ts` and `src/application/schemas/import.ts`.

### Pre-existing Type Errors
- The plan verification included `npx tsc --noEmit passes`, but the project has 135+ pre-existing type errors (Hono Variables typing `TS18046: 'user' is of type 'unknown'`, Zod 4 `flatten()` API change, and others). These affect all route files (`assets.ts`, `ledger.ts`, `insights.ts`, etc.) and are not caused by this plan's changes.

## Key Decisions

- **Zod 4 date validation**: Used `z.iso.date()` consistent with existing schemas, not the Zod 3 `z.string().date()` mentioned in the plan.
- **DELETE returns 204**: Per plan spec, returns HTTP 204 with no body (not 200 with JSON body like the assets pattern).
- **COALESCE for partial updates**: Used in `updateAccount` to allow partial updates without requiring all fields. `?? null` ensures postgres.js type compatibility.
- **Delete guard**: Application-level `SELECT COUNT(*)` before DELETE. Follows the plan's threat model (T-11-02).

## Verification

- [x] Migration 012 created with correct naming convention — adds starting_balance + starting_balance_date with up/down reversibility
- [x] Migration 013 created with idempotent `DO $$` guard — adds UNIQUE(user_id, name) constraint
- [x] Zod schemas created: CreateAccountSchema + UpdateAccountSchema with validation rules
- [x] CRUD use-cases added: createAccount, updateAccount (COALESCE), deleteAccount (transaction guard)
- [x] CRUD routes added: POST (201), PUT (404/200), DELETE (409/204)
- [x] accountsRoutes registered in index.ts at `/accounts`
- [x] schema.sql updated with new columns and constraint
- [x] All existing functions preserved (listAccounts, listCategories)
- [ ] `npx tsc --noEmit passes` — blocked by 135+ pre-existing type errors in the codebase (unrelated to this plan)

## Self-Check

Verification commands:

```
✓ [ -f "src/infrastructure/db/migrations/012_add_accounts_crud_fields.sql" ]
✓ [ -f "src/infrastructure/db/migrations/013_add_accounts_unique_name.sql" ]
✓ [ -f "src/application/schemas/accounts.ts" ]
✓ git log --oneline | grep -q "facc8e8"
✓ git log --oneline | grep -q "d2f9df5"
✓ git log --oneline | grep -q "5172f90"
✓ git log --oneline | grep -q "eebcd07"
✓ git log --oneline | grep -q "2daec46"
✓ git log --oneline | grep -q "fafc071"
```

## Self-Check: PASSED
