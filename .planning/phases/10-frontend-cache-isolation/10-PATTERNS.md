# Phase 10: Frontend Cache Isolation - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 18 (6 new, 8 modified, 4 unmodified helpers)
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `frontend/src/lib/query/client.ts` | config | static | `frontend/src/lib/auth-client.ts` | role-match: both are lib config singletons |
| `frontend/src/lib/query/queryKeys.ts` | utility | static | `frontend/src/lib/insights.ts` | role-match: both export pure functions |
| `frontend/src/lib/query/provider.tsx` | provider/component | event-driven | `frontend/src/components/DismissConfirmDialog.tsx` | partial: component export pattern + React hooks |
| `frontend/src/lib/query/hooks.ts` | hooks | CRUD | `frontend/src/lib/insights.ts` | role-match: both export utility functions |
| `frontend/src/components/Skeleton.tsx` | component | static (UI) | `frontend/src/components/ProgressBar.tsx` | exact: same role + data flow (simple presentational) |
| `frontend/src/main.tsx` | entry/config | static | existing file (self) | exact: minor modification, add wrapper |
| `frontend/src/App.tsx` | app shell | request-response | existing file (self) | exact: add CacheManager component |
| `frontend/src/pages/DashboardPage.tsx` | page | CRUD | existing file (self) | exact: convert useState/useEffect to React Query |
| `frontend/src/pages/MonthlyPage.tsx` | page | CRUD | existing file (self) | exact: template pattern, 3-way Promise.all + mutations |
| `frontend/src/pages/SummaryPage.tsx` | page | CRUD | existing file (self) | exact: single query pattern |
| `frontend/src/pages/InsightsPage.tsx` | page | CRUD | existing file (self) | exact: paginated queries + mutations |
| `frontend/src/pages/AssetsPage.tsx` | page | CRUD | existing file (self) | exact: CRUD queries |
| `frontend/src/components/InsightsWidget.tsx` | component | CRUD + polling | existing file (self) | exact: convert setInterval → refetchInterval |

## Pattern Assignments

### `frontend/src/lib/query/client.ts` (config, static)

**Analog:** `frontend/src/lib/auth-client.ts` (lines 1-3)

**Imports pattern** (lines 1-2):
```typescript
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient();
```

**Analog pattern — follows same singleton export convention:**
```typescript
// frontend/src/lib/auth-client.ts (full file)
// Pattern: single-export singleton from a library init
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient();
```

**Target pattern** (from RESEARCH.md lines 365-381):
```typescript
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

**Key difference:** `client.ts` exports a singleton `QueryClient` instance with custom defaults — same pattern as `auth-client.ts` which exports a singleton `authClient`.

---

### `frontend/src/lib/query/queryKeys.ts` (utility, static)

**Analog:** `frontend/src/lib/insights.ts` (lines 1-69)

**Imports/Exports pattern** (lines 1, 28, 41):
```typescript
// Pure utility functions, no side effects, named exports
export function formatRelativeTime(createdAt: string): string { ... }
export function getPriorityColor(priority: 'high' | 'medium' | 'low'): { dot: string; text: string } { ... }
export function getTypeLabel(type: 'alert' | 'tip' | 'trend' | 'forecast'): string { ... }
```

**Target pattern** (from RESEARCH.md lines 176-241):
```typescript
// Full file — type-safe query key factory, all keys scoped to ['user', userId]
export const queryKeys = {
  user: (userId: string) => ['user', userId] as const,

  transactions: {
    all: (userId: string) => ['user', userId, 'transactions'] as const,
    list: (userId: string, filters?: Record<string, unknown>) =>
      ['user', userId, 'transactions', { ...filters }] as const,
    detail: (userId: string, id: string) =>
      ['user', userId, 'transactions', id] as const,
  },

  categories: {
    all: (userId: string) => ['user', userId, 'categories'] as const,
  },

  accounts: {
    all: (userId: string) => ['user', userId, 'accounts'] as const,
  },

  assets: {
    all: (userId: string) => ['user', userId, 'assets'] as const,
  },

  summary: {
    all: (userId: string) => ['user', userId, 'summary'] as const,
    monthly: (userId: string, year: number, month: number) =>
      ['user', userId, 'summary', { year, month }] as const,
  },

  openingBalance: {
    byMonth: (userId: string, year: number, month: number) =>
      ['user', userId, 'openingBalance', { year, month }] as const,
  },

  insights: {
    all: (userId: string) => ['user', userId, 'insights'] as const,
    list: (userId: string, filters?: Record<string, unknown>) =>
      ['user', userId, 'insights', { ...filters }] as const,
    forecast: (userId: string) => ['user', userId, 'insights', 'forecast'] as const,
  },

  importStatus: (userId: string, jobId: string) =>
    ['user', userId, 'imports', jobId] as const,

  migration: {
    status: (userId: string, jobId: string) =>
      ['user', userId, 'migration', jobId] as const,
  },
};
```

---

### `frontend/src/lib/query/provider.tsx` (provider/component, event-driven)

**Analog:** `frontend/src/components/DismissConfirmDialog.tsx` (lines 1-47)

**Imports/Export pattern** (lines 1-10):
```typescript
import React from 'react';

