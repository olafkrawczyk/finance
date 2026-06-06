import React, { useState, useEffect } from 'react';
import { getInsights } from '../api';
import { formatRelativeTime, getPriorityColor, getTypeLabel } from '../lib/insights';

interface Insight {
  id: string;
  user_id: string;
  type: 'alert' | 'tip' | 'trend' | 'forecast';
  priority: 'high' | 'medium' | 'low';
  title: string;
  content: string;
  dismissed: boolean;
  created_at: string;
}

export default function InsightsWidget() {
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
        setError(err.message || 'Failed to load insights');
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchLatestInsights();

    // Poll every 60 seconds
    const intervalId = setInterval(fetchLatestInsights, 60000);
    return () => clearInterval(intervalId);
  }, []);

  const navigateToInsights = (e: React.MouseEvent) => {
    e.preventDefault();
    window.history.pushState(null, '', '/insights');
    window.dispatchEvent(new PopStateEvent('popstate'));
  };

  if (loading) {
    return (
      <div className="mb-8">
        <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3">
          Najnowsze analizy
        </h3>
        <div className="flex gap-4 overflow-x-auto pb-2">
          {[1, 2, 3].map((n) => (
            <div
              key={n}
              className="animate-pulse bg-slate-800/30 border border-slate-800/50 rounded-xl p-4 min-w-[250px] h-[120px] flex-shrink-0 flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <div className="h-2 w-2 rounded-full bg-slate-700" />
                  <div className="h-4 w-12 bg-slate-700 rounded" />
                </div>
                <div className="space-y-2">
                  <div className="h-3 bg-slate-700 rounded w-full" />
                  <div className="h-3 bg-slate-700 rounded w-5/6" />
                </div>
              </div>
              <div className="h-3 bg-slate-700 rounded w-1/3 mt-2" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="mb-8">
        <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3">
          Najnowsze analizy
        </h3>
        <div className="bg-red-950/20 border border-red-900/30 rounded-xl p-4 text-red-400 text-xs">
          Wystąpił błąd podczas ładowania analiz: {error}
        </div>
      </div>
    );
  }

  if (insights.length === 0) {
    return (
      <div className="mb-8">
        <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3">
          Najnowsze analizy
        </h3>
        <div className="bg-slate-900/50 border border-slate-800/50 rounded-xl p-6 text-center">
          <h4 className="text-slate-300 font-semibold mb-1 text-sm">Brak nowych analiz</h4>
          <p className="text-slate-400 text-xs max-w-md mx-auto">
            Analizy finansowe są generowane automatycznie na podstawie historii transakcji. Zaimportuj transakcje lub wygeneruj analizy na żądanie w sekcji Analizy.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="mb-8">
      <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3">
        Najnowsze analizy
      </h3>
      <div className="flex gap-4 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-slate-800">
        {insights.map((i) => {
          const colorConfig = getPriorityColor(i.priority);
          return (
            <div
              key={i.id}
              className="bg-slate-900/80 border border-slate-800 rounded-xl p-4 min-w-[250px] max-w-[320px] flex-shrink-0 flex flex-col justify-between hover:border-slate-700 transition-colors shadow-lg"
            >
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <span className={`h-2 w-2 rounded-full ${colorConfig.dot}`} />
                  <span className="text-xs px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 font-medium">
                    {getTypeLabel(i.type)}
                  </span>
                </div>
                <p className="text-sm font-medium text-slate-200 line-clamp-2 leading-relaxed">
                  {i.content}
                </p>
              </div>
              <div className="flex items-center justify-between text-xs text-slate-500 mt-4 border-t border-slate-800/60 pt-2">
                <span>{formatRelativeTime(i.created_at)}</span>
                <a
                  href="/insights"
                  onClick={navigateToInsights}
                  className="hover:text-blue-400 transition-colors flex items-center gap-1 font-medium text-blue-500"
                >
                  Więcej <span className="text-[10px]">→</span>
                </a>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
