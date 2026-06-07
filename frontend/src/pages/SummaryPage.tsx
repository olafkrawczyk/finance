import React, { useState, useEffect } from 'react';
import { getMonthlySummary } from '../api';
import SummaryTable, { NormalizedSummaryRow } from '../components/SummaryTable';

export default function SummaryPage() {
  const [data, setData] = useState<NormalizedSummaryRow[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

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
        }));
        setData(normalized);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'Nie udało się załadować danych podsumowania');
        setLoading(false);
      });
  }, []);

  const handleRowClick = (month: string) => {
    window.history.pushState(null, '', `/month/${month}`);
    window.dispatchEvent(new PopStateEvent('popstate'));
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
        <p className="text-slate-400 mt-4 text-sm">Ładowanie podsumowania...</p>
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

  return (
    <div className="space-y-6 max-w-6xl mx-auto w-full px-4">
      <div>
        <h2 className="text-2xl font-semibold text-slate-100 font-medium">Zbiorczo</h2>
        <p className="text-slate-400 text-sm">Zestawienie miesięcznych przepływów finansowych</p>
      </div>

      <SummaryTable rows={data || []} onRowClick={handleRowClick} />
    </div>
  );
}
