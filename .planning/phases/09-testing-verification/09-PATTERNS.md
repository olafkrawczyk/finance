# Phase 9: Testing & Verification - Pattern Map

**Mapped:** 2026-06-07
**Files analyzed:** 5 (2 CREATE, 3 EXTEND)
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `tests/api-scoping.test.ts` | test | request-response, CRUD | `tests/api-scoping.test.ts` (self) | exact (extend existing) |
| `tests/concurrent-isolation.test.ts` | test | request-response, CRUD | `tests/api-scoping.test.ts` | role-match |
| `tests/import-worker.test.ts` | test | event-driven, CRUD | `tests/import-worker.test.ts` (self) | exact (extend existing) |
| `tests/insights-worker.test.ts` | test | event-driven, CRUD | `tests/insights-worker.test.ts` (self) | exact (extend existing) |
| `tests/migration-rollback.test.ts` | test | schema-migration | `tests/schema-migration.test.ts` | role-match |

## Pattern Assignments

### `tests/api-scoping.test.ts` (test, request-response + CRUD) — EXTEND

**Action:** Add Group 6 (Pagination), Group 7 (Filtered Queries), Group 8 (Bulk Create) after existing Group 5.

**Analog:** Self — existing file `tests/api-scoping.test.ts` lines 1-411

There is no need to copy imports/setup — the extension adds new `describe` blocks to the existing file using the same module-scoped variables.

**Existing setup pattern** (lines 1-68) — stays unchanged, new groups reuse variables:
```typescript
import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';

const USER_A_EMAIL = 'scope-user-a@test.com';
const USER_B_EMAIL = 'scope-user-b@test.com';

let userASession: string;
let userBSession: string;
let userAAccountId: string;
let userBAccountId: string;
let userATransactionId: string;

beforeAll(async () => {
  await sql`DELETE FROM "user" WHERE email IN (${USER_A_EMAIL}, ${USER_B_EMAIL})`;
  const resA = await auth.api.signUpEmail({
    body: { email: USER_A_EMAIL, password: USER_A_PASSWORD, name: 'Scope User A' },
    asResponse: true,
  });
  const cookieA = resA.headers.get('set-cookie');
  if (!cookieA) throw new Error('No session cookie for User A');
  userASession = cookieA;
  // ... same for User B, then fetch account IDs via SQL
});
```

**Existing create-then-read pattern** (lines 76-103) — pattern for bulk create (D-04):
```typescript
it('creates a transaction for User A (POST /transactions) → 201', async () => {
  const res = await app.request('/transactions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Cookie: userASession,
    },
    body: JSON.stringify({
      account_id: userAAccountId,
      type: 'expense',
      amount: '100.0000',
      date: '2026-06-01',
      description: 'User A transaction',
    }),
  });
  expect(res.status).toBe(201);
  const json = await res.json();
  expect(json.data.id).toBeDefined();
  userATransactionId = json.data.id;

  // Verify user_id via SQL
  const [row] = await sql`
    SELECT user_id FROM transactions WHERE id = ${userATransactionId}
  `;
  const userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;
  expect(row.user_id).toBe(userAId);
});
```

**Existing paginated-list pattern** (lines 144-151) — pattern for pagination tests (D-02):
```typescript
it('GET /transactions returns User A transactions', async () => {
  const res = await app.request('/transactions?page=1&per_page=50', {
    headers: { Cookie: userASession },
  });
  expect(res.status).toBe(200);
  const json = await res.json();
  expect(json.data.length).toBeGreaterThanOrEqual(1);
  expect(json.data.some((t: any) => t.id === userATransactionId)).toBe(true);
});
```

**Existing cross-user 404 assertion pattern** (lines 194-199) — pattern for D-06 cross-user check:
```typescript
it('GET /transactions/:id with User A transaction + User B cookie → 404', async () => {
  const res = await app.request(`/transactions/${userATransactionId}`, {
    headers: { Cookie: userBSession },
  });
  expect(res.status).toBe(404);
});
```

**Pagination Group 6 template** (derived from D-02 + existing list pattern):
- Create 11+ transactions for User A at top of new `describe` block
- Test page 1 returns page-1 items, page 2 returns page-2 items
- Verify page-2 items all belong to User A via SQL `user_id` check
- Test beyond-last-page returns empty array

