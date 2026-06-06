# Phase 1: Foundation (Core Ledger & DB) - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 13 new files (greenfield — no existing source code)
**Analogs found:** 0 / 13 (no codebase to draw from; all patterns sourced from RESEARCH.md verified references)

---

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `src/index.ts` | entrypoint | request-response | none | no analog |
| `src/infrastructure/db/client.ts` | config | request-response | none | no analog |
| `src/infrastructure/db/schema.sql` | migration | batch | none | no analog |
| `src/infrastructure/db/seed.sql` | migration | batch | none | no analog |
| `src/infrastructure/db/health.ts` | utility | request-response | none | no analog |
| `src/core/ledger/entities.ts` | model | — | none | no analog |
| `src/core/ledger/use-cases.ts` | service | CRUD | none | no analog |
| `src/application/schemas/ledger.ts` | utility | transform | none | no analog |
| `src/interface-adapters/api/ledger.ts` | controller | request-response | none | no analog |
| `src/interface-adapters/api/opening-balance.ts` | controller | CRUD | none | no analog |
| `src/interface-adapters/api/reference.ts` | controller | request-response | none | no analog |
| `tsconfig.json` | config | — | none | no analog |
| `tests/schemas.test.ts` | test | — | none | no analog |
| `tests/ledger.test.ts` | test | — | none | no analog |
| `tests/queue.test.ts` | test | — | none | no analog |

---

## Pattern Assignments

### `src/index.ts` (entrypoint, request-response)

**Source:** RESEARCH.md Pattern 1 — verified against Context7 hono.dev/docs/getting-started/bun

**Bun + Hono entry point — full pattern:**
```typescript
import { Hono } from 'hono'
import { ledgerRoutes } from './interface-adapters/api/ledger'
import { openingBalanceRoutes } from './interface-adapters/api/opening-balance'
import { referenceRoutes } from './interface-adapters/api/reference'
import { healthDb } from './infrastructure/db/health'

const app = new Hono()

// Health
app.get('/health', (c) => c.json({ data: { ok: true }, error: null, meta: null }))
app.get('/health/db', async (c) => {
  const result = await healthDb()
  return c.json({ data: result, error: null, meta: null })
})

// Domain routes
app.route('/transactions', ledgerRoutes)
app.route('/opening-balance', openingBalanceRoutes)
app.route('/', referenceRoutes)

// Bun-native server export — no @hono/node-server
export default {
  port: Number(process.env.PORT) || 3000,
  fetch: app.fetch,
}
```

**Critical:** Do NOT use `@hono/node-server`. Bun uses `export default { port, fetch }` natively.

---

### `src/infrastructure/db/client.ts` (config, singleton)

**Source:** RESEARCH.md Pattern 4 — verified against Context7 porsager/postgres

**postgres.js singleton — full pattern:**
```typescript
import postgres from 'postgres'

const sql = postgres(process.env.DATABASE_URL!, {
  max: 10,
  idle_timeout: 20,
})

export default sql
```

**Notes:**
- Use `DATABASE_URL` as the env var name (most common convention per RESEARCH.md open question resolution).
- `max: 10` connection pool; `idle_timeout: 20` seconds.
- NUMERIC columns come back as JavaScript strings — this is intentional. Do not configure `types` to parse them as numbers.

---

### `src/infrastructure/db/schema.sql` (migration, DDL)

**Source:** RESEARCH.md "Definitive Database Schema" section — authoritative, supersedes all old plan schemas.

