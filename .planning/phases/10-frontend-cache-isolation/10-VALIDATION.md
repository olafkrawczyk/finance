---
phase: 10
slug: frontend-cache-isolation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None detected — no test infra exists in project |
| **Config file** | None |
| **Quick run command** | N/A |
| **Full suite command** | N/A |
| **Estimated runtime** | N/A — manual verification only |

---

## Sampling Rate

- **After every task commit:** No automated tests — verify by code review
- **After every plan wave:** No automated tests — verify by browser DevTools inspection
- **Before `/gsd-verify-work`:** Manual walkthrough of all 3 requirements
- **Max feedback latency:** N/A

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | FRONTEND-01 | — | Query keys include user.id prefix | Manual / Code review | N/A | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | FRONTEND-02 | — | Cache cleared on login/logout | Manual / Browser test | N/A | ❌ W0 | ⬜ pending |
| 10-01-03 | 01 | 1 | FRONTEND-03 | — | Skeletons shown during re-fetch | Manual / Visual inspection | N/A | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `frontend/vitest.config.ts` — test framework config (nonexistent)
- [ ] `frontend/src/lib/__tests__/queryKeys.test.ts` — verify user ID prefix in query keys
- [ ] `frontend/src/lib/__tests__/CacheManager.test.ts` — verify clear on auth transitions

*Existing infrastructure covers no phase requirements — no test framework exists in the project.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Query keys include user.id prefix | FRONTEND-01 | No test infra — verify by inspection of `queryKeys.ts` | Review `queryKeys.ts` — every key factory includes `userId` as second element: `['user', userId, 'resource']` |
| Cache cleared on login/logout | FRONTEND-02 | No test infra — verify via browser DevTools | Login as User A → inspect React Query devtools for cached keys → logout → login as User B → confirm keys are fresh (no User A data visible) |
| Skeletons shown during re-fetch | FRONTEND-03 | No test infra — verify via visual inspection | Login as User A → observe skeleton display → switch to User B → confirm skeleton flashes during re-fetch before new data appears |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < N/A s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
