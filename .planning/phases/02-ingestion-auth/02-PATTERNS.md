# Phase 2: Ingestion & Auth - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 21
**Analogs found:** 16 / 21

---

## File Classification

### New Files

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `src/auth.ts` | config/provider | request-response | none (greenfield) | — |
| `src/interface-adapters/api/auth.ts` | middleware | request-response | none (greenfield) | — |
| `src/interface-adapters/api/import.ts` | controller | request-response + file-I/O | `src/interface-adapters/api/ledger.ts` | exact |
| `src/core/import/entities.ts` | model | — | `src/core/ledger/entities.ts` | exact |
| `src/core/import/use-cases.ts` | service | CRUD + batch | `src/core/ledger/use-cases.ts` | exact |
| `src/application/schemas/import.ts` | config/utility | validation | `src/application/schemas/ledger.ts` | exact |
| `src/workers/import-worker.ts` | worker | batch + event-driven | `src/core/ledger/use-cases.ts` (SQL pattern only) | partial |
| `tests/auth.test.ts` | test | request-response | `tests/api.test.ts` | role-match |
| `tests/import-api.test.ts` | test | request-response + file-I/O | `tests/api.test.ts` | role-match |
| `tests/import-worker.test.ts` | test | batch + event-driven | `tests/queue.test.ts` | role-match |
| `tests/import-parse.test.ts` | test | transform | `tests/schemas.test.ts` | role-match |
| `tests/import-dedup.test.ts` | test | CRUD | `tests/ledger.test.ts` | role-match |
| `tests/import-llm.test.ts` | test | request-response | `tests/api.test.ts` | role-match |

### Modified Files

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `index.ts` | config/entry | request-response | `index.ts` (self) | exact |
| `src/interface-adapters/api/ledger.ts` | controller | request-response | `src/interface-adapters/api/ledger.ts` (self) | exact |
| `src/interface-adapters/api/opening-balance.ts` | controller | request-response | `src/interface-adapters/api/opening-balance.ts` (self) | exact |
| `src/interface-adapters/api/reference.ts` | controller | request-response | `src/interface-adapters/api/reference.ts` (self) | exact |
| `src/infrastructure/db/schema.sql` | migration | — | `src/infrastructure/db/schema.sql` (self) | exact |
| `src/infrastructure/db/seed.sql` | migration | — | `src/infrastructure/db/seed.sql` (self) | exact |
| `src/infrastructure/db/health.ts` | utility | request-response | `src/infrastructure/db/health.ts` (self) | exact |

---

## Pattern Assignments

### `src/auth.ts` (config/provider, request-response)

**Analog:** none — greenfield pattern from RESEARCH.md Pattern 1

**Core pattern** (copy from RESEARCH.md, adapted to project conventions):
```typescript
// src/auth.ts
import { betterAuth } from 'better-auth';
import { Pool } from 'pg';

export const auth = betterAuth({
  database: new Pool({
    connectionString: process.env.DATABASE_URL!,
  }),
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    },
    github: {
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    },
  },
});
```

**Note:** Better Auth uses its own `pg` Pool. Keep it separate from the app's `postgres.js` client (`src/infrastructure/db/client.ts`).

---

### `src/interface-adapters/api/auth.ts` (middleware, request-response)

**Analog:** none — greenfield pattern from RESEARCH.md Pattern 2

**Core pattern**:
```typescript
// src/interface-adapters/api/auth.ts
import { createMiddleware } from 'hono/factory';
import { auth } from '../../auth';

export const requireAuth = createMiddleware(async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  if (!session) {
    return c.json({ data: null, error: { message: 'Unauthorized' }, meta: null }, 401);
  }
  c.set('user', session.user);
  c.set('session', session.session);
  await next();
});
```

---

### `src/interface-adapters/api/import.ts` (controller, request-response + file-I/O)

**Analog:** `src/interface-adapters/api/ledger.ts`

**Imports pattern** (from `src/interface-adapters/api/ledger.ts` lines 1-4):
```typescript
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
// Import schemas and use-cases as needed
```

**Auth + validation pattern** (from `src/interface-adapters/api/ledger.ts` lines 8-18, adapted with auth middleware):
```typescript
// Apply requireAuth before validation, following Hono middleware chaining
importRoutes.post('/import', requireAuth, async (c) => {
  // No zValidator for multipart — validate manually after parsing
});
```

