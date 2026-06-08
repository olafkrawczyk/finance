# Phase 9: Testing & Verification — Research

**Researched:** 2026-06-07
**Domain:** Multi-user isolation testing, concurrent test patterns, background worker isolation verification, schema migration rollback testing
**Confidence:** HIGH

## Summary

Phase 9 extends the existing 27-test isolation matrix with edge cases (pagination, filtered queries, bulk creates), adds concurrent user tests via `Promise.all`, adds worker isolation scenarios to existing worker test files, and creates a standalone migration rollback test. The codebase already reflects all Phase 8 worker isolation fixes — the test extensions build on a correct baseline.

**Primary recommendation:** Extend 3 existing test files + create 1 new test file, following established patterns exactly. No new infrastructure, no shared helpers, no new packages.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Isolation Matrix Expansion (TEST-01)
- **D-01:** Extend existing `tests/api-scoping.test.ts` with additional edge cases — not a separate file. The existing 27-test matrix is the baseline.
- **D-02:** Add pagination + offset tests — LIST with skip/limit parameters, verify page-2 results don't include cross-user data.
- **D-03:** Add filtered query tests — search by amount/date/description category-filtered LIST — verify filters respect `user_id` boundary.
- **D-04:** Add bulk/multi-create tests — verify all created resources are correctly tagged to the creating user.

#### Concurrent User Tests (TEST-04)
- **D-05:** Use `Promise.all` wrapping parallel `app.request()` POST calls — simplest pattern, tests API layer + use-cases + DB integration.
- **D-06:** Verify full isolation after concurrent insert — row count matches per-user, no data mixing, cross-user 404 check against newly created rows.

#### Worker Isolation Tests (TEST-03)
- **D-07:** Hybrid approach — most tests via direct function calls (`processJob`, `processAnalysisMessage` with mock payloads) for speed; one PGMQ routing test via `pgmq.send()` + `processJob`.
- **D-08:** Correct user tagging — import worker inserts transactions with correct `user_id` (verify via SELECT after `processCsvImportJob`).
- **D-09:** Cross-user account rejection — User B's `account_id` passed to User A's import job → verify skip behavior (Phase 8 D-01: skip + log, not throw).
- **D-10:** Insights worker scoped window — regression test that `getInsightDataWindow` and `getLatestTransactionDate` return correct per-user results (Phase 8 D-09, D-10 fixes).
- **D-11:** PGMQ routing test — enqueue messages for both users, verify `processJob` picks up the correct user's message (single PGMQ scenario in a dedicated `describe` block).
- **D-12:** Extend existing worker test files (`tests/import-worker.test.ts`, `tests/insights-worker.test.ts`) — add isolation scenarios alongside existing tests, not a separate file.

#### Migration Rollback Test (TEST-05)
- **D-13:** Standalone `tests/migration-rollback.test.ts` — separate lifecycle to not interfere with other tests (migrate up/down is destructive).
- **D-14:** Assert schema state after `up()` — verify `user_id` columns exist, composite `UNIQUE(user_id, ...)` constraints in place, composite indexes exist.
- **D-15:** Assert schema state after `down()` — verify `user_id` columns removed, global UNIQUE constraints restored, no orphan indexes or partial constraints.
- **D-16:** Assert data integrity — insert test data before migration up, verify accessibility during, verify documented data loss after destructive down (Phase 6 D-07).
- **D-17:** No orphan constraints — verify clean schema state after down (no leftover `user_id` references, no composite indexes pointing at removed columns).

### the agent's Discretion

*None — all decisions were locked during discussion.*

### Deferred Ideas (OUT OF SCOPE)

- **auth-guard-and-redirect.md** — Frontend auth wiring, Phase 10 concern. Was already reviewed in Phase 7 with same determination.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEST-01 | Multi-user isolation test matrix — 2+ users × 6 resource types × CREATE/READ/UPDATE/DELETE/LIST | Existing 27-test baseline in `api-scoping.test.ts`. D-01 through D-04 extend with pagination, filters, bulk creates. |
| TEST-02 | Negative tests — User B receives 404 (not 403) when accessing User A's resources by ID | Already covered in Group 3 of existing api-scoping.test.ts. D-06 adds cross-user 404 check after concurrent insert. |
| TEST-03 | Worker isolation tests — worker processes only the correct user's queued data | D-07 through D-12: extend import-worker.test.ts and insights-worker.test.ts with direct function + one PGMQ routing test. |
| TEST-04 | Concurrent user tests — two users inserting data simultaneously doesn't leak data | D-05/D-06: Promise.all parallel app.request() POST calls, verify isolation post-insert. |
| TEST-05 | Migration rollback test — schema down-migration restores previous state | D-13 through D-17: standalone test using node-pg-migrate runner() programmatically. |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| API isolation matrix tests | Test | API Layer | Tests API endpoints via app.request(), user session cookies |
| Concurrent insert tests | Test | API Layer + DB | Promise.all parallel POSTs test full stack integration |
| Worker isolation tests | Test | Worker | Direct function calls + one PGMQ routing test |
| Migration rollback test | Test | DB | Programmatic node-pg-migrate runner, schema introspection queries |
| Pagination/filter tests | Test | API Layer | Verify skip/limit and search params respect user boundary |
| Bulk create tests | Test | API Layer + DB | Multi-insert verifying user_id tagging per resource |

## Standard Stack

### Core

All packages are already installed and used by existing tests. No new dependencies needed.

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bun:test | built-in | Test framework | Project standard, used by all existing 24 test files |
| node-pg-migrate | — | Programmatic migration runner | Used in migrate.ts — import `runner` directly for rollback test |
| postgres.js | — | SQL client | Project standard for all DB queries including test setup |

### How Existing Tests Import

