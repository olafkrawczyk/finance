# Design: Testable balance / net-worth math + just-in-time test DB

**Date:** 2026-06-14
**Status:** Approved

## Problem

The monthly balance, net-worth (`wartosc_netto`), and running account balance
(`stan_konta`) math all lives inside one DB-coupled function,
`getMonthlySummary()` in `src/core/ledger/use-cases.ts`. Consequences:

1. **The math is untestable without a database.** Arithmetic is entangled with
   SQL, so the trickiest logic can only be exercised through integration tests.
2. **Coverage gaps in the highest-risk paths.** The current `hasStartingBalances`
   path (the production path — per-account baseline + cumulative changes) has no
   tests, and `wartosc_netto` / the asset forward-fill is never asserted anywhere.
3. **Tests can wipe the real DB.** `client.ts` reads `process.env.DATABASE_URL` at
   import and tests `TRUNCATE`/`DELETE` against whatever it points to. Locally that
   is the developer's real finance database.
4. **`tests/ledger.test.ts` is stale.** It calls use-cases without `userId`
   (pre-dating multi-user scoping, migration 008) and relies on a global seed that
   no longer exists, so it cannot pass against the current scoped schema.

## Goals

- Extract the summary math into a pure, DB-free module that can be unit-tested.
- Add unit tests for the `hasStartingBalances` path and the `wartosc_netto`
  forward-fill, plus the existing legacy/derived math.
- Run every DB-backed test against a just-in-time ephemeral Postgres so there is
  zero risk of touching the real database.
- Repair `tests/ledger.test.ts` to the current scoped model.

## Non-goals

- No change to the math's behavior — the extraction is behavior-preserving.
- No change to the API surface or DB schema.
- No general test-suite refactor beyond what these goals require.

## Background / current bootstrap facts

- Production bootstraps via **migrations** (`migrate.ts` runs `001`→`015`).
  Migration `001` creates the better-auth tables (`user`, `session`, `account`,
  `verification`); migration `007` creates the `pgmq` extension and the
  `analysis_queue` / `import_queue` queues. Running all migrations against a fresh
  DB yields a production-faithful schema.
- `schema.sql` / `apply.ts` is a consolidated snapshot that does **not** create the
  `pgmq` extension, so it is not a reliable standalone bootstrap. The JIT DB uses
  the migrations path.
- Accounts and categories are seeded **per-user by the signup hook**, not globally.
  Integration tests therefore sign up a user (see `api.test.ts`) rather than
  relying on a global seed. `seed.sql` is stale (inserts without `user_id`).
- The DB image is `ghcr.io/pgmq/pg18-pgmq` (Postgres + PGMQ extension), pinned in
  `docker-compose.yml`. A test DB must use this image; plain Postgres / pglite
  cannot load the `pgmq` extension.

## Design

### 1. Pure math module — `src/core/ledger/summary-math.ts`

A new module with no `sql` import. It receives already-fetched data and returns
`MonthlySummaryRow[]`:

```ts
interface SummaryMathInput {
  aggregates: Array<{          // transfers already excluded by the SQL query
    month: string;            // "YYYY-MM"
    wydatki: string;
    przychody: string;
    fixed_cost_total: string;
  }>;
  accounts: Array<{
    starting_balance: string;
    starting_balance_date: string | Date | null;
  }>;
  legacyOpeningBalances: Array<{
    year: number;
    month: number;
    opening_balance: string;
  }>;
  assetSnapshots: Array<{
    asset_id: string;
    value: string;
    date: string;
  }>;
}

export function computeMonthlySummary(input: SummaryMathInput): MonthlySummaryRow[];
```

Smaller helpers, each independently testable and exported:

- `computeBaselineByMonth(accounts, months, earliestMonth)` → `Map<string, number>`
  — sums each account's `starting_balance` for every month `>= effectiveFrom`,
  where `effectiveFrom` is `starting_balance_date`'s `YYYY-MM` or `earliestMonth`
  when the date is null. Accounts with `starting_balance <= 0` are skipped.
- `buildSnapshotsByAsset(snapshots)` → `Map<string, Array<{ value; date }>>`
  (preserves the incoming date-ascending order).
- `assetValueForMonth(snapshotsByAsset, month)` → `number` — forward-fill: for each
  asset take the last snapshot with `date <= month-end`, sum across assets.
- Per-row derivation producing `wydatki_bez_stalych`, `zaoszczedzone`,
  `zaoszczedzone_log`, `stan_konta`, `wartosc_netto`.

The logic is moved verbatim from `use-cases.ts` lines ~87–227, including:
`hasStartingBalances` decision, the `baseline + cumulativeChanges` formula for the
new path, the legacy `monthly_opening_balances` carry-forward, `zaoszczedzone_log`
= `log10` when positive else `0`, `.toFixed(4)` (and `.toFixed(6)` for the log),
and the final `.toReversed()` (newest month first).

### 2. Thin `getMonthlySummary(userId)`

`getMonthlySummary` keeps its signature and becomes fetch-then-delegate:

