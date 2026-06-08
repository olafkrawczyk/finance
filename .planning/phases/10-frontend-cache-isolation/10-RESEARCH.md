# Phase 10: Frontend Cache Isolation - Research

**Researched:** 2026-06-08
**Domain:** Frontend client-side state management, cache isolation, React Query
**Confidence:** HIGH

## Summary

This phase introduces `@tanstack/react-query` v5.101.0 as the data-fetching and caching layer for all authenticated pages in a single-user-per-session financial planning app. All 7 data-fetching pages currently use `useState`/`useEffect` + direct `api.ts` calls — these are replaced by React Query hooks with per-user cache scoping via user ID prefix in query keys.

The core pattern: a `CacheManager` component watches Better Auth's `useSession()` hook for login/logout transitions and calls `queryClient.clear()` to wipe stale data. After clear, React Query's `isPending` goes `true` on all active queries, triggering skeleton layouts instead of the current spinner+text pattern. A reusable `<Skeleton>` component provides pulsing gray bars for loading states.

**Primary recommendation:** Use `@tanstack/react-query` v5.101.0 with query key factory pattern (`['user', userId, 'resource', {filters}]`), `QueryClient` defaults of `staleTime: 30_000` and `refetchOnWindowFocus: true`, and a centralized `CacheManager` component for auth-change cache clearing.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Caching Approach
- **D-01:** Install `@tanstack/react-query` — proper query key scoping, cache invalidation, and built-in loading states.
- **D-02:** `QueryClientProvider` wraps the entire app in `main.tsx` — both authenticated and unauthenticated portions.
- **D-03:** `staleTime: 30_000` (30 seconds) — balances caching benefit with data freshness. Auth change triggers `clear()` anyway.
- **D-04:** `refetchOnWindowFocus: true` — default React Query behavior.

#### Query Key Structure
- **D-05:** Nested pattern: `['user', userId, 'transactions', {filters}]` — clear hierarchy, easy to invalidate resource groups per user.
- **D-06:** Type-safe helper factory functions in `frontend/src/lib/query/queryKeys.ts` — single source of truth.
- **D-07:** Custom `useUserId()` hook wrapping `authClient.useSession()` — returns current user ID. Used by all query hooks.
- **D-08:** Files organized in `frontend/src/lib/query/`:
  - `client.ts` — `QueryClient` setup with defaults
  - `queryKeys.ts` — Key factory with type-safe helpers
  - `provider.tsx` — `QueryClientProvider` + `CacheManager` component
  - `hooks.ts` — Custom React Query hooks wrapping `api.ts` functions

#### Cache Clearance on Auth Change
- **D-09:** `queryClient.clear()` on both login AND logout — nuclear clear prevents any stale data leakage.
- **D-10:** Centralized `CacheManager` component inside `QueryClientProvider` — watches `authClient.useSession()` transitions, calls `clear()`.
- **D-11:** Loading skeletons displayed during the re-fetch that follows cache clear (FRONTEND-03).

#### Migration Strategy
- **D-12:** All-at-once conversion — create query keys, hooks, and update all pages in one pass.
- **D-13:** Keep `api.ts` functions as-is — React Query hooks wrap them internally.
- **D-14:** WeeklyPage as the template pattern — most complex data fetching (3-way Promise.all + mutations).
- **D-15:** Broad mutation invalidation: after any mutation, call `queryClient.invalidateQueries({ queryKey: ['user', userId] })`.

#### Loading Skeletons
- **D-16:** Reusable `<Skeleton>` component — pulsing gray bar, configurable width/height/rounded.
- **D-17:** Use React Query `isPending` for skeleton display (no data yet), `isFetching` for background refetch (keep existing data).
- **D-18:** Full-page skeleton layouts per route — skeleton table for MonthlyPage, skeleton cards for Dashboard, matching page structure.

### the agent's Discretion
None specified beyond the agent's Discretion default — all decisions locked.