**Filtered Query Group 7 template** (derived from D-03 + existing list pattern):
- User A creates a mix of expense/income transactions
- Test `?type=expense` returns only expenses belonging to User A
- Test `?date_from=...&date_to=...` respects user boundary
- Test `?uncategorized=true` returns only User A's uncategorized transactions
- Use `it.each` or individual `it` blocks

**Bulk Create Group 8 template** (derived from D-04 + existing create pattern):
- Create 2-3 transactions sequentially in a loop
- SQL SELECT to verify all are tagged to User A
- SQL COUNT to verify correct row count per user

---

### `tests/concurrent-isolation.test.ts` (test, request-response + CRUD) — CREATE

**Analog:** `tests/api-scoping.test.ts` lines 1-72

**Imports pattern** (copy from api-scoping.test.ts lines 1-4):
```typescript
import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { app } from '../index';
import { auth } from '../src/auth';
import sql from '../src/infrastructure/db/client';
```

**Two-user signup pattern** (copy from api-scoping.test.ts lines 6-68, with unique emails):
```typescript
const USER_A_EMAIL = 'concurrent-a@test.com';
const USER_B_EMAIL = 'concurrent-b@test.com';
const USER_A_PASSWORD = 'testpass123';
const USER_B_PASSWORD = 'testpass456';

let userASession: string;
let userBSession: string;
let userAAccountId: string;
let userBAccountId: string;

beforeAll(async () => {
  await sql`DELETE FROM "user" WHERE email IN (${USER_A_EMAIL}, ${USER_B_EMAIL})`;

  const resA = await auth.api.signUpEmail({
    body: { email: USER_A_EMAIL, password: USER_A_PASSWORD, name: 'Concurrent User A' },
    asResponse: true,
  });
  const cookieA = resA.headers.get('set-cookie');
  if (!cookieA) throw new Error('No session cookie for User A');
  userASession = cookieA;
  // ... same for User B, then SQL SELECT account IDs
});
```

**Concurrent POST via Promise.all pattern** (derived from D-05/D-06 + RESEARCH.md Example 3):
```typescript
it('parallel inserts by two users maintain isolation', async () => {
  const N = 10;

  const userARequests = Array.from({ length: N }, (_, i) =>
    app.request('/transactions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Cookie: userASession },
      body: JSON.stringify({
        account_id: userAAccountId,
        type: 'expense',
        amount: `${i + 1}.0000`,
        date: '2026-06-01',
        description: `Concurrent A ${i}`,
      }),
    }).then(async res => {
      const body = await res.json();
      return { status: res.status, id: body.data?.id, index: i };
    })
  );

  const userBRequests = Array.from({ length: N }, (_, i) =>
    // ... same pattern with User B's session + different description prefix
  );

  const allResults = await Promise.all([...userARequests, ...userBRequests]);
  const failures = allResults.filter(r => r.status !== 201);
  expect(failures).toHaveLength(0);
  // ... then verify per-user row counts + cross-user 404
});
```

**afterAll cleanup pattern** (copy from api-scoping.test.ts lines 70-72):
```typescript
afterAll(async () => {
  await sql`DELETE FROM "user" WHERE email IN (${USER_A_EMAIL}, ${USER_B_EMAIL})`;
});
```

---

### `tests/import-worker.test.ts` (test, event-driven + CRUD) — EXTEND

**Action:** Add `describe('Import Worker Multi-User Isolation', ...)` block after existing test block.

**Analog:** Self — existing file `tests/import-worker.test.ts` lines 1-181

**Existing setup** (lines 1-83) — needs User B setup added. Import stays same:
```typescript
import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';
import { enqueueImportJob } from '../src/core/import/use-cases';
import { processJob, recoverStuckJobs } from '../src/workers/import-worker';
```

**Need to add in beforeAll for isolation tests:** Create User B (via signupEmail or direct INSERT), fetch User B's account_id. Modify existing setup to add a second user.

