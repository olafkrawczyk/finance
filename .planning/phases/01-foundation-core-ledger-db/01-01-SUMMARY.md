---
phase: 01-foundation-core-ledger-db
plan: 01
subsystem: database
tags: [bun, postgres, pgmq, docker, tsconfig]

# Dependency graph
requires:
  - phase: initialization
    provides: requirements and architecture roadmap
provides:
  - bun environment configuration
  - docker-compose with postgres and pgmq
  - postgres.js db client singleton
  - core schema ddl and 25 category seeds with 6 fixed cost categories
  - pgmq analysis_queue queue initialization
  - bun test suites for ledger, queue, and schemas
affects:
  - 01-02-PLAN.md
  - 01-03-PLAN.md

# Tech tracking
tech-stack:
  added: [bun, postgres, pgmq-js (removed)]
  patterns: [postgres.js singleton client, immutable transaction triggers, docker compose environment local provision]

key-files:
  created:
    - tsconfig.json
    - bunfig.toml
    - docker-compose.yml
    - src/infrastructure/db/client.ts
    - src/infrastructure/db/schema.sql
    - src/infrastructure/db/seed.sql
    - src/infrastructure/db/apply.ts
    - src/infrastructure/db/health.ts
    - tests/schemas.test.ts
    - tests/ledger.test.ts
    - tests/queue.test.ts
  modified:
    - package.json

key-decisions:
  - "Used postgres.js directly for DB and PGMQ interactions instead of an external library wrapper (removed pgmq-js)."
  - "Configured monthly_opening_balances globally with UNIQUE(year, month) and no account_id."
  - "Enforced transaction immutability at the DB layer via BEFORE UPDATE and BEFORE DELETE exceptions."
  - "Mounted the Postgres 18 data volume at /var/lib/postgresql instead of /var/lib/postgresql/data to align with PG18 cluster expectations."

patterns-established:
  - "Immutability trigger pattern: triggers preventing modification of existing ledger entries."
  - "Idempotent migrations: safe DDL and seed scripts that check existence before applying."

requirements-completed:
  - REQ-1.1
  - REQ-1.2
  - REQ-1.3
  - REQ-2.1
  - REQ-2.2
  - REQ-Tech-DB
  - D-01
  - D-05
  - D-06
  - D-07
  - D-08

# Metrics
duration: 7min
completed: 2026-06-06
---

# Phase 01 Plan 01: Core Ledger & DB Foundation Summary

**Bun runtime config, Postgres+PGMQ container deployment, idempotent database migrations, transaction immutability triggers, and queue client test suites**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-06T10:45:15Z
- **Completed:** 2026-06-06T10:52:45Z
- **Tasks:** 4
- **Files modified:** 12

## Accomplishments
- **Runtime Environment:** Installed Bun 1.3.x, configured tsconfig.json, and created local environment configs (.env, .gitignore).
- **Docker Postgres + PGMQ:** Deployed pg18-pgmq Docker container on port 5432, enabling native message queue support.
- **Authoritative Database Schema:** Applied the core database structures (accounts, categories, transactions, and global opening balances).
- **Fixed-Cost Seed:** Seeded 25 default category items, marking exactly 6 as fixed-cost.
- **Immutability Triggers:** Placed triggers on the `transactions` table to raise exceptions on UPDATE/DELETE, securing database-level single-entry immutability.
- **Green Test Suites:** Created integration tests for `queue`, `ledger`, and schema scaffolds, passing all assertions successfully.

## Task Commits

Each task was committed atomically:

1. **Task 0: Install Bun and provision Postgres + PGMQ (environment prerequisites)** - `fa10f49` (chore)
2. **Task 1: Project config — tsconfig, bunfig, env, postgres.js client** - `279074e` (feat)
3. **Task 2: Schema DDL, category seed, PGMQ queue, apply script, health check** - `77ff66c` (feat)
4. **Task 3: Test scaffolds (Nyquist — discoverable tests)** - `faebed9` (test)

