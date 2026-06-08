import React, { useMemo } from 'react';
import { useTransactionsList, useOpeningBalance, useCategories, useDeleteTransaction } from '../lib/query/hooks';
import Skeleton from '../components/Skeleton';
import TransactionTable, { NormalizedTransaction } from '../components/TransactionTable';
import MonthSidebar from '../components/MonthSidebar';

export interface FilterState {
  searchTerm: string;
  selectedType: string;
  selectedCategory: string;
  sortBy: string;
}

export function filterAndSortTransactions(
  transactions: NormalizedTransaction[] | null,
  filters: FilterState
): NormalizedTransaction[] {
  if (!transactions) return [];

  let results = transactions.filter((t) => {
    const term = filters.searchTerm.toLowerCase().trim();
    const matchesSearch =
      term === '' ||
      (t.description?.toLowerCase().includes(term) ?? false) ||
      (t.category_name?.toLowerCase().includes(term) ?? false);

    const matchesType = filters.selectedType === 'all' || t.type === filters.selectedType;

    const matchesCategory =
      filters.selectedCategory === 'all' ||
      (filters.selectedCategory === 'uncategorized' && t.category_name === null) ||
      t.category_name === filters.selectedCategory;

    return matchesSearch && matchesType && matchesCategory;
  });

  results.sort((a, b) => {
    if (filters.sortBy === 'date-desc') {
      return b.date.localeCompare(a.date) || b.id.localeCompare(a.id);
    }
    if (filters.sortBy === 'date-asc') {
      return a.date.localeCompare(b.date) || a.id.localeCompare(b.id);
    }
    if (filters.sortBy === 'amount-desc') {
      return b.amount - a.amount;
    }
    if (filters.sortBy === 'amount-asc') {
      return a.amount - b.amount;
    }
    if (filters.sortBy === 'description-asc') {
      const descA = a.description || '';
      const descB = b.description || '';
      return descA.localeCompare(descB, 'pl');
    }
    return 0;
  });

  return results;
}

export function extractUniqueCategories(
  transactions: NormalizedTransaction[] | null
): string[] {
  if (!transactions) return [];
  const categoriesSet = new Set<string>();
  transactions.forEach((t) => {
    if (t.category_name) {
      categoriesSet.add(t.category_name);
    }
  });
  return Array.from(categoriesSet).sort((a, b) => a.localeCompare(b, 'pl'));
}

interface MonthlyPageProps {
  yearMonth: string;
}