**Direct processJob call pattern** (existing lines 89-163) — pattern for D-08 user tagging test:
```typescript
it('processes import job, links transfers, updates job status, and dedups', async () => {
  const csvContent = 'Data transakcji;Opis;Kwota\n2026-06-01;T1;-150,00\n...';
  const { job_id, msg_id } = await enqueueImportJob({
    account_id: accountId,
    csv_content: csvContent,
    bank_format: 'ing',
    userId,
  });

  // Read from PGMQ
  const messages = await sql`SELECT * FROM pgmq.read('import_queue', 300, 1)`;
  const msg = messages[0];
  const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;

  // Direct function call
  const result = await processJob(payload);
  expect(result.processed).toBe(3);
  expect(result.errors).toHaveLength(0);

  // Verify user_id via SQL
  const txsWithUser = await sql`
    SELECT DISTINCT user_id FROM transactions WHERE account_id = ${accountId}
  `;
  expect(txsWithUser.every(t => t.user_id === userId)).toBe(true);
});
```

**D-09 cross-user account rejection pattern:** Use User B's account_id + User A's userId. Call `processJob`, verify `{ processed: 0, errors: [...] }` (skip behavior, not throw). This is the Phase 8 D-01 skip pattern — verify the function returns zero processed rather than throwing.

**D-11 PGMQ routing pattern:** Enqueue messages for both users with distinct account_ids. Read both from PGMQ, verify each `processJob()` call processes the correct user's data. Use `describe('PGMQ routing', ...)` for the single PGMQ scenario.

---

### `tests/insights-worker.test.ts` (test, event-driven + CRUD) — EXTEND

**Action:** Add `describe('Insights Worker Per-User Isolation', ...)` block after existing test block.

**Analog:** Self — existing file `tests/insights-worker.test.ts` lines 1-243

**Existing imports** (lines 1-11) — unchanged, add User B setup in beforeAll:
```typescript
import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';
import {
  computeInsightDedupHash,
  sanitizePromptText,
  buildForecastPrompt,
  processAnalysisMessage,
  recoverStuckInsightJobs,
} from '../src/workers/insights-worker';
import { insertInsightBatch, enqueueAnalysisJob } from '../src/core/insights/use-cases';
```

**Need to add in beforeAll:** Create a second user, seed transactions for both with distinct data, note user IDs for verification.

**Full queue round-trip pattern** (existing lines 169-204) — pattern for D-10 scoped window regression:
```typescript
it('performs full queue round-trip and inserts insights', async () => {
  const { msg_id } = await enqueueAnalysisJob(userId);
  expect(msg_id).toBeGreaterThan(0);

  const messages = await sql`SELECT * FROM pgmq.read('analysis_queue', 300, 1)`;
  expect(messages).toHaveLength(1);
  const msg = messages[0];

  await processAnalysisMessage(msg);

  await sql`SELECT pgmq.archive('analysis_queue', ${msg.msg_id}::bigint)`;

  const insights = await sql`
    SELECT * FROM insights WHERE user_id = ${userId} ORDER BY type
  `;
  expect(insights.length).toBeGreaterThanOrEqual(1);
});
```

**D-10 isolation pattern:** Seed transactions for both users → run `processAnalysisMessage` for User A only → verify insights table contains entries only for User A (not User B) → verify `getInsightDataWindow(userId)` returns only User A's transactions (regression for Phase 8 D-09 fix).

---

### `tests/migration-rollback.test.ts` (test, schema-migration) — CREATE

**Analog:** `tests/schema-migration.test.ts` lines 58-285 (information_schema assertions, UNIQUE constraint testing, pg_indexes queries)
**Analog:** `src/infrastructure/db/migrate.ts` lines 1-29 (programmatic runner() pattern)

**Imports pattern** (derived from schema-migration.test.ts lines 1-2 + migrate.ts line 1):
```typescript
import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { runner } from 'node-pg-migrate';
import sql from '../src/infrastructure/db/client';
```

**programmatic runner() pattern** (derived from migrate.ts lines 14-22):
```typescript
await runner({
  databaseUrl: process.env.DATABASE_URL!,
  dir: 'src/infrastructure/db/migrations',
  direction: 'up',           // or 'down'
  count: 4,                  // roll back/forward 4 migrations (008-011)
  migrationsTable: 'pgmigrations',
  migrationFileLanguage: 'sql',
  log: () => {},             // silence in test
});
```

**Column existence via information_schema pattern** (from schema-migration.test.ts lines 73-81):
```typescript
const result = await sql`
  SELECT column_name, data_type, is_nullable
  FROM information_schema.columns
  WHERE table_name = ${table} AND column_name = 'user_id'
`;
expect(result.length).toBe(1);
expect(result[0].data_type).toBe('text');
expect(result[0].is_nullable).toBe('NO');
```