1. Run the SQL aggregation query (unchanged).
2. `listAccounts(userId)`.
3. Query `monthly_opening_balances` for the user (run unconditionally — one cheap
   query — so the pure function owns the `hasStartingBalances` branch).
4. Query `asset_value_snapshots` for the user (unchanged).
5. `return computeMonthlySummary({ aggregates, accounts, legacyOpeningBalances, assetSnapshots })`.

### 3. Unit tests — `tests/summary-math.test.ts` (zero DB)

Cases:

- **Legacy path:** single month (`opening_balance + zaoszczedzone`); multi-month
  carry-forward where a later month with no opening balance inherits the prior
  month's ending balance; reverse-chronological ordering.
- **`hasStartingBalances` path:** per-account baseline aggregation;
  `starting_balance_date` filtering (a balance effective only from its month
  onward); null `starting_balance_date` → effective from earliest month;
  `stan_konta = baseline + cumulativeChanges` across months; accounts with
  `starting_balance <= 0` ignored.
- **`wartosc_netto` forward-fill:** snapshot before vs. after month-end; month-end
  boundary (a snapshot dated Jan 31 counts for January); multiple assets summed;
  an asset with no snapshot on/before the month contributes 0; later month
  forward-fills the most recent prior snapshot.
- **Derived math:** `wydatki_bez_stalych = wydatki - fixed_cost_total`;
  `zaoszczedzone = przychody - wydatki`; `zaoszczedzone_log` for positive, zero,
  and negative `zaoszczedzone`; `.toFixed` formatting of every field.

### 4. Just-in-time test DB — `tests/setup-db.ts`

Wired via `bunfig.toml`:

```toml
[test]
timeout = 30000
preload = ["./tests/setup-db.ts"]
```

On test-run start (top-level `await` in the preload):

1. `docker run -d --rm --name finance-test-db-<rand>` the
   `ghcr.io/pgmq/pg18-pgmq:v1.10.0` image (tag matching `docker-compose.yml`)
   with `POSTGRES_PASSWORD=postgres`, `POSTGRES_DB=finance_test`, published on a
   Docker-assigned ephemeral host port (`-p 127.0.0.1::5432`).
2. Resolve the mapped host port (`docker port` / `docker inspect`).
3. Poll `docker exec <name> pg_isready -U postgres` until ready or a timeout.
4. **Override `process.env.DATABASE_URL`** to
   `postgres://postgres:postgres@127.0.0.1:<port>/finance_test`.
5. Run migrations against it by spawning `bun run src/infrastructure/db/migrate.ts`
   with the overridden `DATABASE_URL` (full schema + pgmq + queues).

Teardown: register `process.on('exit')` and SIGINT/SIGTERM handlers that
`docker rm -f` the container (`--rm` also removes it when stopped).

**Safety property:** the preload runs before any test file imports `client.ts`, and
it overrides `DATABASE_URL` unconditionally to the ephemeral container. Tests can
never reach the real database, regardless of what `.env` contains. If container
startup or readiness fails, the preload throws and the test run aborts rather than
falling back to any existing `DATABASE_URL`.

One container is shared for the whole `bun test` run (preload runs once); files run
sequentially and each resets the tables it needs in `beforeAll`, matching today's
behavior.

### 5. Repair `tests/ledger.test.ts`

Rewrite to the scoped model:

- In `beforeAll`, sign up a user (as `api.test.ts` does) to obtain `userId` and the
  per-user seeded account + `ZUS` category.
- Pass `userId` to every use-case call (`createTransaction`, `listTransactions`,
  `getMonthlySummary`, `createOpeningBalance`, `getTransaction`,
  `updateTransaction`, `deleteTransaction`, `listOpeningBalances`).
- Keep the genuinely DB-backed tests: atomic enqueue to `analysis_queue`,
  pagination/filtering, opening-balance uniqueness, update/delete, and one
  end-to-end `stan_konta` assertion for confidence. The exhaustive math assertions
  now live in `tests/summary-math.test.ts`.

### 6. `package.json`

Add a `"test": "bun test"` script for discoverability. The preload applies to
`bun test` regardless of how it is invoked.

## Testing strategy

- `tests/summary-math.test.ts` runs with no Docker/DB and is the primary coverage
  for the math.
- Existing integration tests plus the repaired `ledger.test.ts` run against the JIT
  DB and confirm the wiring (`getMonthlySummary` fetch + delegate) end-to-end.
- Verification: full `bun test` run is green against the ephemeral DB; confirm via
  the preload logs that `DATABASE_URL` was overridden to `finance_test`.

## Risks

- **Docker required to run DB-backed tests.** Acceptable: the dev/prod DB already
  requires this exact image. The pure unit tests need no Docker.
- **Image pull on first run** may be slow; mitigated by the existing local image
  used by `docker-compose`.
- **Behavior drift during extraction.** Mitigated by moving logic verbatim and by
  the end-to-end `stan_konta` integration assertion guarding the refactor.
