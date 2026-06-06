# Walking Skeleton: Financial Planning App

This document records the core architectural decisions and the "Walking Skeleton" state established in Phase 1. Subsequent phases build on this foundation.

## Architectural Stack

| Layer | Technology | Decision |
|-------|------------|----------|
| **Runtime** | Bun | High-performance JS/TS runtime with built-in test runner. |
| **Framework** | Hono | Lightweight, standard-compliant web framework. |
| **Language** | TypeScript | Strict typing for financial data integrity. |
| **Database** | Postgres | Relational store with PGMQ for background tasks. |
| **DB Driver** | `postgres.js` | Fast, template-string based Postgres client. |
| **Validation** | Zod | Schema-first validation for API and domain boundaries. |

## Core Data Patterns

### Ledger Integrity
- **Double-Entry:** Every transaction consists of balanced debit and credit entries.
- **Immutability:** Transactions are never updated or deleted. Corrections are made via new transactions.
- **Zero-Sum Constraint:** Enforced at the database level using a deferred trigger on `ledger_entries`.
- **Numeric Precision:** All currency amounts stored as `NUMERIC(19, 4)`.

### Background Processing
- **PGMQ:** Integrated directly into Postgres to ensure transactional consistency between the ledger and the message queue.

## Directory Structure (Standard)

```
src/
├── core/                 # Business logic & Domain entities
├── application/          # Application services & Zod schemas
├── infrastructure/       # External tools (DB, Queue, Repositories)
├── interface-adapters/   # API routes, Controllers, Middleware
└── index.ts              # Entry point
```

## Deployment & Environment
- **Local:** Bun + Local Postgres.
- **Environment Variables:**
  - `DB_URL`: Postgres connection string.
  - `PORT`: API port (default 3000).

## Status
- [ ] Phase 1 initialized.
- [ ] Ledger schema defined.
- [ ] Zero-sum trigger implemented.
- [ ] Basic Ledger API working.