**Full DDL (copy verbatim):**
```sql
-- Accounts: ING business + IPKO personal
CREATE TABLE accounts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('personal', 'business')),
  currency   TEXT NOT NULL DEFAULT 'PLN',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Categories: 25 total (arval replaces auto; D-07)
CREATE TABLE categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL UNIQUE,
  is_fixed_cost BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Single-entry ledger: income | expense | transfer
CREATE TABLE transactions (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id             UUID NOT NULL REFERENCES accounts(id),
  category_id            UUID REFERENCES categories(id),
  type                   TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  amount                 NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
  description            TEXT,
  date                   DATE NOT NULL,
  transfer_to_account_id UUID REFERENCES accounts(id),
  import_hash            TEXT UNIQUE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Global monthly opening balance = total net worth (D-01, D-02)
-- NO account_id — tracks all asset classes combined
CREATE TABLE monthly_opening_balances (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  year            INT NOT NULL,
  month           INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  opening_balance NUMERIC(19, 4) NOT NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (year, month)
);

-- Indexes
CREATE INDEX idx_tx_account_date ON transactions(account_id, date DESC);
CREATE INDEX idx_tx_category     ON transactions(category_id);
CREATE INDEX idx_tx_date_type    ON transactions(date, type);
CREATE INDEX idx_mob_year_month  ON monthly_opening_balances(year, month);

-- Immutability triggers (REQ-1.2)
CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Transactions are immutable. Use a correcting entry instead.';
END;
$$;

CREATE TRIGGER trg_transactions_no_update
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_immutable_change();

CREATE TRIGGER trg_transactions_no_delete
  BEFORE DELETE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_immutable_change();
```

**Schema anti-patterns to never introduce:**
- `account_id` on `monthly_opening_balances` — D-01 explicitly removes this
- `UNIQUE(account_id, year, month)` — wrong; must be `UNIQUE(year, month)`
- `FLOAT` or `REAL` for any monetary column — always `NUMERIC(19,4)`
- A `ledger_entries` table — this is single-entry, not double-entry

---

### `src/infrastructure/db/seed.sql` (migration, batch)

**Source:** RESEARCH.md "Category Seed Data" section — D-05, D-06, D-07, D-08

**Full seed (copy verbatim — 25 categories, 6 fixed costs):**
```sql
INSERT INTO categories (name, is_fixed_cost) VALUES
  ('biedronka',   false),
  ('żabka',       false),
  ('paliwo',      false),
  ('taxi',        false),
  ('fun',         false),
  ('VAT',         true),
  ('PIT36',       true),
  ('ZUS',         true),
  ('arval',       true),
  ('biuro',       false),
  ('mieszkanie',  true),
  ('przejazdy',   false),
  ('kawa',        false),
  ('kredyt',      true),
  ('lidl',        false),
  ('ubrania',     false),
  ('rossman',     false),
  ('apteka',      false),
  ('lekarz',      false),
  ('kluska',      false),
  ('krypto',      false),
  ('inwestycje',  false),
  ('prezenty',    false),
  ('restauracje', false),
  ('foto',        false)
ON CONFLICT (name) DO NOTHING;
```

**Verification query:** `SELECT COUNT(*) FROM categories WHERE is_fixed_cost = true` → must return 6.

**PGMQ queue initialization (add to seed or schema apply script):**
```sql
SELECT pgmq.create('analysis_queue');
```

---

### `src/infrastructure/db/health.ts` (utility, request-response)

**Source:** RESEARCH.md Pattern 6 — PGMQ SQL API

**DB health check — pattern:**
```typescript
import sql from './client'

export async function healthDb(): Promise<{ db: boolean; pgmq: boolean }> {
  try {
    await sql`SELECT 1`
    const queues = await sql`SELECT queue_name FROM pgmq.list_queues()`
    const pgmqReady = queues.some((q: { queue_name: string }) => q.queue_name === 'analysis_queue')
    return { db: true, pgmq: pgmqReady }
  } catch {
    return { db: false, pgmq: false }
  }
}
```

---

### `src/core/ledger/entities.ts` (model)

**Source:** RESEARCH.md Patterns 4 and 5 — postgres.js NUMERIC-as-string behavior

