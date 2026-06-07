# Phase 6: Schema Migration & Backfill - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Add `user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE` to all 6 domain tables (accounts, categories, transactions, monthly_opening_balances, assets, import_jobs). Set per-user composite UNIQUE constraints and drop/modify global UNIQUE constraints. Add minimal composite indexes for per-user query patterns.

DB will be wiped before onboarding new users — no data backfill needed.
</domain>

<decisions>
## Implementation Decisions

### Backfill Strategy
- **D-01:** DB wiped before new user onboarding. No backfill needed. No "first user" detection logic required.

### Migration Order & Nullability
- **D-02:** `user_id` added as `NOT NULL` directly (fresh DB means no existing rows to handle).
- **D-03:** Migrations split by concern into separate SQL files: (1) add columns, (2) update constraints, (3) add indexes.

### Composite Index Selection
- **D-04:** Minimal essential indexes only — `(user_id, name)` on assets and categories for per-user UNIQUE constraints, `(user_id, import_hash)` on transactions. No additional composite indexes beyond what constraints require.

### import_hash Scoping
- **D-05:** Constraint changes from `UNIQUE(import_hash)` to `UNIQUE(user_id, import_hash)` — per-user dedup isolation.
- **D-06:** Hash algorithm updated to include `account_id`: SHA-256 of `date|amount|description|account_id`. Update `computeImportHash` in `src/workers/import-worker.ts`.

### Down-migration Strategy
- **D-07:** Down migrations are destructive — `DROP COLUMN user_id`, restore old global UNIQUE constraints, drop new composite indexes. Supports Phase 9 rollback test (TEST-05).

### Folded Todos
- **extract-llm-descriptions.md** — Extract LLM descriptions from prompt to seed data. Relevant to default category/account seeding patterns; seeds may reference LLM-generated descriptions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Spec
- `.planning/REQUIREMENTS.md` § SCHEMA-01 through SCHEMA-11 — Locked schema migration requirements

### Current Schema & DB Setup
- `src/infrastructure/db/schema.sql` — Current declarative schema (target for migration)
- `src/infrastructure/db/client.ts` — Database client (postgres.js)
- `src/infrastructure/db/migrate.ts` — Migration runner config (node-pg-migrate)
- `src/infrastructure/db/migrations/` — Existing numbered SQL migration files (next: 007)

### Query Patterns (for index decisions)
- `src/core/ledger/use-cases.ts` — Transaction query patterns (list, summary, CRUD)
- `src/core/assets/use-cases.ts` — Asset query patterns (list, CRUD)

### Worker & Hash Algorithm
- `src/workers/import-worker.ts` — `computeImportHash` function (needs account_id scope update)

### Spike Findings
- `.opencode/skills/spike-findings-finance/references/import-dedup.md` — Import dedup analysis, hash scoping recommendation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/infrastructure/db/migrate.ts` — node-pg-migrate runner, established pattern for SQL migrations
- Existing migrations in `src/infrastructure/db/migrations/` — numbered files following `NNN_description.sql` convention

### Established Patterns
- SQL-based migrations with node-pg-migrate, one file per change
- `postgres.js` tagged template literal for all SQL queries
- UUID primary keys with `gen_random_uuid()`
- `ON DELETE CASCADE` for foreign key references

### Integration Points
- New migrations go in `src/infrastructure/db/migrations/` starting at `007_add_user_id.sql`
- Schema reference file `src/infrastructure/db/schema.sql` must be updated to match final state
- `src/infrastructure/db/apply.ts` applies schema.sql for fresh DB setup

</code_context>

<specifics>
## Specific Ideas

No specific references — standard migration approach with node-pg-migrate SQL files. Fresh DB means no backfill complexity.

</specifics>

<deferred>
## Deferred Ideas

- **Hash algorithm update for import_hash** — `computeImportHash` modification is noted as D-06 but could be implemented during this phase (migration file) or deferred to Phase 8 (worker isolation). Researcher/planner flexibility.

### Reviewed Todos (not folded)
- **auth-guard-and-redirect.md** — Frontend auth wiring, out of scope for schema migration (Phase 10 concern).
- **dockerize-app.md** — Already handled in Phase 5, not related to this phase.

</deferred>

---

*Phase: 6-Schema Migration & Backfill*
*Context gathered: 2026-06-07*
