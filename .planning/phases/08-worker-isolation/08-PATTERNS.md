# Phase 8: Worker Isolation — Pattern Map

**Mapped:** 2026-06-07
**Files analyzed:** 7 (5 source + 2 test)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `src/workers/import-worker.ts` | worker | event-driven (PGMQ) | `src/workers/insights-worker.ts` | exact (same role + data flow) |
| `src/workers/insights-worker.ts` | worker | event-driven (PGMQ) | itself (current pattern) | exact |
| `src/core/insights/use-cases.ts` | service | request-response (CRUD) | `src/core/ledger/use-cases.ts` | role-match |
| `src/core/import/entities.ts` | model | — | `src/core/insights/entities.ts` | role-match |
| `src/core/ledger/use-cases.ts` | service | CRUD + event-driven (PGMQ enqueue) | itself (current pattern) | exact |
| `tests/import-worker.test.ts` | test | integration | itself (current pattern) | exact |
| `tests/insights-worker.test.ts` | test | integration | itself (current pattern) | exact |

## Pattern Assignments

### `src/workers/import-worker.ts` (worker, event-driven)

**Current file already exists.** Changes: D-04 through D-08 — add `user_id` extraction, account ownership validation, scope all queries by user.

#### Analog: `src/workers/insights-worker.ts` — user_id extraction from PGMQ payload (lines 361-367)

The insights worker already extracts `user_id` from the PGMQ payload — this is the exact pattern to follow for `processCsvImportJob` and `processExcelMigrationJob`:

```typescript
// src/workers/insights-worker.ts lines 361-367
export async function processAnalysisMessage(msg: { message: any }): Promise<void> {
  const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;
  const userId = payload.user_id;
  const triggeredBy = payload.triggered_by;

  if (!userId) {
    throw new Error('Message payload missing user_id');
  }
```

**Apply to:** `processCsvImportJob` — extract `user_id` alongside existing destructuring (D-06):
```typescript
// Current (lines 487-488):
async function processCsvImportJob(payload: {
  job_id: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, account_id, csv_content, bank_format } = payload;

// After — add user_id field (match pattern from insights-worker.ts):
async function processCsvImportJob(payload: {
  job_id: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
  user_id: string;
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, account_id, csv_content, bank_format, user_id } = payload;
```

**Apply to:** `processExcelMigrationJob` — same extraction pattern (D-08):
```typescript
// Current (lines 315-320):
export async function processExcelMigrationJob(payload: {
  job_id: string;
  type: 'excel_migration';
  file_path: string;
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, file_path } = payload;

// After — add user_id:
export async function processExcelMigrationJob(payload: {
  job_id: string;
  type: 'excel_migration';
  file_path: string;
  user_id: string;
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, file_path, user_id } = payload;
```

#### Analog: `src/core/ledger/use-cases.ts` — user_id scoping via SQL WHERE (lines 46, 150-153, 160-161, etc.)

The ledger use-cases consistently scope queries by `user_id`. This is the pattern for all import worker SQL changes:

```typescript
// src/core/ledger/use-cases.ts line 46:
AND user_id = ${userId}

// src/core/ledger/use-cases.ts lines 160-161 (getTransaction):
const [row] = await sql`SELECT * FROM transactions WHERE id = ${id} AND user_id = ${userId}`;

// src/core/ledger/use-cases.ts lines 150-153 (updateOpeningBalance):
const [row] = await sql`
  UPDATE monthly_opening_balances
  SET ${sql(fields)}
  WHERE id = ${id} AND user_id = ${userId}
  RETURNING *
`;
```

**Apply to:**

1. **Account ownership check** (lines 272-273, D-02):
```typescript
// Current (line 272):
const accounts = await sql`SELECT id FROM accounts`;

// After — scope accounts lookup to user (D-01, D-02):
// (This is used by insertBatch to find the "other" account for transfer linking)
const accounts = await sql`SELECT id FROM accounts WHERE user_id = ${userId}`;
```