### Deferred Ideas (OUT OF SCOPE)
- dockerize-app.md — Already handled in Phase 5.
- xlsx-library-dependency.md — Not related to Phase 10.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FRONTEND-01 | React Query keys prefixed with `user.id` — per-user cache separation | Query key factory pattern D-05/D-06 in `queryKeys.ts`; `useUserId()` hook D-07 ensures every key starts with `['user', userId]` |
| FRONTEND-02 | Query cache cleared on login/logout — no stale data flashes across sessions | `CacheManager` component D-10 calls `queryClient.clear()` on auth transitions; D-09 confirms nuclear clear approach |
| FRONTEND-03 | Loading skeletons displayed during re-fetch to prevent brief cross-user data display | Reusable `<Skeleton>` D-16; `isPending` gating D-17 ensures skeletons show after cache clear; per-route skeleton layouts D-18 |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Query key scoping with user ID | Browser / Client | — | All query keys are constructed client-side using `useUserId()` hook reading session data |
| Cache clearing on auth change | Browser / Client | — | `CacheManager` component lives in the browser, watches session transitions, calls `queryClient.clear()` |
| Data fetching (wrapped API calls) | Browser / Client | — | React Query hooks wrap existing `api.ts` functions — no backend changes |
| Skeleton loading display | Browser / Client | — | Skeleton components render on `isPending` — purely client-side UX |
| Mutation invalidation | Browser / Client | — | Post-mutation `invalidateQueries` is client-side; backend already returns 200 on success |
| Auth session state | Browser / Client | API / Backend | Session managed by Better Auth — client reads `useSession()`, backend validates via middleware |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @tanstack/react-query | 5.101.0 | Server-state cache, query key isolation, loading state management | Industry standard for React data fetching; built-in cache invalidation, deduplication, and stale-while-revalidate [VERIFIED: npm registry] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| better-auth/react | ^1.6.14 | Session hook (`useSession()`) for user ID extraction | Already in project — provides `data.user.id` for query key scoping and login/logout detection |
| react | ^19.2.7 | UI framework for hooks and components | Already in project — React Query hooks integrate via `useQuery`/`useMutation` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @tanstack/react-query | SWR (by Vercel) | SWR has simpler API but weaker cache invalidation — no built-in mutation integration, less mature devtools. React Query wins for mutation-heavy CRUD apps |
| @tanstack/react-query | RTK Query (Redux Toolkit) | Adds Redux dependency — fat bundle when project has no Redux. React Query is lighter (Hono/Better Auth stack, no Redux in app) |
| @tanstack/react-query | Zustand + manual cache | Would need to hand-roll cache invalidation, dedup, stale management. Precisely the "Don't Hand-Roll" category |

**Installation:**
```bash
npm install @tanstack/react-query@^5.101.0
```

**Version verification:** @tanstack/react-query 5.101.0 published 2026-06-02, React 19 peer dependency confirmed (`^18 || ^19`).

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| @tanstack/react-query | npm | ~4 yrs | ~15M/week | github.com/TanStack/query | [OK] | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** None
**Packages flagged as suspicious [SUS]:** None

## Architecture Patterns

### System Architecture Diagram

```
User opens app
     |
     v
main.tsx <QueryClientProvider>
     |
     +---> CacheManager (inside provider)
     |        |
     |        +---> Watches authClient.useSession()
     |        +---> null → session (login): calls queryClient.clear()
     |        +---> session → null (logout): calls queryClient.clear()
     |
     v
App.tsx (routes)
     |
     +---> Each page component:
     |        |
     |        +---> Gets userId from useUserId() hook
     |        +---> Builds query key via queryKeys.ts factory
     |        +---> Calls custom hook from hooks.ts
     |        |        |
     |        |        +---> Wraps api.ts function
     |        |        +---> Attaches queryKey from factory
     |        |
     |        +---> Renders based on status:
     |                 ├── isPending → skeleton layout
     |                 ├── isError → error card
     |                 └── success → data + content
     |
     v
Mutations (post/create/update/delete)
     |
     +---> On success: invalidateQueries({ queryKey: ['user', userId] })
     +---> Triggers background refetch of all user queries
     +---> Existing data visible during refetch (isFetching, not isPending)
```

### Recommended Project Structure
```
frontend/src/lib/query/
├── client.ts         # QueryClient creation with defaults
├── queryKeys.ts      # Type-safe query key factory functions
├── provider.tsx      # QueryClientProvider + CacheManager component
└── hooks.ts          # Custom useQuery/useMutation hooks wrapping api.ts

frontend/src/components/
└── Skeleton.tsx      # Reusable pulsing gray bar component
```

### Pattern 1: Query Key Factory (D-05, D-06)

**What:** Type-safe factory for building nested query keys with automatic user ID prefixing. Ensures every key starts with `['user', userId]` without manual repetition.