interface DismissConfirmDialogProps {
  isOpen: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  insightTitle: string;
}

export default function DismissConfirmDialog({ isOpen, onConfirm, onCancel, insightTitle }: DismissConfirmDialogProps) {
```

**Target pattern — CacheManager + QueryProvider** (from RESEARCH.md lines 255-287):
```typescript
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

**Key pattern to copy:** The `useEffect` + `useRef` pattern for detecting session transitions without infinite loops. The `prevSessionRef` stores previous session value, and comparison is by object reference (session objects from Better Auth are stable).

---

### `frontend/src/lib/query/hooks.ts` (hooks, CRUD)

**Analog:** `frontend/src/lib/insights.ts` (lines 1-69) - pure function export convention

**Target pattern — Full hooks file** (from RESEARCH.md lines 394-523):

```typescript
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
```

**Core pattern — every hook has:**
1. `useUserId()` to get the current user ID
2. Query key from `queryKeys` factory with `userId!`
3. `enabled: !!userId` to prevent fetches without a user session
4. `queryFn` wrapping the existing `api.ts` function untouched

**Mutation pattern — every mutation has:**
1. `useUserId()` for broad invalidation
2. `onSuccess: () => queryClient.invalidateQueries({ queryKey: ['user', userId] })` — D-15 pattern

---

### `frontend/src/components/Skeleton.tsx` (component, static/UI)

**Analog:** `frontend/src/components/ProgressBar.tsx` (lines 1-29)

**Imports/Export pattern** (lines 1, 3, 8):
```typescript
import React from 'react';

interface ProgressBarProps {
  percent: number;
  details?: string;
}

export default function ProgressBar({ percent, details }: ProgressBarProps) {
```

**Target pattern — Skeleton component** (from RESEARCH.md lines 527-541):
```typescript
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

**Key patterns from ProgressBar analog:**
- Single `interface Props` inline before component
- `export default function` naming convention (matches all existing components)
- Tailwind classes for styling (same stack)

---

### `frontend/src/main.tsx` (entry, static)

**Analog:** existing file (self) — lines 1-10

**Current pattern** (lines 1-10):
```typescript
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

**Target modification:** Wrap `<App />` with `QueryProvider`:
```typescript
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import { QueryProvider } from './lib/query/provider';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryProvider>
      <App />
    </QueryProvider>
  </React.StrictMode>
);
```

---

### `frontend/src/App.tsx` (app shell, request-response)

**Analog:** existing file (self) — lines 1-246

**Current imports/pattern** (lines 1-14):
```typescript
import React, { useState, useEffect } from 'react';
import ImportUpload from './components/ImportUpload';
import ImportStatus from './components/ImportStatus';
import DashboardPage from './pages/DashboardPage';
// ... other page imports ...
import { authClient } from './lib/auth-client';
import LoginPage from './pages/LoginPage';
```

**Target modification:** Add `CacheManager` inside the authenticated layout (it watches auth transitions). The `CacheManager` component is already inside `QueryProvider` (which wraps the whole app in `main.tsx`), so no import is needed in `App.tsx` — it renders as a sibling inside `QueryProvider` and doesn't need to be added to `App.tsx` at all.

Actually, re-reading D-10: "Centralized CacheManager component inside QueryClientProvider — watches authClient.useSession() transitions, calls clear()." — The CacheManager is rendered inside `QueryProvider`, not inside `App.tsx`. So `App.tsx` doesn't need modification for CacheManager.

But the logout button in `App.tsx` (line 224) calls `authClient.signOut()` — this triggers the session change that `CacheManager` watches. No modification needed.

**No modification to App.tsx required for CacheManager.** The CacheManager lives in provider.tsx inside QueryProvider.

---

### `frontend/src/pages/MonthlyPage.tsx` (page, CRUD — TEMPLATE PATTERN)

**Analog:** existing file (self) — lines 1-434

**Current useState/useEffect data fetching pattern** (lines 78-207):
```typescript
import React, { useState, useEffect, useMemo } from 'react';
import { getTransactions, getOpeningBalance, getCategories, deleteTransaction } from '../api';

// State declarations
const [transactions, setTransactions] = useState<NormalizedTransaction[] | null>(null);
const [sidebarData, setSidebarData] = useState<{...} | null>(null);
const [error, setError] = useState<string | null>(null);
const [loading, setLoading] = useState(true);

// Data fetching in useEffect
useEffect(() => {
  setLoading(true);
  setError(null);

  Promise.all([
    getTransactions({ date_from: dateFrom, date_to: dateTo, per_page: 500 }),
    getOpeningBalance(year, month),
    getCategories(),
  ])
    .then(([txResult, openingBalances, categories]) => {
      // ... complex normalization and computation ...
      setTransactions(normalizedTx);
      setSidebarData({ ... });
      setLoading(false);
    })
    .catch((err) => {
      setError(err.message || 'Failed to load data ...');
      setLoading(false);
    });
}, [yearMonth]);

// Loading state
if (loading) {
  return (
    <div className="flex flex-col items-center justify-center py-20">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
      <p className="text-slate-400 mt-4 text-sm">Ładowanie szczegółów miesiąca...</p>
    </div>
  );
}
```

**Target pattern — React Query version:**
```typescript
import React, { useMemo } from 'react';
import { useTransactionsList, useOpeningBalance, useCategories, useDeleteTransaction } from '../lib/query/hooks';
// ... keep existing filter/sort utility functions, TransactionTable, MonthSidebar ...

export default function MonthlyPage({ yearMonth }: MonthlyPageProps) {
  // Query hooks — replaces useState/useEffect
  const { data: txResult, isPending: txLoading } = useTransactionsList({
    date_from: dateFrom,
    date_to: dateTo,
    per_page: 500,
  });
  const { data: openingBalances, isPending: obLoading } = useOpeningBalance(year, month);
  const { data: categories, isPending: catLoading } = useCategories();
  const deleteMutation = useDeleteTransaction();

  const isPending = txLoading || obLoading || catLoading;

  // Compute derived state from query data (no manual setState)
  const transactions = useMemo(() => {
    if (!txResult?.data || !categories) return null;
    // ... same normalization logic, but as pure computation ...
  }, [txResult, categories]);

  // ... same filter/sort logic ...

  const handleDelete = async (id: string) => {
    deleteMutation.mutate(id);
  };

  // Skeleton loading (D-16, D-18)
  if (isPending) {
    return (
      <div className="max-w-6xl mx-auto w-full px-4 space-y-6" aria-busy="true">
        <div className="space-y-2">
          <Skeleton className="h-8 w-64" />
          <Skeleton className="h-4 w-48" />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-10 w-full rounded-lg" />
          ))}
        </div>
        <Skeleton className="h-10 w-full rounded-lg" />
        {[1, 2, 3, 4, 5, 6].map((i) => (
          <Skeleton key={i} className="h-12 w-full rounded-lg" />
        ))}
      </div>
    );
  }

  // Error state stays the same pattern
  if (!transactions) {
    return (
      <div className="max-w-lg mx-auto p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
        Failed to load data — check connection and try again.
      </div>
    );
  }

  // ... rest of render (same, but without manual error/loading state management)
}
```

**Key conversion patterns:**
1. Replace `useState` + `useEffect` + `Promise.all` → individual `useQuery` hooks (one per API call)
2. Remove `setLoading`/`setError`/`setData` — React Query manages these
3. Derived state (sidebar data, filtered transactions) → `useMemo` (pure computation from query data)
4. Mutations → `useMutation` with `onSuccess: () => queryClient.invalidateQueries(...)`
5. Loading spinner → skeleton layout (matching page structure, D-18)
6. Error → read from `error` property of each query hook

---

### `frontend/src/pages/DashboardPage.tsx` (page, CRUD)

**Analog:** existing file (self) — lines 1-303

**Current useState/useEffect pattern** (lines 17-138):
```typescript
// Three separate useEffects for three API calls
const [data, setData] = useState<NormalizedSummaryRow[] | null>(null);
const [error, setError] = useState<string | null>(null);
const [loading, setLoading] = useState(true);
const [aiForecast, setAiForecast] = useState<... | null>(null);
const [assets, setAssets] = useState<...>([]);

useEffect(() => {
  getMonthlySummary()
    .then((rows) => { setData(normalized); setLoading(false); })
    .catch((err) => { setError(err.message); setLoading(false); });
}, []);

useEffect(() => {
  getAssets()
    .then((rows) => { setAssets(parsed); })
    .catch((err) => { console.error(...); });
}, []);

useEffect(() => {
  if (!data) return;
  getInsightsForecast()
    .then((insights) => { setAiForecast(...); })
    .catch((err) => { console.warn(...); setAiForecast(null); });
}, [data]);
```

**Target pattern — React Query version:**
```typescript
import { useMonthlySummary, useAssets, useInsightsForecast } from '../lib/query/hooks';

export default function DashboardPage({ onMonthClick, onAssetsClick }: DashboardPageProps) {
  const { data, isPending: summaryLoading } = useMonthlySummary();
  const { data: assetsData } = useAssets();
  const { data: forecastData } = useInsightsForecast();

  // Derived state: normalize summary data via useMemo
  const normalizedData = useMemo(() => {
    if (!data) return null;
    return data.map((r: any) => ({...})).reverse();
  }, [data]);

  // Derived state: assets normalization
  const assets = useMemo(() => {
    return (assetsData ?? []).map((a: any) => ({...}));
  }, [assetsData]);

  // Derived state: AI forecast computation
  const aiForecast = useMemo(() => {
    if (!normalizedData || !forecastData) return null;
    // ... same computation from current useEffect ...
  }, [normalizedData, forecastData]);

  if (summaryLoading) {
    return (
      <div className="space-y-6 max-w-6xl mx-auto w-full px-4" aria-busy="true">
        <div className="space-y-2">
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-4 w-64" />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Skeleton className="h-40 rounded-2xl" />
          <Skeleton className="h-40 rounded-2xl" />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Skeleton className="h-80 rounded-2xl" />
          <Skeleton className="h-80 rounded-2xl" />
          <Skeleton className="h-80 rounded-2xl" />
          <Skeleton className="h-80 rounded-2xl" />
        </div>
      </div>
    );
  }

  // ... rest of render stays the same ...
}
```

**Key conversion pattern:** The three separate `useEffect`s become three parallel `useQuery` hooks. Derived state (forecast computation, asset normalization) moves to `useMemo`. The `aiForecast` computation that depends on `data` is naturally handled by `useMemo` with `data` in its dependency array.

---

### `frontend/src/pages/SummaryPage.tsx` (page, CRUD — single query)

**Analog:** existing file (self) — lines 1-63

**Current pattern** (lines 6-29):
```typescript
const [data, setData] = useState<NormalizedSummaryRow[] | null>(null);
const [error, setError] = useState<string | null>(null);
const [loading, setLoading] = useState(true);

useEffect(() => {
  getMonthlySummary()
    .then((rows) => {
      const normalized = rows.map((r: any) => ({...}));
      setData(normalized);
      setLoading(false);
    })
    .catch((err) => {
      setError(err.message || 'Nie udało się załadować danych podsumowania');
      setLoading(false);
    });
}, []);
```

**Target pattern:**
```typescript
import { useMonthlySummary } from '../lib/query/hooks';
import { Skeleton } from '../components/Skeleton';

export default function SummaryPage() {
  const { data, isPending, error } = useMonthlySummary();

  const normalizedData = useMemo(() => {
    if (!data) return null;
    return data.map((r: any) => ({...}));
  }, [data]);

  if (isPending) {
    return (
      <div className="space-y-6 max-w-6xl mx-auto w-full px-4">
        <div className="space-y-2">
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-4 w-64" />
        </div>
        <Skeleton className="h-96 w-full rounded-2xl" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-lg mx-auto p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
        {error.message}
      </div>
    );
  }

  // ... rest same ...
}
```

**Simplest conversion** — single `useQuery` replacing a single `useEffect` + `useState`.

---

### `frontend/src/pages/InsightsPage.tsx` (page, CRUD — paginated)

**Analog:** existing file (self) — lines 1-242

**Current pattern** (lines 21-78):
```typescript
const [insights, setInsights] = useState<Insight[]>([]);
const [loading, setLoading] = useState(true);
const [error, setError] = useState<string | null>(null);
const [page, setPage] = useState(1);
const [totalCount, setTotalCount] = useState(0);
const [counts, setCounts] = useState<Record<string, number>>({});

const fetchInsightsList = () => {
  setLoading(true);
  getInsights({ type: ..., page, per_page: perPage })
    .then((res) => {
      setInsights(res.data || []);
      setTotalCount(res.meta?.total || 0);
      setError(null);
      setLoading(false);
    })
    .catch((err) => { setError(...); setLoading(false); });
};

const fetchCounts = () => {
  getInsights({ dismissed: false, per_page: 100 })
    .then((res) => { setCounts(newCounts); });
};

useEffect(() => { fetchInsightsList(); }, [activeType, page]);
useEffect(() => { fetchCounts(); }, []);

// Mutation handlers
const handleConfirmDismiss = () => {
  dismissInsight(targetId)
    .then(() => {
      setInsights(prev => prev.filter(i => i.id !== targetId));
      setDismissTarget(null);
      fetchCounts();
    });
};

const handleGenerate = () => {
  setGenerating(true);
  generateInsights()
    .then(() => {
      setTimeout(() => {
        fetchInsightsList();
        fetchCounts();
      }, 3000);
    });
};
```

**Target pattern:**
```typescript
import { useInsightsList, useDismissInsight, useGenerateInsights } from '../lib/query/hooks';
import { queryClient } from '../lib/query/client';

export default function InsightsPage() {
  const [activeType, setActiveType] = useState<'all' | ...>('all');
  const [page, setPage] = useState(1);

  // Query with page/type as key dependencies
  const { data, isPending, error } = useInsightsList({
    type: activeType !== 'all' ? activeType : undefined,
    dismissed: false,
    page,
    per_page: 20,
  });

  const insights = data?.data ?? [];
  const totalCount = data?.meta?.total ?? 0;

  // Mutations
  const dismissMutation = useMutation({
    mutationFn: (id: string) => api.dismissInsight(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });

  const generateMutation = useMutation({
    mutationFn: () => api.generateInsights(),
    onSuccess: () => {
      setSuccessMsg('...');
      setTimeout(() => {
        setSuccessMsg(null);
        queryClient.invalidateQueries({ queryKey: ['user', userId] });
      }, 3000);
    },
  });

  // Pagination handler
  const handleTypeChange = (type: ...) => {
    setActiveType(type);
    setPage(1);
  };

  // ... render stays mostly the same, loading = isPending ...
}
```

**Key conversion pattern for pagination:** The `activeType` and `page` state variables become part of the query key implicitly (passed as filter params to `useInsightsList`). When they change, `useQuery` automatically re-fetches. The manual `fetchInsightsList`/`fetchCounts` patterns are eliminated.

---

### `frontend/src/pages/AssetsPage.tsx` (page, CRUD)

**Analog:** existing file (self) — lines 1-346

**Current pattern** (lines 27-48, 50-80, 96-126, 128-143):
```typescript
// Fetch
const fetchAssets = () => {
  setLoading(true);
  getAssets()
    .then((data) => { setAssets(parsed); setLoading(false); })
    .catch((err) => { setError(...); setLoading(false); });
};
useEffect(() => { fetchAssets(); }, []);

// Create
const handleAddAsset = async (e) => {
  e.preventDefault();
  const created = await createAsset({ name, value });
  setAssets((prev) => [...prev, { id: created.id, ... }]);
};

// Update
const handleSaveEdit = async (id) => {
  const updated = await updateAsset(id, { name, value });
  setAssets((prev) => prev.map((a) => a.id === id ? updated : a));
};

// Delete
const handleDeleteAsset = async (id) => {
  await deleteAsset(id);
  setAssets((prev) => prev.filter((a) => a.id !== id));
};
```

**Target pattern:**
```typescript
export default function AssetsPage() {
  const { data: assetsData, isPending } = useAssets();
  const createMutation = useCreateAsset();    // wraps api.createAsset + invalidation
  const updateMutation = useUpdateAsset();    // wraps api.updateAsset + invalidation
  const deleteMutation = useDeleteAsset();    // wraps api.deleteAsset + invalidation

  // Optimistic removal on delete (invalidation handles refetch)
  // Mutations invalidate on success, so manual state updates are eliminated

  // Form state stays the same (local to the page, not cached)
  const [newName, setNewName] = useState<string>('');
  const [newValue, setNewValue] = useState<string>('');

  if (isPending) {
    return (
      <div className="space-y-6 max-w-6xl mx-auto w-full px-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-4 w-48" />
        <Skeleton className="h-96 w-full rounded-2xl" />
      </div>
    );
  }

  // Remove manual setAssets updates — React Query invalidations handle it
}
```

**Key conversion pattern for CRUD:** Mutations no longer need to manually update `assets` state. The D-15 broad invalidation (`queryClient.invalidateQueries({ queryKey: ['user', userId] })`) automatically triggers refetch of all queries. This is simpler and safer than manual array manipulation.

---

### `frontend/src/components/InsightsWidget.tsx` (component, CRUD + polling)

**Analog:** existing file (self) — lines 1-148

**Current pattern** (lines 16-41):
```typescript
const [insights, setInsights] = useState<Insight[]>([]);
const [loading, setLoading] = useState<boolean>(true);
const [error, setError] = useState<string | null>(null);

const fetchLatestInsights = () => {
  getInsights({ per_page: 3, dismissed: false })
    .then((res) => {
      setInsights(res.data || []);
      setError(null);
      setLoading(false);
    })
    .catch((err) => {
      console.error('Failed to fetch latest insights for widget:', err);
      setError(err.message || '...');
      setLoading(false);
    });
};

useEffect(() => {
  fetchLatestInsights();
  const intervalId = setInterval(fetchLatestInsights, 60000);
  return () => clearInterval(intervalId);
}, []);
```

**Target pattern — React Query with refetchInterval:**
```typescript
export default function InsightsWidget() {
  const { data, isPending, error } = useInsightsList({
    per_page: 3,
    dismissed: false,
  }, {
    refetchInterval: 60000,  // Poll every 60 seconds — replaces setInterval
  });

  const insights = data?.data ?? [];

  // Loading/skeleton stays similar (using Skeleton component or inline skeleton)
  if (isPending) {
    return (... skeleton layout ...);
  }

  if (error) {
    return (... error state ...);
  }

  // ... rest of render same ...
}
```

**Key conversion pattern:** `setInterval(fetchLatestInsights, 60000)` → `refetchInterval: 60000` as a query option. React Query handles interval cleanup automatically.

---

## Shared Patterns

### Query Key Scoping with User ID
**Source:** `frontend/src/lib/query/queryKeys.ts` (RESEARCH.md lines 176-241)
**Apply to:** All query hooks in `hooks.ts`, all pages using `useQuery`
```typescript
// Every query key MUST start with ['user', userId]
// Factory pattern ensures consistency
export const queryKeys = {
  user: (userId: string) => ['user', userId] as const,
  transactions: {
    list: (userId: string, filters?) => ['user', userId, 'transactions', { ...filters }] as const,
  },
  // ...
};
```

### CacheManager — Auth Transition Cache Clear
**Source:** `frontend/src/lib/query/provider.tsx` (RESEARCH.md lines 255-287)
**Apply to:** `main.tsx` (QueryProvider wraps the app)
```typescript
export function CacheManager() {
  const { data: session } = authClient.useSession();
  const prevSessionRef = useRef(session);

  useEffect(() => {
    const prev = prevSessionRef.current;
    const curr = session;
    if ((!prev && curr) || (prev && !curr)) {
      queryClient.clear();
    }
    prevSessionRef.current = curr;
  }, [session]);

  return null;
}
```

### Mutation Invalidation Pattern
**Source:** `frontend/src/lib/query/hooks.ts` (RESEARCH.md lines 491-523)
**Apply to:** All mutation hooks
```typescript
export function useDeleteTransaction() {
  const userId = useUserId();
  return useMutation({
    mutationFn: (id: string) => api.deleteTransaction(id),
    onSuccess: () => {
      // Broad invalidation — refetches ALL queries for this user
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}
```

### Skeleton Loading States
**Source:** `frontend/src/components/Skeleton.tsx` (RESEARCH.md lines 527-541)
**Apply to:** All pages in their `isPending` state
```typescript
export default function Skeleton({ className = 'h-4 w-full' }: SkeletonProps) {
  return (
    <div
      className={`animate-pulse bg-slate-800/50 rounded-lg ${className}`}
      aria-hidden="true"
    />
  );
}
```

### useUserId Hook
**Source:** `frontend/src/lib/query/provider.tsx` (RESEARCH.md lines 388-392)
**Apply to:** All hooks in `hooks.ts` that need user-scoped keys
```typescript
export function useUserId(): string | undefined {
  const { data: session } = authClient.useSession();
  return session?.user?.id;
}
```

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `frontend/src/lib/query/client.ts` | config | static | No existing QueryClient equivalent in project |
| `frontend/src/lib/query/queryKeys.ts` | utility | static | No existing query key factory pattern |
| `frontend/src/lib/query/provider.tsx` | provider/component | event-driven | No existing React Query provider or auth-change watcher |
| `frontend/src/lib/query/hooks.ts` | hooks | CRUD | No existing custom hooks wrapping API calls |

All new files have RESEARCH.md patterns that serve as the target blueprint.

---

## Metadata

**Analog search scope:** `frontend/src/` (pages, components, lib)
**Files scanned:** 18 (9 pages, 12 components, 3 lib files)
**Pattern extraction date:** 2026-06-08

### Import Convention Notes
- All existing files use **relative imports** (e.g., `'../api'`, `'../../api'`), no `@/` path alias
- Components use `export default function ComponentName`
- Lib utilities use named `export function`
- New `lib/query/` files should follow relative import convention: `'../../api'` for hooks.ts, `'../auth-client'` for provider.tsx

### Existing Error/UI Pattern Notes
- All pages share a consistent error display: `<div className="max-w-lg mx-auto p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">`
- All pages share a consistent loading display (to be replaced by skeleton): centered spinner + text
- Empty states use centered cards with heading + description
- Buttons use gradient styles: `bg-gradient-to-r from-blue-600 to-indigo-600`
