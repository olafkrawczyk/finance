# Phase 1: Foundation (Core Ledger & DB) - Research

**Researched:** 2026-06-06
**Domain:** Financial Ledger Infrastructure, Database Schema, Bun/Hono/postgres.js/Zod v4
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `monthly_opening_balances` is a **global table** — no `account_id` FK. Schema: `id, year, month, opening_balance NUMERIC(19,4), notes TEXT (nullable), UNIQUE(year, month)`.

**D-02:** `stan konta` = **total net worth** (bank + cash + ETF + silver + receivables). Set manually by the user each month.

**D-03:** User sets opening balance at start of each month. Transactions within the month adjust the running total.

**D-04:** Full CRUD for opening balance in Phase 1: `GET /opening-balance`, `POST /opening-balance`, `PUT /opening-balance/:id`. Required before Phase 2 historical import.

**D-05:** Rename `auto` → `arval`; `is_fixed_cost = true`. Tracks Arval lease.

**D-06:** Fixed cost categories (6 total): `ZUS`, `PIT36`, `VAT`, `mieszkanie`, `kredyt`, `arval`.

**D-07:** Total category count is **25** (REQUIREMENTS.md says 26 — typo; 25 is authoritative, with `auto` renamed to `arval`).

**D-08:** Fuel expenses use `paliwo` category. No separate `auto` category.

**D-09:** All endpoints use standard envelope: `{ data: <resource | array | null>, error: <null | { message: string }>, meta: <null | { total: number, page?: number, per_page?: number }> }`.

**D-10:** List endpoints include `meta: { total, page, per_page }`. Single-resource endpoints set `meta: null`. Error responses set `data: null, meta: null`.

**D-11:** Individual resources expose `created_at` from DB. No `updated_at`.

### Claude's Discretion

- Error `message` format: `{ message: "..." }` or `{ code: "VALIDATION_ERROR", message: "..." }` — planner decides.
- Pagination defaults: 50 or 100 per page are both acceptable.

### Deferred Ideas (OUT OF SCOPE)

- Individual tracking of non-bank assets (ETF positions, silver grams, cash) as separate entities.
- Cursor-based pagination on `GET /transactions` and `GET /summary`.
</user_constraints>

---

## Summary

Phase 1 establishes the complete backend foundation: Bun + Hono server skeleton, Postgres schema, category seed data, and the core read/write API. The schema is a single-entry ledger (not double-entry) as explicitly confirmed in REQUIREMENTS.md — do not use the double-entry pattern from the old research. The prior phase-1 RESEARCH.md recommended double-entry with `ledger_entries` and zero-sum triggers; **that entire approach is superseded** by the locked schema in D-01 through D-11 and the data model notes.

The critical schema deviation from the old plan is `monthly_opening_balances`: D-01 makes it a **global** table (no `account_id`), because `stan konta` tracks total net worth across all asset classes, not per-account balance. The old plan had `account_id` FK — this must not be included.

Three significant technical findings for the planner:
1. **Zod v4 is installed** (4.4.3 in package.json). The old plan's schemas use Zod v3 patterns (`z.string().uuid()` is deprecated; use `z.uuid()` in v4). All Zod schemas must be written to v4 API.
2. **Bun is not installed** on the development machine. Plan 01-01 must include Bun installation as a prerequisite step before any `bun` commands.
3. **No Docker/Postgres available** on this machine. The plan must address Postgres + PGMQ extension setup (Docker is the recommended path; Docker Desktop WSL integration may need to be enabled).

**Primary recommendation:** Follow the locked schema in CONTEXT.md exactly. Use postgres.js tagged template literals for all queries. Write all Zod schemas to v4 API (`z.uuid()`, `z.iso.date()`, etc.). Use raw SQL for PGMQ (no npm wrapper).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Transaction immutability | Database (triggers) | — | BEFORE UPDATE/DELETE triggers are the final enforcement gate — no application code can bypass them |
| Input validation | API (Zod v4) | — | Validate at the HTTP boundary before any DB write; reject bad data before it reaches Postgres |
| PGMQ queue init | Database | API (startup) | Queue is created via SQL on startup; lives in Postgres schema |
| Opening balance CRUD | API (Hono routes) | Database | API enforces envelope + validation; DB enforces UNIQUE(year, month) |
| Summary computation (Zbiorczy) | Database (SQL aggregation) | API (derived fields) | Aggregations (wydatki, przychody) done in SQL GROUP BY; derived fields (zaoszczedzone_log, stan_konta) computed in app layer |
| Category seed | Database (seed.sql) | — | Idempotent INSERT ON CONFLICT DO NOTHING; runs at schema apply time |

