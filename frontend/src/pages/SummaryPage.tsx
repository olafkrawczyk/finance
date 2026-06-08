import React, { useMemo } from 'react';
import { useMonthlySummary } from '../lib/query/hooks';
import Skeleton from '../components/Skeleton';
import SummaryTable, { NormalizedSummaryRow } from '../components/SummaryTable';

export default function SummaryPage() {
  const { data, isPending, error } = useMonthlySummary();

  const normalizedData = useMemo(() => {
    if (!data) return null;
    return data.map((r: any) => ({
      month: r.month,
      expenses: parseFloat(r.wydatki),
      income: parseFloat(r.przychody),
      balance: r.stan_konta != null ? parseFloat(r.stan_konta) : null,
      expensesWithoutFixed: parseFloat(r.wydatki_bez_stalych),
      savings: parseFloat(r.zaoszczedzone),
      savingsLog: parseFloat(r.zaoszczedzone_log),
    }));
  }, [data]);

  const handleRowClick = (month: string) => {
    window.history.pushState(null, '', `/month/${month}`);
    window.dispatchEvent(new PopStateEvent('popstate'));
  };

  if (isPending) {
    return (
      <div className="space-y-6 max-w-6xl mx-auto w-full px-4" aria-busy="true">
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

  return (
    <div className="space-y-6 max-w-6xl mx-auto w-full px-4">
      <div>
        <h2 className="text-2xl font-semibold text-slate-100 font-medium">Zbiorczo</h2>
        <p className="text-slate-400 text-sm">Zestawienie miesięcznych przepływów finansowych</p>
      </div>

      <SummaryTable rows={normalizedData || []} onRowClick={handleRowClick} />
    </div>
  );
}
