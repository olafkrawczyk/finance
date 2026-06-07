# Phase 8: Worker Isolation — Research

**Researched:** 2026-06-07
**Domain:** Background worker data isolation (PGMQ import/insights workers)
**Confidence:** HIGH

## Summary

Phase 8 enforces per-user data isolation in the two background workers (`import-worker.ts`, `insights-worker.ts`). The enqueue side was already scoped in Phase 7 — both `enqueueImportJob` and the Excel migration enqueue (`migration.ts`) already include `user_id` in PGMQ payloads. The insights worker's manual analysis path (`enqueueAnalysisJob`) already includes `user_id`. Phase 8 makes the **consumer side** enforce isolation: extract `user_id` from payload, tag all inserted data, validate ownership, and fix the insights worker's SQL queries that accepted a `userId` parameter but never used it in WHERE clauses.

**Primary recommendation:** Add `userId` parameter to `insertBatch()`, extract `user_id` from PGMQ payloads in both workers, fix `ON CONFLICT` clauses to match the per-user composite constraints from migration 009, and fix `getInsightDataWindow` / `getLatestTransactionDate` to actually filter by `user_id`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Account Ownership Validation
- **D-01:** When `account_id` doesn't belong to the user processing the import, **skip and continue** — log an error, skip the batch, keep processing. Don't fail the entire job for one invalid account.
- **D-02:** Ownership check is implicit via SQL filter (`SELECT id FROM accounts WHERE id = ${accountId} AND user_id = ${userId}`), consistent with Phase 7 D-02. No explicit helper function.
- **D-03:** Excel migration account lookups (by PKO_PERSONAL_ACCOUNT_NAME / ING_BUSINESS_ACCOUNT_NAME) are scoped by `user_id` too — `AND user_id = ${userId}` added to queries.

#### user_id Flow Through Import Pipeline
- **D-04:** `insertBatch` gets an explicit `userId` parameter added (not a context object or trigger). Consistent with existing patterns.
- **D-05:** `ON CONFLICT (import_hash)` updated to `ON CONFLICT (user_id, import_hash)` — Phase 6 D-06 applied. Requires migration to add composite `UNIQUE(user_id, import_hash)` constraint.
- **D-06:** `processCsvImportJob` extracts `user_id` from PGMQ payload via explicit destructuring alongside `account_id`, `csv_content`, `bank_format`.
- **D-07:** All `import_jobs` status UPDATE statements filter by `user_id` in WHERE clause (`WHERE id = ${jobId} AND user_id = ${userId}`).

#### Excel Migration Scoping
- **D-08:** `processExcelMigrationJob` extracts `user_id` from PGMQ payload and scopes all queries the same way as CSV import path. The enqueue side (`migration.ts`) already includes `user_id: user.id` in the payload — worker just needs to consume it.

#### Insights Worker Regression Fix
- **D-09:** `getInsightDataWindow` SQL WHERE clause gets `AND t.user_id = ${userId}` — the `userId` parameter already exists but was never applied in the query.
- **D-10:** `getLatestTransactionDate` is scoped per-user — `SELECT MAX(date)::text AS latest FROM transactions WHERE user_id = ${userId}`. Prevents cross-user date window skew.

#### Folded Todos
- **extract-llm-descriptions** — Already completed in Phase 7. No additional work needed in Phase 8.

### the agent's Discretion

*None — all decisions were locked during discussion.*

### Deferred Ideas (OUT OF SCOPE)