---

## Standard Stack

### Core (all already in package.json)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bun | 1.2+ (latest) | Runtime + package manager + test runner | Built-in test runner, no transpile step, fast I/O — install via `curl -fsSL https://bun.sh/install \| bash` [VERIFIED: Context7/oven-sh/bun] |
| Hono | 4.12.23 | Web framework | Lightweight, Web Standards compliant, native Bun support via `export default { port, fetch }` — no `@hono/node-server` needed on Bun [VERIFIED: Context7/websites/hono_dev] |
| zod | 4.4.3 | Schema validation | **v4 is installed** — use top-level format validators (`z.uuid()`, `z.iso.date()`); `z.string().uuid()` is deprecated [VERIFIED: Context7/websites/zod_dev_v4] |
| postgres | 3.4.9 | DB driver | Tagged template literals auto-parameterize queries (SQL injection safe); NUMERIC returns as string by default [VERIFIED: Context7/porsager/postgres] |
| @hono/zod-validator | 0.8.0 | Hono/Zod bridge | Peer deps: `zod: ^3.25.0 \|\| ^4.0.0` — fully compatible with installed zod 4.4.3 [VERIFIED: npm registry] |

### Supporting (dev only)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @types/bun | 1.3.14 | TypeScript types for Bun APIs | Required for `bun:test`, Bun.serve, etc. in tsconfig `"types": ["bun"]` |

### Packages NOT to install

| Package | Reason |
|---------|--------|
| `@hono/node-server` | Not needed on Bun; Bun's native HTTP server is used via `export default { port, fetch: app.fetch }` |
| `pgmq-js` | Community package (603 downloads/week); PGMQ is used via raw SQL through postgres.js — no JS wrapper needed |
| `pgmq` (npm) | Unrelated old package (last updated 2022); not the Tembo/pgmq Postgres extension |
| `better-auth` | Already in package.json; Phase 2 concern — don't wire up in Phase 1 |

### Installation (what Plan 01-01 actually needs to run)

```bash
# Step 0: Install Bun (not present on this machine)
curl -fsSL https://bun.sh/install | bash
# Reload shell or: source ~/.bashrc

# Step 1: Add missing dev dependency
bun add -D @types/bun

# Step 2: Add Hono/Zod validator bridge (not yet in package.json)
bun add @hono/zod-validator

# Step 3: Start Postgres + PGMQ via Docker
# (Docker Desktop WSL integration must be enabled in Docker Desktop settings)
docker run -d --name finance-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=finance \
  -p 5432:5432 \
  ghcr.io/pgmq/pg18-pgmq:v1.10.0
# Then: psql postgres://postgres:postgres@localhost:5432/finance -c "CREATE EXTENSION pgmq;"
```

---

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| hono | npm | 3+ yrs | 1.5M+/wk | github.com/honojs/hono | [OK] | Approved |
| zod | npm | 4+ yrs | 12M+/wk | github.com/colinhacks/zod | [OK] | Approved |
| postgres | npm | 5+ yrs | 300k+/wk | github.com/porsager/postgres | [OK] | Approved |
| better-auth | npm | ~1 yr | 50k+/wk | github.com/better-auth/better-auth | [OK] | Approved |
| @hono/zod-validator | npm | 2+ yrs | stable | github.com/honojs/middleware | [OK] | Approved |
| pgmq-js | npm | ~2 yrs | 603/wk | github.com/Muhammad-Magdi/pgmq-js | [OK] but low-downloads | NOT USED — raw SQL preferred |
| pgmq (npm) | npm | 9 yrs | very low | github.com/doesdev/pgmq | n/a | NOT USED — wrong package, unrelated |