2. **Category lookup in processCsvImportJob** (line 505):
```typescript
// Current (line 505):
const categoryRows = await sql`SELECT id, name, llm_description FROM categories`;

// After — scope categories per-user:
const categoryRows = await sql`SELECT id, name, llm_description FROM categories WHERE user_id = ${user_id}`;
```

3. **Import job UPDATEs** (multiple locations, D-07):
```typescript
// Current pattern — used ~7 times in file (lines 325-328, 351-354, 361-363, etc.):
WHERE id = ${job_id}

// After — all become:
WHERE id = ${job_id} AND user_id = ${user_id}
```

4. **Excel migration category/account queries** (lines 332-335, D-03):
```typescript
// Current (lines 332-335):
const dbCategories = (await sql`SELECT id, name FROM categories`) as unknown as CategoryRecord[];
const [ingAccount] = await sql`SELECT id FROM accounts WHERE name = ${ING_BUSINESS_ACCOUNT_NAME} LIMIT 1`;
const [pkoAccount] = await sql`SELECT id FROM accounts WHERE name = ${PKO_PERSONAL_ACCOUNT_NAME} LIMIT 1`;

// After — scope by user_id:
const dbCategories = (await sql`
  SELECT id, name FROM categories WHERE user_id = ${user_id}
`) as unknown as CategoryRecord[];
const [ingAccount] = await sql`
  SELECT id FROM accounts WHERE name = ${ING_BUSINESS_ACCOUNT_NAME} AND user_id = ${user_id} LIMIT 1
`;
const [pkoAccount] = await sql`
  SELECT id FROM accounts WHERE name = ${PKO_PERSONAL_ACCOUNT_NAME} AND user_id = ${user_id} LIMIT 1
`;
```

#### Analog: Current `insertBatch` signature — explicit parameters (lines 267-271)

The existing pattern for `insertBatch` uses explicit parameters already — D-04 adds `userId` alongside the existing params:

```typescript
// Current (lines 267-271):
export async function insertBatch(
  accountId: string,
  transactions: ParsedTransaction[],
  categoryMap: Map<string, string> = new Map()
): Promise<void>
```

#### ON CONFLICT changes (D-05)

Migration 009 already changed the constraints. Code must match:

**Transaction inserts** — lines 303, 406:
```typescript
// Current:
ON CONFLICT (import_hash) DO NOTHING

// After:
ON CONFLICT (user_id, import_hash) DO NOTHING
```

**Monthly opening balances** — line 376:
```typescript
// Current:
ON CONFLICT (year, month) DO NOTHING

// After (migration 009 constraint is UNIQUE(user_id, year, month)):
ON CONFLICT (user_id, year, month) DO NOTHING
```

#### INSERT columns — add user_id (D-04)

**Transaction inserts** — lines 282-304 (processCsvImportJob path) and lines 387-407 (excel migration path):
```typescript
// Current INSERT columns:
account_id, category_id, type, amount, description, date, transfer_to_account_id, import_hash

// After — add user_id:
account_id, category_id, type, amount, description, date, transfer_to_account_id, import_hash, user_id
```

**Monthly opening balances insert** — lines 373-377:
```typescript
// Current:
INSERT INTO monthly_opening_balances (year, month, opening_balance)

// After:
INSERT INTO monthly_opening_balances (year, month, opening_balance, user_id)
```

#### `processJob` discriminated union — add user_id to both variants (lines 455-475)

```typescript
// Current (lines 455-465):
export async function processJob(payload: {
  job_id: string;
  type?: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
} | {
  job_id: string;
  type: 'excel_migration';
  file_path: string;
}): Promise<{ processed: number; errors: string[] }> {

// After — add user_id to both union variants:
export async function processJob(payload: {
  job_id: string;
  type?: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
  user_id: string;
} | {
  job_id: string;
  type: 'excel_migration';
  file_path: string;
  user_id: string;
}): Promise<{ processed: number; errors: string[] }> {
```

---

### `src/workers/insights-worker.ts` (worker, event-driven)

**Already extracts `user_id` (lines 361-367).** No payload changes needed.