**TypeScript domain types — pattern:**
```typescript
// NUMERIC(19,4) columns are typed as string — postgres.js returns them as strings.
// Never use number for monetary fields.

export interface Transaction {
  id: string                          // UUID
  account_id: string
  category_id: string | null
  type: 'income' | 'expense' | 'transfer'
  amount: string                      // NUMERIC(19,4) as string, e.g. "1234.5000"
  description: string | null
  date: string                        // DATE as ISO string, e.g. "2024-01-15"
  transfer_to_account_id: string | null
  import_hash: string | null
  created_at: string                  // TIMESTAMPTZ as ISO string
}

export interface MonthlyOpeningBalance {
  id: string
  year: number
  month: number
  opening_balance: string             // NUMERIC(19,4) as string
  notes: string | null
  created_at: string
}

export interface Account {
  id: string
  name: string
  type: 'personal' | 'business'
  currency: string
  created_at: string
}

export interface Category {
  id: string
  name: string
  is_fixed_cost: boolean
  created_at: string
}

// Summary row (computed in app layer from SQL aggregation)
export interface MonthlySummaryRow {
  month: string                       // "YYYY-MM"
  wydatki: string                     // total expenses (excluding transfers)
  przychody: string                   // total income
  fixed_cost_total: string            // sum of fixed-cost categories
  wydatki_bez_stalych: string         // wydatki - fixed_cost_total (computed)
  zaoszczedzone: string               // przychody - wydatki (computed)
  zaoszczedzone_log: string           // log10(zaoszczedzone) if > 0, else "0" (computed)
  stan_konta: string | null           // opening_balance + cumulative net (null if no opening balance set)
}
```

---

### `src/application/schemas/ledger.ts` (utility, transform)

**Source:** RESEARCH.md Pattern 3 — Zod v4 API (verified Context7 zod.dev/v4)

**Zod v4 input schemas — full pattern:**
```typescript
import * as z from 'zod'

// POST /transactions
export const CreateTransactionSchema = z.object({
  account_id: z.uuid(),
  category_id: z.uuid().nullable().optional(),
  type: z.enum(['income', 'expense', 'transfer']),
  amount: z.string().regex(/^\d+(\.\d{1,4})?$/, 'Amount must be a positive decimal with up to 4 places'),
  description: z.string().max(2000).nullable().optional(),
  date: z.iso.date(),
  transfer_to_account_id: z.uuid().nullable().optional(),
})

// POST /opening-balance
export const CreateOpeningBalanceSchema = z.object({
  year: z.number().int().min(2000).max(2100),
  month: z.number().int().min(1).max(12),
  opening_balance: z.string().regex(/^-?\d+(\.\d{1,4})?$/, 'opening_balance must be a decimal with up to 4 places'),
  notes: z.string().max(1000).nullable().optional(),
})

// PUT /opening-balance/:id
export const UpdateOpeningBalanceSchema = CreateOpeningBalanceSchema.partial()

// GET /transactions query params
export const ListTransactionsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  per_page: z.coerce.number().int().min(1).max(500).default(50),
  account_id: z.uuid().optional(),
  type: z.enum(['income', 'expense', 'transfer']).optional(),
  date_from: z.iso.date().optional(),
  date_to: z.iso.date().optional(),
})

export type CreateTransactionInput = z.infer<typeof CreateTransactionSchema>
export type CreateOpeningBalanceInput = z.infer<typeof CreateOpeningBalanceSchema>
export type UpdateOpeningBalanceInput = z.infer<typeof UpdateOpeningBalanceSchema>
export type ListTransactionsQuery = z.infer<typeof ListTransactionsQuerySchema>
```

**Critical:** `z.string().uuid()` is deprecated in Zod v4. Always use `z.uuid()` (top-level). Same for `z.iso.date()` instead of `z.string().regex(...)`.

---

### `src/core/ledger/use-cases.ts` (service, CRUD)

**Source:** RESEARCH.md Patterns 4, 6, 7, 8 — postgres.js, PGMQ, summary query

**Use-case functions — pattern:**
```typescript
import sql from '../../infrastructure/db/client'
import type { Transaction, MonthlyOpeningBalance, MonthlySummaryRow } from './entities'
import type { CreateTransactionInput, CreateOpeningBalanceInput, UpdateOpeningBalanceInput } from '../../application/schemas/ledger'

// createTransaction: atomic insert + PGMQ enqueue
export async function createTransaction(input: CreateTransactionInput): Promise<Transaction> {
  const row = await sql.begin(async sql => {
    const [tx] = await sql`
      INSERT INTO transactions
        (account_id, category_id, type, amount, description, date, transfer_to_account_id)
      VALUES
        (${input.account_id}, ${input.category_id ?? null}, ${input.type},
         ${input.amount}, ${input.description ?? null}, ${input.date},
         ${input.transfer_to_account_id ?? null})
      RETURNING *
    `
    await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({ transaction_id: tx.id })})`
    return tx
  })
  return row as Transaction
}

