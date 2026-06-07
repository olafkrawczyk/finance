# Phase 8: Worker Isolation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 8-Worker Isolation
**Areas discussed:** Account ownership validation, user_id flow through insertBatch, Excel migration job scoping, Insights worker regression fix, Folded todo extract-llm-descriptions

---

## Account Ownership Validation

| Option | Description | Selected |
|--------|-------------|----------|
| Fail the job | Reject the entire import job with an error | |
| Skip and continue | Skip the account and log an error, continue processing | ✓ |

**User's choice:** Skip and continue
**Notes:** Partial imports still complete — resilient approach.

| Option | Description | Selected |
|--------|-------------|----------|
| Implicit via SQL filter | SELECT id FROM accounts WHERE id = ${accountId} AND user_id = ${userId} | ✓ |
| Explicit helper function | Separate validateAccountOwnership() function | |

**User's choice:** Implicit via SQL filter (Recommended)
**Notes:** Consistent with Phase 7 D-02 pattern.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, scope by user | Add AND user_id = ${userId} to account lookups | ✓ |
| No, name-based is fine | Account names are unique per user already | |

**User's choice:** Yes, scope by user (Recommended)
**Notes:** Users only see their own seeded accounts.

---

## user_id Flow Through InsertBatch

| Option | Description | Selected |
|--------|-------------|----------|
| Add userId param | Explicit userId param to insertBatch | ✓ |
| Context object approach | Pass context object {accountId, userId, ...} | |
| DB trigger approach | Auto-populate via trigger from import_jobs join | |

**User's choice:** Add userId param (Recommended)
**Notes:** Consistent with existing function signature patterns.

| Option | Description | Selected |
|--------|-------------|----------|
| Update to (user_id, import_hash) | Apply Phase 6 D-06 UNIQUE(user_id, import_hash) | ✓ |
| Keep global UNIQUE | Keep UNIQUE(import_hash) globally | |

**User's choice:** Update to (user_id, import_hash) (Recommended)
**Notes:** Phase 6 D-06 applied — prevents cross-user hash collisions.

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit destructure | Destructure user_id from payload explicitly | ✓ |
| Payload passthrough | Pass entire payload as context to sub-functions | |

**User's choice:** Explicit destructure (Recommended)
**Notes:** Clear, type-safe.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, scope | Add AND user_id = ${userId} to import_jobs UPDATE | ✓ |
| No, job_id is enough | job_id already unique, skip user_id filter | |

**User's choice:** Yes, scope (Recommended)
**Notes:** Consistent with Phase 7 scoping pattern.

---

## Excel Migration Job Scoping

| Option | Description | Selected |
|--------|-------------|----------|
| Same pattern as CSV | Destructure user_id, scope queries, update ON CONFLICT | ✓ |
| Different approach | Different scoping approach | |

**User's choice:** Same pattern as CSV (Recommended)
**Notes:** Enqueue side already includes user_id in payload (migration.ts:66).

---

## Insights Worker Regression Fix

| Option | Description | Selected |
|--------|-------------|----------|
| Add user_id filter to WHERE | AND t.user_id = ${userId} | ✓ |
| Partition per-user | Run getInsightDataWindow per user separately | |

**User's choice:** Add user_id filter to WHERE (Recommended)
**Notes:** Matches Phase 7 D-02 pattern.

| Option | Description | Selected |
|--------|-------------|----------|
| Scope per-user | Add userId param to getLatestTransactionDate | ✓ |
| Keep global | Keep global latest date as ceiling | |

**User's choice:** Scope per-user (Recommended)
**Notes:** Prevents cross-user date window skew.

---

## Folded Todo: extract-llm-descriptions

| Option | Description | Selected |
|--------|-------------|----------|
| Populate seed data now | Populate descriptions for default categories | ✓ |
| Defer further | Keep deferred, column works with NULL descriptions | |

**User's choice:** Populate seed data now (Recommended)
**Notes:** Column already exists, signup hook already populated with llm_description for 25 categories. Already completed in Phase 7 — no additional work needed.

---

## the agent's Discretion

None — all decisions made by user during discussion.

## Deferred Ideas

None — discussion stayed within phase scope.
