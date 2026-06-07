# Phase 9: Testing & Verification - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Comprehensive test coverage proving no cross-user data leakage exists across all system layers — API isolation matrix, background workers (import + insights), concurrent user inserts, and migration rollback. Extends Phase 7's 27-test isolation baseline with edge cases, worker-specific isolation scenarios, concurrency tests, and schema rollback verification.

</domain>

<decisions>
## Implementation Decisions

### Isolation Matrix Expansion (TEST-01)
- **D-01:** Extend existing `tests/api-scoping.test.ts` with additional edge cases — not a separate file. The existing 27-test matrix is the baseline.
- **D-02:** Add pagination + offset tests — LIST with skip/limit parameters, verify page-2 results don't include cross-user data.
- **D-03:** Add filtered query tests — search by amount/date/description category-filtered LIST — verify filters respect `user_id` boundary.
- **D-04:** Add bulk/multi-create tests — verify all created resources are correctly tagged to the creating user.

### Concurrent User Tests (TEST-04)
- **D-05:** Use `Promise.all` wrapping parallel `app.request()` POST calls — simplest pattern, tests API layer + use-cases + DB integration.
- **D-06:** Verify full isolation after concurrent insert — row count matches per-user, no data mixing, cross-user 404 check against newly created rows.

### Worker Isolation Tests (TEST-03)
- **D-07:** Hybrid approach — most tests via direct function calls (`processJob`, `processAnalysisMessage` with mock payloads) for speed; one PGMQ routing test via `pgmq.send()` + `processJob`.
- **D-08:** Correct user tagging — import worker inserts transactions with correct `user_id` (verify via SELECT after `processCsvImportJob`).
- **D-09:** Cross-user account rejection — User B's `account_id` passed to User A's import job → verify skip behavior (Phase 8 D-01: skip + log, not throw).
- **D-10:** Insights worker scoped window — regression test that `getInsightDataWindow` and `getLatestTransactionDate` return correct per-user results (Phase 8 D-09, D-10 fixes).
- **D-11:** PGMQ routing test — enqueue messages for both users, verify `processJob` picks up the correct user's message (single PGMQ scenario in a dedicated `describe` block).
- **D-12:** Extend existing worker test files (`tests/import-worker.test.ts`, `tests/insights-worker.test.ts`) — add isolation scenarios alongside existing tests, not a separate file.

### Migration Rollback Test (TEST-05)
- **D-13:** Standalone `tests/migration-rollback.test.ts` — separate lifecycle to not interfere with other tests (migrate up/down is destructive).
- **D-14:** Assert schema state after `up()` — verify `user_id` columns exist, composite `UNIQUE(user_id, ...)` constraints in place, composite indexes exist.
- **D-15:** Assert schema state after `down()` — verify `user_id` columns removed, global UNIQUE constraints restored, no orphan indexes or partial constraints.
- **D-16:** Assert data integrity — insert test data before migration up, verify accessibility during, verify documented data loss after destructive down (Phase 6 D-07).
- **D-17:** No orphan constraints — verify clean schema state after down (no leftover `user_id` references, no composite indexes pointing at removed columns).

### Folded Todos
- **extract-llm-descriptions.md** — Already completed in Phase 7 (migration 011 + signup hook + code reads). No additional work needed. Folded for closure.
- **auth-guard-and-redirect.md** — Frontend auth wiring. Reviewed during Phase 7, confirmed as Phase 10 concern. Not folded into this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` § TEST-01 through TEST-05 — Locked test requirements

### Existing Test Files
- `tests/api-scoping.test.ts` — Existing 27-test multi-user isolation matrix (Phase 7 baseline, D-01 extends this file)
- `tests/seeding.test.ts` — Signup hook seeding tests (10 tests)
- `tests/import-worker.test.ts` — Import worker tests (D-12 extends with isolation scenarios)
- `tests/insights-worker.test.ts` — Insights worker tests (D-12 extends with isolation scenarios)
- `tests/schema-migration.test.ts` — Existing migration tests (reference for node-pg-migrate pattern)

### Migration Infrastructure
- `src/infrastructure/db/migrate.ts` — node-pg-migrate runner (TEST-05 programmatic usage)
- `src/infrastructure/db/migrations/` — Migration files 008-011 (rollback cycle for TEST-05)
- `src/infrastructure/db/schema.sql` — Current schema (target state reference for rollback assertions)

### Prior Phase Context
- `.planning/phases/07-backend-scoping/07-CONTEXT.md` — D-02 (implicit ownership via SQL WHERE), D-01 (params object pattern), prior scoping decisions
- `.planning/phases/07-backend-scoping/07-04-SUMMARY.md` — Details of existing api-scoping.test.ts coverage
- `.planning/phases/08-worker-isolation/08-CONTEXT.md` — D-01 through D-10 (worker isolation decisions, ownership validation, skip behavior)
- `.planning/phases/08-worker-isolation/08-RESEARCH.md` — Detailed worker test patterns, pitfalls, test fix guidance
- `.planning/phases/08-worker-isolation/08-PATTERNS.md` — Analog-based implementation patterns for worker changes
- `.planning/phases/06-schema-migration-backfill/06-CONTEXT.md` — D-07 (destructive down migrations)

### Spike Findings
- `.opencode/skills/spike-findings-finance/references/import-dedup.md` — Import dedup hash pattern, UNIQUE(user_id, import_hash) constraint context

### Worker Source Files (for isolation test scenarios)
- `src/workers/import-worker.ts` — `processCsvImportJob`, `processExcelMigrationJob`, `processJob`, `insertBatch`
- `src/workers/insights-worker.ts` — `processAnalysisMessage`, PGMQ user_id extraction pattern
- `src/core/insights/use-cases.ts` — `getInsightDataWindow`, `getLatestTransactionDate`, `getCategoryAggregates`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tests/api-scoping.test.ts` — Full multi-user isolation pattern: `signupEmail()` for 2 users, `app.request()` for API calls, cross-user 404 assertions. Copy this pattern for concurrent tests.
- `tests/schema-migration.test.ts` — Programmatic node-pg-migrate `up()`/`down()` usage. Copy lifecycle pattern for rollback tests.
- `src/infrastructure/db/migrate.ts` — `runMigrations()` function, can be called directly in test setup/teardown.

### Established Patterns
- **Two-user signup pattern:** `signupEmail(userA)` + `signupEmail(userB)` in `beforeAll`, then test both directions (User A creates → User B verifies 404).
- **API test pattern:** `const app = createApp(); const res = await app.request(path, { method, headers, body })`.
- **Direct SQL setup:** `await sql\`INSERT INTO ...\`` in `beforeAll` blocks for seed data.
- **`Promise.all` for concurrency:** Use Bun's built-in Promise.all with parallel `app.request()` calls.
- **Direct worker invocation:** Call `processCsvImportJob()` / `processAnalysisMessage()` directly with constructed payload objects.

### Integration Points
- Migration test requires separate schema lifecycle — rollback tests must not share the same migration state as other tests.
- Worker isolation tests extend existing test files — import existing `processJob`, `processCsvImportJob` from same paths.
- Concurrent tests share `signupEmail()` helper with api-scoping.test.ts — place in a shared helper or duplicate pattern.

</code_context>

<specifics>
## Specific Ideas

No specific references — standard approach following Phase 7/8 testing patterns (bun:test, direct SQL, app.request).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

### Reviewed Todos (not folded)
- **auth-guard-and-redirect.md** — Frontend auth wiring, Phase 10 concern. Was already reviewed in Phase 7 with same determination.

</deferred>

---

*Phase: 9-Testing & Verification*
*Context gathered: 2026-06-07*
