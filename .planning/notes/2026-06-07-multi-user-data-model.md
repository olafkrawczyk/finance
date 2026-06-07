---
title: Multi-User Data Model Decisions
date: 2026-06-07
context: Exploration of multi-tenant readiness for finance app
---

## Data Isolation Model

- Single PostgreSQL instance, single database
- Every domain table gets a `user_id` column (FK to `"user"`):
  - `categories`, `accounts`, `transactions`, `monthly_opening_balances`, `import_jobs`, `assets`
- `insights` already has `user_id`
- Auth tables (`"user"`, `"session"`, `"account"`, `"verification"`) already from Better Auth

## Category Design

- **No shared/system categories** — all categories are user-scoped
- On signup, the user's default 25 categories are seeded via a Better Auth hook
- **Soft delete** via `deleted_at` column — historical transactions remain linked
- **Name uniqueness**: `UNIQUE(user_id, name)` covers both active and soft-deleted rows. If a user tries to re-create a deleted category name, they must revive the old one or choose a different name
- **Revive flow**: app shows "You had a category 'auto' that was deleted. Revive it?" instead of silently creating a duplicate

## LLM Description Column

- New column `llm_description TEXT` on categories
- Existing prompt descriptions (lines 103-128 of import-worker.ts) become seed values
- Users can edit descriptions when creating/editing categories
- LLM prompt for CSV import dynamically fetches only the user's active categories

## Shared vs User-Owned

- **Shared (global):** CSV format parsers/detection (ING vs IPKO logic), bank formatters, LLM configuration
- **Per-user:** accounts, categories, transactions, opening balances, import jobs, assets