// listTransactions: paginated, filtered
export async function listTransactions(params: {
  page: number; per_page: number;
  account_id?: string; type?: string; date_from?: string; date_to?: string
}): Promise<{ rows: Transaction[]; total: number }> {
  const { page, per_page, account_id, type, date_from, date_to } = params
  const offset = (page - 1) * per_page

  const rows = await sql`
    SELECT * FROM transactions
    WHERE true
      ${account_id ? sql`AND account_id = ${account_id}` : sql``}
      ${type ? sql`AND type = ${type}` : sql``}
      ${date_from ? sql`AND date >= ${date_from}` : sql``}
      ${date_to ? sql`AND date <= ${date_to}` : sql``}
    ORDER BY date DESC, created_at DESC
    LIMIT ${per_page} OFFSET ${offset}
  `
  const [{ count }] = await sql`
    SELECT COUNT(*) AS count FROM transactions
    WHERE true
      ${account_id ? sql`AND account_id = ${account_id}` : sql``}
      ${type ? sql`AND type = ${type}` : sql``}
      ${date_from ? sql`AND date >= ${date_from}` : sql``}
      ${date_to ? sql`AND date <= ${date_to}` : sql``}
  `
  return { rows: rows as Transaction[], total: Number(count) }
}

// getMonthlySummary: SQL aggregation + app-layer derived fields
export async function getMonthlySummary(): Promise<MonthlySummaryRow[]> {
  const agg = await sql`
    SELECT
      TO_CHAR(t.date, 'YYYY-MM') AS month,
      SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END)::text AS wydatki,
      SUM(CASE WHEN t.type = 'income'  THEN t.amount ELSE 0 END)::text AS przychody,
      SUM(CASE WHEN t.type = 'expense' AND c.is_fixed_cost = true THEN t.amount ELSE 0 END)::text AS fixed_cost_total
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE t.type != 'transfer'
    GROUP BY TO_CHAR(t.date, 'YYYY-MM')
    ORDER BY month ASC
  `
  const balances = await sql`SELECT year, month, opening_balance FROM monthly_opening_balances ORDER BY year, month`
  const balanceMap = new Map(balances.map((b: { year: number; month: number; opening_balance: string }) =>
    [`${b.year}-${String(b.month).padStart(2, '0')}`, b.opening_balance]
  ))

  return agg.map((row: { month: string; wydatki: string; przychody: string; fixed_cost_total: string }) => {
    const wydatki = parseFloat(row.wydatki)
    const przychody = parseFloat(row.przychody)
    const fixedCost = parseFloat(row.fixed_cost_total)
    const wydatkiBezStalych = wydatki - fixedCost
    const zaoszczedzone = przychody - wydatki
    const zaoszczedzone_log = zaoszczedzone > 0 ? Math.log10(zaoszczedzone) : 0
    const openingBalance = balanceMap.get(row.month)
    // stan_konta: opening_balance for month + net of all transactions in that month
    // (cumulative: for a given month, net = przychody - wydatki)
    const stan_konta = openingBalance != null
      ? String(parseFloat(openingBalance) + zaoszczedzone)
      : null

    return {
      month: row.month,
      wydatki: wydatki.toFixed(4),
      przychody: przychody.toFixed(4),
      fixed_cost_total: fixedCost.toFixed(4),
      wydatki_bez_stalych: wydatkiBezStalych.toFixed(4),
      zaoszczedzone: zaoszczedzone.toFixed(4),
      zaoszczedzone_log: zaoszczedzone_log.toFixed(6),
      stan_konta: stan_konta != null ? parseFloat(stan_konta).toFixed(4) : null,
    }
  })
}
```

---

### `src/interface-adapters/api/ledger.ts` (controller, request-response)

**Source:** RESEARCH.md Patterns 1, 2, 3 — Hono routes, zValidator, standard envelope

**Hono route handler pattern:**
```typescript
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import { CreateTransactionSchema, ListTransactionsQuerySchema } from '../../application/schemas/ledger'
import { createTransaction, listTransactions, getMonthlySummary } from '../../core/ledger/use-cases'