*None — discussion stayed within phase scope.*

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WORKER-01 | PGMQ message payloads for import jobs carry `user_id` — the enqueuing user's identity propagates through the queue | **Already done by Phase 7.** `enqueueImportJob` in `src/core/import/use-cases.ts:36-42` and `migration.ts:62-67` both include `user_id` in PGMQ payloads. No changes needed for WORKER-01. |
| WORKER-02 | Import worker extracts `user_id` from PGMQ payload and tags all inserted transactions with the queuing user's ID | **Needs code changes.** `processCsvImportJob` and `insertBatch` don't extract/use `user_id`. `processExcelMigrationJob` doesn't extract `user_id` from payload. |
| WORKER-03 | Import worker validates that `account_id` belongs to `user_id` before processing records | **Needs ownership validation** via SQL filter (`SELECT id FROM accounts WHERE id = ${accountId} AND user_id = ${userId}`). Per D-01, skip batch on mismatch. |
| WORKER-04 | Insights worker explicitly scopes all queries by `user_id` — confirmed no regression from existing behavior | **Needs two SQL fixes:** `getInsightDataWindow` accepts `userId` param but doesn't use it in WHERE. `getLatestTransactionDate` has no user filter at all. |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PGMQ `user_id` payload extraction | Worker | — | Workers consume messages; the enqueue side already includes `user_id` |
| Transaction INSERT tagging by user | Worker / Data Layer | — | `insertBatch` is the sole insert path for imported transactions — add `userId` param, tag every row |
| Account ownership validation | Worker | Data Layer (implicit SQL) | D-02 establishes implicit SQL WHERE pattern — no helper function |
| Import job status UPDATE scoping | Worker | — | All UPDATEs on `import_jobs` must filter by `user_id` to prevent cross-user modification |
| Excel migration account/category queries | Worker | — | Account lookups by name + category listing must be scoped per-user |
| Insights data window scoping | Data Layer | — | `getInsightDataWindow` / `getLatestTransactionDate` are use-case functions — fix WHERE clauses |
| Excel opening balance INSERT scoping | Worker | Data Layer | `ON CONFLICT (year, month)` must become `ON CONFLICT (user_id, year, month)` |

## Standard Stack

The stack is entirely established from prior phases — no new packages needed for Phase 8.

### Existing Stack (no changes)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bun | 1.3.14 | Runtime | Project runtime, already deployed |
| Hono | — | Web framework | Route handlers already in place |
| postgres.js | — | SQL client | Template-tagged SQL, already used everywhere |
| pgmq | PG extension | Message queue | Import + analysis queues already deployed |
| OpenRouter | — | LLM API | Transaction parsing + insights generation |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `userId` parameter | Context object / AsyncLocalStorage | D-04 locked explicit parameter — consistent with existing `insertBatch(accountId, ...)` pattern |
| Explicit SQL ownership check | Validation helper function | D-02 locked implicit SQL WHERE — consistent with Phase 7 pattern, no helper needed |

## Package Legitimacy Audit

> No external packages to install for Phase 8. Changes are entirely code edits to existing workers and use-case functions. No npm/PyPI/cargo dependencies required.

## Architecture Patterns

### System Architecture Diagram

```
┌──────────────┐     PGMQ payload:        ┌───────────────────┐
│  API Layer   │     { job_id,             │  import-worker.ts │
│ (Phase 7)    │       account_id,         │                   │
│              │       csv_content,        │  D-06: Extract    │
│ enqueueImport │       bank_format,        │  user_id from     │
│ Job          │       user_id     }──────▶│  payload          │
│              │                           │                   │
│ migration.ts │     { job_id,             │  D-08: Scope      │
│ (enqueue)    │       type: 'excel_        │  account/category │
│              │        migration',         │  queries by user  │
│              │       file_path,           │                   │
│              │       user_id     }──────▶│  D-04: insertBatch │
└──────────────┘                           │  gets userId param│
                                           │                   │
┌──────────────┐     PGMQ payload:        │  D-05: ON CONFLICT │
│  createTrans │     { transaction_id      │  (user_id,import_ │
│  action()    │       /* MISSING user_id  │  hash)            │
│  (ledger/    │        — open ??? */      │                   │
│   use-cases) │                           │  D-07: import_    │
│              │     { user_id,            │  jobs UPDATEs     │
│  enqueueAn-  │       triggered_by:       │  filter by user   │
│  alysisJob   │       'manual'   }──────▶│                   │
│  (insights/  │                           └───────────────────┘
│   use-cases) │                                    │
└──────────────┘                           ┌───────────────────┐
                                           │  insights-worker  │
                                           │                   │
                                           │  D-09: getInsight │
                                           │  DataWindow WHERE │
                                           │  t.user_id = $uid │
                                           │                   │
                                           │  D-10: getLatest  │
                                           │  TransactionDate  │
                                           │  WHERE user_id    │
                                           └───────────────────┘
```