**When to use:** Every custom query hook needs its key from this factory — single source of truth for invalidation matching.

**Example:**
```typescript
// frontend/src/lib/query/queryKeys.ts
// Source: Adapted from CONTEXT.md D-05, D-06 — verified pattern from @tanstack/react-query docs

import { useUserId } from './hooks';

export const queryKeys = {
  // Base user scope — used for broad invalidation (D-15)
  user: (userId: string) => ['user', userId] as const,

  // Transaction resources
  transactions: {
    all: (userId: string) => ['user', userId, 'transactions'] as const,
    list: (userId: string, filters?: Record<string, unknown>) =>
      ['user', userId, 'transactions', { ...filters }] as const,
    detail: (userId: string, id: string) =>
      ['user', userId, 'transactions', id] as const,
  },

  // Category resources
  categories: {
    all: (userId: string) => ['user', userId, 'categories'] as const,
  },

  // Account resources
  accounts: {
    all: (userId: string) => ['user', userId, 'accounts'] as const,
  },

  // Asset resources
  assets: {
    all: (userId: string) => ['user', userId, 'assets'] as const,
  },

  // Monthly summary
  summary: {
    all: (userId: string) => ['user', userId, 'summary'] as const,
    monthly: (userId: string, year: number, month: number) =>
      ['user', userId, 'summary', { year, month }] as const,
  },

  // Opening balance
  openingBalance: {
    byMonth: (userId: string, year: number, month: number) =>
      ['user', userId, 'openingBalance', { year, month }] as const,
  },

  // Insights
  insights: {
    all: (userId: string) => ['user', userId, 'insights'] as const,
    list: (userId: string, filters?: Record<string, unknown>) =>
      ['user', userId, 'insights', { ...filters }] as const,
    forecast: (userId: string) => ['user', userId, 'insights', 'forecast'] as const,
  },

  // Import status
  importStatus: (userId: string, jobId: string) =>
    ['user', userId, 'imports', jobId] as const,

  // Migration
  migration: {
    status: (userId: string, jobId: string) =>
      ['user', userId, 'migration', jobId] as const,
  },
};
```

### Pattern 2: Cache Manager on Auth Change (D-09, D-10)

**What:** A component that watches `authClient.useSession()` transitions and calls `queryClient.clear()` on login/logout. Renders nothing — purely a side-effect component.

**When to use:** Placed inside `QueryClientProvider` so it has access to `queryClient` via `useQueryClient()`.

**Example:**
```typescript
// frontend/src/lib/query/provider.tsx
// Source: CONTEXT.md D-09, D-10 — nuclear clear pattern verified from @tanstack/react-query docs

import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import { useEffect, useRef } from 'react';
import { authClient } from '../auth-client';
import { queryClient } from './client';

export function CacheManager() {
  const { data: session } = authClient.useSession();
  const prevSessionRef = useRef(session);

  useEffect(() => {
    const prev = prevSessionRef.current;
    const curr = session;

    // Detect transition: null→session (login) OR session→null (logout)
    if ((!prev && curr) || (prev && !curr)) {
      queryClient.clear();
    }

    prevSessionRef.current = curr;
  }, [session]);

  return null; // No visual output
}

export function QueryProvider({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <CacheManager />
      {children}
    </QueryClientProvider>
  );
}
```

### Pattern 3: Mutation Invalidation (D-15)

**What:** After any successful mutation (create/update/delete), invalidate all queries for the current user by invalidating the prefix `['user', userId]`. This triggers background refetch of all active queries without blocking the UI.

**When to use:** Inside the `onSuccess` callback of every `useMutation` call.

**Example:**
```typescript
// Source: CONTEXT.md D-15 — broad invalidation pattern

const deleteAssetMutation = useMutation({
  mutationFn: (id: string) => api.deleteAsset(id),
  onSuccess: () => {
    // Invalidate ALL queries for this user — broad but safe for app's data volume
    queryClient.invalidateQueries({ queryKey: ['user', userId] });
  },
});
```

### Anti-Patterns to Avoid

