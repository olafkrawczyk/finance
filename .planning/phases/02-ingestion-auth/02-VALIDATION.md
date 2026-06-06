---
phase: 2
slug: ingestion-auth
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-06
updated: 2026-06-06
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bun test runner (built-in) |
| **Config file** | none — Wave 0 installs if needed |
| **Quick run command** | `bun test` |
| **Full suite command** | `bun test` |
| **Estimated runtime** | ~15 seconds |

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
| 2-01-01 | 02-01 | 1 | REQ-6 | T-2-01 / — | OAuth sessions are stateless and validated | integration | `bun test tests/auth.test.ts` | ❌ W0 | ⬜ pending |
| 2-01-02 | 02-01 | 1 | REQ-6 | T-2-02 / — | Auth middleware rejects unauthenticated requests | unit | `bun test tests/auth.test.ts` | ❌ W0 | ⬜ pending |
| 2-01-03 | 02-01 | 1 | REQ-6 | T-2-03 / — | Auth routes are mounted and return valid session | integration | `bun test tests/auth.test.ts` | ❌ W0 | ⬜ pending |
| 2-02-01 | 02-02 | 1 | REQ-4.1 | T-2-04 / — | Import schema created with import_jobs table | unit | `bun test tests/import-schemas.test.ts` | ❌ W0 | ⬜ pending |
| 2-02-02 | 02-02 | 1 | REQ-4.5 | T-2-05 / — | Import entities and schemas validate correctly | unit | `bun test tests/import-schemas.test.ts` | ❌ W0 | ⬜ pending |
| 2-02-03 | 02-02 | 1 | REQ-4.1 | T-2-06 / — | Import queue initialized and healthy | unit | `bun test tests/import-schemas.test.ts` | ❌ W0 | ⬜ pending |
| 2-03-01 | 02-03 | 2 | REQ-4.1 | T-2-07 / — | Import endpoint accepts valid CSV and returns job_id | integration | `bun test tests/import-api.test.ts` | ❌ W0 | ⬜ pending |
| 2-03-02 | 02-03 | 2 | REQ-4.1 | T-2-08 / — | Import endpoint validates account_id and returns 400 on invalid | unit | `bun test tests/import-api.test.ts` | ❌ W0 | ⬜ pending |
| 2-03-03 | 02-03 | 2 | REQ-4.5 | T-2-09 / — | Deduplication hash prevents duplicate inserts | unit | `bun test tests/import-dedup.test.ts` | ❌ W0 | ⬜ pending |
| 2-04-01 | 02-04 | 2 | REQ-4.2 | T-2-10 / — | PGMQ worker processes job and inserts transactions | integration | `bun test tests/import-worker.test.ts` | ❌ W0 | ⬜ pending |
| 2-04-02 | 02-04 | 2 | REQ-4.3-4.4 | T-2-11 / — | ING and IPKO parsers correctly extract transactions | unit | `bun test tests/import-parse.test.ts` | ❌ W0 | ⬜ pending |
| 2-04-03 | 02-04 | 2 | REQ-4.6 | T-2-12 / — | OpenRouter few-shot prompt returns valid JSON | integration | `bun test tests/import-llm.test.ts` | ❌ W0 | ⬜ pending |
| 2-05-01 | 02-05 | 3 | UI | T-2-13 / — | Frontend build succeeds with Vite + React + Tailwind | unit | `bun test tests/ui-build.test.ts` | ❌ W0 | ⬜ pending |
| 2-05-02 | 02-05 | 3 | UI | T-2-14 / — | ImportUpload component renders and submits form | unit | `bun test tests/ui-components.test.ts` | ❌ W0 | ⬜ pending |
| 2-05-03 | 02-05 | 3 | UI | T-2-15 / — | ImportStatus component polls and displays progress | unit | `bun test tests/ui-components.test.ts` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/` directory — test stubs for all requirements
- [ ] `tests/setup.ts` — shared test utilities and database cleanup
- [ ] `bun test` configured in package.json

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| OAuth flow with real providers | REQ-6 | Requires actual Google/GitHub credentials | 1. Configure OAuth apps in Google Cloud + GitHub 2. Run app and click "Sign in with Google" 3. Verify session cookie is set |
| OpenRouter API with real CSV | REQ-4.2 | Requires API key and costs tokens | 1. Set OPENROUTER_API_KEY 2. Upload ing.csv via UI 3. Verify transactions are created with correct categories |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-06