**Packages removed:** none (pgmq-js excluded by design, not flagged)
**Packages flagged as suspicious:** none

*slopcheck run confirmed all used packages are [OK]. No postinstall scripts detected on any package.*

---

## Architecture Patterns

### System Architecture Diagram

```
HTTP Request
     │
     ▼
┌─────────────────────────────────────┐
│  Hono Router (src/index.ts)         │
│  - /health                          │
│  - /health/db                       │
│  - /transactions (POST, GET)        │
│  - /summary (GET)                   │
│  - /opening-balance (GET, POST, PUT)│
│  - /accounts (GET)                  │
│  - /categories (GET)                │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  @hono/zod-validator middleware     │  ← Zod v4 schema validation
│  (validates JSON body on POST/PUT)  │
└───────────────┬─────────────────────┘
                │  validated data
                ▼
┌─────────────────────────────────────┐
│  Use-case functions                 │
│  (src/core/ledger/use-cases.ts)     │
│  - createTransaction                │
│  - listTransactions                 │
│  - getMonthlySummary                │
│  - createOpeningBalance             │
│  - updateOpeningBalance             │
│  - listOpeningBalances              │
└───────────────┬─────────────────────┘
                │  sql`` template calls
                ▼
┌─────────────────────────────────────┐
│  postgres.js client                 │
│  (src/infrastructure/db/client.ts)  │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  PostgreSQL + PGMQ extension        │
│  - accounts, categories             │
│  - transactions (immutable triggers)│
│  - monthly_opening_balances (global)│
│  - pgmq.analysis_queue              │
└─────────────────────────────────────┘
```

### Recommended Project Structure

```
src/
├── core/
│   └── ledger/
│       ├── entities.ts        # TypeScript domain types
│       └── use-cases.ts       # Business logic functions
├── application/
│   └── schemas/
│       └── ledger.ts          # Zod v4 schemas for all inputs
├── infrastructure/
│   └── db/
│       ├── client.ts          # postgres.js singleton
│       ├── schema.sql         # DDL: tables, indexes, triggers
│       ├── seed.sql           # 25 categories with fixed-cost flags
│       └── health.ts          # DB connectivity + PGMQ check
└── interface-adapters/
    └── api/
        ├── ledger.ts          # POST /transactions, GET /transactions, GET /summary
        ├── opening-balance.ts # GET/POST/PUT /opening-balance
        └── reference.ts       # GET /accounts, GET /categories
index.ts                       # Hono app + Bun server export
tests/
├── schemas.test.ts
├── ledger.test.ts
└── queue.test.ts
```

### Pattern 1: Hono on Bun — Entry Point

**What:** Bun uses `export default { port, fetch }` — no `@hono/node-server` wrapper needed.

```typescript
// Source: [VERIFIED: Context7 hono.dev/docs/getting-started/bun]
import { Hono } from 'hono'

const app = new Hono()
app.get('/health', (c) => c.json({ ok: true }))

export default {
  port: Number(process.env.PORT) || 3000,
  fetch: app.fetch,
}
```

### Pattern 2: Standard Response Envelope (D-09, D-10, D-11)

**What:** Every endpoint wraps its payload in `{ data, error, meta }`.

```typescript
// Source: [CITED: CONTEXT.md D-09/D-10]
// Success — list endpoint
return c.json({
  data: rows,
  error: null,
  meta: { total: count, page: pageNum, per_page: perPage }
}, 200)

// Success — single resource
return c.json({
  data: row,
  error: null,
  meta: null
}, 201)

// Error
return c.json({
  data: null,
  error: { message: 'Validation failed' },
  meta: null
}, 400)
```

### Pattern 3: Zod v4 Input Schema (BREAKING CHANGE from v3)

**What:** Zod v4 moves string format validators to top-level. `z.string().uuid()` is deprecated.