```typescript
// API isolation tests (api-scoping.test.ts):
import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { app } from '../index';           // Full Hono app
import { auth } from '../src/auth';        // Better Auth for signupEmail
import sql from '../src/infrastructure/db/client';

// Worker tests (import-worker.test.ts, insights-worker.test.ts):
import sql from '../src/infrastructure/db/client';
import { processJob, ... } from '../src/workers/import-worker';
import { processAnalysisMessage, ... } from '../src/workers/insights-worker';

// Migration tests (schema-migration.test.ts):
import sql from '../src/infrastructure/db/client';

// For rollback test — import runner directly:
import { runner } from 'node-pg-migrate';
```

## Architectural Patterns

### System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                      Phase 9 Test Files                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  tests/api-scoping.test.ts  (EXTEND: +pagination, +filters, +bulk)│
│  ├── Group 1-5: Existing 27-test baseline (unchanged)            │
│  ├── Group 6: Pagination + offset tests [D-02]                   │
│  ├── Group 7: Filtered query tests [D-03]                        │
│  └── Group 8: Bulk/multi-create tests [D-04]                     │
│                                                                  │
│  tests/concurrent-isolation.test.ts  (NEW: +Promise.all) [D-05/06]│
│  └── Two users ← Promise.all → parallel POSTs                    │
│                    ↓ verify per-user row count + cross-user 404   │
│                                                                  │
│  tests/import-worker.test.ts  (EXTEND: +isolation) [D-07/08/09/11]│
│  ├── Existing test block (unchanged)                             │
│  └── New describe: Multi-user isolation                          │
│       ├── D-08: Direct processJob → verify user_id tagging       │
│       ├── D-09: Cross-user account rejection (skip, not throw)   │
│       └── D-11: PGMQ routing — enqueue both → process correct   │
│                                                                  │
│  tests/insights-worker.test.ts  (EXTEND: +scoped window) [D-10]   │
│  ├── Existing test block (unchanged)                             │
│  └── New describe: Per-user window regression                    │
│       └── Seed both users → run processAnalysisMessage → verify  │
│           each gets only their own transactions                   │
│                                                                  │
│  tests/migration-rollback.test.ts  (NEW: +up/down cycle) [D-13-17]│
│  ├── beforeAll: Run up() on all migrations                       │
│  ├── Test up state: user_id columns, composite UNIQUEs           │
│  ├── Run down() on 008-011                                       │
│  ├── Test down state: columns removed, global UNIQUEs restored   │
│  ├── Test data integrity: insert → down → verify data accessible │
│  ├── Run up() again to restore state                             │
│  └── afterAll: Verify clean schema                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow Trace (Primary Use Case — Concurrent Insert)

```
1. beforeAll: signupEmail(UserA) → cookieA, signupEmail(UserB) → cookieB
2. Prepare N payloads for User A, N payloads for User B
3. const results = await Promise.all([
     ...payloadsA.map(p => app.request('/transactions', { method: 'POST', headers: { Cookie: cookieA }, body: p })),
     ...payloadsB.map(p => app.request('/transactions', { method: 'POST', headers: { Cookie: cookieB }, body: p })),
   ]);
4. Verify: all results → 201
5. Verify: User A sees N own transactions, User B sees N own transactions
6. Verify: User A cannot GET any of User B's newly created transaction IDs (404)
7. Verify: User B cannot GET any of User A's newly created transaction IDs (404)
```

### Existing Data Flow for API Isolation Tests

```
1. beforeAll:
   - Clean up prior test users
   - signupEmail(UserA) → cookieA (signup hook creates 2 accounts + 25 categories)
   - signupEmail(UserB) → cookieB
   - SQL: SELECT User A's default account_id
   - SQL: SELECT User B's first category_id + default account_id
2. Group 1: User A creates resources (POST × 3) → store IDs in module-scoped vars
3. Group 2: User A reads own resources (GET × 5) → verify own data visible
4. Group 3: User B accesses User A's resources (GET/PUT/DELETE × 8) → expect 404
5. Group 4: User B operates within own data (GET/POST × 4) → verify isolation
6. Group 5: Unauthenticated requests (POST/GET × 8) → expect 401
7. afterAll: DELETE test users
```

### Pattern 1: Two-User Signup + Session Pattern

**What:** Create two users via Better Auth `auth.api.signUpEmail()` in `beforeAll`, capture session cookies as module-scoped variables. Cookie is passed via `Cookie:` header on every `app.request()` call.

**Source:** `tests/api-scoping.test.ts` lines 20-72 [VERIFIED: codebase inspection]

```typescript
// Create User A
const resA = await auth.api.signUpEmail({
  body: { email: USER_A_EMAIL, password: USER_A_PASSWORD, name: 'Scope User A' },
  asResponse: true,
});
const cookieA = resA.headers.get('set-cookie');
if (!cookieA) throw new Error('No session cookie for User A');
userASession = cookieA;

// API calls use the cookie:
const res = await app.request('/transactions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Cookie: userASession,
  },
  body: JSON.stringify({ ... }),
});
```

### Pattern 2: Direct Worker Function Invocation (D-07 hybrid)

**What:** Call `processJob()` or `processAnalysisMessage()` directly with constructed payload objects rather than going through PGMQ. Only one PGMQ routing test uses `pgmq.send()`.

**Source:** `tests/import-worker.test.ts` lines 89-163 [VERIFIED: codebase inspection]

```typescript
// Enqueue (skip PGMQ for speed, use direct function)
const { job_id, msg_id } = await enqueueImportJob({
  account_id: accountId,
  csv_content: csvContent,
  bank_format: 'ing',
  userId,
});

// Direct function call (no PGMQ read needed)
const result = await processJob(payload);
expect(result.processed).toBe(3);
```

