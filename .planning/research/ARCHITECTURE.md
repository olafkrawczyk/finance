# Architecture Patterns

**Domain:** Financial Planning Application
**Researched:** 2025-05-22

## Recommended Architecture

A modular monolith approach using Hono for the API and Bun for background workers. Both share the same Postgres instance, leveraging PGMQ for communication.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Hono API** | Handles HTTP requests, OAuth flow, and CRUD operations. | Postgres, PGMQ (Producer), React Frontend |
| **PGMQ Worker** | Processes background jobs (file imports, AI analysis). | Postgres, OpenRouter API |
| **Postgres** | Source of truth. Stores Ledger, Sessions, and Queues. | Hono API, PGMQ Worker |
| **OpenRouter** | Provides LLM inference for financial insights. | PGMQ Worker |

### Data Flow

1. **User Uploads CSV**: Hono API receives file → Saves metadata → Enqueues `process_csv` job in PGMQ.
2. **Worker Processes Job**: Bun worker reads job from PGMQ → Parses CSV → Inserts `postings` into Ledger within a Postgres transaction → Archives job.
3. **AI Insight**: Hono API enqueues `generate_insights` → Worker gathers last 30 days of data → Sends to OpenRouter → Saves insight to DB.

## Patterns to Follow

### Pattern 1: Double-Entry Ledger
**What:** Every financial event is a `transaction` with at least two `postings` (debit/credit) that sum to zero.
**When:** All money movements.
**Example:**
```typescript
// Transaction: $50 Grocery Purchase
const transaction = {
  id: "uuid",
  date: "2025-05-22",
  description: "Whole Foods"
};

const postings = [
  { account: "Assets:Checking", amount: -50.00 }, // Credit Asset (Decrease)
  { account: "Expenses:Groceries", amount: 50.00 } // Debit Expense (Increase)
];
```

### Pattern 2: PGMQ Transactional Enqueue
**What:** Wrapping the database update and the job enqueue in the same Postgres transaction.
**Why:** Ensures that if the DB update fails, the background job is never triggered, maintaining consistency.

## Anti-Patterns to Avoid

### Anti-Pattern 1: The "Balance Column"
**What:** Storing a `current_balance` on the `accounts` table and updating it with every transaction.
**Why bad:** Prone to race conditions and drift.
**Instead:** Calculate balance on-the-fly via `SUM(amount)` from the postings ledger, or use a Materialized View.

### Anti-Pattern 2: LocalStorage Sessions
**What:** Storing sensitive auth tokens in browser `localStorage`.
**Why bad:** Vulnerable to XSS.
**Instead:** Use `HttpOnly` cookies via Hono middleware/Better Auth.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| DB Queries | Single Postgres instance | Add Indexes & Read Replicas | Sharding by `user_id` |
| Background Jobs | 1 Bun worker loop | Multiple PGMQ workers | Distributed workers |
| AI Costs | negligible | Caching frequent insights | Self-hosted LLM (Llama 3) |

## Sources

- [Postgres Money Types & Ledger Patterns](PITFALLS.md)
- [PGMQ Job Pattern](https://github.com/tembo-io/pgmq)
- [Martin Fowler - Accounting Patterns](https://martinfowler.com/eaaDev/AccountingPatterns.html)