- **Hardcoding `isLoading` instead of `isPending`:** In React Query v5, `isLoading` is deprecated (alias for `isFetching && isPending`). Always use `isPending` for initial/no-data-yet state and `isFetching` for background refetch.
- **Mixing query key patterns:** Some keys starting with `['user', userId, ...]` and others with just `['transactions']` defeats cache isolation. Enforce the pattern via the factory — never construct query keys manually.
- **Calling `queryClient.clear()` inside component render:** Must be inside `useEffect` with proper dependency tracking to avoid infinite loops.
- **Optimistic updates without rollback:** Not in scope for this phase, but worth avoiding if tempted — broad invalidation (D-15) is simpler and safer.
- **Using `queryClient.removeQueries()` instead of `clear()`:** `removeQueries` only removes inactive queries; `clear()` nukes everything including active ones which is the safer choice for auth transitions.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Data fetching with loading states | `useState` + `useEffect` + loading flag | `useQuery` from @tanstack/react-query | 50+ edge cases handled (dedup, retry, stale detection, race conditions, memory leak prevention) |
| Cache invalidation on mutation | Manual state update after mutation | `queryClient.invalidateQueries()` | Automatic background refetch, no stale data, no manual reconciliation |
| Per-user cache scoping | Manual localStorage/IndexedDB per-user | React Query query keys with user ID prefix | Built-in deterministic hashing, structural sharing, garbage collection |
| Skeleton/pulse animation | Custom CSS animation | Tailwind `animate-pulse` | Already bundled in project — no extra CSS, consistent timing |
| Login/logout cache wipe | Manual state reset per component | `queryClient.clear()` | One call clears everything — mutation cache, query cache, background refetches all cancelled |

**Key insight:** React Query is purpose-built for the exact problems this phase solves (per-user cache isolation, auth-change clearance, loading states). Hand-rolling any of these introduces subtle bugs that React Query's maintainers have already solved.

## Common Pitfalls

### Pitfall 1: Query Key Collision Across Users
**What goes wrong:** Two users on the same browser (sequential logins) share cache entries because query keys don't include user ID.
**Why it happens:** Without user ID prefix, User B sees User A's cached data after login.
**How to avoid:** Factory function (D-06) enforces `['user', userId, ...]` prefix on every key — never construct keys manually.
**Warning signs:** After clearing cache and switching user, old data appears momentarily before refetch completes (flash of stale data — this is exactly FRONTEND-02/03 addressed by cache clear + skeleton).

### Pitfall 2: Skeleton Flash on Fast Networks
**What goes wrong:** Data loads in <100ms but skeleton flashes anyway — jarring UX.
**Why it happens:** React Query `isPending` goes `true` on mount, stays `true` until data arrives. On fast connections, this is a visible flash.
**How to avoid:** Set `staleTime: 30_000` (D-03) — on mount, if data exists in cache and isn't stale, `isPending` stays `false` and cached data shows immediately. Auth change `clear()` empties cache deliberately, making skeleton on re-fetch correct behavior (FRONTEND-03).
**Warning signs:** Users complain about "flickering" on page navigation.

### Pitfall 3: CacheManager Effect Loop
**What goes wrong:** `CacheManager` calls `clear()` on every render because `useEffect` dependency is wrong — causes infinite clear → re-fetch → clear cycle.
**Why it happens:** `useEffect` fires on every render if `session` object reference changes (Better Auth creates new object).
**How to avoid:** Use `useRef` to track previous session value (see Pattern 2). Compare by `session?.user?.id` string equality, not object reference. The pattern in D-10 using `authClient.useSession()` and ref comparison is correct.
**Warning signs:** Infinite loading spinners, console showing constant refetch cycles.

