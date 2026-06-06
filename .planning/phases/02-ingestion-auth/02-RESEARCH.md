# Phase 2: Ingestion & Auth - Research

**Researched:** 2026-06-06
**Domain:** Authentication (Better Auth), LLM-powered CSV parsing (OpenRouter), Job Queue (PGMQ), CSV Encoding
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from Phase 1 CONTEXT.md)

### Locked Decisions
- **D-01:** `monthly_opening_balances` is a **global table** — no `account_id` FK.
- **D-02:** `stan konta` = **total net worth** (bank + cash + ETF + silver + receivables).
- **D-09:** All endpoints use standard envelope: `{ data, error, meta }`.
- **D-10:** List endpoints include `meta: { total, page, per_page }`. Single-resource endpoints set `meta: null`.
- **D-11:** Individual resources expose `created_at` from DB. No `updated_at`.
- **Zod v4:** Use `z.uuid()`, `z.iso.date()`, not v3 deprecated patterns.
- **Bun native server:** No `@hono/node-server`; use `export default { port, fetch }`.
- **postgres.js:** Tagged template literals for all SQL. NUMERIC returns as string.
- **PGMQ via raw SQL:** No JS wrapper; use `pgmq.send/read/archive/delete` via SQL.
- **Transaction immutability:** BEFORE UPDATE/DELETE triggers on `transactions`.

### Claude's Discretion
- Error message format (string vs structured codes) — left to planner.
- Pagination defaults (50 or 100 per page) — reasonable.
- Import batch size and worker poll interval — planner decides.
- OpenRouter model selection — planner decides (recommendation: `openai/gpt-4o-mini` for cost-effective parsing).

### Deferred Ideas (OUT OF SCOPE)
- Individual tracking of non-bank assets (ETF positions, silver, cash) as separate entities.
- Cursor-based pagination.
- Advanced AI insights (Phase 4 concern).
- Non-OAuth auth methods (local email/password is deferred).
</user_constraints>

---

## Summary

Phase 2 adds two major capabilities to the Phase 1 foundation: **user authentication** via Better Auth (OAuth/SSO with Google/GitHub) and **LLM-powered bank CSV import** via OpenRouter. These capabilities are deeply coupled — the import endpoint must be authenticated, and the import worker must associate transactions with the correct account.

The critical technical finding for the planner: **Better Auth already has first-class Hono integration documentation**, and the project already has `better-auth` in `package.json`. The setup is straightforward: configure `betterAuth()` with a Postgres connection pool (using the same `DATABASE_URL`), mount the handler at `/api/auth/*`, add session middleware to Hono context variables, and protect import routes.

For the import pipeline, the architecture is: **POST /import** receives multipart form data (CSV + account_id), validates auth, enqueues a PGMQ job with the CSV content and account_id, returns `{ job_id }`. The **PGMQ worker** (running in a separate process or Bun thread) dequeues jobs, calls OpenRouter with a few-shot prompt containing 3-5 example rows from each bank format, receives structured JSON `[{date, amount, description, raw_type}]`, maps `raw_type` to `income|expense|transfer`, computes `import_hash = SHA-256(date+amount+description)`, and inserts transactions with `category_id = NULL`, skipping on `import_hash` conflict.

**Primary recommendation:** Use OpenRouter's `json_schema` response format (not just `json_object`) for reliable structured output. Use `pgmq.read` with a visibility timeout for at-least-once delivery, archive successfully processed messages, and delete failed messages after max retries. Use `Bun.file()` for reading uploaded CSV files from `/tmp` or memory buffer.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| OAuth/SSO login flow | Backend (Better Auth) | Frontend (redirect UI) | Better Auth handles the entire OAuth dance; frontend only triggers the redirect |
| Session validation | Backend (Hono middleware) | — | Session cookie checked on every protected request |
| File upload (CSV) | Backend (Hono + Bun) | Frontend (file picker) | Bun parses multipart form data natively; frontend is just a form |
| CSV content extraction | Backend (Bun `File` API) | — | `Bun.file().text()` reads CSV as string; `Buffer.from()` for binary encodings |
| LLM parsing (few-shot) | External (OpenRouter API) | Backend (prompt construction) | OpenRouter is the compute provider; backend controls the prompt |
| Job queue management | Database (PGMQ) | Backend (enqueue/dequeue) | PGMQ lives in Postgres; enqueue is atomic with no other writes in this phase |
| Import worker | Background process (Bun) | — | Worker runs continuously, polling PGMQ |
| Deduplication | Database (UNIQUE import_hash) | Backend (hash computation) | DB constraint is the final gate; SHA-256 computed in app |
| Import status tracking | Database (PGMQ message state) | Backend (status endpoint) | `read_ct` from PGMQ shows retry count; custom status table needed |
| Progress indicator | Frontend (polling) | Backend (status endpoint) | Frontend polls `GET /import/:job_id` every 2-3 seconds |

---

## Standard Stack

### Core (already in package.json)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `better-auth` | 1.6.14 | OAuth/SSO authentication | Framework-agnostic, supports Hono natively, has `pg` adapter for Postgres [VERIFIED: Context7 /websites/better-auth] |
| `hono` | 4.12.23 | Web framework | Phase 1 standard; Bun-native via `export default { port, fetch }` [VERIFIED: Context7 /websites/hono_dev] |
| `zod` | 4.4.3 | Schema validation | Phase 1 standard; use v4 API (`z.uuid()`, `z.iso.date()`) [VERIFIED: Context7 /websites/zod_dev_v4] |
| `postgres` | 3.4.9 | DB driver | Phase 1 standard; tagged template literals for PGMQ [VERIFIED: Context7 /porsager/postgres] |
| `@hono/zod-validator` | 0.8.0 | Hono/Zod bridge | Peer deps support zod v4 [VERIFIED: npm registry] |

### Supporting (Phase 2 additions)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `pg` (from `better-auth` dep) | ^8.11.0 | Better Auth's internal DB driver | Better Auth uses its own `pg` Pool for auth tables; keep separate from `postgres.js` client |
| `crypto` (built-in) | Bun built-in | SHA-256 hashing | `crypto.createHash('sha256')` for `import_hash` computation |
| `Bun` APIs | Bun 1.2+ | File reading, text encoding | `Bun.file().text()` for UTF-8; `Buffer.from(text, 'latin1')` for ISO-8859-2 |

### Packages NOT to install

