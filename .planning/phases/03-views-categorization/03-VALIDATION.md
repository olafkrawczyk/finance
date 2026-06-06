---
phase: 03
slug: views-categorization
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-06
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None detected (vitest planned for Wave 0) |
| **Config file** | none — Wave 0 installs |
| **Quick run command** | `npx tsc --noEmit` (type-check frontend) |
| **Full suite command** | none configured |
| **Estimated runtime** | ~5 seconds (type-check) |

---

## Sampling Rate

- **After every task commit:** Run `npx tsc --noEmit`
- **After every plan wave:** Manual smoke test — render each page, verify API calls succeed
- **Before `/gsd-verify-work`:** Import `ing.csv` + `ipko.csv`, categorize, verify Zbiorczy numbers match a known month from `budget.xlsx`
- **Max feedback latency:** 5 seconds (type-check)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-TBD | TBD | TBD | REQ-3.1 | — | N/A | manual / smoke | N/A | ❌ W0 | ⬜ pending |
| 03-TBD | TBD | TBD | REQ-3.2 | — | N/A | manual / smoke | N/A | ❌ W0 | ⬜ pending |
| 03-TBD | TBD | TBD | REQ-3.3 | — | N/A | manual / smoke | N/A | ❌ W0 | ⬜ pending |
| 03-TBD | TBD | TBD | REQ-2.3 | V5-01 | Category-input validation on PATCH endpoint | integration | N/A (needs test setup) | ❌ W0 | ⬜ pending |
| 03-TBD | TBD | TBD | REQ-5.1 | V5-02 | Zod validation on POST /transactions | integration | N/A (needs test setup) | ❌ W0 | ⬜ pending |
| 03-TBD | TBD | TBD | D-08 | — | N/A | manual | N/A | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `frontend/src/__tests__/` — test directory setup
- [ ] `frontend/vitest.config.ts` — vitest configuration
- [ ] `frontend/src/lib/__tests__/linearRegression.test.ts` — unit tests for regression math
- [ ] `npm install vitest @testing-library/react @testing-library/jest-dom` — test framework install
- [ ] API normalization functions tests — string-to-number conversion

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zbiorczy table renders with correct formatting | REQ-3.1 | Visual layout requires human judgment | Navigate to /zbiorczy, verify 7 columns, check data against budget.xlsx |
| Monthly view sidebar computes correct breakdowns | REQ-3.2 | Requires real transaction data comparison | Navigate to /month/YYYY-MM, verify income sources and fixed costs match manual calculation |
| Dashboard renders 4 charts with data from API | REQ-3.3 | Visual chart rendering requires human judgment | Navigate to /dashboard, verify 4 charts render, tooltips work, click drill-down works |
| Responsive layout on mobile | D-08 | Responsive behavior requires human judgment | Open app in iPhone viewport, verify tables scroll horizontally, charts stack vertically |
| Phase gate: Zbiorczy matches budget.xlsx | ROADMAP | End-to-end data integrity verification | Import ing.csv + ipko.csv, categorize all transactions, verify Zbiorczy numbers for a known month match budget.xlsx |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
