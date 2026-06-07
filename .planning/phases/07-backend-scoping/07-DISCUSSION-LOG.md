# Phase 7: Backend Scoping - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 7-Backend Scoping
**Areas discussed:** Use-case signature pattern, Ownership validation approach, Lazy seeding mechanism, Reference data refactoring, Import scoping boundary

---

## Use-case Signature Pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Params object (insights style) | Consistent pattern: `createTransaction({ userId, accountId, ... })`. Easy to add/remove params without breaking callers. | ✓ |
| First positional arg | Simpler diff: `createTransaction(userId, input)`. Less nesting, but mixes scalar userId with object params. | |

**User's choice:** Params object (insights style)
**Notes:** Consistent with existing insights module pattern.

---

## Ownership Validation Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Implicit via SQL WHERE | Add `AND user_id = ${userId}` to every query. If the resource doesn't belong to the user, the query returns empty — 404 naturally. No separate validation step. | ✓ |
| Explicit helper in use-cases | Add a `validateOwnership(table, id, userId)` helper that throws if not found. Clear error messages, slightly more code. | |

**User's choice:** Implicit via SQL WHERE
**Notes:** Consistent with TEST-02 requiring 404 (not 403) for cross-user access.

---

## Lazy Seeding Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Signup hook | Use Better Auth's onSignUp hook instead of lazy seeding. Triggers exactly once, no check on every first request. | ✓ |
| In route handlers | Check + seed inside GET /categories and GET /accounts. Explicit, close to the access point, easy to trace. | |
| Dedicated middleware | A `maybeSeedDefaults` middleware applied to reference routes. Separation of concern, but adds indirection. | |

**User's choice:** Signup hook
**Notes:** Intentional pivot from prior "no signup hook" decision (STATE.md). User confirmed signup hook is preferred approach.

---

## Reference Data Refactoring

| Option | Description | Selected |
|--------|-------------|----------|
| New reference use-cases file | `src/core/reference/use-cases.ts` — clean separation, keeps reference data queries independent from ledger/transaction logic. | ✓ |
| Fold into existing modules | Add `listAccounts()` and `listCategories()` to `src/core/ledger/use-cases.ts` — they're closely related to transaction queries. | |

**User's choice:** New reference use-cases file

---

## Import Scoping Boundary (Phase 7 vs Phase 8)

| Option | Description | Selected |
|--------|-------------|----------|
| Tag job + PGMQ payload | Add user_id to import_jobs insert and pass it in PGMQ payload. Worker-side enforcement deferred to Phase 8. | ✓ |
| Only tag import_jobs | Add user_id column to import_jobs insert. Defer PGMQ payload changes and all worker enforcement to Phase 8. | |

**User's choice:** Tag job + PGMQ payload
**Notes:** Phase 7 scopes the enqueue side of the pipeline. Worker enforcement is Phase 8 work.

---

## Folded Todos

| Todo | Decision |
|------|----------|
| extract-llm-descriptions.md | Folded into Phase 7 scope. Requires migration for llm_description column, seed data population, and buildFewShotPrompt update. |

---

## Deferred Ideas

None — discussion stayed within phase scope.
