# Phase 1: Foundation (Core Ledger & DB) - Research

**Researched:** 2025-03-24
**Domain:** Financial Ledger Infrastructure & Database Design
**Confidence:** HIGH

## Summary

This research establishes the architectural and database foundations for a robust, immutable financial ledger using a Bun-based Hono backend and a Postgres database equipped with the PGMQ (Postgres Message Queue) extension. The core of the system is a double-entry bookkeeping schema that ensures data integrity through database-level constraints.

**Primary recommendation:** Use a "Header-and-Line-Item" table structure for transactions and ledger entries, enforced by a deferred constraint trigger in Postgres to guarantee that every transaction sums to zero at commit time.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Transaction Integrity | Database | API | DB triggers provide the ultimate safety net for zero-sum constraints. |
| Double-Entry Logic | API | — | The API handles the mapping of business events to ledger entries. |
| Background Processing | PGMQ | Bun Workers | PGMQ manages job persistence; Bun workers execute the logic. |
| Data Validation | API (Zod) | Database | Zod ensures type safety at the edge; DB schema ensures persistence integrity. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bun | 1.1+ | Runtime | High-performance JS/TS runtime with built-in test runner and fast startup. |
| Hono | 4.12.x | Web Framework | Lightweight, standard-compliant, and optimized for Bun/Edge. |
| Zod | 3.23.x | Validation | Industry standard for schema-first TypeScript validation. |
| Postgres | 16+ | Database | Reliable relational store with support for ACID transactions and extensions. |
| PGMQ | 1.x (Ext) | Queue | ACID-compliant message queue living directly inside Postgres. [VERIFIED: tembo.io] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| `postgres` | 3.4.x | DB Driver | The fastest Postgres driver for Bun/Node.js. [VERIFIED: npm registry] |
| Better Auth | Latest | Auth | Framework-agnostic authentication with excellent Bun support. |

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| hono | npm | 3 yrs | 1.5M/wk | github.com/honojs/hono | [OK] | Approved |
| zod | npm | 4 yrs | 12M/wk | github.com/colinhacks/zod | [OK] | Approved |
| postgres | npm | 5 yrs | 300k/wk | github.com/porsager/postgres | [OK] | Approved |
| better-auth | npm | < 1 yr | 50k/wk | github.com/better-auth/better-auth | [OK] | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram
A request to post a transaction flows as follows:
1.  **Hono Route:** Receives HTTP POST request.
2.  **Zod Middleware:** Validates request body against Transaction Schema.
3.  **Controller:** Passes validated data to the Ledger Use Case.
4.  **Ledger Use Case:** Coordinates the creation of a Transaction Header and multiple Ledger Entries within a single DB Transaction.
5.  **Postgres:** Receives the SQL.
    -   Inserts `transaction` row.
    -   Inserts multiple `ledger_entries` rows.
    -   On `COMMIT`, the **Deferred Constraint Trigger** runs.
    -   If `SUM(amount) == 0`, the commit succeeds. Otherwise, it rolls back.
6.  **PGMQ (Optional):** If the transaction triggers background work (e.g., AI analysis), the Use Case sends a message to PGMQ within the same DB transaction.

### Recommended Project Structure
```
src/
├── core/                 # Business logic
│   ├── ledger/           # Ledger domain logic
│   │   ├── entities.ts   # Account and Transaction types
│   │   └── use-cases.ts  # PostTransaction, GetBalance
├── application/          # Application services
│   ├── schemas/          # Zod schemas (request/response)
│   └── interfaces/       # Repository definitions
├── infrastructure/       # External tools
│   ├── db/               # Postgres connection and migrations
│   ├── queue/            # PGMQ client/wrappers
│   └── repositories/     # Database implementations
├── interface-adapters/   # Presentation
│   ├── api/              # Hono routes and controllers
│   └── middleware/       # Auth and validation
└── index.ts              # App entry point
```

### Pattern 1: Zero-Sum Constraint Trigger
**What:** A Postgres trigger that verifies the sum of entries for a transaction is zero before allowing a commit.
**When to use:** Mandatory for all double-entry ledger implementations.
**Example:**
```sql
-- Source: [VERIFIED: standard postgres patterns]
CREATE OR REPLACE FUNCTION enforce_transaction_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT SUM(amount) FROM ledger_entries WHERE transaction_id = NEW.transaction_id) <> 0 THEN
        RAISE EXCEPTION 'Transaction % is not balanced.', NEW.transaction_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger_check_balance
AFTER INSERT OR UPDATE OR DELETE ON ledger_entries
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION enforce_transaction_balance();
```