The `processAnalysisMessage` function already calls `getInsightDataWindow(userId)` (line 387) — D-09 fix is in `src/core/insights/use-cases.ts`, not in this file.

---

### `src/core/insights/use-cases.ts` (service, CRUD)

#### Analog: `src/core/ledger/use-cases.ts` — userId parameter in SQL WHERE (lines 45-46, 78, 85, 161, 166-177)

The ledger use-cases consistently use `userId` in SQL WHERE clauses. This is the pattern for fixing `getInsightDataWindow` and `getLatestTransactionDate`:

**Pattern for scoped queries** (from `src/core/ledger/use-cases.ts` lines 68-79):
```typescript
// src/core/ledger/use-cases.ts lines 68-79
export async function getMonthlySummary(userId: string): Promise<MonthlySummaryRow[]> {
  const agg = await sql`
    SELECT ...
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE t.type != 'transfer'
      AND t.user_id = ${userId}
    GROUP BY ...
  `;
```

**Apply D-09 to `getInsightDataWindow`** (lines 12-25):
```typescript
// Current (lines 12-25) — userId param exists but NOT used in SQL:
export async function getInsightDataWindow(userId: string): Promise<TransactionData[]> {
  const anchor = await getLatestTransactionDate();
  const rows = await sql`
    SELECT t.*, c.name as category_name
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE t.date >= (${anchor}::date - interval '3 months')
       OR (EXTRACT(MONTH FROM t.date) = EXTRACT(MONTH FROM ${anchor}::date - interval '12 months')
           AND t.date >= ${anchor}::date - interval '15 months'
           AND t.date < ${anchor}::date - interval '11 months')
    ORDER BY t.date DESC
  `;
  return rows as TransactionData[];
}

// After — add WHERE t.user_id = ${userId} and scope anchor (D-09 + D-10):
export async function getInsightDataWindow(userId: string): Promise<TransactionData[]> {
  const anchor = await getLatestTransactionDate(userId);  // D-10: pass userId
  const rows = await sql`
    SELECT t.*, c.name as category_name
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE (t.date >= (${anchor}::date - interval '3 months')
       OR (EXTRACT(MONTH FROM t.date) = EXTRACT(MONTH FROM ${anchor}::date - interval '12 months')
           AND t.date >= ${anchor}::date - interval '15 months'
           AND t.date < ${anchor}::date - interval '11 months'))
      AND t.user_id = ${userId}                            -- NEW
    ORDER BY t.date DESC
  `;
  return rows as TransactionData[];
```

**Apply D-10 to `getLatestTransactionDate`** (lines 5-8):
```typescript
// Current (lines 5-8):
async function getLatestTransactionDate(): Promise<string> {
  const [row] = await sql`SELECT MAX(date)::text AS latest FROM transactions`;
  return row?.latest ?? new Date().toISOString().slice(0, 10);
}

// After — scope to user (D-10):
async function getLatestTransactionDate(userId: string): Promise<string> {
  const [row] = await sql`
    SELECT MAX(date)::text AS latest FROM transactions WHERE user_id = ${userId}
  `;
  return row?.latest ?? new Date().toISOString().slice(0, 10);
}
```

**Note:** `getCategoryAggregates` (lines 28-79) also calls `getLatestTransactionDate()` on line 31 — will need `userId` passed through. However, it accepts `transactionIds` (already scoped by the caller), not `userId`. The anchor date could remain unscoped or accept `userId` as an additional param — for maximum safety, add `userId` param and scope the anchor:

```typescript
// Current (line 28):
export async function getCategoryAggregates(transactionIds: string[]): Promise<CategoryAggregate[]> {

// After — add userId param for scoped anchor:
export async function getCategoryAggregates(transactionIds: string[], userId: string): Promise<CategoryAggregate[]> {
  // ...
  const anchor = await getLatestTransactionDate(userId);
```

But updating `getCategoryAggregates` propagation depends on what the caller does. `insights-worker.ts` line 402 calls it: `await getCategoryAggregates(txIds)`. If we add `userId` to `getCategoryAggregates`, we must also pass it from the worker, which already has `userId`. This is the agent's discretion.

