# Spike Manifest

## Idea
CRUD operations on financial transactions — edit all fields on existing transactions and remove transactions entirely. Also verify the import deduplication mechanism works correctly.

## Requirements

- Must not corrupt the audit trail (analysis_queue, monthly calculations)
- Import dedup hash should include account_id to prevent cross-account collisions

## Spikes

| # | Name | Type | Validates | Verdict | Tags |
|---|------|------|-----------|---------|------|
| 001 | import-dedup-analysis | standard | Given duplicate CSV rows, when imported, then only one transaction is created per unique date+amount+description hash | PARTIAL ⚠ | import, dedup, hash |
| 002 | backend-edit-delete-triggers | standard | Given the immutability trigger, when we want to edit/delete transactions, then we can safely modify or bypass the trigger without data corruption | PENDING | backend, triggers, api |
| 003 | frontend-edit-delete-ui | standard | Given a transaction in the monthly view, when user clicks edit/delete, then the UI allows inline editing of all fields or removal | PENDING | frontend, ui, edit, delete |
