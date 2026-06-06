---
phase: 1
slug: foundation-core-ledger-db
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-06
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bun Test (built-in) |
| **Config file** | none — Bun test runner requires no config |
| **Quick run command** | `bun test` |
| **Full suite command** | `bun test --coverage` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bun test`
- **After every plan wave:** Run `bun test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | ENV | — | N/A | integration | `bun --version` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | ENV | — | N/A | integration | `docker --version` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 2 | REQ-1.x | — | N/A | integration | `bun run test --run` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 2 | REQ-2.x | — | N/A | integration | `bun run test --run` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 3 | REQ-1.x | — | API returns envelope | integration | `bun run test --run` | ❌ W0 | ⬜ pending |
| 01-03-02 | 03 | 3 | REQ-2.x | — | N/A | integration | `bun run test --run` | ❌ W0 | ⬜ pending |
| 01-03-03 | 03 | 3 | D-04 | — | CRUD opening balance | integration | `bun run test --run` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/schemas.test.ts` — stub created by 01-01 Task 3 before 01-02 fills it
- [ ] `tests/ledger.test.ts` — stub created by 01-01 Task 3 before 01-03 fills it

*Test stubs created in 01-01 Task 3 (wave 1) before functional implementation in waves 2–3.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Docker PGMQ container starts | ENV | External dependency | `docker ps` shows pgmq container running on port 5432 |
| PGMQ queue initialized | ENV | Requires live DB | `psql -c "SELECT * FROM pgmq.list_queues();"` shows `csv_import` queue |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags (all commands use `bun test`, no `--watch`)
- [ ] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