---

### `src/core/import/entities.ts` (model, —)

#### Analog: `src/core/insights/entities.ts` — Insight interface with user_id (best match)

The `ImportJob` interface (lines 4-13) may need `user_id` added. Look at how `Insight` entity is defined:

```typescript
// src/core/insights/entities.ts (grep for reference)
// Pattern: entities include user_id as a field

// Current ImportJob (lines 4-13):
export interface ImportJob {
  id: string;
  account_id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  total_rows: number | null;
  processed: number;
  errors: string[] | null;
  created_at: string;
  updated_at: string;
}

// After — add user_id field:
export interface ImportJob {
  id: string;
  account_id: string;
  user_id: string;       // NEW — reflect schema (table has user_id NOT NULL)
  status: 'pending' | 'processing' | 'completed' | 'failed';
  total_rows: number | null;
  processed: number;
  errors: string[] | null;
  created_at: string;
  updated_at: string;
}
```

---

### `src/core/ledger/use-cases.ts` (service, CRUD + PGMQ enqueue)

#### Fix: `createTransaction` auto-trigger payload (line 22)

**Current** (line 22):
```typescript
await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({ transaction_id: tx.id })}::jsonb)`;
```

**After** — add `user_id` to PGMQ payload so insights worker can process it (fixes Pitfall #5):
```typescript
await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({
  transaction_id: tx.id,
  user_id: input.userId,         // NEW — required by processAnalysisMessage
})}::jsonb)`;
```

---

### `tests/import-worker.test.ts` (test, integration)

#### Analog: Itself — current test structure at lines 70-136

**Fix 1: Add `userId` to `enqueueImportJob` call** (lines 75-79):
```typescript
// Current (lines 75-79) — missing userId:
const { job_id, msg_id } = await enqueueImportJob({
  account_id: accountId,
  csv_content: csvContent,
  bank_format: 'ing',
});

// After — add userId (must get a user ID from the DB first):
const users = await sql`SELECT id FROM "user" LIMIT 1`;
const userId = users[0].id;

const { job_id, msg_id } = await enqueueImportJob({
  account_id: accountId,
  csv_content: csvContent,
  bank_format: 'ing',
  userId,
});
```

**Fix 2: Add `user_id` verification** — after import, verify transactions have `user_id` set:
```typescript
// After existing transaction count check, add:
const txsWithUser = await sql`
  SELECT DISTINCT user_id FROM transactions WHERE account_id = ${accountId}
  AND user_id IS NOT NULL
`;
expect(txsWithUser.length).toBeGreaterThan(0);
```

---

### `tests/insights-worker.test.ts` (test, integration)

#### Fix: Transaction INSERTs in `beforeAll` must include `user_id` (lines 68-73)

**Current** (lines 68-73):
```typescript
await sql`
  INSERT INTO transactions (account_id, category_id, type, amount, description, date)
  VALUES
    (${accountId}, ${categoryId}, 'expense', '150.00', 'Supermarket spend', current_date - interval '10 days'),
    (${accountId}, ${categoryId}, 'expense', '250.00', 'Grocery shopping', current_date - interval '20 days')
`;
```

**After** — add `user_id` column + value:
```typescript
await sql`
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, user_id)
  VALUES
    (${accountId}, ${categoryId}, 'expense', '150.00', 'Supermarket spend', current_date - interval '10 days', ${userId}),
    (${accountId}, ${categoryId}, 'expense', '250.00', 'Grocery shopping', current_date - interval '20 days', ${userId})
`;
```

---

## Shared Patterns

### Pattern A: User ID Extraction from PGMQ Payload
**Source:** `src/workers/insights-worker.ts` lines 361-367
**Apply to:** `processCsvImportJob`, `processExcelMigrationJob`

```typescript
const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;
const userId = payload.user_id;
if (!userId) {
  throw new Error('Message payload missing user_id');
}
```

### Pattern B: Implicit Ownership via SQL WHERE
**Source:** `src/core/ledger/use-cases.ts` lines 46, 78, 150-153, 160-161, 166-177
**Apply to:** All scoped SQL queries in workers