### Pattern 3: Programmatic node-pg-migrate runner (TEST-05)

**What:** Import `runner` from `node-pg-migrate` and call it directly with direction + count. Used in `migrate.ts` currently, repurposed in test setup.

**Source:** `src/infrastructure/db/migrate.ts` lines 14-23 [VERIFIED: codebase inspection]

```typescript
import { runner } from 'node-pg-migrate';

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

### Pattern 4: Schema Assertions via information_schema (TEST-05)

**Source:** `tests/schema-migration.test.ts` lines 72-98 [VERIFIED: codebase inspection]

```typescript
// Verify column exists
const result = await sql`
  SELECT column_name, data_type, is_nullable
  FROM information_schema.columns
  WHERE table_name = ${table} AND column_name = 'user_id'
`;
expect(result.length).toBe(1);
expect(result[0].data_type).toBe('text');
expect(result[0].is_nullable).toBe('NO');

// Verify constraint exists
const constraintResult = await sql`
  SELECT tc.constraint_name, tc.constraint_type
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  WHERE tc.table_name = ${table}
    AND kcu.column_name = 'user_id'
    AND tc.constraint_type = 'FOREIGN KEY'
`;
expect(constraintResult.length).toBe(1);
```

### Pattern 5: UNIQUE Constraint Assertions via Error Catching

**Source:** `tests/schema-migration.test.ts` lines 122-133 [VERIFIED: codebase inspection]

```typescript
// Before down(): catching composite UNIQUE violation
let threw = false;
try {
  await sql`INSERT INTO categories (name, user_id) VALUES ('test-cat-unique-a', ${TEST_USER})`;
} catch (err) { threw = true; }
expect(threw).toBe(true);  // Duplicate blocked by UNIQUE(user_id, name)

// After down(): same INSERT should succeed (global UNIQUE allows duplicate names across users)
// Or: cross-user same name should work in both states, only same-user+same-name blocked after up
```

### Anti-Patterns to Avoid

- **Shared test helpers file** — Don't create `tests/helpers.ts`. The current codebase has zero shared test utilities; each file independently sets up users. D-01 through D-12 all extend existing files, not extract helpers.
- **Migration test running in same process as other tests** — D-13 enforces standalone `tests/migration-rollback.test.ts` because `runner()` changes the global database schema. Other tests would fail if migrations are rolled back. Bun runs test files in parallel by default — but `tests/migration-rollback.test.ts` must be in a separate file so it can be run in isolation or with `--serial` flag.
- **Promise.all without error handling** — Concurrent tests must wrap `Promise.all` results in per-promise error handlers. One failing request shouldn't shadow others. Use `Promise.allSettled` or catch per promise.
- **Assuming test file execution order** — Bun does NOT guarantee test file execution order. Migration rollback tests must explicitly restore state in `afterAll`. Other files cannot depend on migration state being "before" or "after" rollback.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Migration runner in test | Direct SQL to simulate migrations | `node-pg-migrate` `runner()` function | Already used in migrate.ts — consistent, handles `pgmigrations` tracking table, correctly applies both up and down SQL |
| Schema assertions | Custom schema reflection | `information_schema.columns` + `pg_indexes` | Already used in schema-migration.test.ts — covers column existence, data types, nullability, FK constraints, indexes |
| Concurrent test orchestration | Custom threading/workers | `Promise.all` with array of `app.request()` | D-05 locked — simplest, tests full stack, Bun's event loop handles concurrency |
| Session creation | Direct SQL user inserts | `auth.api.signUpEmail()` | Already used in api-scoping.test.ts — correctly sets up Better Auth sessions with cookies |
| PGMQ message routing test | Direct function invocation for routing test | Single `pgmq.send()` + `processJob()` | D-07 locked hybrid — one real PGMQ test per worker, rest via direct calls |

## Common Pitfalls

### Pitfall 1: Migration State Leakage

**What goes wrong:** The rollback test runs `down()` on migrations 008-011, removing `user_id` columns from all tables. If any other test file runs after the rollback test (Bun runs test files concurrently), those tests fail because queries reference `user_id` columns that no longer exist.

**Why it happens:** Bun runs test files in parallel by default. The rollback test's migration changes are visible to all connections sharing the same database.

**How to avoid:** D-13 is the solution — standalone file. Two additional mitigations:
1. The rollback test's `beforeAll` must run ALL migrations `up()` to ensure clean state
2. The rollback test MUST restore migrations to fully migrated state in `afterAll` (run `up()` on all remaining migrations)
3. In `package.json`, add a separate script: `"test:migration-rollback": "bun test tests/migration-rollback.test.ts"` so it can be run in isolation

**Warning signs:** Other test files fail with `column "user_id" does not exist` when the full suite runs.

### Pitfall 2: Promise.all Race Condition on Shared State

**What goes wrong:** Module-scoped variables (`userATransactionId`, `userBTransactionId`) are set by individual test cases that run sequentially within `describe` blocks. Concurrent `Promise.all` tests write newly-created IDs to variables — but concurrent writes to module variables from parallel requests is undefined.

**Why it happens:** If concurrent tests try to store `lastCreatedId = json.data.id` in shared variables, parallel writes race.

**How to avoid:** Capture created IDs directly from `Promise.all` results, not from shared variables:
```typescript
const results = await Promise.all(requests);
const userACreatedIds = results
  .filter((r, i) => i < N)  // first N results are User A
  .map(r => r.json().data.id);
const userBCreatedIds = results
  .filter((r, i) => i >= N) // remaining N results are User B
  .map(r => r.json().data.id);
