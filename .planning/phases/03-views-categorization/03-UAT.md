---
status: testing
phase: 03-views-categorization
source: [03-VERIFICATION.md]
started: 2026-06-06T14:30:00Z
updated: 2026-06-06T14:30:00Z
---

## Current Test

number: 1
name: Prediction line visual on ComboChart
expected: |
  ComboChart shows an amber dashed prediction line. Verify whether the line extends into future months (6-month projection) or overlays existing data. Confirm the visual is acceptable for the use case.
awaiting: user response

## Tests

### 1. Prediction line visual on ComboChart
expected: Amber dashed prediction line is visible and useful on the ComboChart, whether as a historical trend fit or forward projection
result: [pending]

### 2. Chart click drill-down
expected: Clicking a bar/line on BalanceChart or ComboChart navigates to /month/YYYY-MM correctly
result: [pending]

### 3. ZbiorczyPage row click
expected: Clicking a month row in ZbiorczyPage navigates to /month/YYYY-MM (MonthlyPage)
result: [pending]

### 4. CategorizePage bulk assign interaction
expected: Checkboxes select transactions, dropdown assigns category, confirmed transactions disappear from the list after save
result: [pending]

### 5. AddTransactionPage hidden account
expected: account_id is silently populated without user input; form submits a complete transaction
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
