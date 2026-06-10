---
status: complete
phase: 11-account-crud-starting-balances
source:
  - 11-01-SUMMARY.md
  - 11-02-SUMMARY.md
  - 11-03-SUMMARY.md
  - 11-04-SUMMARY.md
started: "2026-06-10T21:30:00Z"
updated: "2026-06-10T22:15:00Z"
---

## Current Test

[testing complete]

## Tests

### 1. Account page renders with correct layout
expected: Navigate to /accounts. Page shows 2-column layout: account list table (left, 2/3) with columns Nazwa, Typ, Waluta, Saldo początkowe, Data salda, Akcje and create form (right, 1/3) with "Dodaj nowe konto" heading. Empty state shows "Brak zapisanych kont".
result: pass

### 2. Create account with valid data
expected: Fill in "Nazwa konta", select type, set balance, pick date. Click "Dodaj konto". Green banner: "Pomyślnie dodano nowe konto". Account appears in table.
result: pass

### 3. Duplicate account name shows error
expected: Creating duplicate name shows error banner "Konto o tej nazwie już istnieje". Account NOT added.
result: pass

### 4. Edit account inline
expected: Click "Edytuj" — inputs become editable. Change name, click "Zapisz". Green banner: "Pomyślnie zaktualizowano konto". Table updates.
result: pass

### 5. Delete account with 0 transactions succeeds
expected: Click "Usuń". TypedDeleteConfirmModal opens. Type "DELETE {name}", confirm. Green banner: "Pomyślnie usunięto konto". Account removed.
result: pass

### 6. Delete account with transactions blocked
expected: Click "Usuń" on account with transactions. Confirm delete. Red error toast: "Nie można usunąć konta, ponieważ ma {X} transakcji". Account remains.
result: pass

### 7. Dashboard shows bank balance and net worth lines
expected: BalanceChart shows blue line for "Stan konta" and purple line for "Wartość netto". Legend shows both names with colored dots.
result: pass

### 8. Net worth toggle hides/shows purple line
expected: Toggle checkbox hides/shows purple net worth line. Label changes between "Ukryj wartość netto" / "Pokaż wartość netto".
result: pass

### 9. "Konta" nav button between "Aktywa" and "Zbiorczy"
expected: Nav button "Konta" appears between "Aktywa" and "Zbiorczy". Clicking navigates to /accounts.
result: pass

## Summary

total: 9
passed: 9
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