### Data Flow Trace (Primary Use Case)

```
1. User uploads CSV → API route → enqueueImportJob()
2. PGMQ message created with { job_id, account_id, csv_content, bank_format, user_id }
3. import-worker picks up message → processJob() → processCsvImportJob()
4. processCsvImportJob extracts user_id from payload [D-06]
5. Validates account_id belongs to user [D-01, D-02]
6. Calls insertBatch(accountId, parsed, categoryMap, userId) [D-04]
7. insertBatch INSERTs transactions with user_id, ON CONFLICT (user_id, import_hash) [D-05]
8. import_jobs status UPDATEs filter by AND user_id = ${userId} [D-07]
```

### Recommended Project Structure

No structural changes needed — all modifications are edits within existing files:

```
src/
├── core/
│   ├── insights/
│   │   └── use-cases.ts          ← D-09, D-10: Fix SQL WHERE clauses
│   └── import/
│       ├── use-cases.ts          ← Already scoped (Phase 7) — no changes needed
│       └── entities.ts           ← MAYBE: add user_id to ImportJob interface
├── workers/
│   ├── import-worker.ts          ← D-04, D-05, D-06, D-07, D-08: All payload + SQL changes
│   └── insights-worker.ts        ← Already extracts user_id — no payload changes needed
└── core/ledger/
    └── use-cases.ts              ← ???: createTransaction auto-trigger missing user_id
```

### Pattern 1: Implicit Ownership via SQL WHERE

**What:** Add `AND user_id = ${userId}` to every scoped query. No separate validation helper.

**When to use:** All queries on user-scoped tables (accounts, categories, transactions, import_jobs, etc.)

**Source:** Phase 7 D-02 pattern, verified in `src/core/ledger/use-cases.ts`

```typescript
// Before (import-worker.ts):
const [ingAccount] = await sql`SELECT id FROM accounts WHERE name = ${ING_BUSINESS_ACCOUNT_NAME} LIMIT 1`;

// After (per D-03):
const [ingAccount] = await sql`
  SELECT id FROM accounts WHERE name = ${ING_BUSINESS_ACCOUNT_NAME} AND user_id = ${userId} LIMIT 1
`;
```

### Pattern 2: Explicit userId Parameter Passing

**What:** `userId` is an explicit parameter to functions, not a context object or global.

**When to use:** All use-case functions and worker helpers that need user scoping.

**Source:** Phase 7 D-01 pattern, verified in `src/core/insights/use-cases.ts`

```typescript
// Before:
export async function insertBatch(
  accountId: string,
  transactions: ParsedTransaction[],
  categoryMap: Map<string, string> = new Map()
): Promise<void>

// After (per D-04):
export async function insertBatch(
  accountId: string,
  transactions: ParsedTransaction[],
  categoryMap: Map<string, string> = new Map(),
  userId: string
): Promise<void>
```

### Anti-Patterns to Avoid

- **Context-based userId** — Don't use AsyncLocalStorage or Hono `c.get('user')` inside worker functions. Workers don't have a request context. Use explicit parameters.
- **Throwing on ownership mismatch** — Per D-01, skip and continue (log error) instead of throwing. This prevents one bad account from failing the entire job.
- **Batch-level transactions for ownership check** — Don't wrap the account check in a transaction. A simple SELECT + early return is sufficient.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deduplication logic | Custom dedup with in-memory set | PostgreSQL `ON CONFLICT (user_id, import_hash) DO NOTHING` | Already implemented, just needs the constraint name updated to match migration 009 |
| Ownership validation | Separate `validateOwnership()` function | Implicit SQL `WHERE id = X AND user_id = Y` | Phase 7 D-02 locked — consistent, simpler, avoids extra round-trips |
| Message payload schema | Zod/JSON Schema for PGMQ payloads | TypeScript discriminated union on `processJob` | PGMQ is schema-less JSONB — TypeScript types are sufficient |