```typescript
// Source: [VERIFIED: Context7 zod.dev/v4]
import * as z from 'zod'

// v4 format validators — use these, NOT z.string().uuid()
export const CreateTransactionSchema = z.object({
  account_id: z.uuid(),                          // NOT z.string().uuid()
  category_id: z.uuid().nullable().optional(),   // NOT z.string().uuid().nullable()
  type: z.enum(['income', 'expense', 'transfer']),
  amount: z.string().regex(/^\d+(\.\d{1,4})?$/), // positive NUMERIC(19,4) as string
  description: z.string().max(2000).nullable().optional(),
  date: z.iso.date(),                            // NOT z.string().regex(/^\d{4}-\d{2}-\d{2}$/)
  transfer_to_account_id: z.uuid().nullable().optional(),
})

export const CreateOpeningBalanceSchema = z.object({
  year: z.number().int().min(2000).max(2100),
  month: z.number().int().min(1).max(12),
  opening_balance: z.string().regex(/^-?\d+(\.\d{1,4})?$/), // can be negative (debt)
  notes: z.string().max(1000).nullable().optional(),
})

export const UpdateOpeningBalanceSchema = CreateOpeningBalanceSchema.partial()
```

### Pattern 4: postgres.js Queries — Tagged Template Literals

**What:** All queries use tagged template literals (auto-parameterized, SQL-injection safe).

```typescript
// Source: [VERIFIED: Context7 porsager/postgres]
import postgres from 'postgres'

const sql = postgres(process.env.DB_URL!, {
  max: 10,
  idle_timeout: 20,
})

// Insert + returning
const [tx] = await sql`
  INSERT INTO transactions
    (account_id, category_id, type, amount, description, date, transfer_to_account_id, import_hash)
  VALUES
    (${input.account_id}, ${input.category_id ?? null}, ${input.type},
     ${input.amount}, ${input.description ?? null}, ${input.date},
     ${input.transfer_to_account_id ?? null}, ${input.import_hash ?? null})
  RETURNING *
`

// Transaction wrapper (for atomic ops)
await sql.begin(async sql => {
  const [row] = await sql`INSERT INTO ... RETURNING *`
  await sql`SELECT pgmq.send('analysis_queue', ${JSON.stringify({ id: row.id })})`
  return row
})
```

### Pattern 5: NUMERIC(19,4) Handling

**What:** postgres.js returns NUMERIC columns as JavaScript strings, not numbers. This is intentional — it preserves precision.

```typescript
// Source: [VERIFIED: Context7 porsager/postgres + standard postgres.js behavior]
// DB returns: { amount: "1234.5000" }
// Keep as string in entities; parse only when doing arithmetic:
const amountDecimal = parseFloat(row.amount) // only for display/computation
// For DB inserts, pass the string directly — postgres.js handles it
```

### Pattern 6: PGMQ via Raw SQL

**What:** PGMQ has no official JS/TS npm client. Use postgres.js SQL calls directly.

```typescript
// Source: [CITED: Context7 pgmq/pgmq — SQL API]
// Initialize queue (idempotent — pgmq.create is safe to call multiple times)
await sql`SELECT pgmq.create('analysis_queue')`

// Send a message
const [{ send: msgId }] = await sql`
  SELECT pgmq.send('analysis_queue', ${JSON.stringify({ transaction_id: id })})
`

// Verify queue exists
const queues = await sql`SELECT queue_name FROM pgmq.list_queues()`
const exists = queues.some(q => q.queue_name === 'analysis_queue')
```

### Pattern 7: Immutability Triggers

**What:** BEFORE UPDATE and BEFORE DELETE triggers on `transactions` enforce ledger immutability (REQ-1.2). Corrections are made via new compensating entries.

```sql
-- Source: [CITED: CONTEXT.md REQ-1.2 + standard Postgres pattern]
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

### Pattern 8: Zbiorczy Summary Query

**What:** SQL aggregation for the monthly summary view. `stan_konta` uses opening balance + cumulative net.

```sql
-- Source: [CITED: REQUIREMENTS.md REQ-3.1 + CONTEXT.md notes]
SELECT
  TO_CHAR(t.date, 'YYYY-MM') AS month,
  SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) AS wydatki,
  SUM(CASE WHEN t.type = 'income'  THEN t.amount ELSE 0 END) AS przychody,
  SUM(CASE WHEN t.type = 'expense' AND c.is_fixed_cost = true THEN t.amount ELSE 0 END) AS fixed_cost_total
