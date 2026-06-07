# Spike Manifest

## Idea
CRUD operations on financial transactions — edit all fields on existing transactions and remove transactions entirely. Also verify the import deduplication mechanism works correctly.

## Requirements

- Must not corrupt the audit trail (analysis_queue, monthly calculations)
- Import dedup hash should include account_id to prevent cross-account collisions
- Use Approach C for edit/delete: modify triggers to allow updates, drop delete trigger, add updated_at column
- Edit/delete should trigger re-analysis via PGMQ analysis_queue

## Spikes

| # | Name | Type | Validates | Verdict | Tags |
|---|------|------|-----------|---------|------|
| 001 | import-dedup-analysis | standard | Given duplicate CSV rows, when imported, then only one transaction is created per unique date+amount+description hash | PARTIAL ⚠ | import, dedup, hash |
| 002 | backend-edit-delete-triggers | standard | Given the immutability trigger, when we want to edit/delete transactions, then we can safely modify or bypass the trigger without data corruption | VALIDATED ✓ | backend, triggers, api |
| 003 | frontend-edit-delete-ui | standard | Given a transaction in the monthly view, when user clicks edit/delete, then the UI allows inline editing of all fields or removal | VALIDATED ✓ | frontend, ui, edit, delete |
| 004 | transaction-filters | standard | Given a list of transactions, when we filter by text search, category, type, and sort by date or amount, then the table updates dynamically and correctly | VALIDATED ✓ | frontend, filter, search, sort |
| 005 | reverse-zbiorczy-order | standard | Given monthly summaries, when fetched/displayed on the Zbiorczo view, then they are ordered with the newest month first (descending) | PENDING | frontend, summary, order |