## Common Pitfalls

### Pitfall 1: ON CONFLICT Constraint Mismatch

**What goes wrong:** Migration 009 already changed `transactions.import_hash` from a standalone `UNIQUE(import_hash)` to a composite `UNIQUE(user_id, import_hash)`. But the code still uses `ON CONFLICT (import_hash) DO NOTHING` — this will **fail at runtime** because PostgreSQL requires `ON CONFLICT` columns to exactly match a unique constraint or index.

**Why it happens:** The migration was applied in Phase 6 but the worker code wasn't updated in Phase 7 (deferred to Phase 8 per D-05).

**How to avoid:** Update ALL `ON CONFLICT` clauses:

| File | Line | Current | Must Become |
|------|------|---------|-------------|
| `import-worker.ts` | 303 | `ON CONFLICT (import_hash)` | `ON CONFLICT (user_id, import_hash)` |
| `import-worker.ts` | 406 | `ON CONFLICT (import_hash)` | `ON CONFLICT (user_id, import_hash)` |
| `import-worker.ts` | 376 | `ON CONFLICT (year, month)` | `ON CONFLICT (user_id, year, month)` |

The INSERT statements must also include `user_id` for the `ON CONFLICT` to work — `ON CONFLICT` can only reference columns that are present in the INSERT's target columns (though actually PostgreSQL allows ON CONFLICT to reference any column of the table, not just the inserted ones — but if the constraint column is NOT NULL, the insert must include it).

**Warning signs:** Production errors like `ERROR: there is no unique or exclusion constraint matching the ON CONFLICT specification`. This will happen immediately on the first import job after migration 009 is applied.

### Pitfall 2: getLatestTransactionDate Returns Wrong Anchor

**What goes wrong:** `getLatestTransactionDate()` (in `src/core/insights/use-cases.ts`) returns `MAX(date)` across ALL users. Both `getInsightDataWindow()` and `getCategoryAggregates()` use this as the anchor date for their 3-month window. If any user has a future-dated transaction, every user's insights window shifts forward.

**Why it happens:** The function has no WHERE clause — it was written before users existed.

**How to avoid:** Per D-10, add `WHERE user_id = ${userId}` to `getLatestTransactionDate`. The function is private to `insights/use-cases.ts` — it needs the `userId` parameter threaded through from its callers.

**Warning signs:** User A creates a transaction dated tomorrow. User B's insights show "no transactions" because the max date is in the future, pushing User B's 3-month window past their data.

### Pitfall 3: Excel Migration ON CONFLICT (year, month) + No user_id

**What goes wrong:** `processExcelMigrationJob` inserts opening balances without `user_id` and uses `ON CONFLICT (year, month) DO NOTHING`. Migration 009 changed the constraint to `UNIQUE(user_id, year, month)`. The insert will either fail (if `user_id` is NOT NULL) or the ON CONFLICT won't match the constraint.

**How to avoid:** Add `user_id` to the INSERT and update ON CONFLICT to `(user_id, year, month)`.

### Pitfall 4: Excel Migration Category/Account Lookups Without User Scope

**What goes wrong:** `processExcelMigrationJob` queries:
- `SELECT id, name FROM categories` (no WHERE at all!)
- `SELECT id FROM accounts WHERE name = ${ING_BUSINESS_ACCOUNT_NAME}` (no user_id)
- `SELECT id FROM accounts WHERE name = ${PKO_PERSONAL_ACCOUNT_NAME}` (no user_id)

If two users have accounts/categories with the same name, the wrong user's data gets used.

**How to avoid:** Per D-03, add `AND user_id = ${userId}` to all three queries.

### Pitfall 5: User_id Missing From createTransaction Auto-Trigger

