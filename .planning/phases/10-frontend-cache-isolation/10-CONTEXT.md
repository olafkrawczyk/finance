# Phase 10: Frontend Cache Isolation - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Client-side state never leaks data across user sessions. Introduce @tanstack/react-query as the caching layer, scope all query keys per-user, clear cache on auth changes, and display loading skeletons during re-fetch after user transition. All existing API functions preserved — wrapped by React Query hooks.

</domain>

<decisions>
## Implementation Decisions

### Caching Approach
- **D-01:** Install `@tanstack/react-query` — proper query key scoping, cache invalidation, and built-in loading states. Requirements explicitly reference React Query keys.
- **D-02:** `QueryClientProvider` wraps the entire app in `main.tsx` — both authenticated and unauthenticated portions.
- **D-03:** `staleTime: 30_000` (30 seconds) — balances caching benefit with data freshness. Auth change triggers `clear()` anyway.
- **D-04:** `refetchOnWindowFocus: true` — default React Query behavior. Auto-refetches when user returns to tab.

### Query Key Structure
- **D-05:** Nested pattern: `['user', userId, 'transactions', {filters}]` — clear hierarchy, easy to invalidate resource groups per user.
- **D-06:** Type-safe helper factory functions in `frontend/src/lib/query/queryKeys.ts` — single source of truth for all query keys.
- **D-07:** Custom `useUserId()` hook wrapping `authClient.useSession()` — returns current user ID. Used by all query hooks.
- **D-08:** Files organized in `frontend/src/lib/query/`:
  - `client.ts` — `QueryClient` setup with defaults
  - `queryKeys.ts` — Key factory with type-safe helpers
  - `provider.tsx` — `QueryClientProvider` + `CacheManager` component
  - `hooks.ts` — Custom React Query hooks wrapping `api.ts` functions

### Cache Clearance on Auth Change
- **D-09:** `queryClient.clear()` on both login AND logout — nuclear clear prevents any stale data leakage. User session state lives outside React Query (Better Auth hook), so clearing doesn't affect auth.
- **D-10:** Centralized `CacheManager` component inside `QueryClientProvider` — watches `authClient.useSession()` transitions (session goes null→exists or exists→null), calls `clear()`.
- **D-11:** Loading skeletons displayed during the re-fetch that follows cache clear (FRONTEND-03).

### Migration Strategy
- **D-12:** All-at-once conversion — create query keys, hooks, and update all pages in one pass. App has ~7 pages with similar data fetching patterns.
- **D-13:** Keep `api.ts` functions as-is — React Query hooks wrap them internally. Data layer unchanged, caching layer added on top. Preserves 401 redirect logic.
- **D-14:** WeeklyPage as the template pattern — most complex data fetching (3-way Promise.all + mutations). Other pages follow the same structure.
- **D-15:** Broad mutation invalidation: after any mutation, call `queryClient.invalidateQueries({ queryKey: ['user', userId] })`. Simple and safe for this app's data volume.

### Loading Skeletons
- **D-16:** Reusable `<Skeleton>` component — pulsing gray bar, configurable width/height/rounded. Single `@/components/Skeleton` export.
- **D-17:** Use React Query `isPending` for skeleton display (no data yet), `isFetching` for background refetch (keep existing data). Skeletons only on first load or after cache clear.
- **D-18:** Full-page skeleton layouts per route — skeleton table for MonthlyPage, skeleton cards for Dashboard, matching page structure.

### Folded Todos
- **auth-guard-and-redirect.md** — Already implemented in `App.tsx` (auth guard with loading spinner + LoginPage redirect). Folded as already done.
- **auth-login-signup-page.md** — Already implemented in `LoginPage.tsx` (email/password + Google OAuth). Folded as already done.
- **auth-logout-button.md** — Already implemented in `App.tsx` header ('Wyloguj' button). Folded as already done.
- **extract-llm-descriptions.md** — Already completed in Phase 7 (migration 011 + signup hook). Folded as already done.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` § FRONTEND-01 through FRONTEND-03 — Locked cache isolation requirements

### Frontend Source
- `frontend/src/api.ts` — All API fetch functions (to be wrapped by React Query hooks)
- `frontend/src/App.tsx` — Main app with auth guard, routing, logout handler
- `frontend/src/lib/auth-client.ts` — Better Auth client (useSession() hook)
- `frontend/src/pages/DashboardPage.tsx` — Complex data fetching (getMonthlySummary, getAssets, getInsightsForecast)
- `frontend/src/pages/MonthlyPage.tsx` — Most complex (3-way Promise.all + mutations) — template pattern
- `frontend/src/pages/SummaryPage.tsx` — Single query pattern
- `frontend/src/pages/InsightsPage.tsx` — Paginated queries with mutations
- `frontend/src/pages/LoginPage.tsx` — Auth page (login/logout triggers)
- `frontend/src/pages/AssetsPage.tsx` — CRUD queries
- `frontend/src/main.tsx` — App entry point (QueryClientProvider goes here)
- `frontend/src/components/InsightsWidget.tsx` — Polling pattern (example of existing skeleton usage)
- `frontend/vite.config.ts` — Vite config with API proxy

### Prior Phase Context
- `.planning/phases/09-testing-verification/09-CONTEXT.md` — Deferred auth-guard-and-redirect.md to Phase 10
- `.planning/phases/07-backend-scoping/07-CONTEXT.md` — D-05 (import scoping boundary), auth UI todos deferred
- `.planning/STATE.md` — "React Query key patterns need audit" noted during Phase 9

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `frontend/src/lib/auth-client.ts` — `authClient.useSession()` hook, provides `data.user.id` for query key scoping
- `frontend/src/api.ts` — All API functions ready to be wrapped (no changes needed)
- `frontend/src/components/InsightsWidget.tsx` — Existing skeleton placeholder pattern (pulsing gray bars)

### Established Patterns
- **Data fetching:** `useState`/`useEffect` + direct API calls (to be replaced with React Query hooks)
- **Auth:** Better Auth `useSession()` hook provides session/user data globally
- **Component structure:** Pages own their data fetching; no shared data hooks yet
- **Auth guard:** `App.tsx` checks `isPending` (spinner), then `!session` (LoginPage), then authenticated layout

### Integration Points
- `main.tsx` — Add `QueryClientProvider` wrapping `<App />`
- `App.tsx` — Add `CacheManager` component for auth transition cache clearing
- Each page — Replace `useState`/`useEffect` fetching with `useQuery`/`useMutation` hooks
- `frontend/src/lib/query/` — New directory for query infrastructure

</code_context>

<specifics>
## Specific Ideas

No specific references — standard React Query approach following established patterns.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

### Reviewed Todos (not folded)
- **dockerize-app.md** — Dockerize for homelab deployment. Already handled in Phase 5. Not related to Phase 10.
- **xlsx-library-dependency.md** — xlsx library dependency for Excel import. Not related to Phase 10.

</deferred>

---

*Phase: 10-Frontend Cache Isolation*
*Context gathered: 2026-06-08*