**FK constraint via information_schema pattern** (from schema-migration.test.ts lines 84-96):
```typescript
const result = await sql`
  SELECT tc.constraint_name, tc.constraint_type
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  WHERE tc.table_name = ${table}
    AND kcu.column_name = 'user_id'
    AND tc.constraint_type = 'FOREIGN KEY'
`;
expect(result.length).toBe(1);
```

**UNIQUE constraint via error catching pattern** (from schema-migration.test.ts lines 122-133):
```typescript
let threw = false;
try {
  await sql`INSERT INTO categories (name, user_id) VALUES ('test-cat-unique-a', ${TEST_USER})`;
} catch (err) { threw = true; }
expect(threw).toBe(true);  // Duplicate blocked by UNIQUE
```

**Composite index via pg_indexes pattern** (from schema-migration.test.ts lines 246-254):
```typescript
const result = await sql`
  SELECT indexname, indexdef
  FROM pg_indexes
  WHERE tablename = 'categories'
    AND indexdef LIKE '%user_id%name%'
`;
expect(result.length).toBeGreaterThan(0);
```

**Standalone lifecycle for rollback** (derived from D-13 through D-17 + RESEARCH.md):
```typescript
beforeAll(async () => {
  // Ensure all migrations applied
  await runner({ ... direction: 'up', log: () => {} });
});

// Block 1: Assert up state (D-14)
describe('After up migration', () => {
  it('user_id columns exist on all domain tables', async () => { /* information_schema */ });
  it('composite UNIQUE(user_id, name) exists on categories', async () => { /* constraint query */ });
  it('composite indexes exist', async () => { /* pg_indexes */ });
  it('test data with user_id is accessible', async () => { /* D-16: insert, verify */ });
});

// Block 2: Run down, assert down state
describe('After down migration', () => {
  beforeAll(async () => {
    await runner({ ... direction: 'down', count: 4, log: () => {} });
  });

  it('user_id columns removed from all domain tables', async () => { /* expect length 0 */ });
  it('global UNIQUE constraints restored', async () => { /* e.g. UNIQUE(name) */ });
  it('no orphan constraints remain', async () => { /* D-17: pg_indexes NOT LIKE user_id */ });
  it('data integrity: documented data loss after destructive down', async () => { /* D-16 */ });
});

afterAll(async () => {
  // CRITICAL: Restore all migrations
  await runner({ ... direction: 'up', log: () => {} });
});
```

**D-17 no orphan constraints pattern** (derived from RESEARCH.md Example 6):
```typescript
// No user_id columns remain
for (const table of ['accounts', 'categories', 'transactions', 'monthly_opening_balances', 'assets', 'import_jobs']) {
  const cols = await sql`
    SELECT column_name FROM information_schema.columns
    WHERE table_name = ${table} AND column_name = 'user_id'
  `;
  expect(cols.length).toBe(0);
}

// No composite indexes mentioning user_id
const idxResult = await sql`
  SELECT indexname, indexdef FROM pg_indexes
  WHERE tablename IN ('accounts', 'categories', 'transactions',
                      'monthly_opening_balances', 'assets', 'import_jobs')
    AND indexdef LIKE '%user_id%'
`;
expect(idxResult.length).toBe(0);
```

---

## Shared Patterns

### Two-User Signup via `auth.api.signUpEmail()`
**Source:** `tests/api-scoping.test.ts` lines 20-68
**Apply to:** `tests/concurrent-isolation.test.ts` (CREATE), worker extension files (User B setup)
```typescript
const res = await auth.api.signUpEmail({
  body: { email, password, name },
  asResponse: true,
});
const cookie = res.headers.get('set-cookie');
if (!cookie) throw new Error('No session cookie');
```

### API Test Pattern via `app.request()`
**Source:** `tests/api-scoping.test.ts` lines 77-103
**Apply to:** `tests/concurrent-isolation.test.ts`, pagination/filter/bulk groups in api-scoping.test.ts
```typescript
const res = await app.request('/path', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', Cookie: sessionCookie },
  body: JSON.stringify({ ... }),
});
expect(res.status).toBe(201);
const json = await res.json();
```