export default function MonthlyPage({ yearMonth }: MonthlyPageProps) {
  const [deleteConfirmId, setDeleteConfirmId] = React.useState<string | null>(null);
  const [deleteError, setDeleteError] = React.useState<string | null>(null);

  const [searchTerm, setSearchTerm] = React.useState('');
  const [selectedType, setSelectedType] = React.useState('all');
  const [selectedCategory, setSelectedCategory] = React.useState('all');
  const [sortBy, setSortBy] = React.useState('date-desc');

  const [yearStr, monthStr] = yearMonth.split('-');
  const year = parseInt(yearStr, 10);
  const month = parseInt(monthStr, 10);
  const dateFrom = `${yearStr}-${monthStr}-01`;
  const lastDay = new Date(year, month, 0).getDate();
  const dateTo = `${yearStr}-${monthStr}-${String(lastDay).padStart(2, '0')}`;

  const getMonthName = (m: number) => {
    const months = [
      'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
      'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
    ];
    return months[m - 1] || '';
  };

  const { data: txResult, isPending: txLoading, error: txError } = useTransactionsList({ date_from: dateFrom, date_to: dateTo, per_page: 500 });
  const { data: openingBalances, isPending: obLoading } = useOpeningBalance(year, month);
  const { data: categories, isPending: catLoading } = useCategories();
  const deleteMutation = useDeleteTransaction();

  const isPending = txLoading || obLoading || catLoading;

  const { transactions, sidebarData, isTruncated } = useMemo(() => {
    if (!txResult?.data || !categories || !openingBalances) {
      return { transactions: null, sidebarData: null, isTruncated: false };
    }

    const categoryMap = new Map<string, any>();
    categories.forEach((cat: any) => {
      categoryMap.set(cat.id, cat);
    });

    const normalizedTx: NormalizedTransaction[] = txResult.data.map((t: any) => ({
      id: t.id,
      date: t.date,
      description: t.description,
      category_name: t.category_id ? (categoryMap.get(t.category_id)?.name ?? null) : null,
      type: t.type,
      amount: parseFloat(t.amount),
    }));

    const truncated = txResult.meta && txResult.meta.total > normalizedTx.length;

    const openingBalanceVal = openingBalances[0]?.opening_balance ?? null;

    const incomeMap = new Map<string, number>();
    txResult.data
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

    let fixedCostTotal = 0;
    let nonFixedExpenses = 0;
    txResult.data
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

    return {
      transactions: normalizedTx,
      sidebarData: {
        openingBalance: openingBalanceVal,
        incomeByCategory,
        fixedCostTotal,
        nonFixedExpenses,
      },
      isTruncated: truncated,
    };
  }, [txResult, openingBalances, categories]);

  const uniqueCategories = useMemo(() => {
    return extractUniqueCategories(transactions);
  }, [transactions]);

  const filteredAndSortedTransactions = useMemo(() => {
    return filterAndSortTransactions(transactions, { searchTerm, selectedType, selectedCategory, sortBy });
  }, [transactions, searchTerm, selectedType, selectedCategory, sortBy]);

  const handleEdit = (id: string) => {
    window.history.pushState(null, '', `/transactions/${id}/edit`);
    window.dispatchEvent(new Event('popstate'));
  };

  const handleDelete = (id: string) => {
    deleteMutation.mutate(id, {
      onSuccess: () => {
        setDeleteConfirmId(null);
        setDeleteError(null);
      },
      onError: (err: any) => {
        setDeleteError(err.message);
      },
    });
  };

  if (isPending) {
    return (
      <div className="max-w-6xl mx-auto w-full px-4 space-y-6" aria-busy="true">
        <div className="space-y-2">
          <Skeleton className="h-8 w-64" />
          <Skeleton className="h-4 w-48" />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-10 w-full rounded-lg" />
          ))}
        </div>
        <Skeleton className="h-10 w-full rounded-lg" />
        {[1, 2, 3, 4, 5, 6].map((i) => (
          <Skeleton key={i} className="h-12 w-full rounded-lg" />
        ))}
      </div>
    );
  }

  if (txError) {
    return (
      <div className="max-w-lg mx-auto p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
        Failed to load data — check connection and try again.
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
          Ostrzeżenie: Ten miesiąc zawiera ponad 500 transakcji. Wyświetlono tylko pierwsze 500.
        </div>
      )}

      <div className="flex flex-col lg:flex-row gap-6 items-start">
        <div className="flex-1 w-full space-y-4">
          <h3 className="text-lg font-semibold text-slate-300 font-medium">Transakcje</h3>

          <div className="p-4 bg-slate-800/40 border border-slate-800 rounded-xl space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-semibold text-slate-200">Filtruj Transakcje</span>
              <span className="text-xs text-slate-400">
                Pokazuje {filteredAndSortedTransactions.length} z {transactions?.length ?? 0} transakcji
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-slate-500">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                </span>
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Szukaj w opisie lub kategorii..."
                  className="w-full pl-9 pr-3 py-2 bg-slate-900 border border-slate-700 rounded-lg text-sm text-slate-200 placeholder-slate-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
                />
              </div>

              <div>
                <select
                  value={selectedType}
                  onChange={(e) => setSelectedType(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-lg text-sm text-slate-200 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
                >
                  <option value="all">Wszystkie typy</option>
                  <option value="income">Przychody</option>
                  <option value="expense">Wydatki</option>
                  <option value="transfer">Przelewy</option>
                </select>
              </div>

              <div>
                <select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-lg text-sm text-slate-200 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
                >
                  <option value="all">Wszystkie kategorie</option>
                  <option value="uncategorized">Nieskategoryzowane</option>
                  {uniqueCategories.map((cat) => (
                    <option key={cat} value={cat}>
                      {cat}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-lg text-sm text-slate-200 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
                >
                  <option value="date-desc">Data: Najnowsze najpierw</option>
                  <option value="date-asc">Data: Najstarsze najpierw</option>
                  <option value="amount-desc">Kwota: Od najwyższej</option>
                  <option value="amount-asc">Kwota: Od najniższej</option>
                  <option value="description-asc">Opis: A do Z</option>
                </select>
              </div>
            </div>

            {(searchTerm !== '' || selectedType !== 'all' || selectedCategory !== 'all' || sortBy !== 'date-desc') && (
              <div className="flex justify-end">
                <button
                  onClick={() => {
                    setSearchTerm('');
                    setSelectedType('all');
                    setSelectedCategory('all');
                    setSortBy('date-desc');
                  }}
                  className="px-3 py-1.5 text-xs font-medium text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-lg transition-colors"
                >
                  Wyczyść filtry
                </button>
              </div>
            )}
          </div>

          {!hasTransactions ? (
            <div className="flex flex-col items-center justify-center p-8 bg-slate-900/50 border border-slate-800 rounded-xl text-center">
              <h3 className="text-lg font-semibold text-slate-300 mb-2">Brak transakcji w tym miesiącu</h3>
              <p className="text-slate-500 text-sm">
                Wróć do widoku zbiorczego lub zaimportuj nowe dane.
              </p>
            </div>
          ) : filteredAndSortedTransactions.length === 0 ? (
            <div className="flex flex-col items-center justify-center p-8 bg-slate-900/50 border border-slate-800 rounded-xl text-center">
              <h3 className="text-lg font-semibold text-slate-300 mb-2">Brak pasujących transakcji</h3>
              <p className="text-slate-500 text-sm">
                Spróbuj zmienić filtry lub wyszukiwaną frazę.
              </p>
            </div>
          ) : (
            <TransactionTable
              transactions={filteredAndSortedTransactions}
              showCategory={true}
              onEdit={handleEdit}
              onDelete={(id) => setDeleteConfirmId(id)}
            />
          )}
        </div>

        <div className="w-full lg:w-80 shrink-0">
          <MonthSidebar
            openingBalance={sidebarData?.openingBalance ?? null}
            incomeByCategory={sidebarData?.incomeByCategory ?? []}
            fixedCostTotal={sidebarData?.fixedCostTotal ?? 0}
            nonFixedExpenses={sidebarData?.nonFixedExpenses ?? 0}
          />
        </div>
      </div>
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