**Core request-response pattern** (from `src/interface-adapters/api/ledger.ts` lines 19-29):
```typescript
async (c) => {
  try {
    const input = c.req.valid('json'); // or formData parsing for import
    const result = await someUseCase(input);
    return c.json({ data: result, error: null, meta: null }, 201);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
}
```

**File upload pattern** (from RESEARCH.md Pattern 3, project-adapted):
```typescript
importRoutes.post('/import', requireAuth, async (c) => {
  const formData = await c.req.formData();
  const file = formData.get('csv');
  const accountId = formData.get('account_id');

  if (!file || !(file instanceof File)) {
    return c.json({ data: null, error: { message: 'CSV file required' }, meta: null }, 400);
  }

  // Read file content
  const content = await file.text(); // for UTF-8 (IPKO)
  // For ISO-8859-2 (ING), read as buffer first:
  // const buffer = Buffer.from(await file.arrayBuffer());
  // const content = buffer.toString('latin1');

  // Enqueue job
  const jobId = await enqueueImportJob({
    account_id: accountId as string,
    csv_content: content,
    bank_format: detectFormat(content), // 'ing' | 'ipko'
  });

  return c.json({ data: { job_id: jobId }, error: null, meta: null }, 202);
});
```

**Status endpoint pattern** (from `src/interface-adapters/api/ledger.ts` GET pattern + RESEARCH.md Pattern 6):
```typescript
importRoutes.get('/import/:job_id', requireAuth, async (c) => {
  try {
    const jobId = c.req.param('job_id');
    const job = await getImportStatus(jobId);
    if (!job) {
      return c.json({ data: null, error: { message: 'Job not found' }, meta: null }, 404);
    }
    return c.json({ data: job, error: null, meta: null }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json({ data: null, error: { message }, meta: null }, 500);
  }
});
```

---

### `src/core/import/entities.ts` (model)

**Analog:** `src/core/ledger/entities.ts`

**Core pattern** (from `src/core/ledger/entities.ts` lines 1-15):
```typescript
// NUMERIC(19,4) columns are typed as string — postgres.js returns them as strings.
// Never use number for monetary fields.

export interface ImportJob {
  id: string                          // UUID
  account_id: string
  status: 'pending' | 'processing' | 'completed' | 'failed'
  total_rows: number | null
  processed: number
  errors: string[] | null
  created_at: string                  // TIMESTAMPTZ as ISO string
}

export interface ParsedTransaction {
  date: string                        // DATE as ISO string
  amount: string                      // positive decimal string
  description: string
  raw_type: 'income' | 'expense' | 'transfer'
}
```

---

### `src/core/import/use-cases.ts` (service, CRUD + batch)

**Analog:** `src/core/ledger/use-cases.ts`

**Imports pattern** (from `src/core/ledger/use-cases.ts` lines 1-7):
```typescript
import sql from '../../infrastructure/db/client';
import type { ImportJob, ParsedTransaction } from './entities';
// Import input types from schemas as needed
```

**Atomic enqueue pattern** (from `src/core/ledger/use-cases.ts` lines 10-25):
```typescript
export async function enqueueImportJob(payload: {
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
}): Promise<{ job_id: string; msg_id: number }> {
  return await sql.begin(async (sql) => {
    // 1. Create import_jobs record
    const [job] = await sql`
      INSERT INTO import_jobs (account_id, status)
      VALUES (${payload.account_id}, 'pending')
      RETURNING id
    `;
    // 2. Enqueue to PGMQ with job_id reference
    const [sendResult] = await sql`
      SELECT pgmq.send('import_queue', ${JSON.stringify({
        job_id: job.id,
        account_id: payload.account_id,
        csv_content: payload.csv_content,
        bank_format: payload.bank_format,
      })}::jsonb) as msg_id
    `;
    return { job_id: job.id, msg_id: Number(sendResult.msg_id) };
  });
}
```

**Status query pattern** (from `src/core/ledger/use-cases.ts` query style):
```typescript
export async function getImportStatus(jobId: string): Promise<ImportJob | undefined> {
  const [row] = await sql`SELECT * FROM import_jobs WHERE id = ${jobId}`;
  return row as ImportJob | undefined;
}
```

---

### `src/application/schemas/import.ts` (config/utility, validation)

**Analog:** `src/application/schemas/ledger.ts`

**Imports pattern** (from `src/application/schemas/ledger.ts` line 1):
```typescript
import * as z from 'zod';
```