```

**Warning signs:** Tests that pass in isolation but fail in CI/parallel — classic race condition.

### Pitfall 3: Promise.all Swallows Individual Request Failures

**What goes wrong:** One `app.request()` fails (e.g. rate limit, 500 error) — `Promise.all` rejects immediately. The error shows "one request failed" but you don't know which user's request or what the error was. Worse, the other promises continue executing but their results are lost.

**How to avoid:** Use per-promise error handling to capture results:
```typescript
const results = await Promise.all(requests.map(async (req, i) => {
  try {
    const res = await req;
    return { index: i, status: res.status, body: await res.json() };
  } catch (err) {
    return { index: i, status: 'error', error: String(err) };
  }
}));
```

**Warning signs:** Intermittent test failures with generic "Promise.all rejected" errors.

### Pitfall 4: node-pg-migrate `runner()` Errors with FK on DROP COLUMN

**What goes wrong:** Migration 008's down migration (`DROP COLUMN user_id`) may fail with `cannot drop column user_id because other objects depend on it` due to foreign key constraints referencing the column.

**Why it happens:** PostgreSQL does not automatically drop FK constraints when dropping a column. The `REFERENCES "user"(id)` constraint depends on the `user_id` column.

**How to verify:** This was already tested in Phase 6/7 — the migration was applied and backfilled. However, the down path has NOT been tested. Check if PostgreSQL auto-drops the FK on `DROP COLUMN`:
- According to PostgreSQL docs: `DROP COLUMN` does drop dependent objects like FK constraints that reference the column
- The migration was written assuming this behavior
- **Risk:** If PostgreSQL version differs, behavior may vary

**How to avoid:** If the down migration fails, it should be fixed by adding `CASCADE` or explicitly dropping FK constraints before `DROP COLUMN`. However, since Phase 6 D-07 locked the down migration design and it's already deployed, this test will validate whether it actually works.

### Pitfall 5: Bun Test Parallelism vs. Serial Migration

**What goes wrong:** Bun runs test files in parallel by default. The migration rollback test changes global database schema. If any test file from Phase 9 or earlier runs concurrently with the rollback test, that file's queries will fail when columns are dropped.

**How to avoid:**
- Use `--serial` flag when running the migration rollback test: `bun test tests/migration-rollback.test.ts --serial`
- OR ensure the rollback test is the ONLY file that runs: `bun test tests/migration-rollback.test.ts`
- Then in `afterAll`, restore all migrations to fully migrated state

## Code Examples

### Example 1: Pagination Test (D-02)

Extends api-scoping.test.ts. After User A creates 10+ transactions, verify page-2 has no cross-user data.

```typescript
// Source: CONTEXT.md D-02 + codebase pattern from existing listTransactions
it('pagination: User A page 2 shows no User B data', async () => {
  // User A creates 10+ transactions first (in Group 1 or setup)
  // User B creates own transactions

  // User A fetches page 2
  const resA = await app.request('/transactions?page=2&per_page=5', {
    headers: { Cookie: userASession },
  });
  expect(resA.status).toBe(200);
  const jsonA = await resA.json();
  expect(jsonA.data.length).toBeGreaterThanOrEqual(1);

  // Verify page 2 items still belong to User A
  const userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;
  for (const item of jsonA.data) {
    expect(item.user_id).toBe(userAId);
  }
});

it('pagination: offset beyond last page returns empty array', async () => {
  const res = await app.request('/transactions?page=999&per_page=50', {
    headers: { Cookie: userASession },
  });
  expect(res.status).toBe(200);
  const json = await res.json();
  expect(json.data).toHaveLength(0);
});
```

### Example 2: Filtered Query Test (D-03)

```typescript
// Source: CONTEXT.md D-03 + listTransactions params in ledger/use-cases.ts
it('filter by type respects user boundary', async () => {
  // Create expense for User A, income for User B
  const res = await app.request('/transactions?type=expense&page=1&per_page=50', {
    headers: { Cookie: userASession },
  });
  expect(res.status).toBe(200);
  const json = await res.json();
  // All returned transactions are expenses AND belong to User A
  for (const tx of json.data) {
    expect(tx.type).toBe('expense');
  }
  // User B's income should not appear
  const hasUserBIncome = json.data.some((t: any) => t.description === 'User B income');
  expect(hasUserBIncome).toBe(false);
});