**What goes wrong:** `createTransaction()` in `src/core/ledger/use-cases.ts:22` enqueues an analysis message with `{ transaction_id: tx.id }` — **without `user_id`**. The insights worker's `processAnalysisMessage` throws `Error('Message payload missing user_id')` when it encounters a payload without `user_id`. This means auto-triggered analysis from manual transaction creation is currently broken.

**Why it happens:** The auto-trigger was added before the `user_id` requirement was enforced in the insights worker. Phase 7 didn't update it.

**How to assess impact:** This is an existing bug predating Phase 8. Whether Phase 8 fixes it depends on scope interpretation:
- In scope (for WORKER-04: "Insights worker verified to correctly scope by user_id"): The insights worker can't scope analysis for auto-triggered messages if the payload doesn't carry `user_id`. Fix: add `user_id: input.userId` to the PGMQ message in `createTransaction()`.
- Out of scope: The auto-trigger analysis was never tested and may be a pre-existing broken feature.

## Code Examples

### Pattern: user_id Extraction in processCsvImportJob (D-06)

```typescript
// Current:
async function processCsvImportJob(payload: {
  job_id: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, account_id, csv_content, bank_format } = payload;

// After:
async function processCsvImportJob(payload: {
  job_id: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
  user_id: string;
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, account_id, csv_content, bank_format, user_id } = payload;
```

### Pattern: Account Ownership Validation (D-01, D-02)

```typescript
// In processCsvImportJob, before starting batch processing:
// Validate account_id belongs to user (D-02: implicit SQL WHERE)
const [account] = await sql`
  SELECT id FROM accounts WHERE id = ${account_id} AND user_id = ${user_id}
`;
if (!account) {
  throw new Error(`Account ${account_id} not found for user ${user_id}`);
}
```

### Pattern: Insert with user_id + ON CONFLICT per-user (D-04, D-05)

```typescript
export async function insertBatch(
  accountId: string,
  transactions: ParsedTransaction[],
  categoryMap: Map<string, string> = new Map(),
  userId: string  // D-04: explicit userId parameter
): Promise<void> {
  // ... existing account lookup stays the same ...

  await sql.begin(async (sql) => {
    for (const tx of transactions) {
      const hash = computeImportHash(tx.date, tx.amount, tx.description, accountId);
      // ... transfer logic stays the same ...

      await sql`
        INSERT INTO transactions (
          account_id, category_id, type, amount, description, date,
          transfer_to_account_id, import_hash,
          user_id                                   -- NEW: tag with user
        )
        VALUES (
          ${accountId}, ${categoryId}, ${tx.raw_type}, ${tx.amount},
          ${tx.description}, ${tx.date}, ${transferToAccountId}, ${hash},
          ${userId}                                 -- NEW
        )
        ON CONFLICT (user_id, import_hash) DO NOTHING  -- D-05: updated constraint
      `;
    }
  });
}
```

### Pattern: Excel Migration Scoped Queries (D-03, D-08)

```typescript
// Current (unscoped):
const dbCategories = await sql`SELECT id, name FROM categories`;
const [ingAccount] = await sql`
  SELECT id FROM accounts WHERE name = ${ING_BUSINESS_ACCOUNT_NAME} LIMIT 1
`;

// After (per-user scoped):
const dbCategories = await sql`
  SELECT id, name FROM categories WHERE user_id = ${user_id}
`;
const [ingAccount] = await sql`
  SELECT id FROM accounts WHERE name = ${ING_BUSINESS_ACCOUNT_NAME} AND user_id = ${user_id} LIMIT 1
`;
```

### Pattern: Excel Migration Opening Balance (user_id + ON CONFLICT)

```typescript
// Current:
await tx`
  INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (${sheet.meta.year}, ${sheet.meta.month}, ${sheet.openingBalance})
  ON CONFLICT (year, month) DO NOTHING
`;

// After:
await tx`
  INSERT INTO monthly_opening_balances (year, month, opening_balance, user_id)
  VALUES (${sheet.meta.year}, ${sheet.meta.month}, ${sheet.openingBalance}, ${user_id})
  ON CONFLICT (user_id, year, month) DO NOTHING