### Direct Worker Function Invocation (hybrid approach)
**Source:** `tests/import-worker.test.ts` lines 90-163, `tests/insights-worker.test.ts` lines 169-204
**Apply to:** Worker isolation extension tests (D-08, D-09, D-10)
```typescript
// Direct call — skip PGMQ for speed
const result = await processJob(payload);
expect(result.processed).toBe(N);
```

### Cross-User 404 Assertion
**Source:** `tests/api-scoping.test.ts` lines 194-199
**Apply to:** `tests/concurrent-isolation.test.ts` (D-06), worker isolation tests
```typescript
const res = await app.request(`/resource/${otherUsersId}`, {
  headers: { Cookie: mySession },
});
expect(res.status).toBe(404);
```

### SQL SELECT for user_id Verification
**Source:** `tests/api-scoping.test.ts` lines 97-102
**Apply to:** All extension files verifying user_id tagging
```typescript
const [row] = await sql`SELECT user_id FROM transactions WHERE id = ${id}`;
const ownerId = (await sql`SELECT id FROM "user" WHERE email = ${EMAIL}`)[0].id;
expect(row.user_id).toBe(ownerId);
```

### Information Schema Assertions
**Source:** `tests/schema-migration.test.ts` lines 72-98, 246-285
**Apply to:** `tests/migration-rollback.test.ts`
```typescript
// Column existence
const result = await sql`SELECT column_name FROM information_schema.columns WHERE table_name = ${table} AND column_name = 'user_id'`;
expect(result.length).toBe(1);

// Constraint existence
const constraintResult = await sql`
  SELECT tc.constraint_name FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
  WHERE tc.table_name = ${table} AND kcu.column_name = 'user_id' AND tc.constraint_type = 'FOREIGN KEY'
`;

// Index query
const idxResult = await sql`SELECT indexname, indexdef FROM pg_indexes WHERE tablename = ${table} AND indexdef LIKE '%user_id%'`;
```

### Mock OpenRouter Server
**Source:** `tests/import-worker.test.ts` lines 44-78, `tests/insights-worker.test.ts` lines 76-127
**Apply to:** Worker isolation extension tests (reuse existing mock, add second user data)
```typescript
mockServer = Bun.serve({
  port: 0,
  async fetch(req) {
    if (url.pathname === '/chat/completions') {
      return new Response(JSON.stringify({
        choices: [{ message: { content: JSON.stringify({ transactions: [...] }) } }],
      }), { headers: { 'Content-Type': 'application/json' }, status: 200 });
    }
    return new Response('Not found', { status: 404 });
  },
});
mockPort = mockServer.port;
process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
```

## No Analog Found

All 5 files have strong existing analogs:

| File | Role | Data Flow | Analog | Rationale |
|------|------|-----------|--------|-----------|
| `tests/api-scoping.test.ts` | test | request-response, CRUD | Self (extend) | Extending existing file with Groups 6-8 |
| `tests/concurrent-isolation.test.ts` | test | request-response + concurrent CRUD | `api-scoping.test.ts` | Same two-user signup + app.request patterns |
| `tests/import-worker.test.ts` | test | event-driven, CRUD | Self (extend) | Extending existing file with isolation block |
| `tests/insights-worker.test.ts` | test | event-driven, CRUD | Self (extend) | Extending existing file with isolation block |
| `tests/migration-rollback.test.ts` | test | schema-migration | `schema-migration.test.ts` | Same information_schema + pg_indexes assertions |

## Metadata

**Analog search scope:** `tests/`, `src/infrastructure/db/`
**Files scanned:** 6 (5 test files + migrate.ts)
**Pattern extraction date:** 2026-06-07

### Key Design Decisions for Planner

1. **No shared helpers file** — Each test file independently sets up its own users (confirmed: no `tests/helpers*` exists). Copy ~50-line signup pattern between files.
2. **Migration rollback must be standalone** — Bun runs test files in parallel. Rollback test's `runner({ direction: 'down' })` mutates global schema. Must run via `bun test tests/migration-rollback.test.ts` only.
3. **Worker hybrid approach** — D-07: most tests use direct `processJob()` calls. Only one `describe` block per worker uses real PGMQ routing.
4. **Promise.allSettled not needed** — Per-promise error handling inside `.then()` suffices (capture individual failures).
5. **Module-scoped variable safety** — Within a single file, `describe` blocks run sequentially. Each `it` block within runs sequentially. Module-scoped variables are safe for sequential state sharing.