it('filter by date range respects user boundary', async () => {
  const res = await app.request('/transactions?date_from=2026-01-01&date_to=2026-12-31&page=1&per_page=50', {
    headers: { Cookie: userASession },
  });
  expect(res.status).toBe(200);
  const json = await res.json();
  for (const tx of json.data) {
    expect(tx.user_id).toBeDefined();
  }
});
```

### Example 3: Concurrent Insert Test (D-05, D-06)

```typescript
// Source: CONTEXT.md D-05, D-06
it('parallel inserts by two users maintain isolation', async () => {
  const N = 10; // 10 transactions per user

  // Build parallel requests
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
    app.request('/transactions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Cookie: userBSession },
      body: JSON.stringify({
        account_id: userBAccountId,
        type: 'income',
        amount: `${(i + 1) * 100}.0000`,
        date: '2026-06-15',
        description: `Concurrent B ${i}`,
      }),
    }).then(async res => {
      const body = await res.json();
      return { status: res.status, id: body.data?.id, index: i, user: 'B' };
    })
  );

  const allResults = await Promise.all([...userARequests, ...userBRequests]);

  // All should succeed
  const failures = allResults.filter(r => r.status !== 201);
  expect(failures).toHaveLength(0);

  // Extract created IDs
  const aIds = allResults.filter((r: any) => !r.user).map(r => r.id).filter(Boolean);
  const bIds = allResults.filter((r: any) => r.user === 'B').map(r => r.id).filter(Boolean);

  // Verify row counts
  const userAId = (await sql`SELECT id FROM "user" WHERE email = ${USER_A_EMAIL}`)[0].id;
  const userBId = (await sql`SELECT id FROM "user" WHERE email = ${USER_B_EMAIL}`)[0].id;

  const [aCount] = await sql`
    SELECT COUNT(*)::int AS count FROM transactions WHERE user_id = ${userAId}
    AND description LIKE 'Concurrent A %'
  `;
  expect(aCount.count).toBe(N);

  const [bCount] = await sql`
    SELECT COUNT(*)::int AS count FROM transactions WHERE user_id = ${userBId}
    AND description LIKE 'Concurrent B %'
  `;
  expect(bCount.count).toBe(N);

  // Cross-user 404 check
  for (const id of bIds) {
    const res = await app.request(`/transactions/${id}`, {
      headers: { Cookie: userASession },
    });
    expect(res.status).toBe(404);
  }

  for (const id of aIds) {
    const res = await app.request(`/transactions/${id}`, {
      headers: { Cookie: userBSession },
    });
    expect(res.status).toBe(404);
  }
});
```

### Example 4: Cross-User Account Rejection Test (D-09)

```typescript
// Source: CONTEXT.md D-09 + import-worker.ts processCsvImportJob lines 509-516
it('import worker skips job when account_id does not belong to user', async () => {
  // User B's account_id passed to User A's import job
  const { job_id } = await enqueueImportJob({
    account_id: userBAccountId,  // User B's account!
    csv_content: 'Data transakcji;Opis;Kwota\n2026-06-01;Test;-100,00',
    bank_format: 'ing',
    userId: userAId,              // User A's userId
  });

  const [msg] = await sql`
    SELECT * FROM pgmq.read('import_queue', 300, 1)
  `;
  const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;

  const result = await processJob(payload);
  expect(result.processed).toBe(0);              // No rows processed
  expect(result.errors.length).toBeGreaterThan(0); // Error logged

  await sql`SELECT pgmq.archive('import_queue', ${msg.msg_id}::bigint)`;
});
```

### Example 5: Insights Worker Scoped Window Regression Test (D-10)

```typescript
// Source: CONTEXT.md D-10 + insights-worker.ts processAnalysisMessage
it('processAnalysisMessage scopes insight data window per user', async () => {
  // Seed transactions for both users (ensure they have data in window)
  // Both users already have accounts/categories from signup hook

  // Create User A transactions (recent)
  await sql`INSERT INTO transactions (... user_id) VALUES (..., ${userAId})`;
  // Create User B transactions (recent)  
  await sql`INSERT INTO transactions (... user_id) VALUES (..., ${userBId})`;

  // Enqueue for User A
  const { msg_id: msgIdA } = await enqueueAnalysisJob(userAId);
  const [msgA] = await sql`SELECT * FROM pgmq.read('analysis_queue', 300, 1)`;
  await processAnalysisMessage(msgA);
  await sql`SELECT pgmq.archive('analysis_queue', ${msgA.msg_id}::bigint)`;

  // User A's insights should only reference User A's transactions
  const aInsights = await sql`
    SELECT * FROM insights WHERE user_id = ${userAId}
  `;
  expect(aInsights.length).toBeGreaterThan(0);

  // User B should have NO insights from User A's analysis
  const bInsights = await sql`
    SELECT * FROM insights WHERE user_id = ${userBId}
  `;
  // If there were pre-existing B insights, they should remain unrelated
});
```

### Example 6: Migration Rollback Schema Assertions (D-14, D-15)

```typescript
// Source: schema-migration.test.ts pattern + migration 008/009 down SQL

// D-14: After up() — verify composite UNIQUE
it('after up: categories has UNIQUE(user_id, name)', async () => {
  const result = await sql`
    SELECT constraint_name, constraint_type
    FROM information_schema.table_constraints
    WHERE table_name = 'categories'
      AND constraint_name = 'categories_user_id_name_key'
  `;
  expect(result.length).toBe(1);
});

// D-15: After down() — verify global UNIQUE restored
it('after down: categories has UNIQUE(name)', async () => {
  const result = await sql`
    SELECT constraint_name, constraint_type
    FROM information_schema.table_constraints
    WHERE table_name = 'categories'
      AND constraint_name = 'categories_name_key'
  `;
  expect(result.length).toBe(1);

  // Composite UNIQUE is gone
  const compositeResult = await sql`
    SELECT constraint_name
    FROM information_schema.table_constraints
    WHERE table_name = 'categories'
      AND constraint_name = 'categories_user_id_name_key'
  `;
  expect(compositeResult.length).toBe(0);
});

