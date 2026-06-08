import React, { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { useInsightsList } from '../lib/query/hooks';
import { queryClient } from '../lib/query/client';
import { useUserId } from '../lib/query/provider';
import Skeleton from '../components/Skeleton';
import * as api from '../api';
import InsightCard from '../components/InsightCard';
import InsightsTabs from '../components/InsightsTabs';
import DismissConfirmDialog from '../components/DismissConfirmDialog';

interface Insight {
  id: string;
  user_id: string;
  type: 'alert' | 'tip' | 'trend' | 'forecast';
  priority: 'high' | 'medium' | 'low';
  title: string;
  content: string;
  dismissed: boolean;
  created_at: string;
  linked_transaction_ids?: string[];
  linked_category_ids?: string[];
}

export default function InsightsPage() {
  const [activeType, setActiveType] = useState<'all' | 'alert' | 'trend' | 'tip' | 'forecast'>('all');
  const [page, setPage] = useState(1);
  const [dismissTarget, setDismissTarget] = useState<{ id: string; title: string } | null>(null);
  const [generating, setGenerating] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const perPage = 20;

  const { data, isPending, error } = useInsightsList({
    type: activeType !== 'all' ? activeType : undefined,
    dismissed: false,
    page,
    per_page: perPage,
  });

  const insights = data?.data ?? [];
  const totalCount = data?.meta?.total ?? 0;

  const userId = useUserId();

  const dismissMutation = useMutation({
    mutationFn: (id: string) => api.dismissInsight(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });

  const generateMutation = useMutation({
    mutationFn: () => api.generateInsights(),
    onSuccess: () => {
      setSuccessMsg('Zgłoszenie wysłane. Analizowanie Twoich finansów...');
      setTimeout(() => {
        setGenerating(false);
        setSuccessMsg(null);
        setPage(1);
        queryClient.invalidateQueries({ queryKey: ['user', userId] });
      }, 3000);
    },
    onError: (err: any) => {
      console.error('Failed to generate insights:', err);
      setGenerating(false);
    },
  });

  const handleTypeChange = (type: 'all' | 'alert' | 'trend' | 'tip' | 'forecast') => {
    setActiveType(type);
    setPage(1);
  };

  const handleDismissClick = (id: string) => {
    const target = insights.find(i => i.id === id);
    if (target) {
      setDismissTarget({ id, title: target.title });
    }
  };

  const handleConfirmDismiss = () => {
    if (!dismissTarget) return;
    dismissMutation.mutate(dismissTarget.id, {
      onSuccess: () => {
        setDismissTarget(null);
      },
      onError: () => {
        alert('Nie udało się odrzucić wskazówki');
        setDismissTarget(null);
      },
    });
  };

  const handleGenerate = () => {
    setGenerating(true);
    generateMutation.mutate();
  };

  const totalPages = Math.ceil(totalCount / perPage);

  return (
    <div className="max-w-6xl mx-auto space-y-6 w-full px-4">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold text-slate-100">Analizy</h2>
          <p className="text-slate-400 text-sm">Analiza finansowa wspierana przez AI</p>
        </div>

        <div>
          <button
            onClick={handleGenerate}
            disabled={generating}
            className={`font-bold rounded-xl px-6 py-3 transition-colors flex items-center gap-2 shadow-lg cursor-pointer ${
              generating
                ? 'bg-slate-800 text-slate-500 opacity-60 cursor-not-allowed'
                : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white'
            }`}
          >
            {generating ? (
              <>
                <svg className="animate-spin h-5 w-5 text-slate-500" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Analizowanie Twoich finansów...
              </>
            ) : (
              'Generuj analizy'
            )}
          </button>
        </div>
      </div>

      {successMsg && (
        <div className="bg-emerald-950/20 border border-emerald-900/30 rounded-xl p-4 text-emerald-400 text-sm">
          {successMsg}
        </div>
      )}

      {error && (
        <div className="bg-red-950/50 border border-red-800 rounded-lg p-4 text-red-300 text-sm">
          {error.message}
        </div>
      )}

      <InsightsTabs activeType={activeType} onTypeChange={handleTypeChange} counts={{}} />

      {isPending ? (
        <div className="space-y-4" aria-busy="true">
          <div className="flex gap-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <Skeleton key={i} className="h-8 w-24 rounded-lg" />
            ))}
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {[1, 2].map((i) => (
              <Skeleton key={i} className="h-48 w-full rounded-2xl" />
            ))}
          </div>
        </div>
      ) : insights.length === 0 ? (
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-8 text-center max-w-lg mx-auto">
          <h3 className="text-lg font-semibold text-slate-300">Brak analiz</h3>
          <p className="text-slate-500 text-sm mt-2">
            Analizy finansowe są generowane automatycznie w nocy na podstawie historii transakcji. Zaimportuj transakcje, aby rozpocząć, lub wygeneruj analizy teraz.
          </p>
          <button
            onClick={handleGenerate}
            disabled={generating}
            className="mt-6 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-bold rounded-xl px-6 py-3 transition-colors shadow-lg cursor-pointer"
          >
            Generuj analizy
          </button>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {insights.map((insight: Insight) => (
              <InsightCard
                key={insight.id}
                insight={insight}
                onDismiss={handleDismissClick}
              />
            ))}
          </div>

          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-4 pt-6">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-4 py-2 rounded-lg text-sm font-semibold bg-slate-800 text-slate-300 hover:bg-slate-700 disabled:opacity-40 disabled:hover:bg-slate-800 transition-colors cursor-pointer"
              >
                Poprzednia
              </button>
              <span className="text-sm text-slate-400">
                Strona {page} z {totalPages}
              </span>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-4 py-2 rounded-lg text-sm font-semibold bg-slate-800 text-slate-300 hover:bg-slate-700 disabled:opacity-40 disabled:hover:bg-slate-800 transition-colors cursor-pointer"
              >
                Następna
              </button>
            </div>
          )}
        </>
      )}

      <DismissConfirmDialog
        isOpen={dismissTarget !== null}
        onConfirm={handleConfirmDismiss}
        onCancel={() => setDismissTarget(null)}
        insightTitle={dismissTarget?.title || ''}
      />
    </div>
  );
}