**Schema pattern** (from `src/application/schemas/ledger.ts` lines 4-12, adapted for import):
```typescript
export const ImportUploadSchema = z.object({
  account_id: z.uuid(),
  bank_format: z.enum(['ing', 'ipko']).optional(), // optional — can auto-detect
});

export const ImportStatusQuerySchema = z.object({
  job_id: z.uuid(),
});

export const ParsedTransactionSchema = z.object({
  date: z.iso.date(),
  amount: z.string().regex(/^\d+(\.\d{1,4})?$/, 'Amount must be a positive decimal with up to 4 places'),
  description: z.string().min(1).max(2000),
  raw_type: z.enum(['income', 'expense', 'transfer']),
});

export type ImportUploadInput = z.infer<typeof ImportUploadSchema>;
export type ImportStatusQuery = z.infer<typeof ImportStatusQuerySchema>;
export type ParsedTransaction = z.infer<typeof ParsedTransactionSchema>;
```

---

### `src/workers/import-worker.ts` (worker, batch + event-driven)

**Analog:** `src/core/ledger/use-cases.ts` (SQL/transaction pattern only) + `tests/queue.test.ts` (PGMQ pattern)

**Imports pattern** (from `src/core/ledger/use-cases.ts` line 1 + RESEARCH.md):
```typescript
import sql from '../infrastructure/db/client';
import { createHash } from 'crypto';
// Import schemas for LLM output validation
```