FROM transactions t
LEFT JOIN categories c ON t.category_id = c.id
WHERE t.type != 'transfer'
GROUP BY TO_CHAR(t.date, 'YYYY-MM')
ORDER BY month ASC;
```

Then in the application layer, compute per-row:
- `wydatki_bez_stalych` = `wydatki − fixed_cost_total`
- `zaoszczedzone` = `przychody − wydatki`
- `zaoszczedzone_log` = `log10(zaoszczedzone)` if `zaoszczedzone > 0`, else `0`
- `stan_konta`: join with `monthly_opening_balances` for the month's opening balance, then `opening_balance + cumulative_net_since_month_start`

### Anti-Patterns to Avoid

- **Old double-entry pattern:** The prior RESEARCH.md describes a `ledger_entries` table with zero-sum constraint trigger. **Do not use** — this project is single-entry by design (confirmed in REQUIREMENTS.md "No double-entry").
- **`z.string().uuid()` in Zod v4:** Deprecated. Use `z.uuid()` (top-level).
- **`z.string().regex(/^\d{4}-\d{2}-\d{2}$/)` for dates:** Use `z.iso.date()` in Zod v4.
- **Installing `@hono/node-server`:** Not needed on Bun. Bun runs Hono natively via `export default { port, fetch }`.
- **Using the npm `pgmq` package:** It's an unrelated 2017 project. Use raw SQL via postgres.js.
- **Floating-point for currency:** Never `FLOAT` or `REAL`. Always `NUMERIC(19,4)`.
- **`account_id` on `monthly_opening_balances`:** D-01 explicitly removes this FK. The table is global (total net worth, not per-account).

---

## Definitive Database Schema

This is the authoritative schema for Plan 01-02, incorporating all CONTEXT.md decisions.

```sql
-- Accounts: ING business + IPKO personal
CREATE TABLE accounts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('personal', 'business')),
  currency   TEXT NOT NULL DEFAULT 'PLN',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Categories: 25 total (auto renamed to arval, D-07)
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
  category_id            UUID REFERENCES categories(id),  -- NULL = uncategorized
  type                   TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  amount                 NUMERIC(19, 4) NOT NULL CHECK (amount > 0),  -- always positive
  description            TEXT,
  date                   DATE NOT NULL,
  transfer_to_account_id UUID REFERENCES accounts(id),   -- only when type='transfer'
  import_hash            TEXT UNIQUE,                     -- SHA-256 dedup (Phase 2)
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Global monthly opening balance = total net worth (D-01, D-02)
-- NO account_id — this is net worth across ALL asset classes
CREATE TABLE monthly_opening_balances (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  year            INT NOT NULL,
  month           INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  opening_balance NUMERIC(19, 4) NOT NULL,
  notes           TEXT,                                   -- optional (D-01)
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (year, month)
);

-- Indexes
CREATE INDEX idx_tx_account_date    ON transactions(account_id, date DESC);
CREATE INDEX idx_tx_category        ON transactions(category_id);
CREATE INDEX idx_tx_date_type       ON transactions(date, type);
CREATE INDEX idx_mob_year_month     ON monthly_opening_balances(year, month);

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

### Category Seed Data (25 categories, D-05 to D-08)

