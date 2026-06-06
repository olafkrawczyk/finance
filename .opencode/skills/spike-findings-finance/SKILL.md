---
name: spike-findings-finance
description: Implementation blueprint from spike experiments. Requirements, proven patterns, and verified knowledge for building finance. Auto-loaded during implementation work.
---

<context>
## Project: finance

CRUD operations on financial transactions — edit all fields on existing transactions and remove transactions entirely. Also verify the import deduplication mechanism works correctly.

Spike sessions wrapped: 2026-06-06
</context>

<requirements>
## Requirements

- Must not corrupt the audit trail (analysis_queue, monthly calculations)
- Import dedup hash should include account_id to prevent cross-account collisions
- Use Approach C for edit/delete: modify triggers to allow updates, drop delete trigger, add updated_at column
- Edit/delete should trigger re-analysis via PGMQ analysis_queue
</requirements>

<findings_index>
## Feature Areas

| Area | Reference | Key Finding |
|------|-----------|-------------|
| Import & Dedup | references/import-dedup.md | SHA-256 of `date|amount|description` works but missing `account_id` — cross-account collision risk |
| Transaction CRUD | references/transaction-crud.md | Approach C: modify immutability triggers, add `updated_at`, wire PATCH→PUT and add DELETE endpoints |

## Source Files

Original spike source files are preserved in `sources/` for complete reference.
</findings_index>

<metadata>
## Processed Spikes

- 001-import-dedup-analysis
- 002-backend-edit-delete-triggers
- 003-frontend-edit-delete-ui
</metadata>
