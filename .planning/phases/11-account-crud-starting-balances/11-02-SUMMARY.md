---
phase: 11-account-crud-starting-balances
plan: 02
type: execute
subsystem: frontend
tags:
  - account-crud
  - ui
  - react
  - typescript
  - tanstack-query
requires:
  - 11-01 (backend account CRUD API)
affects:
  - frontend/src/api.ts
  - frontend/src/lib/query/queryKeys.ts
  - frontend/src/lib/query/hooks.ts
  - frontend/src/App.tsx
  - frontend/src/pages/AccountPage.tsx (new)
  - frontend/src/components/TypedDeleteConfirmModal.tsx (new)
tech-stack:
  added: []
  patterns:
    - Direct useMutation for CRUD (AssetsPage pattern)
    - D-15 broad invalidation on ['user', userId] after mutations
    - Typed delete confirmation with dynamic challenge phrase
    - Inline edit with per-row editing state
    - 2-column layout: table (2/3) + form (1/3)
key-files:
  created:
    - frontend/src/pages/AccountPage.tsx
    - frontend/src/components/TypedDeleteConfirmModal.tsx
  modified:
    - frontend/src/api.ts
    - frontend/src/lib/query/queryKeys.ts
    - frontend/src/lib/query/hooks.ts
    - frontend/src/App.tsx
decisions:
  - Hook wrappers (useCreateAccount, etc.) added to hooks.ts for consistency, but AccountPage uses direct useMutation per AssetsPage pattern
  - getAccount API function added as Rule 2 pre-req for useAccountDetail hook (missing from plan)
metrics:
  duration: ~8 min
  completed: "2026-06-10"
---

# Phase 11 Plan 02: Frontend Account Management UI Summary

Built full Account CRUD frontend: API functions, query keys + hooks, AccountPage (list/create/inline-edit/delete), TypedDeleteConfirmModal, and route/nav registration.

## Tasks Execution

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add account CRUD API functions to api.ts | `80360dc` | frontend/src/api.ts |
| 2 | Add account query keys and hooks | `ec28704` | frontend/src/api.ts, frontend/src/lib/query/queryKeys.ts, frontend/src/lib/query/hooks.ts |
| 3 | Create AccountPage.tsx | `1d70c24` | frontend/src/pages/AccountPage.tsx |
| 4 | Create TypedDeleteConfirmModal component | `996aa1d` | frontend/src/components/TypedDeleteConfirmModal.tsx |
| 5 | Add route and nav button in App.tsx | `6775622` | frontend/src/App.tsx |

## What Was Built

### API Functions (`api.ts`)
- `getAccount(id)` — GET /accounts/{id}
- `createAccount(data)` — POST /accounts with name, type, currency, starting_balance, starting_balance_date
- `updateAccount(id, data)` — PUT /accounts/{id} with name, starting_balance, starting_balance_date
- `deleteAccount(id)` — DELETE /accounts/{id}
- All use `apiFetch()` wrapper with 401 redirect, JSON error parsing

### Query Infrastructure
- `queryKeys.accounts.detail(userId, id)` — `['user', userId, 'accounts', id]`
- `useAccountDetail(id)` — query hook with enabled guard
- `useCreateAccount()` — mutation hook, invalidates `['user', userId]`
- `useUpdateAccount()` — mutation hook, invalidates `['user', userId]`
- `useDeleteAccount()` — mutation hook, invalidates `['user', userId]`

### AccountPage (`AccountPage.tsx` — 536 lines)
- **2-column layout**: Account list table (2/3 width) + create form (1/3 width, sticky)
- **Table columns**: Nazwa, Typ (badges), Waluta, Saldo początkowe, Data salda, Akcje
- **Type badges**: "Firmowe" (blue), "Osobiste" (green) — per UI-SPEC.md
- **Inline edit**: Click "Edytuj" → editable inputs for name, balance, date → "Zapisz" / "Anuluj"
- **Create form**: Nazwa konta, Typ konta (select), Waluta (read-only PLN), Saldo początkowe, Data salda początkowego
- **Delete**: Uses TypedDeleteConfirmModal with dynamic challenge phrase
- **Notifications**: Error (red) / success (emerald) banners with 4s auto-clear
- **Empty state**: "Brak zapisanych kont" with subtitle
- **Total balance**: "Całkowite saldo początkowe" summary row
- **Skeleton**: 2-column skeleton loading on `isPending`