```sql
-- 25 categories; arval (renamed from auto) is the 6th fixed cost
INSERT INTO categories (name, is_fixed_cost) VALUES
  ('biedronka',   false),
  ('żabka',       false),
  ('paliwo',      false),
  ('taxi',        false),
  ('fun',         false),
  ('VAT',         true),
  ('PIT36',       true),
  ('ZUS',         true),
  ('arval',       true),   -- renamed from 'auto' per D-05; Arval lease (fixed cost)
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
-- Verify: SELECT COUNT(*) FROM categories WHERE is_fixed_cost = true → should be 6
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Job queue | Custom polling loop | PGMQ (raw SQL) | ACID-compliant; lives in Postgres; enqueue atomically with ledger writes |
| DB driver | Raw `pg` pool | `postgres.js` tagged templates | Auto-parameterized queries; prevents SQL injection by construction |
| Input validation | Manual type checks | Zod v4 schemas | Compile-time types + runtime validation in one declaration |
| UUID generation | `crypto.randomUUID()` in app | `gen_random_uuid()` in DB | DB-side generation means the ID is always set even on direct SQL inserts |
| Date arithmetic for summary | JavaScript date math | `TO_CHAR(date, 'YYYY-MM')` GROUP BY | Correct month grouping with timezone handling in Postgres |

---

## Common Pitfalls

### Pitfall 1: Using Zod v3 API with Zod v4 Installed

**What goes wrong:** Schemas with `z.string().uuid()`, `z.string().email()`, `z.string().datetime()` compile but emit deprecation warnings; some edge cases behave differently.
**Why it happens:** The project has zod 4.4.3 installed but the old RESEARCH.md and plan templates show v3 patterns.
**How to avoid:** Use top-level format validators: `z.uuid()`, `z.email()`, `z.iso.date()`, `z.iso.datetime()`.
**Warning signs:** TypeScript deprecation warnings on `z.string().uuid()` calls.

### Pitfall 2: Adding account_id to monthly_opening_balances

**What goes wrong:** Stan konta (total net worth) computation breaks — it tries to join or aggregate by account instead of using the global monthly figure.
**Why it happens:** The old data model note and old schema both had `account_id` FK here; D-01 removed it.
**How to avoid:** Schema must be `UNIQUE(year, month)` with no account FK. Double-check this before applying schema.
**Warning signs:** `UNIQUE(account_id, year, month)` appearing anywhere in schema.sql.

### Pitfall 3: NUMERIC Columns Returned as Strings

**What goes wrong:** Code tries `row.amount + row.amount2` and gets string concatenation (`"10.00001000.0000"`) instead of addition.
**Why it happens:** postgres.js returns NUMERIC as JavaScript strings by default (correct behavior — preserves precision).
**How to avoid:** In TypeScript entities, type amount fields as `string`. For arithmetic in the summary layer, use `parseFloat()` or a decimal library.
**Warning signs:** Any `+` operator applied directly to `row.amount`.

### Pitfall 4: Bun Not Installed

**What goes wrong:** Plan 01-01 tasks fail immediately with `bun: command not found`.
**Why it happens:** Bun is not on this machine (verified: `command -v bun` returns nothing).
**How to avoid:** Plan 01-01 Wave 0 must install Bun before any other task.
**Command:** `curl -fsSL https://bun.sh/install | bash && source ~/.bashrc`

### Pitfall 5: Postgres + PGMQ Not Available

**What goes wrong:** DB connectivity tests fail; `CREATE EXTENSION pgmq` fails on plain Postgres.
**Why it happens:** Neither `psql` nor a running Postgres is present (verified). PGMQ is not in the standard Postgres image.
**How to avoid:** Use `ghcr.io/pgmq/pg18-pgmq:v1.10.0` Docker image (PGMQ pre-installed) as the Postgres provider.
**Warning signs:** `could not open extension control file` error on `CREATE EXTENSION pgmq`.

### Pitfall 6: Transfer Transactions in Summary Totals

**What goes wrong:** Zbiorczy view shows inflated `wydatki` because ING→PKO transfers (type='transfer') are counted as expenses.
**Why it happens:** Simple `WHERE type = 'expense'` instead of explicit `WHERE type != 'transfer'`.
**How to avoid:** All summary queries must filter out `type='transfer'` (see Pattern 8 above).
**Warning signs:** Monthly `wydatki` total that matches a known month from budget.xlsx is significantly higher than expected.

### Pitfall 7: Non-Atomic PGMQ Enqueue

**What goes wrong:** Transaction is written to DB, server restarts before PGMQ message is sent — background work is silently lost.
**Why it happens:** Sending the PGMQ message outside the DB transaction.
**How to avoid:** Use `sql.begin()` to wrap both the INSERT and the `pgmq.send()` call in a single Postgres transaction (Pattern 4 above). If either fails, both roll back.

---

## Runtime State Inventory