`;
```

### Pattern: import_jobs UPDATE Scoping (D-07)

```typescript
// Current:
await sql`
  UPDATE import_jobs SET status = 'processing', updated_at = now()
  WHERE id = ${job_id}
`;

// After:
await sql`
  UPDATE import_jobs SET status = 'processing', updated_at = now()
  WHERE id = ${job_id} AND user_id = ${user_id}
`;
```

### Pattern: getLatestTransactionDate Scoped (D-10)

```typescript
// Current:
async function getLatestTransactionDate(): Promise<string> {
  const [row] = await sql`SELECT MAX(date)::text AS latest FROM transactions`;
  return row?.latest ?? new Date().toISOString().slice(0, 10);
}

// After:
async function getLatestTransactionDate(userId: string): Promise<string> {
  const [row] = await sql`
    SELECT MAX(date)::text AS latest FROM transactions WHERE user_id = ${userId}
  `;
  return row?.latest ?? new Date().toISOString().slice(0, 10);
}
```

### Pattern: getInsightDataWindow Scoped (D-09)

```typescript
// Current — userId param is accepted but NOT used in SQL:
export async function getInsightDataWindow(userId: string): Promise<TransactionData[]> {
  const anchor = await getLatestTransactionDate();
  const rows = await sql`
    SELECT t.*, c.name as category_name
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE t.date >= (${anchor}::date - interval '3 months')
       OR (...)
    ORDER BY t.date DESC
  `;

// After — add userId filter to WHERE:
export async function getInsightDataWindow(userId: string): Promise<TransactionData[]> {
  const anchor = await getLatestTransactionDate(userId);  // D-10: scoped anchor
  const rows = await sql`
    SELECT t.*, c.name as category_name
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE (t.date >= (${anchor}::date - interval '3 months')
       OR (EXTRACT(MONTH FROM t.date) = EXTRACT(MONTH FROM ${anchor}::date - interval '12 months')
           AND t.date >= ${anchor}::date - interval '15 months'
           AND t.date < ${anchor}::date - interval '11 months'))
      AND t.user_id = ${userId}                           -- NEW: scope by user
    ORDER BY t.date DESC
  `;
```

## Runtime State Inventory

> Not a rename/refactor phase — omit. Phase 8 is a pure code-change phase with no runtime state migrations.

*Step 2.6: SKIPPED (no external dependencies identified — all changes are code edits to existing files using established patterns)*

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bun:test |
| Config file | none — bun:test is built-in |
| Quick run command | `bun test tests/import-worker.test.ts` and `bun test tests/insights-worker.test.ts` |
| Full suite command | `bun test` (all tests) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WORKER-01 | PGMQ payload carries user_id for import jobs | Already implemented in Phase 7 | — | — |
| WORKER-02 | Import worker inserts transactions tagged with user ID | Integration | `bun test tests/import-worker.test.ts` | ✅ (needs update) |
| WORKER-03 | Import worker validates account ownership | Integration | `bun test tests/import-worker.test.ts` | ✅ (needs new test) |
| WORKER-04 | Insights worker scoped correctly by user_id | Integration | `bun test tests/insights-worker.test.ts` | ✅ (may pass after fix) |

### Existing Test Coverage Gaps

**`tests/import-worker.test.ts`:**
- Calls `enqueueImportJob({ account_id, csv_content, bank_format })` — **missing `userId`** parameter (which is now required after Phase 7). This test will fail with a TypeScript error or runtime error. Needs updating to provide a valid `userId`.
- No test for multiple users isolating data.
- No test for account ownership validation (WORKER-03) — ownership mismatch should skip, not fail.
- No test for import_jobs UPDATE scoping.

**`tests/insights-worker.test.ts`:**
- `processAnalysisMessage` test already provides `user_id` via `enqueueAnalysisJob` → good.
- BUT: uses raw transactions seeded without `user_id` — needs checking if `beforeAll` transaction inserts include `user_id`.
- Looking at lines 68-73: `INSERT INTO transactions (account_id, category_id, type, amount, description, date)` — **no user_id column in INSERT or VALUES**. This will work because transactions table has default... no, `user_id` is `NOT NULL` (migration 008). This test would fail if the migration has been applied.

