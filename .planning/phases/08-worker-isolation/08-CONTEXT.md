# Phase 8: Worker Isolation - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Background workers (import CSV, Excel migration, insights) enforce per-user data isolation. Import workers extract `user_id` from PGMQ payloads, validate account ownership, and tag all inserted transactions with the correct user. Insights worker's `getInsightDataWindow` is fixed to actually filter by `user_id`. The `import_hash` unique constraint is updated to `(user_id, import_hash)`.

</domain>

<decisions>
## Implementation Decisions

### Account Ownership Validation
- **D-01:** When `account_id` doesn't belong to the user processing the import, **skip and continue** — log an error, skip the batch, keep processing. Don't fail the entire job for one invalid account.
- **D-02:** Ownership check is implicit via SQL filter (`SELECT id FROM accounts WHERE id = ${accountId} AND user_id = ${userId}`), consistent with Phase 7 D-02. No explicit helper function.
- **D-03:** Excel migration account lookups (by PKO_PERSONAL_ACCOUNT_NAME / ING_BUSINESS_ACCOUNT_NAME) are scoped by `user_id` too — `AND user_id = ${userId}` added to queries.

### user_id Flow Through Import Pipeline
- **D-04:** `insertBatch` gets an explicit `userId` parameter added (not a context object or trigger). Consistent with existing patterns.
- **D-05:** `ON CONFLICT (import_hash)` updated to `ON CONFLICT (user_id, import_hash)` — Phase 6 D-06 applied. Requires migration to add composite `UNIQUE(user_id, import_hash)` constraint.
- **D-06:** `processCsvImportJob` extracts `user_id` from PGMQ payload via explicit destructuring alongside `account_id`, `csv_content`, `bank_format`.
- **D-07:** All `import_jobs` status UPDATE statements filter by `user_id` in WHERE clause (`WHERE id = ${jobId} AND user_id = ${userId}`).

### Excel Migration Scoping
- **D-08:** `processExcelMigrationJob` extracts `user_id` from PGMQ payload and scopes all queries the same way as CSV import path. The enqueue side (`migration.ts`) already includes `user_id: user.id` in the payload — worker just needs to consume it.

### Insights Worker Regression Fix
- **D-09:** `getInsightDataWindow` SQL WHERE clause gets `AND t.user_id = ${userId}` — the `userId` parameter already exists but was never applied in the query.
- **D-10:** `getLatestTransactionDate` is scoped per-user — `SELECT MAX(date)::text AS latest FROM transactions WHERE user_id = ${userId}`. Prevents cross-user date window skew.

### Folded Todos
- **extract-llm-descriptions** — Already completed in Phase 7 (migration 011 + signup hook seed data + code reads). No additional work needed in Phase 8 — noted here for awareness.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` § WORKER-01 through WORKER-04 — Locked worker isolation requirements

### Import Worker
- `src/workers/import-worker.ts` — `processCsvImportJob`, `processExcelMigrationJob`, `insertBatch`, `processJob` — all need user_id plumbing
- `src/core/import/use-cases.ts` — `enqueueImportJob` already includes `user_id` in PGMQ payload (Phase 7 scope)
- `src/core/import/entities.ts` — `ImportJob` interface (may need `user_id` field added)
- `src/interface-adapters/api/migration.ts` — Excel migration enqueue, already includes `user_id: user.id` in PGMQ payload

### Insights Worker
- `src/workers/insights-worker.ts` — `processAnalysisMessage` already extracts `user_id` from payload
- `src/core/insights/use-cases.ts` — `getInsightDataWindow(userId)` — userId param exists but SQL WHERE doesn't filter by it (needs fix)
- `src/core/insights/use-cases.ts` — `getLatestTransactionDate()` — needs `user_id` param

### Seed Data
- `src/auth.ts:37-69` — Signup hook seeds 25 default categories with `llm_description` already populated

### Prior Context
- `.planning/phases/07-backend-scoping/07-CONTEXT.md` — D-05 (import scoping boundary), D-02 (implicit ownership validation pattern)
- `.planning/phases/06-schema-migration-backfill/06-CONTEXT.md` — D-06 (hash includes account_id, UNIQUE(user_id, import_hash))

### Spike Findings
- `.opencode/skills/spike-findings-finance/references/import-dedup.md` — Import dedup analysis, hash scoping recommendation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/core/insights/use-cases.ts` — the params-object-with-userId pattern is already established and tested
- `src/interface-adapters/api/auth.ts` — `requireAuth` middleware sets `c.get('user')` — used by migration enqueue

### Established Patterns
- **Implicit ownership via SQL WHERE** — Phase 7 D-02 pattern, reused for worker ownership validation
- **Explicit param passing** — `userId` added as parameter (not context object), consistent with how `accountId` is already passed in `insertBatch`
- **PGMQ payload structure** — `user_id` already threaded into both import_queue and analysis_queue payloads

### Integration Points
- `import-worker.ts` — Insert `user_id` in INSERT INTO transactions, add `user_id = ${userId}` to import_jobs UPDATEs, scope `ON CONFLICT` to `(user_id, import_hash)`, scope `getCategoryAggregates` / `getLatestTransactionDate` per-user
- `insights-worker.ts` — Fix `getInsightDataWindow` WHERE clause to actually use the `userId` parameter
- `insertBatch()` — Add `userId` parameter, pass to each INSERT
- `processExcelMigrationJob()` — Extract `user_id` from payload, scope category/account queries

</code_context>

<specifics>
## Specific Ideas

No specific references — standard approach following Phase 7 patterns.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 8-Worker Isolation*
*Context gathered: 2026-06-07*
