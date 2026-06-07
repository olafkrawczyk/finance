---
phase: 6
slug: schema-migration-backfill
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-07
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `bun:test` |
| **Config file** | none — Bun uses convention (`tests/*.test.ts`) |
| **Quick run command** | `bun test --filter "dedup\|schema\|unique\|index"` |
| **Full suite command** | `bun test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bun test --filter "dedup|schema"`
- **After every plan wave:** Run `bun test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | SCHEMA-01–06 | T-6-01 / — | FK `ON DELETE CASCADE` enforces referential integrity | integration | `bun test --filter "schema"` | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 1 | SCHEMA-08–10 | T-6-02 / — | Per-user UNIQUE constraints prevent cross-user collisions | integration | `bun test --filter "unique"` | ❌ W0 | ⬜ pending |
| 06-03-01 | 03 | 1 | SCHEMA-11 | T-6-03 / — | Composite indexes exist for per-user query patterns | integration | `bun test --filter "index"` | ❌ W0 | ⬜ pending |
| 06-XX-XX | XX | 1 | SCHEMA-06 | — | N/A | integration | `bun test --filter "schema"` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `tests/schema-migration.test.ts` — integration tests for SCHEMA-01 through SCHEMA-11
- [ ] DB test fixtures — may need `beforeAll` setup to establish migration state

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Migration file inspection | SCHEMA-01–11 | File format is human-verifiable; up/down SQL correctness is code review | Review each migration SQL file for correct syntax, FK types, and constraint names |
| schema.sql alignment | SCHEMA-01–11 | Must match final migration state; verified by reading both files | Compare migration output with updated schema.sql |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