Step 2.6: SKIPPED — This is a greenfield project with no existing runtime state. No data migrations, no live service configs, no OS-registered state, no secrets referencing this project, no installed build artifacts to consider.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bun | Backend runtime, test runner | **✗ not installed** | — | Install via `curl -fsSL https://bun.sh/install \| bash` |
| PostgreSQL | Data layer | **✗ not running** | — | Docker: `ghcr.io/pgmq/pg18-pgmq:v1.10.0` |
| PGMQ extension | Queue system | **✗ not installed** | — | Pre-installed in pgmq Docker image |
| Docker | Container runtime | ✗ (WSL integration not enabled) | — | Enable in Docker Desktop → Settings → Resources → WSL Integration |
| Node.js | npm commands (already used) | ✓ | v22.22.2 | — |
| npm | Package management | ✓ | 10.9.7 | — |

**Missing dependencies with no fallback:**
- Bun (must install before any `bun` commands)
- Postgres + PGMQ (must have a running instance before DB tests run)

**Missing dependencies with fallback:**
- Docker WSL integration: if Docker Desktop is not enabled for WSL, manual Bun + local Postgres install is an alternative (but Docker is recommended for reproducibility).

**Plan 01-01 must handle:** Bun installation + Docker/Postgres setup as Wave 0 prerequisites.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bun Test (built-in, no install needed) |
| Config file | none needed — `bun test` discovers `*.test.ts` automatically |
| Quick run command | `bun test` |
| Full suite command | `bun test --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-1.1 | Transaction fields stored correctly | DB Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| REQ-1.2 | UPDATE/DELETE on transactions raises exception | DB Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| REQ-1.3 | Two accounts (ING + IPKO) can be created | DB Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| REQ-1.4 | Transfers excluded from wydatki/przychody | DB Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| REQ-2.1 | 25 categories seeded after seed.sql | DB Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| REQ-2.2 | 6 categories have is_fixed_cost=true | DB Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| D-01 | monthly_opening_balances has no account_id | Schema test | `bun test tests/schemas.test.ts` | ❌ Wave 0 |
| D-04 | CRUD endpoints for opening balance work | HTTP Integration | `bun test tests/ledger.test.ts` | ❌ Wave 0 |
| D-09/10 | All responses use standard envelope | Unit | `bun test tests/schemas.test.ts` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bun test` (all tests)
- **Per wave merge:** `bun test --coverage`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `tests/schemas.test.ts` — Zod schema validation tests (covers D-01 schema shape, D-09 envelope, input validation)
- [ ] `tests/ledger.test.ts` — DB integration tests (REQ-1.1 through REQ-2.2, D-04)
- [ ] `tests/queue.test.ts` — PGMQ send/read round-trip
- [ ] `tsconfig.json` — needed for Bun TypeScript compilation with `"types": ["bun"]`
- [ ] `bunfig.toml` — optional, for test timeout config: `[test]\ntimeout = 30000`

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Auth is Phase 2 |
| V3 Session Management | no | Auth is Phase 2 |
| V4 Access Control | no | No auth in Phase 1 |
| V5 Input Validation | yes | Zod v4 schemas on all POST/PUT body |
| V6 Cryptography | no | No crypto in Phase 1 (import_hash is Phase 2) |
| V13 Data Protection | partial | DB credentials via env var, not hardcoded |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection | Tampering | postgres.js tagged template literals auto-parameterize all values |
| Numeric overflow/precision | Tampering | NUMERIC(19,4) + Zod regex for amount strings; never use JS float for amounts |
| Invalid date range in summary | Tampering | Zod validates date format; SQL uses DATE type constraint |
| Duplicate import dedup bypass | Tampering | `import_hash UNIQUE` constraint at DB level (Phase 2 concern, but column is in Phase 1 schema) |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Docker Desktop is installed on Windows (WSL host) but WSL integration is not enabled | Environment | Medium — if Docker Desktop is not installed at all, Postgres setup requires a different path (native install or cloud) |
| A2 | The `notes` field on `monthly_opening_balances` is `TEXT` (unlimited) | Schema | Low — D-01 says `TEXT (nullable)`, no length constraint mentioned |
| A3 | The PGMQ `analysis_queue` needs to be initialized in Phase 1 even though Phase 2 uses it | Architecture | Low — idempotent, no downside to early init; Phase 2 worker depends on it |

**If this table is empty:** Not applicable — three low-risk assumptions logged above.

---

## Key Deltas from Old Plans (Planner Must Apply)