### TypedDeleteConfirmModal (`TypedDeleteConfirmModal.tsx`)
- Dynamic challenge phrase: `DELETE {accountName}` (case-sensitive)
- Delete button disabled until input matches exactly
- Escape key closes, overlay click closes, Enter triggers confirm
- Auto-focus input on open, reset state on close
- Warning box with account name label

### Route & Nav (`App.tsx`)
- Import `AccountPage` and route `/accounts` renders it (between `/assets` and `/summary`)
- "Konta" nav button between "Aktywa" and "Zbiorczy" with active state styling

## Polish Copy Compliance

All UI copy matches UI-SPEC.md Copywriting Contract:
- Page: "Zarządzanie kontami" / "Zarządzaj swoimi kontami bankowymi i saldami początkowymi"
- Form: "Dodaj nowe konto" / "Dodaj konto" / "Dodawanie..."
- Table headers: "Nazwa", "Typ", "Waluta", "Saldo początkowe", "Data salda", "Akcje"
- Actions: "Edytuj", "Zapisz" / "Zapisywanie...", "Anuluj", "Usuń"
- Empty: "Brak zapisanych kont" / "Dodaj pierwsze konto..."
- Total: "Całkowite saldo początkowe"
- Badges: "Firmowe", "Osobiste"
- Success: "Pomyślnie dodano nowe konto" / "zaktualizowano" / "usunięto"
- Error: "Nie można usunąć konta, ponieważ ma {X} transakcji"
- Validation: "Nazwa konta nie może być pusta" / "Saldo początkowe musi być liczbą"
- Modal: "Usunięcie konta" / warning text / "Usuń konto"

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added `getAccount` API function**
- **Found during:** Task 2
- **Issue:** The plan specified a `useAccountDetail(id)` query hook in hooks.ts, but there was no `getAccount` API function in api.ts for the hook to call
- **Fix:** Added `export async function getAccount(id: string)` — GET /accounts/{id} with error handling, following same pattern as existing API functions
- **Files modified:** frontend/src/api.ts
- **Commit:** `ec28704`

## Must-Haves Verification

| Must-Have | Status |
|-----------|--------|
| AccountPage.tsx follows AssetsPage.tsx CRUD pattern | ✅ |
| TypedDeleteConfirmModal uses dynamic "DELETE {account_name}" | ✅ |
| API functions follow existing api.ts CRUD pattern | ✅ |
| Query hooks use broad ['user', userId] invalidation (D-15) | ✅ |
| Account key factory follows queryKeys pattern with per-user prefix | ✅ |
| Route /accounts renders AccountPage; nav "Konta" between Aktywa and Zbiorczy | ✅ |
| Delete with 0 transactions: green banner "Pomyślnie usunięto konto" | ✅ |
| Delete with transactions: error toast with count | ✅ |
| Duplicate account name: error banner | ✅ |
| All UI copy in Polish per UI-SPEC.md | ✅ |

## Threat Surface Scan

No new threat surface introduced — all new API functions use existing `apiFetch()` wrapper (401 redirect preserved), and the typed delete confirmation prevents accidental deletion (T-11-06 mitigated).

## Known Stubs

None identified.

## Self-Check: PASSED

- ✅ frontend/src/pages/AccountPage.tsx exists (536 lines, min 300)
- ✅ frontend/src/components/TypedDeleteConfirmModal.tsx exists
- ✅ frontend/src/App.tsx has AccountPage import and /accounts route
- ✅ frontend/src/App.tsx has "Konta" nav button
- ✅ 5 commits for 5 tasks
- ✅ No accidental deletions
