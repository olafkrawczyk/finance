# Phase 1 Validation Plan: Foundation (Core Ledger & DB)

## Overview
This document outlines the automated and manual verification strategy for Phase 1. The goal is to ensure the double-entry ledger is mathematically sound, immutable, and correctly integrated with the PGMQ system.

## Automated Testing Strategy

### Framework
- **Bun Test:** Using the built-in Bun runner for high performance and native TypeScript support.
- **Database:** A local Postgres instance (or Docker) will be used for integration tests.

### Test Map
| Requirement | Behavior | Test Type | Automated Command |
|-------------|----------|-----------|-------------------|
| REQ-1.1 | Double-Entry Zero-Sum | DB Integration | `bun test tests/ledger.test.ts` |
| REQ-1.2 | Immutable Ledger | DB Integration | `bun test tests/ledger.test.ts` |
| REQ-T1.3 | PGMQ Send/Read | Integration | `bun test tests/queue.test.ts` |
| REQ-T2.1 | Schema Validation | Unit Test | `bun test tests/schemas.test.ts` |

## Verification Gates

### Gate 1: Double-Entry Soundness
- **Criteria:** Transactions with entries that don't sum to zero must be rejected by the database.
- **Method:** `tests/ledger.test.ts` will attempt to insert unbalanced entries and assert that a Postgres exception is raised.

### Gate 2: Immutability
- **Criteria:** `UPDATE` and `DELETE` operations on `transactions` and `ledger_entries` must be blocked.
- **Method:** `tests/ledger.test.ts` will attempt to update/delete an existing entry and assert that a Postgres exception is raised.

### Gate 3: Walking Skeleton
- **Criteria:** The API is reachable and responds to health checks.
- **Method:** `curl http://localhost:3000/health` (verified in 01-01-PLAN.md).

## Manual Verification
- Reviewing the `schema.sql` to ensure `NUMERIC(19, 4)` is consistently applied.
- Verifying the `pgmq` extension is active: `SELECT * FROM pg_extension WHERE extname = 'pgmq';`.