export const ledgerRoutes = new Hono()

// POST /transactions
ledgerRoutes.post(
  '/',
  zValidator('json', CreateTransactionSchema),
  async (c) => {
    try {
      const input = c.req.valid('json')
      const tx = await createTransaction(input)
      return c.json({ data: tx, error: null, meta: null }, 201)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error'
      const status = message.includes('immutable') ? 409 : 500
      return c.json({ data: null, error: { message }, meta: null }, status)
    }
  }
)

// GET /transactions
ledgerRoutes.get(
  '/',
  zValidator('query', ListTransactionsQuerySchema),
  async (c) => {
    try {
      const query = c.req.valid('query')
      const { rows, total } = await listTransactions(query)
      return c.json({
        data: rows,
        error: null,
        meta: { total, page: query.page, per_page: query.per_page }
      }, 200)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error'
      return c.json({ data: null, error: { message }, meta: null }, 500)
    }
  }
)

// GET /summary
ledgerRoutes.get('/summary', async (c) => {
  try {
    const rows = await getMonthlySummary()
    return c.json({ data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } }, 200)
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error'
    return c.json({ data: null, error: { message }, meta: null }, 500)
  }
})
```

**Validation error hook (add to all zValidator calls for consistent envelope):**
```typescript
zValidator('json', CreateTransactionSchema, (result, c) => {
  if (!result.success) {
    return c.json(
      { data: null, error: { message: 'Validation failed', details: result.error.flatten() }, meta: null },
      400
    )
  }
})
```

---

### `src/interface-adapters/api/opening-balance.ts` (controller, CRUD)

**Source:** RESEARCH.md D-04, Patterns 2 and 3

**Opening balance CRUD — pattern:**
```typescript
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import { CreateOpeningBalanceSchema, UpdateOpeningBalanceSchema } from '../../application/schemas/ledger'
import { createOpeningBalance, updateOpeningBalance, listOpeningBalances } from '../../core/ledger/use-cases'

export const openingBalanceRoutes = new Hono()

// GET /opening-balance
openingBalanceRoutes.get('/', async (c) => {
  try {
    const year = c.req.query('year')
    const month = c.req.query('month')
    const rows = await listOpeningBalances({ year: year ? Number(year) : undefined, month: month ? Number(month) : undefined })
    return c.json({ data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } }, 200)
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error'
    return c.json({ data: null, error: { message }, meta: null }, 500)
  }
})

// POST /opening-balance
openingBalanceRoutes.post(
  '/',
  zValidator('json', CreateOpeningBalanceSchema, (result, c) => {
    if (!result.success) return c.json({ data: null, error: { message: 'Validation failed' }, meta: null }, 400)
  }),
  async (c) => {
    try {
      const input = c.req.valid('json')
      const row = await createOpeningBalance(input)
      return c.json({ data: row, error: null, meta: null }, 201)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error'
      const status = message.includes('unique') || message.includes('duplicate') ? 409 : 500
      return c.json({ data: null, error: { message }, meta: null }, status)
    }
  }
)

// PUT /opening-balance/:id
openingBalanceRoutes.put(
  '/:id',
  zValidator('json', UpdateOpeningBalanceSchema, (result, c) => {
    if (!result.success) return c.json({ data: null, error: { message: 'Validation failed' }, meta: null }, 400)
  }),
  async (c) => {
    try {
      const id = c.req.param('id')
      const input = c.req.valid('json')
      const row = await updateOpeningBalance(id, input)
      if (!row) return c.json({ data: null, error: { message: 'Not found' }, meta: null }, 404)
      return c.json({ data: row, error: null, meta: null }, 200)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal server error'
      return c.json({ data: null, error: { message }, meta: null }, 500)
    }
  }
)
```

---

### `src/interface-adapters/api/reference.ts` (controller, request-response)

**Source:** RESEARCH.md Patterns 1 and 2

**Reference data routes — pattern:**
```typescript
import { Hono } from 'hono'
import sql from '../../infrastructure/db/client'