## Files Created/Modified
- `package.json` (modified) - Removed `pgmq-js` and added `@types/bun`.
- `tsconfig.json` (created) - Bun compiler options.
- `bunfig.toml` (created) - Bun test timeout settings.
- `.env.example` (created) - Database and port placeholder config.
- `.gitignore` (created) - Standard node/bun ignores.
- `docker-compose.yml` (created) - Postgres/PGMQ service definition.
- `src/infrastructure/db/client.ts` (created) - `postgres.js` singleton instance.
- `src/infrastructure/db/schema.sql` (created) - Schema table definitions, triggers, and indices.
- `src/infrastructure/db/seed.sql` (created) - Seeding script for categories, accounts, and queue creation.
- `src/infrastructure/db/apply.ts` (created) - Runnable script to execute SQL migrations.
- `src/infrastructure/db/health.ts` (created) - Health checks for database and PGMQ status.
- `tests/schemas.test.ts` (created) - Zod schema test placeholders.
- `tests/ledger.test.ts` (created) - Ledger immutability and seed verification.
- `tests/queue.test.ts` (created) - PGMQ queue send/read/delete integration test.

## Decisions Made
- **Removed pgmq-js library:** Chose raw SQL operations via `postgres.js` instead of installing the library. PGMQ exposes a direct SQL interface (`pgmq.send`, `pgmq.read`, `pgmq.delete`), making wrapper libraries redundant.
- **Global opening balances:** Stored global net worth values instead of account-specific opening balances by leaving `account_id` out of `monthly_opening_balances`.
- **Trigger-based immutability:** Decided to raise errors at the database layer on attempts to write or delete from the ledger to prevent application-layer bypasses.
- **Adjusted Docker Volume Mount:** Mounted the Docker data directory to `/var/lib/postgresql` instead of `/var/lib/postgresql/data` to conform with Postgres 18+ container compatibility requirements.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Postgres 18 volume compatibility issue**
- **Found during:** Task 0 (Postgres environment provisioning)
- **Issue:** Deployed container exited with code 1 because the data mount path was set directly to `/var/lib/postgresql/data`.
- **Fix:** Changed the volume mount path in `docker-compose.yml` to `/var/lib/postgresql`.
- **Files modified:** docker-compose.yml
- **Verification:** Docker container started and accepted connections successfully.
- **Committed in:** fa10f49 (Task 0 commit)

**2. [Rule 1 - Bug] PGMQ delete ambiguity in type inference**
- **Found during:** Task 3 (Test suite execution)
- **Issue:** `pgmq.delete` failed with "function pgmq.delete(unknown, unknown) is not unique" because the database could not resolve the parameter type.
- **Fix:** Added a `::bigint` type cast to the message ID variable.
- **Files modified:** tests/queue.test.ts
- **Verification:** `bun test` passed successfully.
- **Committed in:** faebed9 (Task 3 commit)

**3. [Rule 1 - Bug] Ledger test database cleanup blocked by immutability**
- **Found during:** Task 3 (Test suite execution)
- **Issue:** `DELETE FROM transactions` in `beforeAll` failed because the `trg_transactions_no_delete` trigger correctly blocked all delete operations.
- **Fix:** Replaced `DELETE FROM transactions` with `TRUNCATE transactions CASCADE` which bypasses delete triggers.
- **Files modified:** tests/ledger.test.ts
- **Verification:** Database successfully cleaned up, and all tests passed.
- **Committed in:** faebed9 (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (3 bugs)
**Impact on plan:** All fixes were necessary for standard execution and verified correctness. No scope creep.

## Issues Encountered
- **Bun/WSL Docker Integration:** The `docker` command was initially missing in the current WSL distro. Enabled integration in Docker Desktop Settings -> Resources -> WSL Integration to solve.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Postgres + PGMQ environment fully running.
- Idempotent migrations and triggers validated.
- Ready to proceed to 01-02-PLAN.md (Domain Layer, entities, Monthly summary, and Zod v4 validation).

---
*Phase: 01-foundation-core-ledger-db*
*Completed: 2026-06-06*