The existing `01-01-PLAN.md`, `01-02-PLAN.md`, `01-03-PLAN.md` are being replaced. These are the material differences the new plans must incorporate:

| Area | Old Plan | New Plan (from CONTEXT.md decisions) |
|------|----------|--------------------------------------|
| `monthly_opening_balances` | Has `account_id FK`, `UNIQUE(account_id, year, month)` | **Global table**, no `account_id`, `UNIQUE(year, month)` + `notes TEXT` |
| Category count | 25, with `auto` (not fixed cost) | 25, with `arval` replacing `auto` (IS a fixed cost) |
| Fixed cost count | 5 (`ZUS, PIT36, VAT, mieszkanie, kredyt`) | **6** (`ZUS, PIT36, VAT, mieszkanie, kredyt, arval`) |
| Opening balance API | Not present | **Required**: `GET /opening-balance`, `POST /opening-balance`, `PUT /opening-balance/:id` |
| Zod API | v3 patterns (`z.string().uuid()`) | **v4 patterns** (`z.uuid()`, `z.iso.date()`) |
| Architecture model | Double-entry with `ledger_entries` | **Single-entry** (`transactions` table only) |
| Bun install | Assumed present | **Must install** — not on this machine |
| Postgres | Assumed present | **Must set up** via Docker (with PGMQ image) |
| Summary response shape | Raw SQL result | **Standard envelope** `{ data, error, meta }` (D-09/D-10) |
| `@hono/node-server` | Implied in old STACK.md | **Not needed** on Bun |

---

## Open Questions (RESOLVED)

1. **Docker availability on WSL**
   - What we know: Docker Desktop for Windows is installed; WSL integration status is unknown.
   - What's unclear: Whether `docker` command is available inside WSL after enabling integration.
   - Recommendation: Plan 01-01 should include a `docker --version` check as a prerequisite and provide instructions to enable WSL integration if not available.

2. **DB_URL environment variable format**
   - What we know: postgres.js accepts both connection string and env var options.
   - What's unclear: Whether to use `DB_URL`, `DATABASE_URL`, or standard PG env vars (`PGHOST`, `PGUSER`, etc.).
   - Recommendation: Use `DATABASE_URL` (most common convention) with postgres.js accepting it as a connection string.

3. **Opening balance initial seed for Phase 2**
   - What we know: Historical data starts July 2020; opening balance for that month needed before Phase 2 import produces correct `stan konta`.
   - What's unclear: Whether Phase 1 should seed a placeholder or leave this for Phase 2.
   - Recommendation: Phase 1 just needs the CRUD endpoints working. The actual July 2020 value is entered manually or as part of Phase 2 data migration.

---

## Sources

### Primary (HIGH confidence)

- Context7 `/websites/zod_dev_v4` — Zod v4 API, breaking changes from v3, format validators
- Context7 `/websites/hono_dev` — Hono Bun setup, zValidator middleware, port/fetch export pattern
- Context7 `/porsager/postgres` — postgres.js tagged templates, transactions, NUMERIC type behavior
- Context7 `/pgmq/pgmq` — PGMQ SQL API (create, send, read, delete), Docker image name
- Context7 `/oven-sh/bun` — Bun installation, tsconfig.json, test runner API

### Secondary (MEDIUM confidence)

- `package.json` in project root — confirmed installed versions (hono 4.12.23, zod 4.4.3, postgres 3.4.9, better-auth 1.6.14)
- npm registry — confirmed `@hono/zod-validator` peer deps support both zod v3 and v4
- slopcheck — confirmed all 5 packages are [OK]

### Tertiary (LOW confidence)

- None — all major claims verified against Context7 or official package metadata.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages confirmed via npm registry + Context7; versions from installed package.json
- Schema: HIGH — derived directly from CONTEXT.md locked decisions D-01 to D-11
- Zod v4 patterns: HIGH — confirmed via Context7 official Zod v4 documentation
- Environment: HIGH — directly verified via `command -v bun`, `pg_isready`, `docker --version`
- Pitfalls: HIGH — most are verified breaking changes or directly observed gaps (Bun/Postgres not installed)

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 (30 days — stable libraries)