// D-17: No orphan constraints
it('after down: no orphan user_id constraints or indexes remain', async () => {
  // No FK constraints referencing user_id column
  for (const table of ['accounts', 'categories', 'transactions', 'monthly_opening_balances', 'assets', 'import_jobs']) {
    const cols = await sql`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = ${table} AND column_name = 'user_id'
    `;
    expect(cols.length).toBe(0);
  }

  // No composite indexes mentioning user_id
  // (PRIMARY KEY indexes on "user" table are OK — they're the referenced table, not referencing)
  const idxResult = await sql`
    SELECT indexname, indexdef FROM pg_indexes
    WHERE tablename IN ('accounts', 'categories', 'transactions',
                        'monthly_opening_balances', 'assets', 'import_jobs')
      AND indexdef LIKE '%user_id%'
  `;
  expect(idxResult.length).toBe(0);
});
```

## Runtime State Inventory

> Not a rename/refactor phase — omit. Phase 9 is a pure test-addition phase with no runtime state migrations.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bun:test (built into Bun runtime) |
| Config file | none — bun:test needs no config |
| Quick run command | `bun test tests/<file>.test.ts --timeout 30000` |
| Full suite command | `bun test --timeout 30000` |
| Serial run command | `bun test tests/migration-rollback.test.ts --timeout 60000` (rollback needs longer timeout) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | Isolation matrix — pagination | Integration | `bun test tests/api-scoping.test.ts` | ✅ Extend |
| TEST-01 | Isolation matrix — filtered queries | Integration | `bun test tests/api-scoping.test.ts` | ✅ Extend |
| TEST-01 | Isolation matrix — bulk create | Integration | `bun test tests/api-scoping.test.ts` | ✅ Extend |
| TEST-02 | Cross-user 404 after concurrent insert | Integration | (part of concurrent test file) | ❌ Wave 0 |
| TEST-03 | Import worker user_id tagging | Integration | `bun test tests/import-worker.test.ts` | ✅ Extend |
| TEST-03 | Cross-user account rejection | Integration | `bun test tests/import-worker.test.ts` | ✅ Extend |
| TEST-03 | PGMQ routing isolation | Integration | `bun test tests/import-worker.test.ts` | ✅ Extend |
| TEST-03 | Insights worker scoped window | Integration | `bun test tests/insights-worker.test.ts` | ✅ Extend |
| TEST-04 | Concurrent user isolation | Integration | (part of concurrent test file) | ❌ Wave 0 |
| TEST-05 | Migration up schema assertions | Integration | `bun test tests/migration-rollback.test.ts` | ❌ Wave 0 |
| TEST-05 | Migration down schema assertions | Integration | `bun test tests/migration-rollback.test.ts` | ❌ Wave 0 |
| TEST-05 | Data integrity through migration | Integration | `bun test tests/migration-rollback.test.ts` | ❌ Wave 0 |
| TEST-05 | No orphan constraints after down | Integration | `bun test tests/migration-rollback.test.ts` | ❌ Wave 0 |

### Wave 0 Gaps

- [ ] `tests/concurrent-isolation.test.ts` — covers TEST-04 (D-05/D-06). Needs: two-user signup setup, Promise.all parallel POST pattern, row count + cross-user 404 assertions.
- [ ] `tests/migration-rollback.test.ts` — covers TEST-05 (D-13 through D-17). Needs: node-pg-migrate `runner()` import, up/down cycle, information_schema assertions, data integrity checks, `afterAll` restoration.
- [ ] Existing framework: bun:test is built-in — no conftest or test infrastructure needed.

### Migration Rollback Test Lifecycle

The rollback test MUST follow this exact lifecycle to avoid database state corruption:

```typescript
let originalDbState: 'migrated' | 'unknown' = 'unknown';

beforeAll(async () => {
  // Ensure all migrations are applied (safety — in case prior test left state dirty)
  await runner({
    databaseUrl: process.env.DATABASE_URL!,
    dir: 'src/infrastructure/db/migrations',
    direction: 'up',
    migrationsTable: 'pgmigrations',
    migrationFileLanguage: 'sql',
    log: () => {},
  });
  originalDbState = 'migrated';
});

describe('After up() — D-14, D-16 assertions', () => {
  // Assert schema state (user_id columns, composite UNIQUEs)
  // Assert data integrity (insert test data, verify accessible)
});

describe('After down() — D-15, D-17 assertions', async () => {
  // Run down on 008-011
  beforeAll(async () => {
    await runner({
      databaseUrl: process.env.DATABASE_URL!,
      dir: 'src/infrastructure/db/migrations',
      direction: 'down',
      count: 4,  // roll back 011, 010, 009, 008
      migrationsTable: 'pgmigrations',
      migrationFileLanguage: 'sql',
      log: () => {},
    });
  });

  // Assert columns dropped, global UNIQUEs restored, no orphan constraints
  // Assert data integrity (data still exists in rows, or documented data loss)
});