| Package | Reason |
|---------|--------|
| `@hono/node-server` | Not needed on Bun (Phase 1 standard) |
| `csv-parser` / `papaparse` | Not needed — CSV parsing is done by OpenRouter LLM, not a JS parser. For simple header row detection, `String.split()` and `Buffer` operations are sufficient. |
| `pgmq-js` | Community wrapper (603 downloads/week); raw SQL is preferred (Phase 1 standard) |
| `multer` / `busboy` | Not needed — Bun's native `FormData` and `File` APIs handle multipart uploads. |
| `openai` SDK | Not needed — OpenRouter is OpenAI-compatible, but `fetch` with JSON is sufficient for this simple use case. Adding the SDK adds dependency weight for no gain. |
| `iconv-lite` / `iconv` | Not needed — `Buffer.toString('latin1')` correctly handles CP1250 for Polish characters. Bringing in a full iconv library is unnecessary overhead. |

### Auth testing: emailAndPassword configuration

Better Auth requires `emailAndPassword: { enabled: true }` in the auth config to support test sign-up/sign-in without real OAuth credentials. This is not an additional package — it's a built-in plugin. Include it in `src/auth.ts` either always or conditionally:

```typescript
// src/auth.ts
export const auth = betterAuth({
  database: new Pool({ connectionString: process.env.DATABASE_URL! }),
  emailAndPassword: {
    enabled: true, // Enables /api/auth/sign-up/email + /api/auth/sign-in/email for tests
  },
  socialProviders: { google: { ... }, github: { ... } },
});
```

[VERIFIED: Context7 /better-auth/better-auth — signUpEmail endpoint is gated by this config flag]

### Installation

```bash
# No new packages needed — all are already in package.json
# better-auth 1.6.14 is already installed
# hono, zod, postgres, @hono/zod-validator already in package.json
```

**Version verification:**
```bash
npm view better-auth version  # 1.6.14
npm view hono version         # 4.12.23
npm view zod version          # 4.4.3
npm view postgres version     # 3.4.9
```

---

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| better-auth | npm | ~1 yr | 50k+/wk | github.com/better-auth/better-auth | [OK] | Approved |
| hono | npm | 3+ yrs | 1.5M+/wk | github.com/honojs/hono | [OK] | Approved |
| zod | npm | 4+ yrs | 12M+/wk | github.com/colinhacks/zod | [OK] | Approved |
| postgres | npm | 5+ yrs | 300k+/wk | github.com/porsager/postgres | [OK] | Approved |
| @hono/zod-validator | npm | 2+ yrs | stable | github.com/honojs/middleware | [OK] | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck run confirmed all used packages are [OK]. No postinstall scripts detected.*

