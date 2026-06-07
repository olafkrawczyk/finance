# Phase 9: Testing & Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 9-Testing & Verification
**Areas discussed:** Isolation matrix depth, Concurrent user tests, Worker isolation approach, Migration rollback design

---

## Isolation Matrix Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Edge case expansion | Add pagination, filtered queries, bulk operations | ✓ |
| Asset + import coverage gap-fill | Dedicated tests for assets and import_jobs | |
| Worker + migration = comprehensive | Don't expand matrix further | |

**User's choice:** Edge case expansion
**Notes:** Selected pagination+offset, filtered queries, and bulk/multi-create edge cases.

---

## Concurrent User Tests

| Option | Description | Selected |
|--------|-------------|----------|
| Promise.all parallel API requests | Simplest, uses existing patterns | ✓ |
| Parallel SQL inserts via sql.begin | Bypasses API layer | |
| PGMQ worker-triggered concurrent inserts | Most realistic but complex | |

**User's choice:** Promise.all parallel API requests

Follow-up: What should the concurrent test verify?

| Option | Description | Selected |
|--------|-------------|----------|
| Row counts + data ownership | Each user sees exactly their rows | |
| Full isolation — rows + counts + 404 cross-check | Run cross-user 404 after concurrent insert | ✓ |
| No errors or collisions | Just verify no errors | |

**User's choice:** Full isolation — rows + counts + 404 cross-check

---

## Worker Isolation Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Direct function calls | Call processJob directly with mock payloads | ✓ |
| Full PGMQ enqueue-and-consume | Realistic but timing-dependent | |
| New dedicated worker-isolation file | Separate from existing tests | |

**User's choice:** Direct function calls (recommended)

Follow-up: Which scenarios?

| Scenario | Selected |
|----------|----------|
| Correct user tagging | ✓ |
| Cross-user account rejection | ✓ |
| Insights worker scoped window | ✓ |
| Worker ignores other user's PGMQ messages | ✓ |

Follow-up: PGMQ routing scenario conflicts with direct function calls. Hybrid or drop?

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid | Direct for 3, PGMQ for routing | ✓ |
| Drop PGMQ routing | Focus on 3 direct-call scenarios | |
| All 4 via PGMQ | Slower but more realistic | |

**User's choice:** Hybrid

---

## Migration Rollback Design

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone test file with lifecycle | Separate file, doesn't interfere | ✓ |
| Add to schema-migration.test.ts | Uses existing setup | |
| Separate script (not a test) | Manual/CI gate | |

**User's choice:** Standalone test file with lifecycle

Follow-up: What assertions?

| Assertion | Selected |
|-----------|----------|
| Schema state after up | ✓ |
| Schema state after down | ✓ |
| Data integrity | ✓ |
| No orphan constraints | ✓ |

**User's choice:** All 4 assertions

---

## Deferred Ideas

None — discussion stayed within phase scope.

### Reviewed Todos
- **auth-guard-and-redirect.md** — Frontend auth wiring, Phase 10 concern
- **extract-llm-descriptions.md** — Already completed in Phase 7, folded for closure