### Pitfall 4: `clear()` Interfering with Auth State
**What goes wrong:** `queryClient.clear()` wipes the mutation cache, which might hold in-progress auth mutations.
**Why it happens:** `clear()` nukes everything — query cache AND mutation cache.
**How to avoid:** Auth state is managed by Better Auth `useSession()` — lives outside React Query. `clear()` doesn't affect Better Auth's internal state, only cached server responses (D-09 confirms this is safe). Verified by official docs: `clear()` clears all connected caches (queries and mutations) but does not affect external state.
**Warning signs:** Auth session seems to reset after `clear()` — means auth is leaking into React Query (shouldn't happen with Better Auth separation).

### Pitfall 5: Stale `api.ts` 401 Redirect and React Query Error Retry Conflict
**What goes wrong:** A 401 from expired session triggers React Query's automatic retry (3 attempts with backoff) while `api.ts` calls `redirectToLogin()` on 401.
**Why it happens:** `api.ts`'s 401 redirect runs on the first request, redirecting user before React Query retries. The retry then fails with a different error (page changed).
**How to avoid:** The `api.ts` redirectToLogin is preserved (D-13). React Query's default `retry: 3` with exponential backoff is fine — the first 401 already redirects, subsequent retries are harmless (user already redirected). No change needed.
**Warning signs:** Console shows "Session expired — redirecting to login" errors during normal use (only expected when session actually expires).

## Code Examples

Verified patterns from official sources:

### QueryClient Default Setup
```typescript
// frontend/src/lib/query/client.ts
// Source: @tanstack/react-query docs — QueryClient configuration

import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,          // D-03: 30 second freshness window
      refetchOnWindowFocus: true,  // D-04: auto-refetch on tab return
      retry: 3,                    // Default: 3 retries with exponential backoff
      retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 10000),
    },
  },
});
```

### useUserId Hook Setup
```typescript
// frontend/src/lib/query/provider.tsx (inline or as separate hook)
// Source: CONTEXT.md D-07

export function useUserId(): string | undefined {
  const { data: session } = authClient.useSession();
  return session?.user?.id;
}
```

### Custom Hook Wrapping api.ts (MonthlyPage template pattern)
```typescript
// frontend/src/lib/query/hooks.ts (excerpt)
// Source: CONTEXT.md D-14 — MonthlyPage as template pattern
//           @tanstack/react-query docs verified — useQuery/useMutation patterns

import { useQuery, useMutation } from '@tanstack/react-query';
import * as api from '../../api';
import { queryKeys } from './queryKeys';
import { useUserId } from './provider';
import { queryClient } from './client';

// ---- Queries ----

export function useTransactionsList(filters?: Record<string, unknown>) {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.transactions.list(userId!, filters),
    queryFn: () => api.getTransactions(filters as any),
    enabled: !!userId,  // Only fetch when user ID is available
  });
}

export function useMonthlySummary() {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.summary.all(userId!),
    queryFn: () => api.getMonthlySummary(),
    enabled: !!userId,
  });
}

export function useOpeningBalance(year: number, month: number) {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.openingBalance.byMonth(userId!, year, month),
    queryFn: () => api.getOpeningBalance(year, month),
    enabled: !!userId,
  });
}

export function useCategories() {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.categories.all(userId!),
    queryFn: () => api.getCategories(),
    enabled: !!userId,
  });
}

export function useAssets() {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.assets.all(userId!),
    queryFn: () => api.getAssets(),
    enabled: !!userId,
  });
}

export function useInsightsList(filters?: Record<string, unknown>) {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.insights.list(userId!, filters),
    queryFn: () => api.getInsights(filters as any),
    enabled: !!userId,
  });
}

export function useInsightsForecast() {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.insights.forecast(userId!),
    queryFn: () => api.getInsightsForecast(),
    enabled: !!userId,
  });
}

export function useImportStatus(jobId: string) {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.importStatus(userId!, jobId),
    queryFn: () => api.getImportStatus(jobId),
    enabled: !!userId && !!jobId,
  });
}

export function useMigrationStatus(jobId: string) {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.migration.status(userId!, jobId),
    queryFn: () => api.getMigrationStatus(jobId),
    enabled: !!userId && !!jobId,
  });
}

// ---- Mutations (with D-15 broad invalidation) ----

export function useDeleteTransaction() {
  const userId = useUserId();
  return useMutation({
    mutationFn: (id: string) => api.deleteTransaction(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}

export function useCreateTransaction() {
  const userId = useUserId();
  return useMutation({
    mutationFn: (data: Parameters<typeof api.createTransaction>[0]) => api.createTransaction(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}

export function useUpdateTransaction() {
  const userId = useUserId();
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Parameters<typeof api.updateTransaction>[1] }) =>
      api.updateTransaction(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}

// (Additional mutations follow same pattern: assignCategory, createAsset, updateAsset, deleteAsset, dismissInsight, generateInsights)
```

### Skeleton Component (D-16)
```typescript
// frontend/src/components/Skeleton.tsx
// Source: CONTEXT.md D-16 — plus Tailwind v4 animate-pulse verified in codebase

interface SkeletonProps {
  className?: string;
}

export default function Skeleton({ className = 'h-4 w-full' }: SkeletonProps) {
  return (
    <div
      className={`animate-pulse bg-slate-800/50 rounded-lg ${className}`}
      aria-hidden="true"
    />
  );
}
```

### MonthlyPage Skeleton Layout (D-18)
```tsx
// Inside MonthlyPage when isPending
if (isPending) {
  return (
    <div className="max-w-6xl mx-auto w-full px-4 space-y-6" aria-busy="true">
      {/* Title skeleton */}
      <div className="space-y-2">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-4 w-48" />
      </div>
      {/* Filter bar skeleton */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {[1, 2, 3, 4].map((i) => (
          <Skeleton key={i} className="h-10 w-full rounded-lg" />
        ))}
      </div>
      {/* Table header */}
      <Skeleton className="h-10 w-full rounded-lg" />
      {/* Table rows */}
      {[1, 2, 3, 4, 5, 6].map((i) => (
        <Skeleton key={i} className="h-12 w-full rounded-lg" />
      ))}
    </div>
  );
}
```

### DashboardPage Skeleton Layout (D-18)
```tsx
// Inside DashboardPage when isPending
if (isPending) {
  return (
    <div className="space-y-6 max-w-6xl mx-auto w-full px-4" aria-busy="true">
      {/* Title */}
      <div className="space-y-2">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-4 w-64" />
      </div>
      {/* Summary cards row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Skeleton className="h-40 rounded-2xl" />
        <Skeleton className="h-40 rounded-2xl" />
      </div>
      {/* Charts grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Skeleton className="h-80 rounded-2xl" />
        <Skeleton className="h-80 rounded-2xl" />
        <Skeleton className="h-80 rounded-2xl" />
        <Skeleton className="h-80 rounded-2xl" />
      </div>
    </div>
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| useState/useEffect + direct api.ts calls | React Query hooks with cache isolation | Phase 10 | Per-user cache separation, automatic refetch, skeleton loading states, cache clear on auth change |
| Spinner + text loading states | Structural skeleton layouts matching page geometry | Phase 10 | Better perceived performance, no content reflow, no stale data flash |
| Manual state updates after mutations | Broad query invalidation via invalidateQueries | Phase 10 | No manual reconciliation, automatic refetch of all related data |

**Deprecated/outdated:**
- **`isLoading` status field**: Deprecated in React Query v5 — use `isPending` for initial loading, `isFetching` for background refetches, and `isRefetching` for `isFetching && !isPending`.
- **`removeQueries()` for cache clearing**: Not suitable for auth change — use `clear()` which nukes both query and mutation caches.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `authClient.useSession()` returns `session` with `user.id` immediately after login (before first render) | Standard Stack / useUserId | If session is stale during render, query keys will lack userId or have wrong userId — but `enabled: !!userId` prevents premature fetches |
| A2 | `queryClient.clear()` does not interrupt or redirect the auth flow | Common Pitfalls Pitfall 4 | If Better Auth stores session state in a format React Query can reach, clearing might cause auth loop — but Better Auth doesn't use React Query |
| A3 | All pages can be converted in one pass without breaking existing functionality | Migration Strategy / D-12 | If a page has complex side-effect-based data flows (e.g., polling in InsightsWidget), re-architecting to hooks may need extra work |
| A4 | Vite/React 19 with @tanstack/react-query v5 has no compatibility issues | Standard Stack | Package verification shows `^18 || ^19` peer dep — confirmed compatible |
| A5 | No stale data flash occurs between `clear()` and skeleton render — they happen in the same render cycle | Code Examples / CacheManager | React Query's `isPending` goes `true` on next render after `clear()` — if there's an intermediate render, users briefly see empty/old data |

## Open Questions

1. **InsightsWidget polling pattern** — currently uses `setInterval(fetchLatestInsights, 60000)` for polling. Should this be converted to `refetchInterval: 60000` in React Query?
   - What we know: InsightsWidget polls every 60s for latest 3 insights. React Query supports `refetchInterval` natively.
   - What's unclear: Whether conversion is worth the effort (only 1 polling instance) or keep polling via `api.ts` call + React Query manual cache update.
   - Recommendation: Convert to `refetchInterval` for consistency — it's a trivial change and removes the manual interval management.

2. **Dependent query timing in DashboardPage** — `getAssets()` and `getInsightsForecast()` depend on `getMonthlySummary()` data (`data` is a dependency for forecast calculation).
   - What we know: Current code runs `getMonthlySummary` in one useEffect, then `getAssets` and `getInsightsForecast` in separate effects. The forecast computation depends on the summary data being available.
   - What's unclear: Should forecast computation be a `select` transformation on the summary query, or a separate derived state? Assets fetch is independent.
   - Recommendation: Keep both `getAssets` and `getInsightsForecast` as separate parallel queries (no dependency between them and monthly summary at query level — only the forecast calculation uses summary data as derived state, not as query dependency).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Runtime | ✓ | 22.22.2 | — |
| npm | Package mgmt | ✓ | 10.9.7 | — |
| @tanstack/react-query | Cache layer | ✓ (to be installed) | 5.101.0 | — |

**Missing dependencies with no fallback:** None — all dependencies identified are npm packages to install.

## Validation Architecture

> `workflow.nyquist_validation` not set in config.json — defaults to enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected in project |
| Config file | None |
| Quick run command | N/A |
| Full suite command | N/A |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FRONTEND-01 | React Query keys include user.id prefix | Manual / Code review | N/A — verify by inspection | ❌ No test infra |
| FRONTEND-02 | Cache cleared on login/logout | Manual / Browser test | N/A — verify by browser DevTools | ❌ No test infra |
| FRONTEND-03 | Skeletons shown during re-fetch | Manual / Browser test | N/A — verify by visual inspection | ❌ No test infra |

### Sampling Rate
No sampling — no test infrastructure exists.

### Wave 0 Gaps
- [ ] `frontend/vitest.config.ts` — test framework config (nonexistent, project has no tests)
- [ ] `frontend/src/lib/__tests__/queryKeys.test.ts` — would verify user ID prefix in query keys
- [ ] `frontend/src/lib/__tests__/CacheManager.test.ts` — would verify clear on auth transitions

*(No existing test infrastructure — validation is manual for this phase. Adding unit tests for queryKeys.ts and CacheManager is recommended but not required.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Auth is managed by Better Auth — React Query has no auth responsibilities |
| V3 Session Management | No | Session managed by Better Auth cookies — React Query cache layer doesn't handle sessions |
| V4 Access Control | No | Access control is backend-scoped (Phase 7/8) — frontend cache isolation prevents cross-user data display, not a replacement for backend authorization |
| V5 Input Validation | No | React Query wraps existing `api.ts` functions — input validation unchanged |
| V6 Cryptography | No | No crypto involved in cache layer |

**Security impact analysis:** This phase introduces no new attack surface. Cache isolation is a correct-by-construction UX concern — the security guarantee (cross-user data isolation) is enforced at the backend layer (Phase 7/8). The frontend cache isolation prevents *visual* data leakage across sessions, which is a UX/compliance issue, not an authentication bypass.

### Known Threat Patterns for {stack}
None — React Query cache layer operates entirely in the browser and handles only already-authorized data.

## Sources

### Primary (HIGH confidence)
- [VERIFIED: npm registry] — @tanstack/react-query v5.101.0, published 2026-06-02, React 19 peer dependency confirmed
- [VERIFIED: npm registry] — Better Auth react package, version from `package.json` = ^1.6.14
- [CITED: tanstack.com/query/latest/docs/framework/react/guides/query-keys] — Query key structure, deterministic hashing, variables in keys
- [CITED: tanstack.com/query/latest/docs/framework/react/guides/query-invalidation] — `invalidateQueries` and `clear()` API verified
- [CITED: tanstack.com/query/latest/docs/framework/react/guides/background-fetching-indicators] — `isPending` vs `isFetching` distinctions verified
- [CITED: github.com/TanStack/query/blob/main/docs/reference/QueryClient.md] — `queryClient.clear()` API reference
- [CONFIRMED: codebase scan] — Current `useState`/`useEffect` patterns in all 7 data-fetching pages

### Secondary (MEDIUM confidence)
- [CITED: CONTEXT.md] — D-01 through D-18 locked decisions
- [CITED: 10-UI-SPEC.md] — Skeleton component spec, color tokens, spacing scale, interaction contract
- [CITED: tkdodo.eu/blog/effective-react-query-keys] — Community best practice for query key organization in large apps

### Tertiary (LOW confidence)
- None — all claims verified against codebase scan, npm registry, official docs, or CONTEXT.md

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — @tanstack/react-query version verified on npm, peer dependencies confirmed, React 19 compatible
- Architecture: HIGH — Query key factory, CacheManager, skeleton patterns all follow locked decisions and official docs
- Pitfalls: MEDIUM — CacheManager effect loop and stale flash timing are real concerns, documented with mitigations based on established React Query knowledge

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (stable packages — React Query is well-established)