```typescript
// Standard pattern for scoping queries by user:
WHERE id = ${someId} AND user_id = ${userId}
// or directly:
AND t.user_id = ${userId}
```

### Pattern C: Explicit `userId` Parameter Passing
**Source:** `src/core/ledger/use-cases.ts` throughout, `src/core/insights/use-cases.ts` throughout
**Apply to:** `insertBatch`, `getLatestTransactionDate`, any helper needing user scope

```typescript
// Parameters are explicit — no context objects:
export async function someFunction(
  entityId: string,
  otherData: SomeType,
  userId: string   // <-- always last or near-last param
): Promise<void>
```

### Pattern D: Skip on Ownership Mismatch (D-01)
**Source:** CONTEXT.md D-01 decision
**Apply to:** Account ownership check in `processCsvImportJob`

```typescript
// Per D-01: skip batch, don't throw for one bad account
// Per D-02: implicit SQL WHERE, no helper
const [account] = await sql`
  SELECT id FROM accounts WHERE id = ${account_id} AND user_id = ${user_id}
`;
if (!account) {
  console.error(`Account ${account_id} not found for user ${user_id} — skipping job`);
  return { processed: 0, errors: [`Account ${account_id} not found for user ${user_id}`] };
}
// Note: D-01 says skip and continue, but this check happens before batch processing
// so early return is acceptable (per the context)
```

### Pattern E: ON CONFLICT with Composite Unique Constraints
**Source:** Migration 009 (`src/infrastructure/db/migrations/009_update_uniques.sql`)
**Apply to:** All INSERT statements with ON CONFLICT

| Constraint | Current | Must Become |
|------------|---------|-------------|
| `transactions` import_hash | `ON CONFLICT (import_hash)` | `ON CONFLICT (user_id, import_hash)` |
| `monthly_opening_balances` year+month | `ON CONFLICT (year, month)` | `ON CONFLICT (user_id, year, month)` |

### Pattern F: enqueueImportJob Already Includes userId
**Source:** `src/core/import/use-cases.ts` lines 36-42
**Apply to:** Understanding the payload structure

```typescript
// The enqueue side already posts user_id in PGMQ (Phase 7):
SELECT pgmq.send('import_queue', ${JSON.stringify({
  job_id: job.id,
  account_id: payload.account_id,
  csv_content: payload.csv_content,
  bank_format: payload.bank_format,
  user_id: payload.userId,       // <-- already present
})}::jsonb)
```

### Pattern G: import.ts Route Handler Already Passes userId
**Source:** `src/interface-adapters/api/import.ts` lines 37-42
**Apply to:** Understanding that the API layer already passes `userId` to `enqueueImportJob`

```typescript
const { job_id } = await enqueueImportJob({
  account_id: accountId as string,
  csv_content: csvContent,
  bank_format,
  userId: user.id,    // <-- already present in route handler
});
```

### Pattern H: Excel Migration Enqueue Already Includes userId
**Source:** `src/interface-adapters/api/migration.ts` lines 62-67
**Apply to:** Understanding that `processExcelMigrationJob` payload already has `user_id`

```typescript
SELECT pgmq.send(${QUEUE_NAME}, ${JSON.stringify({
  job_id: jobId,
  type: 'excel_migration',
  file_path: filePath,
  user_id: user.id,        // <-- already present (Phase 7)
})}::jsonb) as msg_id
```

---

## No Analog Found

None — all files have close analogs or are the files themselves.

## Metadata

**Analog search scope:**
- `src/workers/` — both workers
- `src/core/insights/` — use-cases + entities
- `src/core/import/` — use-cases + entities
- `src/core/ledger/` — use-cases
- `src/interface-adapters/api/` — import.ts, migration.ts
- `tests/` — import-worker.test.ts, insights-worker.test.ts
- `src/infrastructure/db/` — migrations, schema.sql

**Files scanned:** 15 source files, 2 test files
**Pattern extraction date:** 2026-06-07