**PGMQ worker loop pattern** (from RESEARCH.md Pattern 5, project-adapted with `postgres.js`):
```typescript
const QUEUE_NAME = 'import_queue';
const VISIBILITY_TIMEOUT = 300; // 5 minutes
const POLL_INTERVAL_MS = 5000;
const MAX_RETRIES = 3;

async function workerLoop() {
  while (true) {
    try {
      const messages = await sql`
        SELECT * FROM pgmq.read(${QUEUE_NAME}, ${VISIBILITY_TIMEOUT}, 1)
      `;

      if (messages.length === 0) {
        await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
        continue;
      }

      const msg = messages[0];
      const readCount = Number(msg.read_ct);
      const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;

      try {
        await processJob(payload);
        await sql`SELECT pgmq.archive(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
      } catch (err) {
        console.error(`Job ${msg.msg_id} failed (attempt ${readCount}):`, err);
        if (readCount >= MAX_RETRIES) {
          await sql`SELECT pgmq.delete(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        }
      }
    } catch (err) {
      console.error('Worker loop error:', err);
      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    }
  }
}

if (import.meta.main) {
  console.log('Import worker starting...');
  workerLoop();
}
```

**Batch insert + dedup pattern** (from `src/core/ledger/use-cases.ts` `sql.begin` pattern):
```typescript
async function insertBatch(accountId: string, transactions: ParsedTransaction[]) {
  await sql.begin(async (sql) => {
    for (const tx of transactions) {
      const hash = computeImportHash(tx.date, tx.amount, tx.description);
      const type = tx.raw_type;

      await sql`
        INSERT INTO transactions
          (account_id, category_id, type, amount, description, date, import_hash)
        VALUES
          (${accountId}, null, ${type}, ${tx.amount}, ${tx.description}, ${tx.date}, ${hash})
        ON CONFLICT (import_hash) DO NOTHING
      `;
    }
  });
}

function computeImportHash(date: string, amount: string, description: string): string {
  return createHash('sha256')
    .update(`${date}|${amount}|${description}`)
    .digest('hex');
}
```

---

### `index.ts` (config/entry, request-response)

**Analog:** `index.ts` (self)

**Auth mount pattern** (from RESEARCH.md Pattern 1, applied to existing `index.ts`):
```typescript
// Existing imports
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { auth } from './src/auth';

// Existing routes
import { ledgerRoutes } from './src/interface-adapters/api/ledger';
import { openingBalanceRoutes } from './src/interface-adapters/api/opening-balance';
import { referenceRoutes } from './src/interface-adapters/api/reference';
import { importRoutes } from './src/interface-adapters/api/import'; // NEW
import { healthDb } from './src/infrastructure/db/health';

const app = new Hono<{
  Variables: {
    user: typeof auth.$Infer.Session.user | null;
    session: typeof auth.$Infer.Session.session | null;
  };
}>();

// CORS for auth routes
app.use(
  '/api/auth/*',
  cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    allowHeaders: ['Content-Type', 'Authorization'],
    allowMethods: ['POST', 'GET', 'OPTIONS'],
    credentials: true,
  })
);

// Mount Better Auth handler
app.on(['POST', 'GET'], '/api/auth/*', (c) => auth.handler(c.req.raw));

// Session middleware for all routes
app.use('*', async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  c.set('user', session?.user ?? null);
  c.set('session', session?.session ?? null);
  await next();
});

// Existing health + domain routes
app.get('/health', (c) => c.json({ data: { ok: true }, error: null, meta: null }));
app.get('/health/db', async (c) => { /* ... */ });

app.route('/transactions', ledgerRoutes);
app.route('/opening-balance', openingBalanceRoutes);
app.route('/', referenceRoutes);
app.route('/import', importRoutes); // NEW

export { app };
export default {
  port: Number(process.env.PORT) || 3000,
  fetch: app.fetch,
};
```

---

### `src/infrastructure/db/schema.sql` (migration)

**Analog:** `src/infrastructure/db/schema.sql` (self)

**Schema addition pattern** (following existing DDL style):
```sql
-- Import jobs tracking table
CREATE TABLE IF NOT EXISTS import_jobs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    UUID NOT NULL REFERENCES accounts(id),
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  total_rows    INT,
  processed     INT NOT NULL DEFAULT 0,
  errors        TEXT[],
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for status lookups
CREATE INDEX IF NOT EXISTS idx_import_jobs_account ON import_jobs(account_id);
CREATE INDEX IF NOT EXISTS idx_import_jobs_status ON import_jobs(status);

-- (existing schema continues below)
```

---

### `src/infrastructure/db/seed.sql` (migration)

**Analog:** `src/infrastructure/db/seed.sql` (self)

**Queue init pattern** (from `src/infrastructure/db/seed.sql` lines 40-45):
```sql
-- Idempotent PGMQ queue initialization for import
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pgmq.list_queues() WHERE queue_name = 'import_queue') THEN
    PERFORM pgmq.create('import_queue');
  END IF;
END $$;
```

---

### `src/infrastructure/db/health.ts` (utility)

**Analog:** `src/infrastructure/db/health.ts` (self)

**Health check extension pattern** (from `src/infrastructure/db/health.ts` lines 3-11):
```typescript
export async function healthDb(): Promise<{ db: boolean; pgmq: boolean; import_queue: boolean }> {
  try {
    await sql`SELECT 1`;
    const queues = await sql`SELECT queue_name FROM pgmq.list_queues()`;
    const pgmqReady = queues.some((q: { queue_name: string }) => q.queue_name === 'analysis_queue');
    const importQueueReady = queues.some((q: { queue_name: string }) => q.queue_name === 'import_queue');
    return { db: true, pgmq: pgmqReady, import_queue: importQueueReady };
  } catch {
    return { db: false, pgmq: false, import_queue: false };
  }
}
```

---

### `tests/auth.test.ts` (test, request-response)

**Analog:** `tests/api.test.ts`

**Test setup pattern** (from `tests/api.test.ts` lines 1-9, 28-34):
```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import { app } from '../index';
import sql from '../src/infrastructure/db/client';

describe('Auth Integration Tests', () => {
  it('GET /api/auth/providers returns auth configuration', async () => {
    const res = await app.request('/api/auth/providers');
    expect(res.status).toBe(200);
    // assertions...
  });

  it('POST /import returns 401 without session', async () => {
    const res = await app.request('/import', { method: 'POST' });
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error.message).toBe('Unauthorized');
  });
});
```

---

### `tests/import-api.test.ts` (test, request-response + file-I/O)

**Analog:** `tests/api.test.ts`

**Multipart upload test pattern** (from `tests/api.test.ts` request pattern + Bun File API):
```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import { app } from '../index';
import sql from '../src/infrastructure/db/client';

describe('Import API Tests', () => {
  beforeAll(async () => {
    await sql`TRUNCATE import_jobs CASCADE`;
    await sql`DELETE FROM pgmq.q_import_queue`;
  });

  it('POST /import accepts multipart CSV and returns job_id', async () => {
    const formData = new FormData();
    const csvContent = 'Data transakcji;Data ksi...;...';
    const blob = new Blob([csvContent], { type: 'text/csv' });
    formData.append('csv', blob, 'ing.csv');
    formData.append('account_id', accountId);

    const res = await app.request('/import', {
      method: 'POST',
      body: formData,
    });

    expect(res.status).toBe(202);
    const json = await res.json();
    expect(json.data.job_id).toBeDefined();
    expect(json.error).toBeNull();
  });

  it('GET /import/:job_id returns job status', async () => {
    // Create a job first, then poll status
  });
});
```

---

### `tests/import-worker.test.ts` (test, batch + event-driven)

**Analog:** `tests/queue.test.ts`

**PGMQ worker test pattern** (from `tests/queue.test.ts` lines 8-32):
```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';

beforeAll(async () => {
  await sql`DELETE FROM pgmq.q_import_queue`;
  await sql`TRUNCATE import_jobs CASCADE`;
});

describe('Import Worker Tests', () => {
  it('processes a job from import_queue and inserts transactions', async () => {
    // 1. Create a job record
    // 2. Send message to import_queue
    // 3. Run worker logic
    // 4. Verify transactions inserted
    // 5. Verify message archived
  });
});
```

---

### `tests/import-parse.test.ts` (test, transform)

**Analog:** `tests/schemas.test.ts`

**Unit test pattern for CSV preprocessing**:
```typescript
import { describe, it, expect } from 'bun:test';
import { preprocessIngCsv, preprocessIpkoCsv, detectFormat } from '../src/workers/import-worker';

describe('CSV Preprocessing', () => {
  it('extracts ING header and skips metadata rows', () => {
    const raw = 'Wygenerowany dnia...\nLista transakcji\n...\n"Data transakcji";"Data ksi..."\n2026-05-27;...';
    const result = preprocessIngCsv(raw);
    expect(result).toContain('Data transakcji');
    expect(result).not.toContain('Wygenerowany dnia');
  });

  it('filters IPKO Blokada rows', () => {
    const raw = '"2026-05-25","2026-05-25","Blokada","-11.99",...\n"2026-05-25","2026-05-25","Patno kart",...';
    const result = preprocessIpkoCsv(raw);
    expect(result).not.toContain('Blokada');
  });
});
```

---

### `tests/import-dedup.test.ts` (test, CRUD)

**Analog:** `tests/ledger.test.ts`

**Deduplication test pattern** (from `tests/ledger.test.ts` lines 33-58):
```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';

describe('Import Deduplication', () => {
  it('skips duplicate transactions by import_hash', async () => {
    const hash = 'sha256-of-date-amount-description';
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
      VALUES (${accountId}, 'expense', '100.00', 'Test', '2026-06-01', ${hash})
    `;

    // Attempt duplicate insert
    await sql`
      INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
      VALUES (${accountId}, 'expense', '100.00', 'Test', '2026-06-01', ${hash})
      ON CONFLICT (import_hash) DO NOTHING
    `;

    const [{ count }] = await sql`SELECT COUNT(*) as count FROM transactions WHERE import_hash = ${hash}`;
    expect(Number(count)).toBe(1);
  });
});
```

---

## Shared Patterns

### Standard JSON Response Envelope
**Source:** All existing route files (`src/interface-adapters/api/ledger.ts`, `src/interface-adapters/api/opening-balance.ts`, `src/interface-adapters/api/reference.ts`)
**Apply to:** All new controller files and modified existing controllers

```typescript
// Success (single resource)
return c.json({ data: result, error: null, meta: null }, 201);

