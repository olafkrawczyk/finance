import React, { useState, useEffect, useMemo } from 'react';
import { getMonthlySummary } from '../api';
import { linearRegression } from '../lib/linearRegression';
import { NormalizedSummaryRow } from '../components/ZbiorczyTable';
import BalanceChart from '../charts/BalanceChart';
import ComboChart from '../charts/ComboChart';
import SavingsChart from '../charts/SavingsChart';
import SavingsLogChart from '../charts/SavingsLogChart';

interface DashboardPageProps {
  onMonthClick: (month: string) => void;
}

export default function DashboardPage({ onMonthClick }: DashboardPageProps) {
  const [data, setData] = useState<NormalizedSummaryRow[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getMonthlySummary()
      .then((rows) => {
        const normalized = rows.map((r: any) => ({
          month: r.month,
          wydatki: parseFloat(r.wydatki),
          przychody: parseFloat(r.przychody),
          stan_konta: r.stan_konta != null ? parseFloat(r.stan_konta) : null,
          wydatki_bez_stalych: parseFloat(r.wydatki_bez_stalych),
          zaoszczedzone: parseFloat(r.zaoszczedzone),
          zaoszczedzone_log: parseFloat(r.zaoszczedzone_log),
        }));
        setData(normalized);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'Failed to load summary data');
        setLoading(false);
      });
  }, []);

  const predictionData = useMemo(() => {
    if (!data) return [];
    
    // Map index to stan_konta for regression
    const points = data
      .map((d, index) => ({ x: index, y: d.stan_konta }))
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
        <p className="text-slate-400 mt-4 text-sm">Loading dashboard...</p>
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
        <h3 className="text-lg font-semibold text-slate-300 mb-2">No data to chart</h3>
        <p className="text-slate-500 text-sm">
          Import transactions to populate dashboard charts.
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
          <ComboChart data={data} prediction={predictionData} onMonthClick={onMonthClick} />
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