export const referenceRoutes = new Hono()

referenceRoutes.get('/accounts', async (c) => {
  try {
    const rows = await sql`SELECT * FROM accounts ORDER BY name`
    return c.json({ data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } }, 200)
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error'
    return c.json({ data: null, error: { message }, meta: null }, 500)
  }
})

referenceRoutes.get('/categories', async (c) => {
  try {
    const rows = await sql`SELECT * FROM categories ORDER BY name`
    return c.json({ data: rows, error: null, meta: { total: rows.length, page: 1, per_page: rows.length } }, 200)
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error'
    return c.json({ data: null, error: { message }, meta: null }, 500)
  }
})
```

---

### `tsconfig.json` (config)

**Source:** RESEARCH.md "Standard Stack" — Bun TypeScript setup, verified Context7 oven-sh/bun

**Full tsconfig pattern:**
```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "types": ["bun-types"]
  },
  "include": ["src/**/*", "tests/**/*", "index.ts"]
}
```

---

### `tests/schemas.test.ts` (test)

**Source:** RESEARCH.md "Validation Architecture" — Bun Test (built-in)

**Bun test file structure — pattern:**
```typescript
import { describe, it, expect } from 'bun:test'
import { CreateTransactionSchema, CreateOpeningBalanceSchema } from '../src/application/schemas/ledger'

describe('CreateTransactionSchema', () => {
  it('accepts valid transaction', () => {
    const result = CreateTransactionSchema.safeParse({
      account_id: '00000000-0000-0000-0000-000000000001',
      type: 'expense',
      amount: '42.5000',
      date: '2024-01-15',
    })
    expect(result.success).toBe(true)
  })

  it('rejects invalid uuid with z.uuid() (not z.string().uuid())', () => {
    const result = CreateTransactionSchema.safeParse({
      account_id: 'not-a-uuid',
      type: 'expense',
      amount: '10.00',
      date: '2024-01-15',
    })
    expect(result.success).toBe(false)
  })
})

describe('CreateOpeningBalanceSchema', () => {
  it('accepts negative opening_balance (net worth can be negative)', () => {
    const result = CreateOpeningBalanceSchema.safeParse({
      year: 2024, month: 1, opening_balance: '-500.0000'
    })
    expect(result.success).toBe(true)
  })
})
```

---

### `tests/ledger.test.ts` and `tests/queue.test.ts` (test, DB integration)

**Source:** RESEARCH.md "Phase Requirements → Test Map"

**DB integration test structure — pattern:**
```typescript
import { describe, it, expect, beforeAll, afterAll } from 'bun:test'
import sql from '../src/infrastructure/db/client'

beforeAll(async () => {
  // Ensure clean state; tests assume schema is already applied
  await sql`DELETE FROM transactions`
  await sql`DELETE FROM monthly_opening_balances`
})

afterAll(async () => {
  await sql.end()
})

describe('Transaction immutability (REQ-1.2)', () => {
  it('raises exception on UPDATE', async () => {
    const [tx] = await sql`
      INSERT INTO transactions (account_id, type, amount, date)
      VALUES (/* seeded account id */, 'expense', 10.00, '2024-01-01')
      RETURNING id
    `
    await expect(
      sql`UPDATE transactions SET amount = 99 WHERE id = ${tx.id}`
    ).rejects.toThrow('immutable')
  })
})
```

---

## Shared Patterns

### Standard Response Envelope
**Source:** RESEARCH.md Patterns 2, D-09, D-10, D-11
**Apply to:** All route handlers in `api/ledger.ts`, `api/opening-balance.ts`, `api/reference.ts`

```typescript
// List endpoint
{ data: rows, error: null, meta: { total: number, page: number, per_page: number } }

// Single resource (201 Created)
{ data: row, error: null, meta: null }