// Success (list)
return c.json({ data: rows, error: null, meta: { total, page, per_page } }, 200);

// Error
return c.json({ data: null, error: { message }, meta: null }, status);
```

**Note:** `meta` is `null` for single-resource endpoints and `{ total, page, per_page }` for list endpoints (D-09, D-10).

---

### Error Handling Structure
**Source:** `src/interface-adapters/api/ledger.ts` lines 24-28
**Apply to:** All route handlers

```typescript
try {
  // ... handler logic
} catch (err) {
  const message = err instanceof Error ? err.message : 'Internal server error';
  const status = message.includes('immutable') ? 409 : 500; // or other domain-specific mapping
  return c.json({ data: null, error: { message }, meta: null }, status);
}
```

---

### Zod Validation with `@hono/zod-validator`
**Source:** `src/interface-adapters/api/ledger.ts` lines 11-18
**Apply to:** All JSON body routes (not multipart)

```typescript
zValidator('json', SomeSchema, (result, c) => {
  if (!result.success) {
    return c.json(
      { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
      400
    );
  }
})
```

**Note:** For multipart uploads, validate manually after parsing `c.req.formData()`.

---

### postgres.js Tagged Template Literals
**Source:** `src/core/ledger/use-cases.ts` throughout
**Apply to:** All new service and worker files

```typescript
import sql from '../../infrastructure/db/client';

// Parameterized queries (auto-escaped)
const [row] = await sql`SELECT * FROM table WHERE id = ${id}`;

// Conditional query building
const rows = await sql`
  SELECT * FROM transactions
  WHERE true
    ${account_id ? sql`AND account_id = ${account_id}` : sql``}
  ORDER BY date DESC
`;

// Atomic transactions
await sql.begin(async (sql) => {
  const [tx] = await sql`INSERT INTO ... RETURNING *`;
  await sql`SELECT pgmq.send('queue', ${JSON.stringify(payload)}::jsonb)`;
});
```

**Note:** `sql.begin()` is used for atomic multi-statement operations. `sql.unsafe()` is used in `apply.ts` for raw DDL only.

---

### PGMQ Queue Operations
**Source:** `src/core/ledger/use-cases.ts` line 21, `tests/queue.test.ts`, `src/infrastructure/db/seed.sql`
**Apply to:** Import worker, enqueue use-case, tests

```typescript
// Send
await sql`SELECT pgmq.send('queue_name', ${JSON.stringify(payload)}::jsonb)`;

// Read (with visibility timeout)
const messages = await sql`SELECT * FROM pgmq.read('queue_name', ${vt}, ${qty})`;

// Archive (success)
await sql`SELECT pgmq.archive('queue_name', ${msg_id}::bigint)`;

// Delete (permanent removal, e.g., after max retries)
await sql`SELECT pgmq.delete('queue_name', ${msg_id}::bigint)`;
```

---

### Bun Test Setup / Teardown
**Source:** `tests/api.test.ts` lines 10-26, `tests/ledger.test.ts` lines 15-30
**Apply to:** All new test files

```typescript
import { describe, it, expect, beforeAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';

beforeAll(async () => {
  await sql`TRUNCATE transactions CASCADE`;
  await sql`DELETE FROM monthly_opening_balances`;
  await sql`DELETE FROM pgmq.q_analysis_queue`;
  // Add for import tests:
  await sql`TRUNCATE import_jobs CASCADE`;
  await sql`DELETE FROM pgmq.q_import_queue`;
});
```

---

### Bun Native Server Export
**Source:** `index.ts` lines 24-28
**Apply to:** `index.ts` (no changes needed to server export pattern)

```typescript
export default {
  port: Number(process.env.PORT) || 3000,
  fetch: app.fetch,
};
```

**Anti-pattern to avoid:** Do NOT add `@hono/node-server`.

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `src/auth.ts` | config/provider | request-response | Better Auth is new to the project; no auth configuration exists yet |
| `src/interface-adapters/api/auth.ts` | middleware | request-response | No middleware files exist in the project yet |
| `src/workers/import-worker.ts` | worker | batch + event-driven | No background worker / polling loop exists in the project yet |
| `tests/import-llm.test.ts` | test | request-response | No external API integration tests exist yet |

---

## Metadata

**Analog search scope:**
- `src/interface-adapters/api/*.ts`
- `src/core/ledger/*.ts`
- `src/application/schemas/*.ts`
- `src/infrastructure/db/*.ts`
- `tests/*.ts`
- `index.ts`

**Files scanned:** 15
**Pattern extraction date:** 2026-06-06

---

## PATTERN MAPPING COMPLETE

**Phase:** 2 — Ingestion & Auth
**Files classified:** 21
**Analogs found:** 16 / 21

### Coverage
- Files with exact analog: 13
- Files with role-match analog: 3
- Files with no analog: 5 (4 new patterns + 1 test pattern)

### Key Patterns Identified
1. **Standard JSON envelope:** All controllers return `{ data, error, meta }`. Single-resource `meta: null`; lists `meta: { total, page, per_page }`.
2. **postgres.js tagged templates:** All SQL uses tagged template literals with `${parameter}` auto-escaping. Atomic operations use `sql.begin()`.
3. **Zod v4 + `@hono/zod-validator`:** JSON body validation uses `zValidator()` with `.flatten()` error details. Multipart uploads validate manually.
4. **Bun native server:** `export default { port, fetch }` — no `@hono/node-server`.
5. **PGMQ raw SQL:** `pgmq.send/read/archive/delete` via `postgres.js` tagged templates. No JS wrapper.
6. **Error handling:** Consistent `try/catch` with `err instanceof Error` message extraction and domain-specific status code mapping.
7. **Test setup:** `bun:test` with `beforeAll` truncating tables and cleaning PGMQ queues.

### File Created
`/home/olafk/finance/.planning/phases/02-ingestion-auth/02-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files.