---

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Frontend (React + Tailwind)                  │
│  ┌─────────────┐  ┌─────────────────────┐  ┌─────────────────────┐ │
│  │ Login Button │  │ File Upload Form     │  │ Import Progress     │ │
│  │ (Google/GH)  │  │ (account selector +  │  │ (polls status)      │ │
│  └──────┬──────┘  │  CSV file picker)    │  └─────────────────────┘ │
│         │         └──────────┬──────────┘                         │
│         │                      │                                    │
│         ▼                      ▼                                    │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  OAuth redirect → Better Auth callback → set cookie          │ │
│  │  (handled by Better Auth at /api/auth/*)                     │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP (multipart/form-data)
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Hono Router (index.ts)                                             │
│  - GET /health, /health/db                                        │
│  - POST/GET /api/auth/* → auth.handler(c.req.raw)                 │
│  - POST /import (authenticated) → enqueue PGMQ job               │
│  - GET /import/:job_id (authenticated) → status                   │
│  - All Phase 1 routes (now protected)                              │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ validated data / session
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Better Auth Middleware                                           │
│  - Checks session cookie                                          │
│  - Injects { user, session } into Hono context                    │
│  - Returns 401 for unauthenticated requests                        │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ session valid
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Import Use Cases (src/core/import/use-cases.ts)                    │
│  - enqueueImportJob: pgmq.send('import_queue', payload)           │
│  - getImportStatus: query PGMQ + status table                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ SQL
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PostgreSQL + PGMQ                                                │
│  - transactions (immutable, with import_hash UNIQUE)                │
│  - accounts, categories, monthly_opening_balances                   │
│  - pgmq.import_queue (new queue for Phase 2)                      │
│  - better-auth tables (users, sessions, accounts, etc.)           │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ dequeue (separate process)
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Import Worker (src/workers/import-worker.ts)                       │
│  - Poll: pgmq.read('import_queue', vt=60, qty=1)                  │
│  - Extract CSV content from message payload                        │
│  - Call OpenRouter API with few-shot prompt + CSV rows             │
│  - Receive JSON [{date, amount, description, raw_type}]          │
│  - Map raw_type → income|expense|transfer                         │
│  - Compute import_hash = SHA-256(date+amount+description)          │
│  - Insert transactions (SKIP ON CONFLICT for dedup)                │
│  - Archive message on success, increment retry on failure         │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP POST
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  OpenRouter API (external)                                        │
│  - POST /api/v1/chat/completions                                  │
│  - response_format: { type: 'json_schema', ... }                  │
│  - Model: openai/gpt-4o-mini (recommended) or anthropic/claude-3.5 │
└─────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
src/
├── core/
│   └── ledger/
│       ├── entities.ts          # Phase 1 — Transaction, Account, etc.
│       └── use-cases.ts         # Phase 1 — createTransaction, listTransactions, etc.
├── core/
│   └── import/
│       ├── entities.ts          # ImportJob, ParsedTransaction, ImportStatus
│       └── use-cases.ts         # enqueueImportJob, getImportStatus
├── application/
│   └── schemas/
│       ├── ledger.ts            # Phase 1 — Zod schemas
│       └── import.ts            # ImportUploadSchema, ImportStatusQuerySchema
├── infrastructure/
│   └── db/
│       ├── client.ts            # postgres.js singleton (Phase 1)
│       ├── schema.sql           # Phase 1 DDL (add import_queue init)
│       ├── seed.sql             # Phase 1 seed (add import_queue init)
│       └── health.ts            # Phase 1 health check
├── interface-adapters/
│   └── api/
│       ├── auth.ts              # Better Auth handler mount + middleware
│       ├── ledger.ts            # Phase 1 routes (now protected)
│       ├── opening-balance.ts   # Phase 1 routes (now protected)
│       ├── reference.ts         # Phase 1 routes (now protected)
│       └── import.ts            # POST /import, GET /import/:job_id
├── workers/
│   └── import-worker.ts         # PGMQ consumer + OpenRouter caller
├── auth.ts                      # Better Auth configuration
index.ts                         # Hono app + Bun server + Better Auth mount
```

### Pattern 1: Better Auth with Hono and Bun

**What:** Mount Better Auth handler at `/api/auth/*` and add session middleware to all routes.

**Source:** [VERIFIED: Context7 /websites/better-auth + official docs https://better-auth.com/docs/integrations/hono]

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

// index.ts
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { auth } from './src/auth';

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

// Export for test suites
export { app };
export default {
  port: Number(process.env.PORT) || 3000,
  fetch: app.fetch,
};
```

### Pattern 2: Auth-Protected Route

**What:** Reusable Hono middleware that returns 401 if no session.

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

// Usage in import.ts
import { requireAuth } from './auth';
importRoutes.post('/import', requireAuth, async (c) => {
  // ... handler code
});
```

### Pattern 3: Hono Multipart File Upload (Bun)

**What:** Accept CSV file via `multipart/form-data` using standard Web APIs.

**Source:** [ASSUMED: Bun supports `FormData` and `File` natively; Hono exposes `c.req.formData()`]

**CRITICAL:** Both ING and IPKO CSV files are CP1250 (not UTF-8). Always read as buffer + latin1 decode. [VERIFIED: direct file inspection]

```typescript
// POST /import
importRoutes.post('/import', requireAuth, async (c) => {
  const formData = await c.req.formData();
  const file = formData.get('csv');
  const accountId = formData.get('account_id');

  if (!file || !(file instanceof File)) {
    return c.json({ data: null, error: { message: 'CSV file required' }, meta: null }, 400);
  }

  // ALWAYS decode as latin1 — both ING and IPKO use CP1250 (not UTF-8)
  // file.text() would throw/garble Polish diacritics on both formats
  const buffer = Buffer.from(await file.arrayBuffer());
  const content = buffer.toString('latin1');

  // Auto-detect format after decoding (ING has semicolons + 'Data transakcji')
  const bankFormat = detectFormat(content); // 'ing' | 'ipko'

  const { job_id } = await enqueueImportJob({
    account_id: accountId as string,
    csv_content: content,
    bank_format: bankFormat,
  });

  return c.json({ data: { job_id }, error: null, meta: null }, 202);
});
```

### Pattern 4: OpenRouter Structured Output (JSON Schema)

**What:** Use `response_format: { type: 'json_schema', ... }` for reliable parsing.

**Source:** [VERIFIED: Context7 /websites/openrouter_ai]

```typescript
// src/workers/import-worker.ts
async function callOpenRouter(csvRows: string, format: 'ing' | 'ipko'): Promise<ParsedTransaction[]> {
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': process.env.APP_URL || 'http://localhost:3000',
      'X-Title': 'Financial Planning App',
    },
    body: JSON.stringify({
      model: 'openai/gpt-4o-mini', // cost-effective, reliable JSON
      messages: [
        {
          role: 'system',
          content: `You are a financial transaction parser. Parse CSV rows into a JSON array.
          Bank format: ${format}. Rules:
          - Date: YYYY-MM-DD
          - Amount: always positive number (strip sign, use absolute value)
          - raw_type: 'income' if money received, 'expense' if money spent, 'transfer' if between own accounts
          - Description: clean, readable description
          Return ONLY valid JSON array, no markdown.`,
        },
        {
          role: 'user',
          content: `Parse these CSV rows:\n${csvRows}`,
        },
      ],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'transactions',
          strict: true,
          schema: {
            type: 'object',
            properties: {
              transactions: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    date: { type: 'string', description: 'YYYY-MM-DD' },
                    amount: { type: 'string', description: 'Positive decimal string' },
                    description: { type: 'string' },
                    raw_type: { type: 'string', enum: ['income', 'expense', 'transfer'] },
                  },
                  required: ['date', 'amount', 'description', 'raw_type'],
                  additionalProperties: false,
                },
              },
            },
            required: ['transactions'],
            additionalProperties: false,
          },
        },
      },
      temperature: 0.1,
      max_tokens: 4096,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenRouter error: ${response.status} ${await response.text()}`);
  }

  const data = await response.json();
  const content = data.choices[0].message.content;

  // Parse the JSON string response
  const parsed = JSON.parse(content);
  return parsed.transactions;
}
```

### Pattern 5: PGMQ Worker Loop

**What:** Continuous polling loop with `pgmq.read`, process, then archive or delete.

**Source:** [VERIFIED: Context7 /pgmq/pgmq]

```typescript
// src/workers/import-worker.ts
import sql from '../infrastructure/db/client';

const QUEUE_NAME = 'import_queue';
const VISIBILITY_TIMEOUT = 300; // 5 minutes
const POLL_INTERVAL_MS = 5000;

async function processJob(msg: any) {
  const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;
  const { account_id, csv_content, bank_format } = payload;

  // 1. Extract relevant rows from CSV
  const rows = extractRows(csv_content, bank_format);

  // 2. Call OpenRouter in batches
  const BATCH_SIZE = 50;
  let processed = 0;
  let errors: string[] = [];

  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    try {
      const parsed = await callOpenRouter(batch.join('\n'), bank_format);
      await insertBatch(account_id, parsed);
      processed += parsed.length;
    } catch (err) {
      errors.push(`Batch ${i}-${i + BATCH_SIZE}: ${err instanceof Error ? err.message : 'Unknown'}`);
    }
  }

  return { processed, errors };
}

async function insertBatch(accountId: string, transactions: ParsedTransaction[]) {
  await sql.begin(async (sql) => {
    for (const tx of transactions) {
      const hash = computeImportHash(tx.date, tx.amount, tx.description);
      const type = tx.raw_type; // 'income' | 'expense' | 'transfer'

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
  const hash = crypto.createHash('sha256');
  hash.update(`${date}|${amount}|${description}`);
  return hash.digest('hex');
}

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
      const maxRetries = 3;

      try {
        const result = await processJob(msg);
        // Archive on success
        await sql`SELECT pgmq.archive(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        console.log(`Job ${msg.msg_id} completed: ${result.processed} transactions`);
      } catch (err) {
        console.error(`Job ${msg.msg_id} failed (attempt ${readCount}):`, err);
        if (readCount >= maxRetries) {
          // Delete after max retries
          await sql`SELECT pgmq.delete(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
          console.error(`Job ${msg.msg_id} deleted after ${maxRetries} retries`);
        }
        // If not max retries, message will reappear after visibility timeout
      }
    } catch (err) {
      console.error('Worker loop error:', err);
      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    }
  }
}

// Start worker if this file is run directly
if (import.meta.main) {
  console.log('Import worker starting...');
  workerLoop();
}
```

### Pattern 6: Import Status Endpoint

**What:** `GET /import/:job_id` returns status. Since PGMQ doesn't expose per-message status by ID, we need a status table.

```typescript
// Schema addition (schema.sql)
CREATE TABLE IF NOT EXISTS import_jobs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    UUID NOT NULL REFERENCES accounts(id),
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  total_rows    INT,
  processed     INT NOT NULL DEFAULT 0,
  errors        TEXT[], -- array of error messages
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

// Status endpoint
importRoutes.get('/import/:job_id', requireAuth, async (c) => {
  const jobId = c.req.param('job_id');
  const [job] = await sql`SELECT * FROM import_jobs WHERE id = ${jobId}`;

  if (!job) {
    return c.json({ data: null, error: { message: 'Job not found' }, meta: null }, 404);
  }

  return c.json({
    data: {
      job_id: job.id,
      status: job.status,
      processed: job.processed,
      total_rows: job.total_rows,
      errors: job.errors || [],
    },
    error: null,
    meta: null,
  }, 200);
});
```

### Anti-Patterns to Avoid

- **Storing the original CSV in the database:** Don't store raw CSV content in `import_jobs` — enqueue it in PGMQ and let the worker process it. The CSV can be large (thousands of rows). If needed, store it in a temporary file, not in a DB column.
- **Parsing CSV with regex:** Don't use regex to parse CSV. The ING format has semicolons, quotes, and Polish characters. The IPKO format has quoted commas. Let the LLM handle the parsing complexity.
- **Calling OpenRouter synchronously in the HTTP handler:** Never block the HTTP request on an LLM API call. Always enqueue and return immediately.
- **Using `pg` Pool for application queries:** Better Auth uses its own `pg` Pool for auth tables. Keep the app's `postgres.js` client separate for all other queries. Don't mix them.
- **Trusting LLM output without validation:** Always validate the JSON array structure with Zod before inserting. The LLM can hallucinate malformed data.
- **Not wrapping LLM insertions in transactions:** Use `sql.begin()` to wrap batch inserts. If a batch fails, it rolls back completely.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OAuth/SSO flow | Custom OAuth implementation | Better Auth | Handles OAuth 2.0, PKCE, token refresh, session management securely |
| Session management | Custom JWT or cookie logic | Better Auth sessions | Secure, HTTP-only cookies, CSRF protection, automatic refresh |
| Auth database tables | Custom user/session schema | Better Auth's built-in schema | Automatic migrations, proven schema design |
| CSV parsing | Custom split/regex parser | OpenRouter LLM + few-shot prompt | Handles encoding quirks, varying formats, edge cases natively |
| Job queue | Custom polling loop with `setInterval` | PGMQ (raw SQL) | ACID-compliant, visibility timeout, archive, retry built-in |
| Import hash | Custom collision-prone hash | SHA-256 (Node.js `crypto`) | Cryptographically secure, collision-resistant |
| JSON schema validation of LLM output | Manual property checks | Zod schema | Compile-time types + runtime validation in one declaration |

**Key insight:** The biggest complexity in this phase is the CSV parsing. Polish bank exports have inconsistent encoding (ISO-8859-2 vs UTF-8), varying delimiters (semicolon vs comma), and metadata headers. A traditional CSV parser would require hundreds of lines of format-specific code. An LLM with a few-shot prompt handles this naturally in a single API call.

---

## Runtime State Inventory

Step 2.5: SKIPPED — This is not a rename/refactor/migration phase. This is a greenfield feature addition. No existing runtime state needs migration. The `import_hash` column already exists in the Phase 1 schema (added for Phase 2), and the `analysis_queue` already exists. We need to add a new `import_queue`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bun | Backend runtime | ✓ | 1.2+ | — |
| PostgreSQL + PGMQ | Data + Queue | ✓ | 18 + pgmq v1.10.0 | Docker Compose |
| Docker | Postgres container | ✓ | — | — |
| OpenRouter API | LLM parsing | ✗ | — | Cannot implement Phase 2 without API key |
| Google OAuth | Auth provider | ✗ | — | Cannot implement Google SSO without client credentials |
| GitHub OAuth | Auth provider | ✗ | — | Cannot implement GitHub SSO without client credentials |

**Missing dependencies with no fallback:**
- `OPENROUTER_API_KEY` — Required for CSV parsing. Must be obtained from openrouter.ai.
- `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` — Required for Google OAuth. Must be obtained from Google Cloud Console.
- `GITHUB_CLIENT_ID` + `GITHUB_CLIENT_SECRET` — Required for GitHub OAuth. Must be obtained from GitHub Developer Settings.

**Missing dependencies with fallback:**
- None — all missing items are external API credentials that must be obtained manually.

**Plan must address:** Environment variable setup instructions for all three external credentials. The app must fail gracefully (clear error message) if credentials are missing.

---

## Common Pitfalls

### Pitfall 1: BOTH CSVs Are CP1250, Not UTF-8 [VERIFIED by direct inspection]

**What goes wrong:** `file.text()` reads the file as UTF-8, causing Polish characters (ą, ę, ć, ł, ń, ó, ś, ź, ż) to become garbled mojibake on BOTH ING and IPKO files.
**Why it happens:** The `file` command on both sample files returns `Non-ISO extended-ASCII text` (CP1250/Windows-1250). IPKO is NOT UTF-8 as the requirements document suggests — verified directly with `python3 -c "open(...).read().decode('utf-8')"` which throws `UnicodeDecodeError`. Both banks use CP1250.
**How to avoid:** Read ALL CSV uploads as `Buffer` first, then convert. Use `latin1` (which covers CP1250 byte range for Polish characters):
```typescript
// In POST /import handler — for BOTH ING and IPKO:
const buffer = Buffer.from(await file.arrayBuffer());
const content = buffer.toString('latin1'); // Covers CP1250; Polish chars preserved correctly
```
Do NOT use `file.text()` for either format. The bank_format auto-detection should happen after decoding.
**Warning signs:** Description fields contain garbled characters (`?`, replacement chars, or wrong Polish diacritics); `Data transakcji` header is not found even though the file has it.

**Sample file line counts (VERIFIED):**
- `ing.csv`: 106 lines, 83 transaction rows (after skipping 20 metadata rows + header)
- `ipko.csv`: 256 lines, 252 valid rows (3 Blokada rows excluded, 1 header excluded)

### Pitfall 2: IPKO "Blokada" Rows — Detected After CP1250 Decode [VERIFIED by direct inspection]

**What goes wrong:** Pending transactions without a `Data operacji` date are imported, causing NULL date violations or future-dated transactions.
**Why it happens:** IPKO CSV includes pending card authorizations (`Typ transakcji = "Blokada"`) that have no settlement date yet. The sample has 3 such rows. Because the file is CP1250, string matching must happen on the decoded content — searching the raw bytes will fail.
**How to avoid:** The `preprocessIpkoCsv` function operates on already-decoded content (string). Filter by checking if the decoded line contains `"Blokada"` (with the surrounding quotes as they appear in the CSV):
```typescript
function preprocessIpkoCsv(content: string): string {
  const lines = content.split('\n');
  // Skip header row (line 0), filter Blokada rows
  return [lines[0], ...lines.slice(1).filter(line => !line.includes('"Blokada"'))].join('\n');
}
```
Also validate in the worker: skip any transaction with an empty `date` field.
**Warning signs:** Imported transaction count higher than 252 for the sample IPKO file; `date` column has NULL values.

### Pitfall 3: ING Metadata Header Rows [VERIFIED: header at line 19]

**What goes wrong:** The first 20 rows of ING CSV are metadata (account info, document number, summary statistics) that get parsed as transactions.
**Why it happens:** ING doesn't start with a clean header row. The actual transaction header `"Data transakcji";"Data księgowania";"Dane kontrahenta";...` appears at line index 19 (0-based) in the sample — verified by inspection.
**How to avoid:** Decode content as CP1250 (latin1), then find the header line containing `'Data transakcji'` and strip everything above it. The worker pre-filters before sending to the LLM:
```typescript
function preprocessIngCsv(content: string): string {
  const lines = content.split('\n');
  const headerIndex = lines.findIndex(line => line.includes('Data transakcji'));
  if (headerIndex === -1) throw new Error('ING CSV header not found');
  return lines.slice(headerIndex).join('\n');
}
```
**Warning signs:** Imported transactions include "Lista transakcji", "Dokument nr", "Wygenerowany dnia" as descriptions; transaction count far exceeds 83 for the sample ING file.

### Pitfall 4: ING Amount Format (Comma Decimal Separator)

**What goes wrong:** `amount = "-246,00"` — the comma decimal separator causes `parseFloat` to fail (`parseFloat("-246,00")` returns `-246`, not `-246.00`).
**Why it happens:** ING uses Polish locale formatting (comma as decimal separator, period as thousands separator is not used here).
**How to avoid:** In the LLM prompt, explicitly say: "Amounts use comma as decimal separator. Convert to standard dot decimal format in the output." Also validate in worker: replace `,` with `.` before inserting.
**Warning signs:** Amounts are integer values (e.g., `-246` instead of `-246.00`); `NUMERIC(19,4)` loses precision.

### Pitfall 5: Transfer Detection (ING "Wplata wlasna" / IPKO "Przelew na konto")

**What goes wrong:** Transfers between own accounts (ING → IPKO) are categorized as `expense` or `income`, inflating totals.
**Why it happens:** The bank description contains "Wplata wlasna" (ING) or "Przelew na konto" (IPKO) with sender/receiver matching the user's own accounts. The LLM may not recognize these as internal transfers.
**How to avoid:** Include in the few-shot prompt examples of transfer rows with their correct `raw_type: 'transfer'`. Specifically include:
- ING: `"Wplata wlasna"` with counterparty account `69102024720000680205516705` (IPKO account)
- IPKO: `"Wplata wlasna"` with sender `48 1050 1328 1000 0092 5865 6629` (ING account)
**Warning signs:** `wydatki` and `przychody` totals are inflated by the same amount on the same date.

### Pitfall 6: PGMQ Message Visibility Timeout Too Short

**What goes wrong:** The worker processes a job but the visibility timeout expires before the worker can archive the message. The message reappears and is processed again (duplicate transactions).
**Why it happens:** Default `vt` of 30 seconds is too short for an LLM API call (1-5 seconds) + database insertion (1-2 seconds) + potential retries.
**How to avoid:** Set visibility timeout to **300 seconds (5 minutes)** for import jobs. The worker should archive the message immediately after successful processing, before any slow operations.
**Warning signs:** Duplicate transactions appear on re-import; `import_hash` conflict logs show many skipped rows.

### Pitfall 7: Not Validating LLM Output with Zod

**What goes wrong:** LLM returns a JSON object with wrong types (e.g., `amount: -246.00` instead of positive string), causing DB insert to fail or violate `CHECK (amount > 0)`.
**Why it happens:** LLMs can hallucinate output format even with `json_schema`.
**How to avoid:** Always pass LLM output through a Zod schema before inserting:
```typescript
const ParsedTransactionSchema = z.object({
  date: z.iso.date(),
  amount: z.string().regex(/^\d+(\.\d{1,4})?$/),
  description: z.string().min(1).max(2000),
  raw_type: z.enum(['income', 'expense', 'transfer']),
});
```
**Warning signs:** DB insert errors for `amount` column; `CHECK` constraint violations.

### Pitfall 8: Mixing Better Auth `pg` Pool with App `postgres.js`

**What goes wrong:** Using the same connection pool for both Better Auth and application queries causes connection exhaustion or transaction isolation issues.
**Why it happens:** Better Auth creates its own `pg.Pool` internally. The app uses `postgres.js`. They have different connection pools.
**How to avoid:** Keep them separate. Better Auth manages its own pool. The app uses the `postgres.js` singleton. Do not try to share a single pool instance.
**Warning signs:** "Too many clients" errors from Postgres; connection pool exhaustion.

### Pitfall 9: `api.test.ts` Health Check Assertion Breaks After Phase 2 [VERIFIED: code inspection]

**What goes wrong:** The existing `api.test.ts` test at line 40 asserts `expect(json.data).toEqual({ db: true, pgmq: true })` (exact equality). When Plan 02-02 adds `import_queue: true` to the health response, this assertion fails because `toEqual` checks all keys.
**Why it happens:** `toEqual` in bun:test checks for exact structural equality, not a subset. Adding a new key to the health response object breaks all existing assertions that use `toEqual`.
**How to avoid:** Plan 02-02 must ALSO update the `api.test.ts` health check test to: `expect(json.data).toMatchObject({ db: true, pgmq: true })` OR update the assertion to include `import_queue: true`. The plan currently does not mention this required change to `api.test.ts`.
**Warning signs:** `bun test tests/api.test.ts` fails on health/db test after running Plan 02-02.

### Pitfall 10: Auth Testing — No Real OAuth in CI [VERIFIED: code inspection]

**What goes wrong:** Plans 02-01 and 02-03 require authenticated requests in tests, but Better Auth's OAuth providers (Google/GitHub) require real redirect flows that cannot work in unit/integration tests.
**Why it happens:** OAuth 2.0 requires user browser interaction. You cannot mock the OAuth provider flow in a unit test without significant infrastructure.
**How to avoid:** Enable `emailAndPassword: { enabled: true }` in the Better Auth config (either always or conditionally when `NODE_ENV === 'test'`). This allows `POST /api/auth/sign-up/email` and `POST /api/auth/sign-in/email` endpoints which work synchronously in tests. Use Better Auth's `api.signUpEmail({ body: {...} })` server-side API to create a test user and obtain a session cookie for test assertions. Better Auth also exposes `api.createSession` for direct session creation without credentials.

```typescript
// In test beforeAll:
const testUser = { email: 'test@example.com', password: 'testpassword123', name: 'Test User' };
const signupRes = await auth.api.signUpEmail({ body: testUser });
const sessionCookie = signupRes.headers?.get('set-cookie') ?? '';

// Then in requests:
await app.request('/import', { method: 'POST', headers: { Cookie: sessionCookie } });
```

**Warning signs:** 401 on all auth-protected test requests; tests pass individually but fail in CI without credentials; "provider not configured" errors when using OAuth endpoints in tests.

---

## Code Examples

### CP1250 Decoding (Required for BOTH ING and IPKO)

```typescript
// Source: [VERIFIED: direct inspection of ing.csv and ipko.csv — both are CP1250/Non-ISO-ASCII]
// Apply this in the POST /import handler BEFORE format detection
async function decodeCsvContent(file: File): Promise<string> {
  const buffer = Buffer.from(await file.arrayBuffer());
  return buffer.toString('latin1'); // latin1 covers CP1250 byte range for Polish characters
}
```

**Critical:** Do NOT use `file.text()` for either format. Both sample files fail UTF-8 decode. The `latin1` encoding covers the CP1250 byte range and preserves all Polish diacritics correctly.

### ING CSV Preprocessing (Header Detection)

```typescript
// Source: [VERIFIED: direct inspection of ing.csv — header at line 19, 83 transaction rows]
function preprocessIngCsv(content: string): string {
  const lines = content.split('\n');
  // Header "Data transakcji" appears at line 19 (0-indexed) in sample ing.csv
  const headerIndex = lines.findIndex(
    (line) => line.includes('Data transakcji')
  );
  if (headerIndex === -1) {
    throw new Error('ING CSV header not found');
  }
  return lines.slice(headerIndex).join('\n');
}
```

### IPKO CSV Preprocessing (Blokada Filter)

```typescript
// Source: [VERIFIED: direct inspection of ipko.csv — 3 Blokada rows, 252 valid rows]
function preprocessIpkoCsv(content: string): string {
  const lines = content.split('\n');
  // Preserve header (line 0), filter Blokada rows from data rows
  // "Blokada" appears as the 3rd field in quoted CSV: ,"Blokada",
  return [lines[0], ...lines.slice(1).filter((line) => !line.includes('"Blokada"'))].join('\n');
}
```

### Few-Shot Prompt Construction

```typescript
// Source: [CITED: REQUIREMENTS.md REQ-4.6 + sample CSV analysis]
function buildFewShotPrompt(format: 'ing' | 'ipko', csvRows: string): string {
  const ingExamples = `
Example 1:
Input: 2026-05-27;2026-05-27;" SOFTWAREMILL";"NIP/6392015837/Faktura VAT nr FVS/4 /05/2026";...;33495,98;PLN
Output: {"date":"2026-05-27","amount":"33495.98","description":"SoftwareMill - Faktura VAT FVS/4/05/2026","raw_type":"income"}

Example 2:
Input: 2026-05-05;2026-05-05;" P4 sp. z o. o.";"9512120077-20260603-041168C00305-0D";...;-246,00;PLN
Output: {"date":"2026-05-05","amount":"246.00","description":"P4 sp. z o.o. - 9512120077-20260603-041168C00305-0D","raw_type":"expense"}

Example 3:
Input: 2026-05-25;2026-05-25;" Olaf Krawczyk";"Wplata wlasna";...;-8000,00;PLN
Output: {"date":"2026-05-25","amount":"8000.00","description":"Wplata wlasna - Olaf Krawczyk","raw_type":"transfer"}
`;

  const ipkoExamples = `
Example 1:
Input: "2026-05-25","2026-05-25","Przelew na konto","+8000.00","PLN","+8200.05","Tytu: Wplata wlasna"
Output: {"date":"2026-05-25","amount":"8000.00","description":"Wplata wlasna","raw_type":"transfer"}

Example 2:
Input: "2026-05-04","2026-05-04","Patno kart","-11.99","PLN","+5421.49","Tytu: ZABKA Z0685 K.2"
Output: {"date":"2026-05-04","amount":"11.99","description":"ZABKA Z0685 K.2","raw_type":"expense"}
`;

  return `
You are a financial transaction parser for Polish bank CSV exports.
Bank format: ${format === 'ing' ? 'ING (semicolon-delimited, comma decimal, ISO-8859-2)' : 'IPKO (comma-quoted, UTF-8, signed amounts)'}

Rules:
- Date format: YYYY-MM-DD
- Amount: ALWAYS positive decimal string with dot separator (e.g., "123.45")
- Description: concise, clean description (remove transaction IDs, card numbers, bank names)
- raw_type: "income" for money received, "expense" for money spent, "transfer" for between own accounts

${format === 'ing' ? ingExamples : ipkoExamples}

Now parse these rows. Return ONLY a JSON object with a "transactions" array. No markdown, no explanations.

Rows to parse:
${csvRows}
`;
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom CSV parser with regex | LLM-powered parsing with few-shot prompt | 2024-2025 | Handles format variations without code changes; 10x less CSV parsing code |
| `json_object` response mode | `json_schema` with strict validation | OpenRouter 2025 | More reliable structured output; validates schema at API level |
| `pgmq-js` npm wrapper | Raw SQL via `postgres.js` | Phase 1 decision | Fewer dependencies; direct SQL control over queue operations |
| `jsonwebtoken` + custom OAuth | Better Auth framework | 2024-2025 | Single library handles OAuth, sessions, DB schema, and security |
| `@hono/node-server` | Bun native `export default { port, fetch }` | Phase 1 decision | Zero overhead HTTP server on Bun |

**Deprecated/outdated:**
- `jsonwebtoken` for session management: Better Auth handles this internally.
- `passport.js` for OAuth: Better Auth is the modern replacement.
- `csv-parse` / `papaparse` for bank CSVs: LLM parsing is simpler for heterogeneous formats.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | OpenRouter `json_schema` mode is available for `openai/gpt-4o-mini` | Pattern 4 | Medium — if not supported, fallback to `json_object` and manual Zod validation |
| A2 | Few-shot prompt with 3 examples per format is sufficient for reliable parsing | Pattern 4 | Medium — if accuracy is low, increase to 5 examples or switch to fine-tuned model |
| A3 | `auth.api.signUpEmail()` server-side call creates a usable session cookie for test assertions | Pitfall 10 | Low — fallback is to directly insert a session row into the DB using Better Auth's migrated schema |
| A4 | Better Auth's `emailAndPassword` credential fields are co-located in the `account` table created by the standard migration | Auth testing | Low — verified by Better Auth source; no separate table needed |

**VERIFIED claims (previously assumed):**
- Both ING and IPKO CSVs are CP1250: VERIFIED by `file` command and Python decode test
- `Buffer.toString('latin1')` correctly decodes both: VERIFIED — latin1 covers CP1250 byte range
- ING header is at line 19 (0-indexed): VERIFIED by direct inspection (83 transaction rows)
- IPKO has 3 Blokada rows, 252 valid rows: VERIFIED by direct inspection
- Better Auth accepts `new Pool({ connectionString })` directly: VERIFIED by Context7 docs

---

## Open Questions (RESOLVED)

1. **OpenRouter API Key availability** ✅ RESOLVED
   - What we know: The app needs `OPENROUTER_API_KEY` for CSV parsing.
   - Resolution: Plans 02-04 includes `user_setup` checkpoint for OpenRouter API key. Fallback: manual entry UI deferred to Phase 3.
   - Batch size: 50 rows per batch (recommended in 02-04).

2. **OAuth App registration** ✅ RESOLVED
   - What we know: Google and GitHub OAuth require app registration.
   - Resolution: Plan 02-01 includes `user_setup` checkpoint for OAuth credentials. App starts without auth if credentials missing (graceful degradation).

3. **Worker deployment strategy** ✅ RESOLVED
   - What we know: The worker needs to run continuously.
   - Resolution: Plan 02-04 specifies `bun run src/workers/import-worker.ts` as separate process. Production deployment (systemd/Docker) deferred.

4. **Import batch size** ✅ RESOLVED
   - What we know: Historical data has thousands of transactions.
   - Resolution: 50 rows per batch chosen for cost/accuracy balance. Documented in 02-04.

---

## Environment Availability

### Dependency Verification

```bash
# Check Bun
bun --version
# Expected: 1.2.x

# Check Postgres + PGMQ
curl -s http://localhost:5432 || echo "Postgres not running"
docker ps | grep finance-postgres

# Check OpenRouter (requires API key)
curl -s https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | head -5

# Check environment variables
env | grep -E "(DATABASE_URL|OPENROUTER|GOOGLE|GITHUB)"
```

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bun Test (built-in, no install needed) |
| Config file | `bunfig.toml` (already exists) |
| Quick run command | `bun test` |
| Full suite command | `bun test --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-4.1 | POST /import accepts CSV + account_id, returns job_id | HTTP Integration | `bun test tests/import-api.test.ts` | ❌ Wave 0 |
| REQ-4.2 | PGMQ worker calls OpenRouter, inserts transactions | Integration | `bun test tests/import-worker.test.ts` | ❌ Wave 0 |
| REQ-4.3 | ING format: skip header, comma decimal, negative=expense | Unit | `bun test tests/import-parse.test.ts` | ❌ Wave 0 |
| REQ-4.4 | IPKO format: skip Blokada, signed amounts | Unit | `bun test tests/import-parse.test.ts` | ❌ Wave 0 |
| REQ-4.5 | Deduplication: import_hash skips duplicates | DB Integration | `bun test tests/import-dedup.test.ts` | ❌ Wave 0 |
| REQ-4.6 | Few-shot prompt returns valid JSON | Integration | `bun test tests/import-llm.test.ts` | ❌ Wave 0 |
| REQ-4.7 | Bulk import handles thousands of rows | Performance | `bun test tests/import-bulk.test.ts` | ❌ Wave 0 |
| REQ-6 | Better Auth OAuth login flow | HTTP Integration | `bun test tests/auth.test.ts` | ❌ Wave 0 |
| REQ-6 | Protected routes require session | HTTP Integration | `bun test tests/auth.test.ts` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bun test` (all tests)
- **Per wave merge:** `bun test --coverage`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `tests/import-api.test.ts` — file upload + enqueue + status endpoint
- [ ] `tests/import-worker.test.ts` — worker dequeue + mock OpenRouter + insert
- [ ] `tests/import-parse.test.ts` — ING/IPKO preprocessing + row extraction
- [ ] `tests/import-dedup.test.ts` — SHA-256 conflict handling
- [ ] `tests/import-llm.test.ts` — OpenRouter integration (may need mock server)
- [ ] `tests/auth.test.ts` — Better Auth session middleware + protected routes
- [ ] `tests/api.test.ts` — Phase 1 routes must be updated to test 401 without auth
- [ ] `src/workers/import-worker.ts` — worker entry point
- [ ] `src/auth.ts` — Better Auth configuration
- [ ] `src/core/import/entities.ts` — Import domain types
- [ ] `src/application/schemas/import.ts` — Import Zod schemas
- [ ] `src/interface-adapters/api/import.ts` — Import routes
- [ ] `src/interface-adapters/api/auth.ts` — Auth middleware
- [ ] `src/infrastructure/db/schema.sql` — Add `import_jobs` table + `import_queue` init

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Better Auth OAuth 2.0 with PKCE |
| V3 Session Management | yes | Better Auth HTTP-only cookies, CSRF tokens |
| V4 Access Control | yes | Hono middleware `requireAuth` on all protected routes |
| V5 Input Validation | yes | Zod v4 schemas for all API inputs; Zod for LLM output validation |
| V6 Cryptography | yes | SHA-256 for import_hash (not for security, for dedup) |
| V13 Data Protection | yes | No sensitive data in logs; API key in env var |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Session hijacking | Spoofing | Better Auth HTTP-only, Secure, SameSite=Lax cookies |
| CSRF on OAuth callback | Spoofing | Better Auth built-in CSRF protection for OAuth state |
| File upload path traversal | Tampering | Store uploaded files in `/tmp` with random names; never use user-provided filenames |
| CSV injection / formula injection | Tampering | Sanitize descriptions before display; LLM output is plain text |
| LLM prompt injection | Tampering | Few-shot prompt includes explicit instructions; validate output with Zod |
| Replay of import job | Spoofing | `requireAuth` on /import; `import_hash` dedup prevents duplicate transactions |
| OpenRouter API key exposure | Information Disclosure | Store in env var; never log or send to client |
| OAuth client secret exposure | Information Disclosure | Store in env var; never sent to client |
| SQL injection in import worker | Tampering | `postgres.js` tagged template literals auto-parameterize all values |

---

## Sources

### Primary (HIGH confidence)
- Context7 `/better-auth/better-auth` — `new Pool({ connectionString })` database config, `emailAndPassword` config, `signUpEmail` API
- Context7 `/websites/better-auth` — Hono integration, OAuth providers, session middleware, CORS config
- Context7 `/websites/openrouter_ai` — Chat completions API, JSON schema response format, model selection
- Context7 `/pgmq/pgmq` — `pgmq.read`, `pgmq.archive`, `pgmq.delete`, visibility timeout, queue management
- Context7 `/websites/hono_dev` — Hono app structure, `c.req.formData()`, `createMiddleware`, `c.req.raw`
- Context7 `/websites/zod_dev_v4` — Zod v4 API, `z.uuid()`, `z.iso.date()`, schema validation
- Sample CSV direct inspection (`ing.csv`, `ipko.csv`) — encoding confirmed CP1250 via `file` command and Python decode test; row counts verified

### Secondary (MEDIUM confidence)
- Official Better Auth docs: https://better-auth.com/docs/integrations/hono — Hono-specific setup verified
- Official OpenRouter docs: https://openrouter.ai/docs/api — API endpoint and response format verified
- Phase 1 codebase (`src/`, `index.ts`, `tests/`) — Existing patterns confirmed; api.test.ts health assertion breakage identified by code inspection
- better-auth node_modules inspection (`dist/test-utils/`, `dist/auth/full.mjs`) — test instance pattern and email/password auth verified

### Tertiary (LOW confidence)
- None — all major claims verified against Context7, official documentation, or direct code/file inspection.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages confirmed via npm registry + Context7; versions from installed package.json
- Better Auth integration: HIGH — verified against Context7 and official docs; Hono integration is documented
- OpenRouter API: HIGH — verified against Context7; structured outputs (`json_schema`) confirmed
- PGMQ worker: HIGH — verified against Context7; raw SQL patterns confirmed
- CSV formats: HIGH — verified by direct inspection of sample files
- Pitfalls: HIGH — most are verified by sample CSV analysis and official documentation

**Research date:** 2026-06-06 (updated 2026-06-06 with codebase inspection corrections)
**Valid until:** 2026-07-06 (30 days — stable libraries, but OpenRouter model availability may change)

**Update notes (2026-06-06):**
- CORRECTED: IPKO CSV is CP1250, not UTF-8 (verified by direct decode test)
- CORRECTED: Both ING and IPKO require `Buffer.toString('latin1')` decode (not `file.text()`)
- ADDED: Pitfall 9 — api.test.ts health check will break when `import_queue` is added to response
- ADDED: Pitfall 10 — auth testing requires `emailAndPassword: { enabled: true }` in Better Auth config
- VERIFIED: ING has 83 transaction rows; IPKO has 252 valid rows (3 Blokada excluded)
- VERIFIED: Better Auth `new Pool({ connectionString })` is the correct pg config (not Kysely dialect)

---

## Key Decisions and Recommendations for the Planner

1. **Use `json_schema` response format, not `json_object`:** OpenRouter's `json_schema` mode enforces schema at the API level, reducing validation failures. This is the standard approach for structured outputs.

2. **Worker as separate process:** Run `bun run src/workers/import-worker.ts` in a separate terminal/process. Do not run the worker in the HTTP server process. This is the standard pattern for background job processing.

3. **Batch size of 50 rows per LLM call:** This balances cost (OpenRouter charges per token) and accuracy. 50 rows of Polish CSV ≈ 1000-1500 tokens. Historical bulk import of 1000 rows = 20 API calls.

4. **Use `openai/gpt-4o-mini`:** At ~$0.15 per 1M input tokens, it's the most cost-effective model that reliably follows JSON schema instructions. `gpt-4o` is 10x more expensive with marginal accuracy gains for this task.

5. **Preprocess CSV before sending to LLM:** Don't send the raw CSV. For ING: find the `Data transakcji` header and strip everything above it. For IPKO: filter out `Blokada` rows. This reduces token count and prevents hallucination on metadata.

6. **Add `import_jobs` table for status tracking:** PGMQ doesn't expose per-message status by ID. Create a simple table to track `pending → processing → completed/failed` with `processed` count and `errors[]`.

7. **Protect ALL Phase 1 routes with `requireAuth`:** After implementing auth, add `requireAuth` middleware to `/transactions`, `/opening-balance`, `/summary`, `/accounts`, `/categories`. The Phase 1 tests will need to be updated to include auth headers.

8. **Keep Better Auth `pg` pool separate from app `postgres.js`:** Better Auth manages its own connection pool. The app should continue using the `postgres.js` singleton for all non-auth queries.

9. **Environment variables needed:** `OPENROUTER_API_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`. The app must fail gracefully with a clear error message if any are missing.

10. **Test strategy:** Use Bun's `Bun.serve()` on a local port to mock the OpenRouter API response in worker tests. No external packages needed. Enable `emailAndPassword: { enabled: true }` in Better Auth config to allow sync sign-up/sign-in in tests without real OAuth flow.

11. **BOTH CSV files are CP1250, not UTF-8 [VERIFIED]:** Always decode uploaded CSVs as `Buffer.from(await file.arrayBuffer()).toString('latin1')`. Never use `file.text()`. This applies to both ING and IPKO formats — the REQUIREMENTS.md incorrectly describes IPKO as UTF-8.

12. **Fix `api.test.ts` health check when adding `import_queue` to health response:** The existing test asserts `toEqual({ db: true, pgmq: true })`. After Plan 02-02 adds `import_queue: true` to the health response, this test will fail. Plan 02-02 must also update this test to `toMatchObject({ db: true, pgmq: true })` or include `import_queue: true`.

13. **Verified expected transaction counts from sample files:** ING sample: 83 valid transactions (after skipping 20 metadata rows). IPKO sample: 252 valid transactions (after removing 3 Blokada rows). Plans can use these as exact verification targets.

---

## RESEARCH COMPLETE
