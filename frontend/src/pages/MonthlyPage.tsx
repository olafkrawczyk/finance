import React, { useState, useEffect } from 'react';
import { getTransactions, getOpeningBalance, getCategories, deleteTransaction } from '../api';
import TransactionTable, { NormalizedTransaction } from '../components/TransactionTable';
import MonthSidebar from '../components/MonthSidebar';

interface MonthlyPageProps {
  yearMonth: string; // YYYY-MM
}

export default function MonthlyPage({ yearMonth }: MonthlyPageProps) {
  const [transactions, setTransactions] = useState<NormalizedTransaction[] | null>(null);
  const [sidebarData, setSidebarData] = useState<{
    openingBalance: string | null;
    incomeByCategory: { category: string; amount: number }[];
    fixedCostTotal: number;
    nonFixedExpenses: number;
  } | null>(null);
  
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [isTruncated, setIsTruncated] = useState(false);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  // Parse YYYY-MM into year and month components
  const [yearStr, monthStr] = yearMonth.split('-');
  const year = parseInt(yearStr, 10);
  const month = parseInt(monthStr, 10);
  const dateFrom = `${yearStr}-${monthStr}-01`;
  // Compute the real last day of the month: new Date(year, month, 0) gives day 0
  // of the following month, which is the last day of the current month.
  const lastDay = new Date(year, month, 0).getDate();
  const dateTo = `${yearStr}-${monthStr}-${String(lastDay).padStart(2, '0')}`;

  // Format month heading in Polish or general English depending on locale
  const getMonthName = (m: number) => {
    const months = [
      'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
      'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
    ];
    return months[m - 1] || '';
  };

  useEffect(() => {
    setLoading(true);
    setError(null);

    Promise.all([
      getTransactions({ date_from: dateFrom, date_to: dateTo, per_page: 500 }),
      getOpeningBalance(year, month),
      getCategories(),
    ])
      .then(([txResult, openingBalances, categories]) => {
        const txRows = txResult.data;
        const txMeta = txResult.meta;
        // Create lookup maps for categories
        const categoryMap = new Map<string, any>();
        categories.forEach((cat: any) => {
          categoryMap.set(cat.id, cat);
        });

        // 1. Normalize transactions
        const normalizedTx: NormalizedTransaction[] = txRows.map((t: any) => ({
          id: t.id,
          date: t.date,
          description: t.description,
          category_name: t.category_id ? (categoryMap.get(t.category_id)?.name ?? null) : null,
          type: t.type,
          amount: parseFloat(t.amount),
        }));
        setTransactions(normalizedTx);

        // Warn if the response was truncated at the 500-row cap
        if (txMeta && txMeta.total > normalizedTx.length) {
          setIsTruncated(true);
        }

        // 2. Compute Sidebar Data
        // Opening balance
        const openingBalanceVal = openingBalances[0]?.opening_balance ?? null;

        // Income by category
        const incomeMap = new Map<string, number>();
        txRows
          .filter((t: any) => t.type === 'income')
          .forEach((t: any) => {
            const catName = t.category_id ? (categoryMap.get(t.category_id)?.name ?? 'Inne') : 'Nieskategoryzowane';
            const amt = parseFloat(t.amount);
            incomeMap.set(catName, (incomeMap.get(catName) || 0) + amt);
          });
        const incomeByCategory = Array.from(incomeMap.entries()).map(([category, amount]) => ({
          category,
          amount,
        }));

        // Fixed vs Non-fixed costs
        let fixedCostTotal = 0;
        let nonFixedExpenses = 0;
        txRows
          .filter((t: any) => t.type === 'expense')
          .forEach((t: any) => {
            const cat = t.category_id ? categoryMap.get(t.category_id) : null;
            const amt = parseFloat(t.amount);
            if (cat && cat.is_fixed_cost) {
              fixedCostTotal += amt;
            } else {
              nonFixedExpenses += amt;
            }
          });

        setSidebarData({
          openingBalance: openingBalanceVal,
          incomeByCategory,
          fixedCostTotal,
          nonFixedExpenses,
        });

        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'Failed to load month data');
        setLoading(false);
      });
  }, [yearMonth]);

  const handleEdit = (id: string) => {
    window.history.pushState(null, '', `/transactions/${id}/edit`);
    window.dispatchEvent(new Event('popstate'));
  };

  const handleDelete = async (id: string) => {
    try {
      setDeleteError(null);
      await deleteTransaction(id);
      setDeleteConfirmId(null);
      const [txResult, freshCategories] = await Promise.all([
        getTransactions({ date_from: dateFrom, date_to: dateTo, per_page: 500 }),
        getCategories(),
      ]);
      const categoryMap = new Map<string, any>();
      freshCategories.forEach((cat: any) => categoryMap.set(cat.id, cat));
      const normalizedTx: NormalizedTransaction[] = txResult.data.map((t: any) => ({
        id: t.id,
        date: t.date,
        description: t.description,
        category_name: t.category_id ? (categoryMap.get(t.category_id)?.name ?? null) : null,
        type: t.type,
        amount: parseFloat(t.amount),
      }));
      setTransactions(normalizedTx);
    } catch (err: any) {
      setDeleteError(err.message);
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
        <p className="text-slate-400 mt-4 text-sm">Loading month view...</p>
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

  const hasTransactions = transactions && transactions.length > 0;

  return (
    <div className="max-w-6xl mx-auto w-full px-4 space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-slate-100 font-medium">
          {getMonthName(month)} {year}
        </h2>
        <p className="text-slate-400 text-sm">Szczegóły przepływów dla wybranego miesiąca</p>
      </div>

      {isTruncated && (
        <div className="p-4 bg-yellow-950/50 border border-yellow-800 rounded-lg text-yellow-300 text-sm">
          Warning: This month has more than 500 transactions. Only the first 500 are shown.
        </div>
      )}

      <div className="flex flex-col lg:flex-row gap-6 items-start">
        {/* Main transaction list */}
        <div className="flex-1 w-full space-y-4">
          <h3 className="text-lg font-semibold text-slate-300 font-medium">Transakcje</h3>
          {!hasTransactions ? (
            <div className="flex flex-col items-center justify-center p-8 bg-slate-900/50 border border-slate-800 rounded-xl text-center">
              <h3 className="text-lg font-semibold text-slate-300 mb-2">No transactions for this month</h3>
              <p className="text-slate-500 text-sm">
                Go back to the summary view or import more data.
              </p>
            </div>
          ) : (
            <TransactionTable
              transactions={transactions}
              showCategory={true}
              onEdit={handleEdit}
              onDelete={(id) => setDeleteConfirmId(id)}
            />
          )}
        </div>

        {/* Sidebar */}
        <div className="w-full lg:w-80 shrink-0">
          <MonthSidebar
            openingBalance={sidebarData?.openingBalance ?? null}
            incomeByCategory={sidebarData?.incomeByCategory ?? []}
            fixedCostTotal={sidebarData?.fixedCostTotal ?? 0}
            nonFixedExpenses={sidebarData?.nonFixedExpenses ?? 0}
          />
        </div>
      </div>
      {/* Delete confirmation dialog */}
      {deleteConfirmId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl p-6 w-full max-w-md mx-4 shadow-2xl">
            <h3 className="text-lg font-semibold text-slate-100 mb-2">Usuń transakcję</h3>
            <p className="text-slate-400 text-sm mb-6">
              Czy na pewno chcesz usunąć tę transakcję? Tej operacji nie można cofnąć.
            </p>
            {deleteError && (
              <div className="mb-4 p-3 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-xs">
                {deleteError}
              </div>
            )}
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => { setDeleteConfirmId(null); setDeleteError(null); }}
                className="px-4 py-2 rounded-lg text-sm font-medium text-slate-400 hover:text-slate-200 bg-slate-800 hover:bg-slate-700 transition-colors"
              >
                Anuluj
              </button>
              <button
                onClick={() => handleDelete(deleteConfirmId)}
                className="px-4 py-2 rounded-lg text-sm font-medium text-white bg-red-600 hover:bg-red-500 transition-colors"
              >
                Usuń
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
