import React from 'react';

export interface NormalizedSummaryRow {
  month: string;
  expenses: number;
  income: number;
  balance: number | null;
  expensesWithoutFixed: number;
  savings: number;
  savingsLog: number;
}

interface SummaryTableProps {
  rows: NormalizedSummaryRow[];
  onRowClick?: (month: string) => void;
}

const fmt = (n: number): string =>
  new Intl.NumberFormat('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);

export default function SummaryTable({ rows, onRowClick }: SummaryTableProps) {
  if (!rows || rows.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center p-8 bg-slate-900/50 border border-slate-800 rounded-xl text-center">
        <h3 className="text-lg font-semibold text-slate-300 mb-2">Brak danych o transakcjach</h3>
        <p className="text-slate-500 text-sm max-w-sm">
          Zaimportuj wyciąg bankowy CSV, aby zobaczyć podsumowanie miesięczne.
        </p>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-slate-800 bg-slate-900/40 backdrop-blur-xl">
      <table className="w-full min-w-[700px] text-sm text-left border-collapse">
        <thead className="bg-slate-900 text-slate-400 uppercase text-xs font-semibold">
          <tr>
            <th className="px-6 py-4 text-left">Miesiąc</th>
            <th className="px-6 py-4 text-right">Wydatki</th>
            <th className="px-6 py-4 text-right">Przychody</th>
            <th className="px-6 py-4 text-right">Stan konta</th>
            <th className="px-6 py-4 text-right">Wydatki bez stałych</th>
            <th className="px-6 py-4 text-right">Zaoszczędzone</th>
            <th className="px-6 py-4 text-right">Zaoszcz. log</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800 text-slate-300">
          {rows.map((row) => (
            <tr
              key={row.month}
              onClick={() => onRowClick && onRowClick(row.month)}
              className={`transition-colors ${
                onRowClick ? 'cursor-pointer hover:bg-slate-900/50' : ''
              }`}
            >
              <td className="px-6 py-4 text-left text-slate-200 font-medium">
                {row.month}
              </td>
              <td className="px-6 py-4 text-right text-red-400 font-mono">
                {fmt(row.expenses)}
              </td>
              <td className="px-6 py-4 text-right text-green-400 font-mono">
                {fmt(row.income)}
              </td>
              <td className="px-6 py-4 text-right text-blue-400 font-mono">
                {row.balance !== null ? fmt(row.balance) : '—'}
              </td>
              <td className="px-6 py-4 text-right font-mono">
                {fmt(row.expensesWithoutFixed)}
              </td>
              <td className="px-6 py-4 text-right font-mono">
                {fmt(row.savings)}
              </td>
              <td className="px-6 py-4 text-right text-slate-400 font-mono">
                {isNaN(row.savingsLog) ? '—' : row.savingsLog.toFixed(2)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
