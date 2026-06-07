---
phase: 08
slug: worker-isolation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-07
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bun:test |
| **Config file** | none — bun:test is built-in |
| **Quick run command** | `bun test tests/import-worker.test.ts` |
| **Full suite command** | `bun test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bun test tests/<affected-test-file>.test.ts`
- **After every plan wave:** Run `bun test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _populated by planner_ | 1 | 1 | WORKER-01 | T-8-01 | PGMQ payload carries user_id | — | — | ✅ | ⬜ pending |
| _populated by planner_ | 1 | 1 | WORKER-02 | T-8-02 | Inserted transactions tagged with user ID | integration | `bun test tests/import-worker.test.ts` | ✅ | ⬜ pending |
| _populated by planner_ | 1 | 1 | WORKER-03 | T-8-03 | Account ownership validated before processing | integration | `bun test tests/import-worker.test.ts` | ✅ | ⬜ pending |
| _populated by planner_ | 1 | 2 | WORKER-04 | T-8-04 | Insights worker scoped by user_id | integration | `bun test tests/insights-worker.test.ts` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements — tests exist for both workers, need updates for user_id scoping.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ON CONFLICT constraint mismatch | WORKER-02 | Syntax vs runtime error — code compiles but DB constraint fails | Run import with multi-user data, verify no constraint violation |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
