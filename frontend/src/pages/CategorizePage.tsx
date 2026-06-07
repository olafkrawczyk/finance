import React, { useState, useEffect } from 'react';
import { getTransactions, getCategories, assignCategory } from '../api';
import TransactionTable, { NormalizedTransaction } from '../components/TransactionTable';
import CategoryDropdown, { Category } from '../components/CategoryDropdown';

export default function CategorizePage() {
  const [transactions, setTransactions] = useState<NormalizedTransaction[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [targetCategory, setTargetCategory] = useState<string>('');
  const [assigning, setAssigning] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  const fetchData = () => {
    setLoading(true);
    setError(null);
    Promise.all([
      getTransactions({ per_page: 500, uncategorized: true }),
      getCategories(),
    ])
      .then(([txResult, catRows]) => {
        setCategories(catRows);

        const uncategorized = (txResult.data ?? [])
          .map((t: any) => ({
            id: t.id,
            date: t.date,
            description: t.description,
            category_name: null,
            type: t.type,
            amount: parseFloat(t.amount),
          }));

        setTransactions(uncategorized);
        setSelectedIds(new Set());
        
        // Auto-select first category as target if available
        if (catRows.length > 0) {
          setTargetCategory(catRows[0].id);
        }
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'Nie udało się załadować nieskategoryzowanych transakcji');
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleToggleSelect = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const handleSelectAll = () => {
    setSelectedIds((prev) => {
      const allSelected = transactions.every((t) => prev.has(t.id));
      if (allSelected) {
        return new Set();
      } else {
        return new Set(transactions.map((t) => t.id));
      }
    });
  };

  const handleAssign = async () => {
    if (selectedIds.size === 0 || !targetCategory) return;
    setAssigning(true);
    setError(null);
    setSuccess(null);

    const ids = Array.from(selectedIds);
    try {
      await Promise.all(ids.map((id) => assignCategory(id, targetCategory)));
      setSuccess('Kategorie zostały pomyślnie zapisane');
      
      // Remove successfully categorized transactions from state
      setTransactions((prev) => prev.filter((t) => !selectedIds.has(t.id)));
      setSelectedIds(new Set());
    } catch (err: any) {
      setError(err.message || 'Nie udało się zapisać kategorii');
    } finally {
      setAssigning(false);
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
        <p className="text-slate-400 mt-4 text-sm font-medium">Ładowanie transakcji...</p>
      </div>
    );
  }

  const hasUncategorized = transactions.length > 0;

  return (
    <div className="space-y-6 max-w-6xl mx-auto w-full px-4">
      <div>
        <h2 className="text-2xl font-semibold text-slate-100 font-medium">Kategoryzuj</h2>
        <p className="text-slate-400 text-sm">Przypisz kategorie do zaimportowanych transakcji</p>
      </div>

      {error && (
        <div role="alert" className="p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
          {error}
        </div>
      )}

      {success && (
        <div className="p-4 bg-green-950/50 border border-green-800 rounded-lg text-green-300 text-sm">
          {success}
        </div>
      )}

      {!hasUncategorized ? (
        <div className="flex flex-col items-center justify-center p-12 bg-slate-900/40 backdrop-blur-xl border border-slate-800 rounded-2xl text-center max-w-lg mx-auto space-y-3">
          <h3 className="text-xl font-semibold text-slate-200">Wszystko zrobione!</h3>
          <p className="text-slate-400 text-sm">
            Każda zaimportowana transakcja ma przypisaną kategorię.
          </p>
        </div>
      ) : (
        <div className="space-y-6">
          <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 flex flex-col md:flex-row md:items-end gap-6">
            <div className="flex-1 max-w-xs">
              <CategoryDropdown
                categories={categories}
                value={targetCategory}
                onChange={setTargetCategory}
                label="Przypisz do kategorii"
                includeUncategorized={false}
              />
            </div>
            
            <button
              onClick={handleAssign}
              disabled={selectedIds.size === 0 || !targetCategory || assigning}
              className={`py-3 px-6 rounded-xl font-semibold text-white shadow-lg transition-all duration-300 ${
                selectedIds.size === 0 || !targetCategory || assigning
                  ? 'bg-slate-800 text-slate-500 cursor-not-allowed shadow-none'
                  : 'bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 hover:shadow-emerald-500/20 active:scale-95'
              }`}
            >
              {assigning ? (
                <span className="flex items-center justify-center">
                  <svg
                    className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                    fill="none"
                    viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <circle
                      className="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      strokeWidth="4"
                    />
                    <path
                      className="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    />
                  </svg>
                  Zapisywanie kategorii...
                </span>
              ) : (
                `Zapisz kategorie (${selectedIds.size})`
              )}
            </button>
          </div>

          <div className="space-y-2">
            <div className="flex justify-between items-center px-1">
              <span className="text-xs text-slate-400 font-semibold uppercase tracking-wider">
                Nieskategoryzowane transakcje ({transactions.length})
              </span>
            </div>
            <TransactionTable
              transactions={transactions}
              showCategory={false}
              showCheckbox={true}
              selectedIds={selectedIds}
              onToggleSelect={handleToggleSelect}
              onSelectAll={handleSelectAll}
            />
          </div>
        </div>
      )}
    </div>
  );
}
