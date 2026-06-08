import { useQuery, useMutation } from '@tanstack/react-query';
import * as api from '../../api';
import { queryKeys } from './queryKeys';
import { useUserId } from './provider';
import { queryClient } from './client';

export function useTransactionsList(filters?: Record<string, unknown>) {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.transactions.list(userId!, filters),
    queryFn: () => api.getTransactions(filters as any),
    enabled: !!userId,
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

export function useAccounts() {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.accounts.all(userId!),
    queryFn: () => api.getAccounts(),
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

export function useInsightsList(filters?: Record<string, unknown>, options?: Record<string, unknown>) {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.insights.list(userId!, filters),
    queryFn: () => api.getInsights(filters as any),
    enabled: !!userId,
    ...options,
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

export function useTransactionDetail(id: string) {
  const userId = useUserId();
  return useQuery({
    queryKey: queryKeys.transactions.detail(userId!, id),
    queryFn: () => api.getTransaction(id),
    enabled: !!userId && !!id,
  });
}

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

export function useAssignCategory() {
  const userId = useUserId();
  return useMutation({
    mutationFn: ({ transactionId, categoryId }: { transactionId: string; categoryId: string }) =>
      api.assignCategory(transactionId, categoryId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}

export function useCreateAsset() {
  const userId = useUserId();
  return useMutation({
    mutationFn: (data: Parameters<typeof api.createAsset>[0]) => api.createAsset(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}

export function useUpdateAsset() {
  const userId = useUserId();
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Parameters<typeof api.updateAsset>[1] }) =>
      api.updateAsset(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}

export function useDeleteAsset() {
  const userId = useUserId();
  return useMutation({
    mutationFn: (id: string) => api.deleteAsset(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}

export function useDismissInsight() {
  const userId = useUserId();
  return useMutation({
    mutationFn: (insightId: string) => api.dismissInsight(insightId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}

export function useGenerateInsights() {
  const userId = useUserId();
  return useMutation({
    mutationFn: () => api.generateInsights(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });
}
