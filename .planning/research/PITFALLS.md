# Domain Pitfalls

**Domain:** Financial Planning Application
**Researched:** 2025-05-22

## Critical Pitfalls

### Pitfall 1: Floating Point Math for Money
**What goes wrong:** Using `double precision` or `float` in Postgres.
**Why it happens:** Developer convenience.
**Consequences:** Rounding errors (e.g., $0.10 + $0.20 = $0.300000004) that make the ledger impossible to balance over time.
**Prevention:** Use `NUMERIC(19, 4)` for all currency fields.

### Pitfall 2: Non-Atomic Transfers
**What goes wrong:** Subtracting money from one account and adding to another in separate DB calls.
**Consequences:** If the server crashes between calls, money "disappears" or "appears" out of nowhere.
**Prevention:** Use Postgres Transactions (`BEGIN; ... COMMIT;`) and the Double-Entry pattern (one transaction containing multiple postings).

### Pitfall 3: Timezone Confusion
**What goes wrong:** Using `TIMESTAMP` without timezone.
**Consequences:** Transactions appear on the wrong day during daylight savings shifts or for users in different zones, breaking monthly budget calculations.
**Prevention:** Use `TIMESTAMPTZ` for all temporal data.

## Moderate Pitfalls

### Pitfall 4: AI Hallucinations in Financial Advice
**What goes wrong:** Trusting an LLM to calculate interest rates or portfolio returns directly.
**Prevention:** Use AI for *categorization* and *narrative insights*, but use code (TypeScript/Mathjs) for *calculations*. Supply the AI with the calculated results to comment on.

### Pitfall 5: Local Postgres Backup Failure
**What goes wrong:** Assuming a local Postgres instance is "safe" without a backup strategy.
**Prevention:** Implement automated `pg_dump` jobs enqueued via PGMQ to a local or cloud storage.

## Minor Pitfalls

### Pitfall 6: Category Over-Complexity
**What goes wrong:** Giving users 100+ categories out of the box.
**Prevention:** Start with broad categories (Needs, Wants, Savings) and allow users to create sub-categories.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Core Ledger | Race conditions on balance check | Use `SERIALIZABLE` isolation level or `SELECT FOR UPDATE`. |
| PGMQ Workers | Job "Stuck" in progress | Set a reasonable `visibility_timeout` (e.g., 30s) so failed jobs reappear. |
| OpenRouter | High latency in UI | Use PGMQ for AI generation; notify user via Websocket/Polling when done. |

## Sources

- [Postgres Documentation - Numeric Types](https://www.postgresql.org/docs/current/datatype-numeric.html)
- [Beancount / Ledger-cli Best Practices](https://beancount.github.io/docs/the_double_entry_counting_method.html)
- [Hacker News - "How to store money in a database"](https://news.ycombinator.com/item?id=32549321)
