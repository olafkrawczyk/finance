---
phase: 07
slug: backend-scoping
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-07
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bun:test (built-in) |
| **Config file** | none — zero-config |
| **Quick run command** | `bun test --timeout 30000 tests/api-scoping.test.ts` |
| **Full suite command** | `bun test --timeout 30000` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** `bun test --timeout 30000 tests/api-scoping.test.ts`
- **After every plan wave:** `bun test --timeout 30000`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | SCOPE-01 | T-07-01 / — | SELECT filters by user_id | integration | `bun test tests/api-scoping.test.ts` | ❌ W0 | ⬜ pending |
| 07-01-02 | 01 | 1 | SCOPE-02 | T-07-01 / — | INSERT includes user_id | integration | `bun test tests/api-scoping.test.ts` | ❌ W0 | ⬜ pending |
| 07-01-03 | 01 | 1 | SCOPE-06 | T-07-01 / — | Route handler extracts from session | integration | `bun test tests/api-scoping.test.ts` | ✅ existing | ⬜ pending |
| 07-01-04 | 01 | 1 | SCOPE-07 | T-07-01 / — | Inline SQL refactored to use-cases | code review | Manual | ❌ W0 | ⬜ pending |
| 07-02-01 | 02 | 1 | SCOPE-03 | T-07-01 / — | UPDATE filters by user_id | integration | `bun test tests/api-scoping.test.ts` | ❌ W0 | ⬜ pending |
| 07-02-02 | 02 | 1 | SCOPE-04 | T-07-01 / — | DELETE filters by user_id | integration | `bun test tests/api-scoping.test.ts` | ❌ W0 | ⬜ pending |
| 07-02-03 | 02 | 1 | SCOPE-05 | T-07-01 / — | Ownership validation via WHERE | integration | `bun test tests/api-scoping.test.ts` | ❌ W0 | ⬜ pending |
| 07-03-01 | 03 | 2 | SEED-01 | T-07-02 / — | Default categories seeded | integration | `bun test tests/seeding.test.ts` | ❌ W0 | ⬜ pending |
| 07-03-02 | 03 | 2 | SEED-02 | T-07-02 / — | Default account created | integration | `bun test tests/seeding.test.ts` | ❌ W0 | ⬜ pending |
| 07-03-03 | 03 | 2 | D-05 / SCOPE-02 | T-07-01 / — | Import enqueue includes user_id | integration | `bun test tests/api-scoping.test.ts` | ❌ W0 | ⬜ pending |
| 07-04-01 | 04 | 2 | SEED-01 | T-07-02 / — | onSignUp hook creates defaults | integration | `bun test tests/seeding.test.ts` | ❌ W0 | ⬜ pending |
| 07-04-02 | 04 | 2 | D-04 / SCOPE-01 | T-07-01 / — | Reference use-cases extract | code review | Manual | ❌ W0 | ⬜ pending |
| 07-05-01 | 05 | 3 | folded todo | — | llm_description column added | migration | `bun test tests/schema-migration.test.ts` | ✅ existing | ⬜ pending |
| 07-05-02 | 05 | 3 | folded todo | — | buildFewShotPrompt reads from DB | code review | Manual | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/api-scoping.test.ts` — Multi-user isolation tests for SCOPE-01 through SCOPE-07
- [ ] `tests/seeding.test.ts` — onSignUp hook seeding verification tests
- [ ] No framework install needed (bun:test exists)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inline SQL refactored to use-cases | SCOPE-07 | No automated test for code structure | Verify `git grep 'sql\`' src/interface-adapters/api/` has no matches in ledgers.ts (PATCH /:id/category) and reference.ts is a thin shell |
| Reference use-cases extracted | D-04 | File existence check | Confirm `src/core/reference/use-cases.ts` exists with `listAccounts` and `listCategories` |
| buildFewShotPrompt reads from DB | folded todo | Behavior change requires manual review | Confirm `src/workers/import-worker.ts` `buildFewShotPrompt` queries `llm_description` column instead of hardcoded strings |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