// Error
{ data: null, error: { message: string }, meta: null }
```

Rules:
- List endpoints always include `meta` with `total`, `page`, `per_page`.
- Single-resource endpoints set `meta: null`.
- Error responses set `data: null, meta: null`.
- `created_at` is always included in resource payloads (D-11). No `updated_at`.

### SQL Injection Prevention
**Source:** RESEARCH.md Pattern 4 — postgres.js auto-parameterization
**Apply to:** All files that query the database

Always use tagged template literals:
```typescript
// CORRECT
await sql`SELECT * FROM transactions WHERE id = ${id}`

// NEVER do this
await sql.unsafe(`SELECT * FROM transactions WHERE id = '${id}'`)
```

### NUMERIC Precision
**Source:** RESEARCH.md Pattern 5
**Apply to:** `entities.ts`, all use-case functions, all API handlers

NUMERIC(19,4) columns come back as JavaScript strings. Type them as `string` in entities. Only call `parseFloat()` when arithmetic is needed (summary computation). Pass strings directly to INSERT statements.

### PGMQ Atomicity
**Source:** RESEARCH.md Pattern 6, Pitfall 7
**Apply to:** `use-cases.ts` — `createTransaction`

Always wrap transaction INSERT + PGMQ send inside `sql.begin()`:
```typescript
await sql.begin(async sql => {
  const [row] = await sql`INSERT INTO transactions ... RETURNING *`
  await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({ transaction_id: row.id })})`
  return row
})
```

### Zod v4 Format Validators
**Source:** RESEARCH.md Pattern 3, Pitfall 1
**Apply to:** `src/application/schemas/ledger.ts` and any future schema files

| Use this (v4) | Not this (v3 deprecated) |
|---------------|--------------------------|
| `z.uuid()` | `z.string().uuid()` |
| `z.iso.date()` | `z.string().regex(/^\d{4}-\d{2}-\d{2}$/)` |
| `z.iso.datetime()` | `z.string().datetime()` |
| `z.email()` | `z.string().email()` |

---

## No Analog Found

All files have no analog — this is a greenfield project. The table below records which RESEARCH.md section is the authoritative pattern source for each file instead.

| File | Role | Data Flow | Pattern Source |
|------|------|-----------|----------------|
| `src/index.ts` | entrypoint | request-response | RESEARCH.md Pattern 1 |
| `src/infrastructure/db/client.ts` | config | — | RESEARCH.md Pattern 4 |
| `src/infrastructure/db/schema.sql` | migration | DDL | RESEARCH.md "Definitive Database Schema" |
| `src/infrastructure/db/seed.sql` | migration | batch | RESEARCH.md "Category Seed Data" |
| `src/infrastructure/db/health.ts` | utility | request-response | RESEARCH.md Pattern 6 |
| `src/core/ledger/entities.ts` | model | — | RESEARCH.md Pattern 5 |
| `src/core/ledger/use-cases.ts` | service | CRUD | RESEARCH.md Patterns 4, 6, 8 |
| `src/application/schemas/ledger.ts` | utility | transform | RESEARCH.md Pattern 3 |
| `src/interface-adapters/api/ledger.ts` | controller | request-response | RESEARCH.md Patterns 1, 2, 3 |
| `src/interface-adapters/api/opening-balance.ts` | controller | CRUD | RESEARCH.md D-04, Patterns 2, 3 |
| `src/interface-adapters/api/reference.ts` | controller | request-response | RESEARCH.md Patterns 1, 2 |
| `tsconfig.json` | config | — | RESEARCH.md Standard Stack |
| `tests/*.test.ts` | test | — | RESEARCH.md Validation Architecture |

---

## Metadata

**Analog search scope:** Entire `/home/olafk/finance/src` tree — does not exist (greenfield)
**Files scanned:** 0 (no source code yet; package.json confirmed stack versions)
**Pattern extraction date:** 2026-06-06
**Pattern sources:** All patterns derived from RESEARCH.md verified references (Context7 hono.dev, zod.dev/v4, porsager/postgres, pgmq/pgmq, oven-sh/bun) and locked CONTEXT.md decisions D-01 through D-11.
