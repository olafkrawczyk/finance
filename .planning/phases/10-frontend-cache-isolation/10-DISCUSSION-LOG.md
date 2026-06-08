# Phase 10: Frontend Cache Isolation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 10-Frontend Cache Isolation
**Areas discussed:** Caching approach, Query key structure, Cache clearance on auth change, Migration strategy, Loading skeleton standard

---

## Caching Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Install React Query | Proper query key scoping, cache invalidation, built-in loading/error states. Requirements reference React Query keys. | ✓ |
| Lightweight custom context | Simple React context + Map-based cache. Zero new deps. | |

**User's choice:** Install React Query
**Notes:** None

---

## Query Key Structure

**Sub-question 1 — Key pattern:**

| Option | Description | Selected |
|--------|-------------|----------|
| Nested by resource + user | `['user', userId, 'transactions', {filters}]` — clear hierarchy, easy to invalidate by resource | ✓ |
| Flat with userId prefix | `[userId, 'transactions', filters]` — simpler but no hierarchy | |

**User's choice:** Nested by resource + user

**Sub-question 2 — Key definition:**

| Option | Description | Selected |
|--------|-------------|----------|
| Helper functions with TS strictness | `queryKeys.transactions.list(userId, filters)` — single source of truth, type-safe | ✓ |
| Inline in each component | `['user', user.id, 'transactions', ...]` — simpler but harder to audit | |

**User's choice:** Helper functions with TS strictness

**Sub-question 3 — User ID source:**

| Option | Description | Selected |
|--------|-------------|----------|
| Custom useUserId() hook | Wraps authClient.useSession(), passed explicitly to hooks | ✓ |
| React Query context | Put userId on query meta or context | |

**User's choice:** Custom useUserId() hook

**Sub-question 4 — File structure:**

| Option | Description | Selected |
|--------|-------------|----------|
| frontend/src/lib/query/ | Dedicated directory: queryKeys.ts, hooks.ts, client.ts | ✓ |
| Extend api.ts | Add key helpers alongside existing fetch functions | |

**User's choice:** frontend/src/lib/query/

---

## Cache Clearance on Auth Change

**Sub-question 1 — Clear method:**

| Option | Description | Selected |
|--------|-------------|----------|
| queryClient.clear() | Nuclear — wipes everything. Simplest, safest. Session state outside React Query. | ✓ |
| queryClient.removeQueries with prefix | Surgical — only user-scoped keys. More complex. | |

**User's choice:** queryClient.clear()

**Sub-question 2 — When to clear:**

| Option | Description | Selected |
|--------|-------------|----------|
| Both login AND logout | Safest — matches FRONTEND-02 | ✓ |
| Logout only | Simpler but misses tab-switching | |

**User's choice:** Both login AND logout

**Sub-question 3 — Mechanism:**

| Option | Description | Selected |
|--------|-------------|----------|
| React Query provider hook + effect | CacheManager watches session transitions, calls clear() centrally | ✓ |
| Manual calls at each auth action | Scattered across components, error-prone | |

**User's choice:** React Query provider hook + effect

**Sub-question 4 — Auth transition UX:**

| Option | Description | Selected |
|--------|-------------|----------|
| Loading skeletons | FRONTEND-03 compliance. Shows skeleton state during refetch. | ✓ |
| No special UI | Components show natural loading. May flash empty states. | |

**User's choice:** Loading skeletons

---

## Migration Strategy

**Sub-question 1 — Approach:**

| Option | Description | Selected |
|--------|-------------|----------|
| All-at-once conversion | Convert all pages in one pass. Consistent, manageable scope. | ✓ |
| Incremental per-page | Lower risk per plan but extends phase duration. | |

**User's choice:** All-at-once conversion

**Sub-question 2 — API layer:**

| Option | Description | Selected |
|--------|-------------|----------|
| Wrap api.ts functions | Keep api.ts as-is. Hooks call api.ts internally. | ✓ |
| Replace api.ts with inline fetch | Move fetch into hooks, remove api.ts. More churn. | |

**User's choice:** Wrap api.ts functions

**Sub-question 3 — Template page:**

| Option | Description | Selected |
|--------|-------------|----------|
| MonthlyPage | Most complex — 3-way Promise.all + mutations. Best pattern template. | ✓ |
| DashboardPage | Has derived data. Good showcase but less complex. | |
| SummaryPage | Simplest — single query. Too simple to be representative. | |

**User's choice:** MonthlyPage

**Sub-question 4 — Mutation invalidation:**

| Option | Description | Selected |
|--------|-------------|----------|
| Invalidate all user-scoped queries | `invalidateQueries(['user', userId])` after any mutation. Simple, safe. | ✓ |
| Targeted per-resource | More precise but more maintenance. | |

**User's choice:** Invalidate all user-scoped queries

---

## Loading Skeleton Standard

**Sub-question 1 — Skeleton approach:**

| Option | Description | Selected |
|--------|-------------|----------|
| Reusable Skeleton component | Shared `<Skeleton />` — configurable, consistent across pages | ✓ |
| Keep per-page custom skeletons | Flexible but inconsistent | |

**User's choice:** Reusable Skeleton component

**Sub-question 2 — Loading states:**

| Option | Description | Selected |
|--------|-------------|----------|
| isPending for initial, isFetching for refetch | Skeletons on first load or after cache clear only | ✓ |
| Show skeletons on both | More conservative but more flicker | |

**User's choice:** isPending for initial, isFetching for refetch

**Sub-question 3 — Auth transition layout:**

| Option | Description | Selected |
|--------|-------------|----------|
| Full-page skeleton per route | Table skeletons for Monthly, card skeletons for Dashboard | ✓ |
| Simple centered spinner | Reuse existing pattern. Simpler but less polished. | |

**User's choice:** Full-page skeleton per route

---

## the agent's Discretion

None — all decisions explicitly captured.

## Deferred Ideas

None — discussion stayed within phase scope.
