import React, { useState, useEffect, useMemo } from 'react';
import { getMonthlySummary, getInsightsForecast, getAssets } from '../api';
import { linearRegression } from '../lib/linearRegression';
import { NormalizedSummaryRow } from '../components/SummaryTable';
import BalanceChart from '../charts/BalanceChart';
import ComboChart from '../charts/ComboChart';
import SavingsChart from '../charts/SavingsChart';
import SavingsLogChart from '../charts/SavingsLogChart';
import InsightsWidget from '../components/InsightsWidget';

interface DashboardPageProps {
  onMonthClick: (month: string) => void;
  onAssetsClick: () => void;
}

export default function DashboardPage({ onMonthClick, onAssetsClick }: DashboardPageProps) {
  const [data, setData] = useState<NormalizedSummaryRow[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [aiForecast, setAiForecast] = useState<{ monthIndex: number; value: number }[] | null>(null);
  const [assets, setAssets] = useState<{ id: string; name: string; value: number }[]>([]);

  useEffect(() => {
    getMonthlySummary()
      .then((rows) => {
        const normalized = rows.map((r: any) => ({
          month: r.month,
          expenses: parseFloat(r.wydatki),
          income: parseFloat(r.przychody),
          balance: r.stan_konta != null ? parseFloat(r.stan_konta) : null,
          expensesWithoutFixed: parseFloat(r.wydatki_bez_stalych),
          savings: parseFloat(r.zaoszczedzone),
          savingsLog: parseFloat(r.zaoszczedzone_log),
        })).reverse();
        setData(normalized);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'Nie udało się wczytać podsumowania');
        setLoading(false);
      });
  }, []);

  useEffect(() => {
    getAssets()
      .then((rows) => {
        const parsed = (rows ?? []).map((a: any) => ({
          id: a.id,
          name: a.name,
          value: parseFloat(a.value),
        }));
        setAssets(parsed);
      })
      .catch((err) => {
        console.error('Failed to load assets in dashboard:', err);
      });
  }, []);

  const formatPln = (val: number) => {
    return new Intl.NumberFormat('pl-PL', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(val);
  };

  const formatMonthLabel = (monthStr: string) => {
    if (!monthStr) return '';
    const [year, month] = monthStr.split('-');
    const date = new Date(parseInt(year), parseInt(month) - 1, 1);
    const formatted = date.toLocaleDateString('pl-PL', { month: 'long', year: 'numeric' });
    return formatted.charAt(0).toUpperCase() + formatted.slice(1);
  };

  const totalNetValue = assets.reduce((sum, a) => sum + a.value, 0);

  const totalBankBalance = useMemo(() => {
    if (!data) return 0;
    return data.reduce((sum, r) => sum + r.savings, 0);
  }, [data]);

  const totalNetWorth = totalBankBalance + totalNetValue;

  const currentMonthStr = new Date().toISOString().substring(0, 7);

  // Find current month or fallback to last element of data
  const currentMonthData = useMemo(() => {
    if (!data || data.length === 0) return null;
    return data.find((r) => r.month === currentMonthStr) || data[data.length - 1];
  }, [data, currentMonthStr]);


  useEffect(() => {
    if (!data) return;

    getInsightsForecast()
      .then((insights) => {
        if (!insights || insights.length === 0) {
          setAiForecast(null);
          return;
        }

        // Sum all category forecast spending
        let totalForecastSpend = 0;
        insights.forEach((insight: any) => {
          if (insight.type !== 'forecast') return;
          const match = insight.content.match(/wynoszą\s+([\d.]+)\s+PLN/);
          if (match) {
            const val = parseFloat(match[1]);
            if (!isNaN(val)) totalForecastSpend += val;
          }
        });

        if (totalForecastSpend === 0) {
          setAiForecast(null);
          return;
        }

        const lastPoint = data[data.length - 1];
        if (lastPoint.balance === null) {
          setAiForecast(null);
          return;
        }

        // Estimate income as average of last 3 months
        const avgIncome = data.slice(-3).reduce((sum, d) => sum + d.income, 0) / Math.min(3, data.length);
        const projectedBalance = lastPoint.balance + avgIncome - totalForecastSpend;

        // Two points: anchor at last known balance, then projected next month
        setAiForecast([
          { monthIndex: data.length - 1, value: lastPoint.balance },
          { monthIndex: data.length, value: projectedBalance },
        ]);
      })
      .catch((err) => {
        console.warn('Failed to load AI forecast data:', err);
        setAiForecast(null);
      });
  }, [data]);

  const predictionData = useMemo(() => {
    if (!data) return [];
    
    // Map index to balance for regression
    const points = data
      .map((d, index) => ({ x: index, y: d.balance }))
      .filter((p): p is { x: number; y: number } => p.y !== null);

    if (points.length < 2) return [];

    // Predict for the length of data (project trend onto existing months)
    const { slope, intercept } = linearRegression(points);
    return data.map((_, index) => ({
      monthIndex: index,
      value: slope * index + intercept,
    }));
  }, [data]);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
        <p className="text-slate-400 mt-4 text-sm">Ładowanie dashboardu...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-lg mx-auto p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
        {error}
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center p-8 bg-slate-900/50 border border-slate-800 rounded-xl text-center max-w-lg mx-auto">
        <h3 className="text-lg font-semibold text-slate-300 mb-2">Brak danych do wykresu</h3>
        <p className="text-slate-500 text-sm">
          Zaimportuj transakcje, aby uzupełnić wykresy na pulpicie.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-6xl mx-auto w-full px-4">
      <div>
        <h2 className="text-2xl font-semibold text-slate-100">Dashboard</h2>
        <p className="text-slate-400 text-sm">Przegląd analizy finansowej</p>
      </div>

      <InsightsWidget />

      {/* Summary Tiles Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Total Net Value Card */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 shadow-xl flex flex-col justify-between">
          <div>
            <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-2">
              Całkowita wartość netto
            </h3>
            <p className="text-3xl font-bold text-slate-100 mt-2">
              {formatPln(totalNetWorth)} PLN
            </p>
            
            <div className="mt-4 space-y-2 border-t border-slate-800/60 pt-4 text-xs">
              <div className="flex justify-between items-center text-slate-300">
                <span className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-blue-500 inline-block"></span>
                  Konta bankowe (Saldo)
                </span>
                <span className="font-semibold text-slate-200">{formatPln(totalBankBalance)} PLN</span>
              </div>
              <div className="flex justify-between items-center text-slate-300">
                <span className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-slate-500 inline-block"></span>
                  Pozostałe aktywa (Ręczne)
                </span>
                <span className="font-semibold text-slate-200">{formatPln(totalNetValue)} PLN</span>
              </div>
            </div>
          </div>
          <div className="mt-4 pt-4 border-t border-slate-800/60">
            <button
              onClick={onAssetsClick}
              className="text-xs font-semibold text-blue-400 hover:text-blue-300 transition-colors flex items-center"
            >
              Zarządzaj aktywami &rarr;
            </button>
          </div>
        </div>

        {/* Current Month summary Card */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 shadow-xl">
          <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3">
            {currentMonthData && currentMonthData.month !== currentMonthStr
              ? `Podsumowanie (${formatMonthLabel(currentMonthData.month)})`
              : `Bieżący miesiąc (${formatMonthLabel(currentMonthStr)})`}
          </h3>
          {currentMonthData ? (
            <div className="grid grid-cols-3 gap-4 mt-4 text-center">
              <div className="bg-slate-950/45 p-3 rounded-xl border border-slate-800/40">
                <span className="text-xs text-slate-500 block">Przychody</span>
                <span className="text-sm font-bold text-emerald-400 mt-1 block">
                  {formatPln(currentMonthData.income)}
                </span>
              </div>
              <div className="bg-slate-950/45 p-3 rounded-xl border border-slate-800/40">
                <span className="text-xs text-slate-500 block">Wydatki</span>
                <span className="text-sm font-bold text-rose-400 mt-1 block">
                  {formatPln(currentMonthData.expenses)}
                </span>
              </div>
              <div className="bg-slate-950/45 p-3 rounded-xl border border-slate-800/40">
                <span className="text-xs text-slate-500 block">Oszczędności</span>
                <span className="text-sm font-bold text-blue-400 mt-1 block">
                  {formatPln(currentMonthData.savings)}
                </span>
              </div>
            </div>
          ) : (
            <div className="text-slate-500 text-sm py-4">Brak danych podsumowania</div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Balance Over Time */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider">
            Stan konta z upływem czasu
          </h3>
          <BalanceChart data={data} onMonthClick={onMonthClick} />
        </div>

        {/* Expenses + Income + Balance + Prediction */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider">
            Przychody, wydatki i predykcja
          </h3>
          <ComboChart data={data} prediction={predictionData} aiForecast={aiForecast || undefined} onMonthClick={onMonthClick} />
        </div>

        {/* Savings Over Time */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider">
            Zaoszczędzone kwoty
          </h3>
          <SavingsChart data={data} onMonthClick={onMonthClick} />
        </div>

        {/* Savings (Log Scale) */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider">
            Zaoszczędzone kwoty (skala logarytmiczna)
          </h3>
          <SavingsLogChart data={data} onMonthClick={onMonthClick} />
        </div>
      </div>
    </div>
  );
}