Actually wait — the test inserts happen in `beforeAll`. If the migration has been applied, the INSERT would need `user_id`. Let me check if the schema.sql (which is used to set up test DB) includes the updated schema...

The schema.sql at line 33 shows:
```sql
user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE
```

So the test MUST include `user_id` in the INSERT. The current test code at line 68-73 doesn't include it. This means either:
1. The test DB was created with the old schema and migration 008 was never applied to it
2. OR the test currently fails

This is a pre-existing issue that Phase 8 should address. But I'll note it in the open questions.

### Test Fixes for Phase 8

1. **Update `import-worker.test.ts`** — add `userId` param to `enqueueImportJob` calls, add ownership validation test, add multi-user isolation test
2. **Update `insights-worker.test.ts`** — ensure transaction inserts include `user_id`, verify scoping after D-09/D-10 fixes
3. **New test for ownership mismatch** — enqueue job for account that doesn't belong to user, verify it's skipped gracefully

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ON CONFLICT (import_hash)` | `ON CONFLICT (user_id, import_hash)` | Phase 6 (migration 009) | Code must match constraint or queries fail |
| Worker ignores user_id in payload | Worker extracts and uses user_id | Phase 8 | Data isolation in worker path |
| `getLatestTransactionDate()` global | `getLatestTransactionDate(userId)` per-user | Phase 8 | Correct insights window per user |
| `getInsightDataWindow` parametrized but unenforced | SQL WHERE actually filters by user | Phase 8 | No cross-user data leakage in insights |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `createTransaction` auto-trigger (`src/core/ledger/use-cases.ts:22`) lacks `user_id` in PGMQ payload, causing `processAnalysisMessage` to throw | Common Pitfalls #5 | If this is intentional (auto-trigger is known-broken and will be fixed separately), Phase 8 implementing the fix would be out-of-scope. If it's unintended, auto-triggered analysis is silently broken. |
| A2 | `import-worker.test.ts` calls `enqueueImportJob` without `userId` | Validation Architecture | The test may already fail after Phase 7. If so, it needs fixing as part of Phase 8. |
| A3 | `insights-worker.test.ts` `beforeAll` inserts transactions without `user_id` column | Validation Architecture | The test may fail because `user_id` is `NOT NULL` after migration 008. |

## Open Questions

1. **Should Phase 8 fix the `createTransaction` auto-trigger payload?**
   - What we know: `createTransaction()` in `src/core/ledger/use-cases.ts:22` sends `{ transaction_id: tx.id }` without `user_id`. The insights worker requires `user_id` in the payload. This breaks auto-triggered analysis on manual transaction creation.
   - What's unclear: Whether this is in-scope for Phase 8. The CONTEXT.md decisions don't explicitly mention it. D-09 and D-10 fix the SQL but don't fix the payload that feeds into those queries.
   - Recommendation: **Flag for planner.** Adding `user_id: input.userId` to the PGMQ message in `createTransaction` is a one-line change and is necessary for WORKER-04 (ensuring insights worker correctly scopes by user_id for ALL analysis paths, not just manual). Worth including as a scope clarification.

2. **Does the `ImportJob` entity need a `user_id` field?**
   - What we know: `src/core/import/entities.ts` defines `ImportJob` without `user_id`. The table has `user_id` after migration 008. The `getImportStatus` use-case returns results with `user_id` but the entity type doesn't include it.
   - What's unclear: Whether the missing field causes any type issues downstream. The route handler only returns `ImportJob` fields that the frontend needs — if `user_id` isn't returned to the client, the entity doesn't strictly need updating.
   - Recommendation: **Low priority.** The TypeScript type is for internal use. If no compilation error, skip. If added, it's a quick field addition.

3. **Are the existing tests broken after Phase 6 + 7 migrations?**
   - What we know: `import-worker.test.ts` calls `enqueueImportJob` without `userId` (required after Phase 7). `insights-worker.test.ts` inserts transactions without `user_id` in `beforeAll`.
   - What's unclear: Whether the test DB has been migrated to the new schema. If not, tests would pass currently but fail after Phase 8 schema updates.
   - Recommendation: **Investigate during execution.** Run the existing tests first to establish baseline, then fix and extend.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bun | Runtime | ✓ | 1.3.14 | — |
| Node.js | — | ✓ | 22.22.2 | Fallback only |
| PostgreSQL | Database | ✓ (via postgres.js) | — | — |
| psql CLI | Direct DB queries | ✗ | — | Use postgres.js via code |

**Missing dependencies with no fallback:** None — all required tools are available.

**Missing dependencies with fallback:** `psql` CLI is not installed but not needed — all database operations go through the postgres.js client.

## Security Domain

> Required when `security_enforcement` is enabled (absent in config.json = enabled).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | Yes | Per-user data isolation via SQL WHERE + userId extraction from PGMQ payload |
| V5 Input Validation | No | Input validation happens before enqueue (Phase 7) |
| V6 Cryptography | No | — |
| V8 Data Protection | Yes | Prevent cross-user data leakage in background workers |

### Known Threat Patterns for Background Worker Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-user data contamination in import path | Tampering / Information Disclosure | D-04 (explicit userId param), D-05 (per-user unique constraint), D-07 (scoped UPDATEs) |
| Cross-user data leakage in insights path | Information Disclosure | D-09 (WHERE user_id in getInsightDataWindow), D-10 (scoped getLatestTransactionDate) |
| Account ownership mismatch in Excel migration | Tampering | D-03 (user_id scope on account/category queries) |
| Unauthorized message processing (no user context) | Spoofing / Tampering | D-06 (extract user_id from payload), every query scoped by user |

## Sources

### Primary (HIGH confidence) — Verified via codebase inspection

- `src/workers/import-worker.ts` — Complete worker code, all `ON CONFLICT` clauses, `processCsvImportJob`, `processExcelMigrationJob`, `insertBatch`
- `src/workers/insights-worker.ts` — `processAnalysisMessage`, `getInsightDataWindow` usage, rate limiting
- `src/core/insights/use-cases.ts` — `getInsightDataWindow`, `getLatestTransactionDate`, `getCategoryAggregates`
- `src/core/import/use-cases.ts` — `enqueueImportJob` payload structure (already includes `user_id`)
- `src/core/import/entities.ts` — `ImportJob` interface definition
- `src/core/ledger/use-cases.ts` — `createTransaction` auto-trigger (missing `user_id` in PGMQ payload)
- `src/interface-adapters/api/migration.ts` — Excel migration enqueue (already includes `user_id`)
- `src/infrastructure/db/migrations/009_update_uniques.sql` — Composite unique constraints already created
- `src/infrastructure/db/schema.sql` — Current schema with `UNIQUE(user_id, import_hash)` and `user_id NOT NULL`
- `.planning/phases/08-worker-isolation/08-CONTEXT.md` — Locked decisions D-01 through D-10
- `.planning/phases/07-backend-scoping/07-CONTEXT.md` — Prior decisions D-01 through D-05
- `.planning/REQUIREMENTS.md` — WORKER-01 through WORKER-04 requirements

### Medium confidence — Codebase patterns

- User extraction pattern: `c.get('user')` in route handlers, explicit `userId` param in use-cases (verified across all use-case files)
- Ownership validation: Implicit SQL WHERE only (verified: no separate validation helper exists in the codebase)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — stack is unchanged from prior phases, no new packages
- Architecture: HIGH — all patterns are established from Phase 7 and verified in code
- Pitfalls: HIGH — confirmed by reading migration 009, current code, and understanding PostgreSQL `ON CONFLICT` behavior

**Research date:** 2026-06-07
**Valid until:** 2026-07-07 (stable phase — no fast-moving dependencies)