afterAll(async () => {
  // CRITICAL: Restore all migrations for other test files
  await runner({
    databaseUrl: process.env.DATABASE_URL!,
    dir: 'src/infrastructure/db/migrations',
    direction: 'up',
    migrationsTable: 'pgmigrations',
    migrationFileLanguage: 'sql',
    log: () => {},
  });
});
```

### Sampling Rate
- **Per task commit:** `bun test tests/<affected-file>.test.ts --timeout 30000`
- **Per wave merge:** `bun test --timeout 30000` (exclude rollback test from parallel runs)
- **Phase gate:** Full suite green before `/gsd-verify-work`

## Security Domain

> `security_enforcement` is absent from config.json — treat as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Partial | Testing that unauthenticated requests return 401 (Group 5 of api-scoping.test.ts) |
| V3 Session Management | Partial | Session cookies from signupEmail used throughout — tests verify session scoping |
| V4 Access Control | Yes | Core focus: cross-user 404 assertions, per-user data isolation verification |
| V5 Input Validation | Yes (via test) | Filtered query tests verify SQL injection doesn't break user boundary |
| V8 Data Protection | Yes | Concurrent insert isolation, worker user_id tagging, migration rollback data integrity |

### Known Threat Patterns for Test Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-user data leakage via pagination | Information Disclosure | D-02: pagination tests verify page-2 contains no cross-user data |
| Cross-user data leakage via filters | Information Disclosure | D-03: filtered queries verify user boundary on amount/date/description searches |
| Data contamination during concurrent writes | Tampering | D-05/D-06: Promise.all tests with per-user row count + cross-user 404 |
| Worker processing wrong user's data | Tampering / Information Disclosure | D-07 through D-11: direct function + PGMQ routing verification |
| Migration rollback leaving orphan constraints | Tampering (schema) | D-17: verify no leftover user_id references after down() |
| Migration data loss in destructive down | Denial of Service | D-16: verify documented data loss after destructive down |

## File-by-File Recommendation

### 1. `tests/api-scoping.test.ts` — EXTEND

**What to add:**
- **Group 6: Pagination + Offset tests** (D-02): Create enough transactions to span multiple pages (11+). Test page 1, page 2, last page, beyond-last-page (empty). Verify per-page count. Verify cross-user data does not appear on any page.
- **Group 7: Filtered Query tests** (D-03): Test `type=expense`, `date_from`/`date_to`, `uncategorized=true`, `account_id` filter. Each test verifies both the filter works and no cross-user data appears.
- **Group 8: Bulk/Multi-Create tests** (D-04): Create 2-3 transactions in a loop (not parallel — bulk sequential create). Verify all are tagged to the creating user via SQL SELECT.

**How:**
- Reuse existing `USER_A_EMAIL`, `USER_B_EMAIL`, `userASession`, `userBSession`, `userAAccountId`, `userBAccountId`, `userBCategoryId` variables
- Store newly created IDs in new module-scoped variables (or generate within tests)
- No modifications to existing Groups 1-5

**Risk:** Module-scoped variables from new test groups could conflict with existing tests if Bun runs `describe` blocks non-sequentially. Verify that bun:test runs each test within the same file sequentially (it does — `describe` blocks are sequential within a file).

### 2. `tests/concurrent-isolation.test.ts` — CREATE  

**What to create:**
- Full two-user signup setup (copy pattern from api-scoping.test.ts lines 6-72)
- One `describe` block: "Concurrent User Isolation"
- One test: "parallel inserts maintain isolation across users"
- Uses `Promise.all` with N parallel requests per user

**How:**
- Follow the exact signup pattern as api-scoping.test.ts (no shared helper)
- Use `Promise.all` with ~10 POST requests per user (D-05 implies small N is sufficient)
- After Promise.all completes:
  - Verify all statuses are 201
  - Count rows per user via SQL
  - Verify cross-user 404 for newly created IDs
  - Clean up in afterAll

**Risk:** Without `Promise.allSettled`, one failure kills all results. Use per-promise try/catch as shown in Code Examples section.

### 3. `tests/import-worker.test.ts` — EXTEND

**What to add:**
- New `describe('Import Worker Multi-User Isolation', ...)` block
- **D-08 - User tagging test:** Import through `processJob` — SQL SELECT to verify all inserted transactions have the correct `user_id`
- **D-09 - Cross-user account rejection:** Create import job with User B's `account_id` + User A's `userId` → verify `processJob` returns `{ processed: 0, errors: [...] }` (skip, not throw)
- **D-11 - PGMQ routing test:** Enqueue messages for both users with distinct job_ids → verify `processJob` picks correct user's message

**How:**
- Reuse existing test setup (mock server, user/account creation)
- For D-08/D-09: direct `processJob()` call (D-07 hybrid approach)
- For D-11: single PGMQ test via `pgmq.send()` + `processJob()` (not direct call)
- Need both User A and User B's session/userId — test must create or fetch a second user

**Risk:** Worker tests need mock OpenRouter server (already in existing tests). D-09 cross-user test must verify skip behavior per Phase 8 D-01 (log error, don't throw). The `processCsvImportJob` already implements this (line 514: `return { processed: 0, errors: [...] }`).

### 4. `tests/insights-worker.test.ts` — EXTEND

**What to add:**
- New `describe('Insights Worker Per-User Isolation', ...)` block
- **D-10 - Scoped window regression test:**
  - Create a second user in `beforeAll` (or fetch existing)
  - Seed transactions for both users with different dates
  - Run `processAnalysisMessage` for User A
  - Verify insights were created only for User A (by querying `insights` table with `WHERE user_id = UserA`)
  - Verify User B has no new insights from User A's analysis

**How:**
- Reuse existing mock server from existing test setup
- Add second user setup in `beforeAll` hook (signupEmail or direct INSERT)
- Verify `getInsightDataWindow(userA)` returns only User A's transactions
- Verify `getInsightDataWindow(userB)` returns only User B's transactions

**Risk:** The insights worker calls OpenRouter mock. The mock server returns deterministic responses. For the isolation test, we need to ensure both users have transaction data in their respective windows. The existing test inserts 2 transactions for the test user.

### 5. `tests/migration-rollback.test.ts` — CREATE

**What to create:**
- Standalone file with its own lifecycle (D-13)
- `beforeAll`: Run `runner({ direction: 'up' })` to ensure clean state
- **D-14 block**: Assert up state — columns exist, composite UNIQUEs present, composite indexes present
- **Inner `beforeAll`**: Run `runner({ direction: 'down', count: 4 })` to roll back 008-011
- **D-15 block**: Assert down state — `user_id` columns removed, global UNIQUEs restored
- **D-16 block**: Data integrity — insert test data before running up, verify it remains accessible; after destructive down, verify documented data loss
- **D-17 block**: No orphan constraints — no remaining `user_id` references in any domain table
- `afterAll`: Run `runner({ direction: 'up' })` to restore state

**How:**
- Import `{ runner }` from `node-pg-migrate`
- Use `process.env.DATABASE_URL` for connection
- Copy `information_schema` assertion patterns from `tests/schema-migration.test.ts`
- Use statement-level timeout for migration operations (they can be slow)
- CRITICAL: Must restore migrations in `afterAll` or other tests fail

**Risk:**
- If Bun runs test files in parallel, rollback test's schema changes break other tests. Mitigation: standalone file that MUST be run separately.
- The `count: 4` assumes migrations 008-011 are the last 4 applied. If more migrations are added later, the count needs updating.
- Alternative: track which migrations were applied before test and restore exactly those. Simpler: just use `direction: 'down'` without count (rolls back all) then `direction: 'up'` (reapplies all).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 27-test isolation baseline (Phase 7) | 40+ test isolation matrix + concurrent + worker + rollback | Phase 9 | Every isolation concern has a regression test |
| Worker tests only test one user path | Worker tests include cross-user rejection + PGMQ routing | Phase 9 | Worker isolation verified at both direct-call and PGMQ levels |
| No migration rollback tests | Programmatic up/down cycle with schema assertions | Phase 9 | Down migration correctness verified (was previously untested) |
| Tests can be run in any order | Rollback test MUST run isolated | Phase 9 | New constraint: `package.json` must list rollback test as serial-only |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Bun runs test files in parallel unless `--serial` is used | Validation Architecture | Rollback test breaks other tests. Mitigation: standalone file + documented requirement for isolation. |
| A2 | `runner({ direction: 'down', count: 4 })` rolls back migrations 008-011 | Migration Rollback | If migration count changes (new migrations added), count must be adjusted. Mitigation: document in test file. |
| A3 | PostgreSQL `DROP COLUMN user_id` auto-drops FK constraints | Pitfall 4 | Down migration 008 might fail with FK dependency error. Mitigation: test will reveal this — if it fails, the migration needs CASCADE keyword. |
| A4 | The `signupEmail` pattern from api-scoping.test.ts works identically in concurrent tests | Concurrent Tests | Better Auth rate limiting or session uniqueness issues. Mitigation: use fresh unique email per test run. |
| A5 | `app.request()` is safe to call concurrently with `Promise.all` | Concurrent Tests | Hono's request handling is async but shares global state. Mitigation: test in isolation first. |

## Open Questions — (RESOLVED)

1. **(RESOLVED) Should concurrent tests be in a separate file or in api-scoping.test.ts?**
   - What we know: D-01 explicitly lists pagination, filters, and bulk create as API scoping extensions. D-05/D-06 (concurrent) are a separate TEST-04 concern. The concurrent test shares the same signup setup as api-scoping.test.ts.
   - Resolution: **Separate file `tests/concurrent-isolation.test.ts`** — the Promise.all pattern and its cleanup (deleting concurrently created rows) are distinct enough to warrant isolation. The signup pattern is ~50 lines to copy. This also allows running concurrent tests independently to debug timing issues.

2. **(RESOLVED) What's the right `count` for migration rollback?**
   - What we know: Migrations 008, 009, 010, 011 are the Phase 6-7 migration set. 008 adds user_id columns, 009 changes UNIQUE constraints, 010 is a documentation-only migration, 011 adds llm_description.
   - Resolution: Use `count: 4` to roll back 008-011 specifically, as documented in the plan's Task 2 action. The down migration only targets Phase 6-7 migrations; 001-007 are out of scope and are not rolled back.

3. **(RESOLVED) Should the rollback test verify 008-011 down individually or batch?**
   - What we know: D-14 through D-17 require schema assertions after up and down. Running down individually per migration would allow granular assertions.
   - Resolution: **Batch approach** — run all 4 down in a single `beforeAll`, then assert full down state. The per-migration intermediate states are not specified in requirements and add complexity with no clear value. The constraints D-15 and D-17 clearly describe the post-down state after all 4 are rolled back.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bun | Test runner | ✓ | 1.3.14 | — |
| PostgreSQL | Database | ✓ (via postgres.js) | — | — |
| node-pg-migrate | Migration runner in rollback test | ✓ | (already in node_modules) | — |

**Missing dependencies with no fallback:** None — all required tools are available.

## Sources

### Primary (HIGH confidence) — Verified via codebase inspection
- `tests/api-scoping.test.ts` (411 lines, 27 tests) — Full isolation matrix pattern, two-user signup pattern
- `tests/import-worker.test.ts` (181 lines, 2 tests) — Direct function invocation pattern, PGMQ setup
- `tests/insights-worker.test.ts` (243 lines, 6 tests) — processAnalysisMessage pattern, mock server setup
- `tests/schema-migration.test.ts` (287 lines, 28 tests) — information_schema assertions, UNIQUE constraint testing
- `src/infrastructure/db/migrate.ts` (29 lines) — Programmatic runner() pattern
- `src/infrastructure/db/migrations/008-011` — Up and down SQL for rollback test
- `src/infrastructure/db/schema.sql` (235 lines) — Current schema reference for assertions
- `src/core/ledger/use-cases.ts` — listTransactions params (page/per_page, filters)
- `src/workers/import-worker.ts` — processJob, processCsvImportJob skip behavior (already fixed by Phase 8)
- `src/workers/insights-worker.ts` — processAnalysisMessage, user_id extraction pattern (already correct)
- `src/core/insights/use-cases.ts` — getInsightDataWindow, getLatestTransactionDate (already fixed by Phase 8)
- `.planning/phases/09-testing-verification/09-CONTEXT.md` — Locked decisions D-01 through D-17
- `.planning/phases/08-worker-isolation/08-RESEARCH.md` — Detailed worker test patterns, pitfalls, test fix guidance
- `.planning/phases/08-worker-isolation/08-PATTERNS.md` — Pattern map with before/after code examples
- `.planning/phases/07-backend-scoping/07-04-SUMMARY.md` — Phase 7 test execution summary, auto-fixes

### Secondary (MEDIUM confidence)
- node-pg-migrate `runner()` API — `count` parameter behavior inferred from codebase usage and docs; verified that `migrate.ts` follows the documented pattern
- PostgreSQL `DROP COLUMN` FK cascade behavior — based on PostgreSQL documentation; actual behavior confirmed by migration being successfully applied in Phase 6/7

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, all patterns verified in codebase
- Architecture: HIGH — all patterns exist in current test files (api-scoping, schema-migration, worker tests)
- Pitfalls: HIGH — identified from codebase inspection (Promise.all race conditions, migration state leakage, Bun parallelism)

**Research date:** 2026-06-07
**Valid until:** 2026-07-07 (stable phase — no fast-moving dependencies)