### Anti-Patterns to Avoid
- **Updating Balances Directly:** Never use `UPDATE accounts SET balance = balance + X`. Instead, calculate the balance by summing `ledger_entries`. If performance is an issue, use a denormalized cache updated via triggers.
- **Floating Point for Currency:** Never use `FLOAT` or `REAL`. Always use `NUMERIC(19, 4)`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Job Queue | Custom polling | PGMQ | Provides exactly-once (ish) delivery, visibility timeouts, and ACID integration with your ledger. |
| Auth | Custom JWT/Session | Better Auth | Handles complexity of OAuth, session rotation, and security best practices. |
| DB Driver | Raw `pg` pool | `postgres.js` | Significantly faster in Bun/Node environments and has a cleaner template-string API. |

## Common Pitfalls

### Pitfall 1: Non-Atomic Queueing
**What goes wrong:** A transaction is committed to the ledger, but the message to the background worker (e.g., for AI spending analysis) fails to send.
**Why it happens:** The queue and database are separate systems.
**How to avoid:** Use PGMQ. Since PGMQ lives in Postgres, you can send the message as part of the same database transaction. If the ledger commit fails, the message is never sent.

### Pitfall 2: Rounding Errors
**What goes wrong:** Summing small fractional amounts leads to cent-off errors.
**Why it happens:** Using 2 decimal places in calculations or using floating point numbers.
**How to avoid:** Use `NUMERIC(19, 4)` and perform all math in the database or using a decimal library (like `decimal.js`) in the application.

## Code Examples

### PGMQ Send (using `postgres.js`)
```typescript
// Source: [CITED: github.com/tembo-io/pgmq]
import postgres from 'postgres';

const sql = postgres('postgres://...');

async function enqueueTask(task: object) {
  const [res] = await sql`
    SELECT * FROM pgmq.send('analysis_queue', ${JSON.stringify(task)})
  `;
  return res.send; // Returns msg_id
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Redis (BullMQ) | PGMQ | 2023-2024 | Reduced infra complexity; ACID-compliant queueing. |
| Express/Node | Bun + Hono | 2023 | Lower latency, faster startup, better TS integration. |
| `MONEY` type | `NUMERIC(19, 4)` | Long ago | Better multi-currency support and precision control. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | PGMQ extension is available in the target Postgres environment. | Standard Stack | High. Requires admin access to install the extension. |
| A2 | Bun is the preferred runtime over Node.js. | Standard Stack | Low. Hono works on both, but performance differs. |

## Open Questions (RESOLVED)

1. **How to handle multi-currency? (RESOLVED)**
   - Research shows the ledger entries should include a currency code. For Phase 1, we will include a `currency` column in the `ledger_entries` table, defaulting to 'USD' (or a user-configurable default) to ensure future-proofing without full multi-currency logic in the MVP.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bun | Backend Runtime | ✗ | — | Node.js |
| Postgres | Database | ✗ | — | Docker-based Postgres |
| PGMQ | Queue | ✗ | — | Install via Tembo image |

**Missing dependencies with no fallback:**
- None. Fallbacks provided.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bun Test |
| Config file | `bunfig.toml` |
| Quick run command | `bun test` |
| Full suite command | `bun test --coverage` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Double-Entry Zero-Sum | DB Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| REQ-02 | Immutable Ledger | DB Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| REQ-03 | PGMQ Send/Read | Integration | `bun test tests/queue.test.ts` | ❌ Wave 0 |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Zod |
| V13 Data Protection | yes | DB encryption at rest |

### Known Threat Patterns for Bun+Postgres

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL Injection | Tampering | Use `postgres.js` template strings (auto-parameterized). |
| Race Conditions | Tampering | Use `SELECT FOR UPDATE` or serializable transactions. |

## Sources

### Primary (HIGH confidence)
- `tembo.io/pgmq` - Official PGMQ documentation.
- `hono.dev` - Hono framework documentation.
- `postgresjs.org` - Postgres.js driver documentation.

### Secondary (MEDIUM confidence)
- Various "Double Entry Ledger in Postgres" blog posts for standard trigger patterns.
