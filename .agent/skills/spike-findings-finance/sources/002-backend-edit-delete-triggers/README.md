---
spike: 002
name: backend-edit-delete-triggers
type: standard
validates: "Given the immutability trigger, when we want to edit/delete transactions, then we can safely modify or bypass the trigger without data corruption"
verdict: VALIDATED
related: [003]
tags: [backend, triggers, api]
---

# Spike 002: Backend Edit/Delete — Trigger Modification and API

## What This Validates

Transactions are currently protected by DB triggers that block UPDATE (except category_id null→non-null) and DELETE. This spike validates a safe approach to allow full edits and deletion.

## Research

Four approaches analyzed — see `approach.md` for full comparison.

**Chosen approach (C):** Modify the `block_immutable_change()` trigger to allow all updates, drop the `block_delete()` trigger, add an `updated_at` column, and enqueue re-analysis on edit via PGMQ.

## How to Run

Review the approach document:
```
cat .planning/spikes/002-backend-edit-delete-triggers/approach.md
```

## Investigation Trail

- The existing trigger function `block_immutable_change()` already has a carve-out for category_id assignment. Extending it to pass all updates is a one-line change (RETURN NEW).
- The `block_delete()` function needs to be dropped entirely.
- `updated_at` column needs adding to transactions table.
- Insights worker uses a 3-month window — editing a transaction will naturally be picked up on next re-analysis.
- Soft delete (approach B) adds significant query filtering complexity for a single-user app.

## Results

**Verdict: VALIDATED ✓**

The backend changes are straightforward and low-risk:
- 1 SQL migration file (add column, replace trigger, drop delete trigger)
- 3 new API endpoints (PUT, DELETE, GET single)
- 3 new use-case functions
- Re-enqueue to analysis_queue on edit
