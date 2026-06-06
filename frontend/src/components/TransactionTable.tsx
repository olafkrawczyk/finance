import React from 'react';

export interface NormalizedTransaction {
  id: string;
  date: string;
  description: string | null;
  category_name: string | null;
  type: 'income' | 'expense' | 'transfer';
  amount: number;
}

interface TransactionTableProps {
  transactions: NormalizedTransaction[];
  showCategory?: boolean;
  showCheckbox?: boolean;
  selectedIds?: Set<string>;
  onToggleSelect?: (id: string) => void;
  onSelectAll?: () => void;
}

const fmt = (n: number): string =>
  new Intl.NumberFormat('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);

export default function TransactionTable({
  transactions,
  showCategory = false,
  showCheckbox = false,
  selectedIds = new Set(),
  onToggleSelect,
  onSelectAll,
}: TransactionTableProps) {
  if (!transactions || transactions.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center p-8 bg-slate-900/50 border border-slate-800 rounded-xl text-center">
        <h3 className="text-lg font-semibold text-slate-300 mb-2">No transactions found</h3>
      </div>
    );
  }

  const allSelected =
    transactions.length > 0 && transactions.every((t) => selectedIds.has(t.id));

  return (
    <div className="overflow-x-auto rounded-xl border border-slate-800 bg-slate-900/40 backdrop-blur-xl">
      <table className="w-full text-sm text-left border-collapse">
        <thead className="bg-slate-900 text-slate-400 uppercase text-xs font-semibold">
          <tr>
            {showCheckbox && (
              <th className="w-12 px-6 py-4 text-center">
                <input
                  type="checkbox"
                  checked={allSelected}
                  onChange={() => onSelectAll && onSelectAll()}
                  className="rounded border-slate-800 bg-slate-950 text-blue-500 focus:ring-blue-500 focus:ring-opacity-50"
                />
              </th>
            )}
            <th className="px-6 py-4 text-left">Data</th>
            {showCategory && <th className="px-6 py-4 text-left">Kategoria</th>
            }
            <th className="px-6 py-4 text-left">Opis</th>
            <th className="px-6 py-4 text-right">Kwota</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800 text-slate-300">
          {transactions.map((tx) => {
            const isSelected = selectedIds.has(tx.id);
            let amountColor = 'text-slate-300';
            if (tx.type === 'income') {
              amountColor = 'text-green-400';
            } else if (tx.type === 'expense') {
              amountColor = 'text-red-400';
            } else if (tx.type === 'transfer') {
              amountColor = 'text-yellow-400';
            }

            return (
              <tr
                key={tx.id}
                className={`transition-colors ${
                  isSelected ? 'bg-blue-950/20' : 'hover:bg-slate-900/50'
                }`}
              >
                {showCheckbox && (
                  <td className="px-6 py-4 text-center">
                    <input
                      type="checkbox"
                      checked={isSelected}
                      onChange={() => onToggleSelect && onToggleSelect(tx.id)}
                      className="rounded border-slate-800 bg-slate-950 text-blue-500 focus:ring-blue-500 focus:ring-opacity-50"
                    />
                  </td>
                )}
                <td className="px-6 py-4 text-left whitespace-nowrap font-mono text-xs">
                  {tx.date}
                </td>
                {showCategory && (
                  <td className="px-6 py-4 text-left text-slate-200">
                    {tx.category_name || '—'}
                  </td>
                )}
                <td className="px-6 py-4 text-left text-slate-300">
                  {tx.description || '—'}
                </td>
                <td className={`px-6 py-4 text-right font-mono font-medium ${amountColor}`}>
                  {tx.type === 'expense' && '-'}
                  {tx.type === 'income' && '+'}
                  {fmt(tx.amount)}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
