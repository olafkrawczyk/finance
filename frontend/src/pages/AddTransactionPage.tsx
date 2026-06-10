import React, { useState, useEffect, useMemo } from 'react';
import { useCategories, useAccounts, useTransactionDetail } from '../lib/query/hooks';
import { useMutation } from '@tanstack/react-query';
import { queryClient } from '../lib/query/client';
import { useUserId } from '../lib/query/provider';
import Skeleton from '../components/Skeleton';
import * as api from '../api';
import CategoryDropdown, { Category } from '../components/CategoryDropdown';

interface Account {
  id: string;
  name: string;
  type: string;
  currency: string;
}

interface AddTransactionPageProps {
  onSuccess?: () => void;
  transactionId?: string;
}

export default function AddTransactionPage({ onSuccess, transactionId }: AddTransactionPageProps) {
  const userId = useUserId();
  const [categoryId, setCategoryId] = useState<string>('');
  const [amount, setAmount] = useState<string>('');
  const [description, setDescription] = useState<string>('');
  const [date, setDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [type, setType] = useState<'income' | 'expense' | 'transfer'>('expense');
  const [submitting, setSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<boolean>(false);

  const { data: categoryRows, isPending: catLoading } = useCategories();
  const { data: accountRows, isPending: accLoading } = useAccounts();
  const { data: editTx, isPending: txLoading } = useTransactionDetail(transactionId!);

  const isEditLoading = !!transactionId && (txLoading || catLoading || accLoading);

  const categories = useMemo(() => categoryRows ?? [], [categoryRows]);
  const accounts = useMemo(() => accountRows ?? [], [accountRows]);

  const [accountId, setAccountId] = useState<string>('');

  useEffect(() => {
    if (accounts.length > 0 && !accountId) {
      setAccountId(accounts[0].id);
    }
  }, [accounts, accountId]);

  useEffect(() => {
    if (categories.length > 0 && !categoryId) {
      setCategoryId(categories[0].id);
    }
  }, [categories, categoryId]);

  useEffect(() => {
    if (!editTx) return;
    setType(editTx.type);
    setAccountId(editTx.account_id || '');
    setCategoryId(editTx.category_id || '');
    setAmount(editTx.amount);
    setDescription(editTx.description || '');
    setDate(editTx.date.split('T')[0]);
  }, [editTx]);

  const createMutation = useMutation({
    mutationFn: (data: Parameters<typeof api.createTransaction>[0]) => api.createTransaction(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Parameters<typeof api.updateTransaction>[1] }) =>
      api.updateTransaction(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!accountId) {
      setError('Proszę wybrać konto.');
      return;
    }
    if (!categoryId) {
      setError('Proszę wybrać kategorię.');
      return;
    }
    if (!amount || parseFloat(amount) <= 0) {
      setError('Proszę wpisać kwotę większą niż 0.');
      return;
    }
    if (!date) {
      setError('Proszę wybrać datę.');
      return;
    }

    setSubmitting(true);
    setError(null);
    setSuccess(false);

    try {
      const formattedAmount = parseFloat(amount).toFixed(4);
      if (transactionId) {
        await updateMutation.mutateAsync({
          id: transactionId,
          data: {
            account_id: accountId,
            category_id: categoryId,
            type,
            amount: formattedAmount,
            description: description.trim() || null,
            date,
          },
        });
      } else {
        await createMutation.mutateAsync({
          account_id: accountId,
          category_id: categoryId,
          type,
          amount: formattedAmount,
          description: description.trim() || null,
          date,
        });
      }

      setSuccess(true);
      setAmount('');
      setDescription('');
      setDate(new Date().toISOString().split('T')[0]);

      if (onSuccess) {
        onSuccess();
      }
    } catch (err: any) {
      setError(err.message || 'Nie udało się zapisać transakcji');
    } finally {
      setSubmitting(false);
    }
  };

  const isFormValid = accountId && categoryId && amount && parseFloat(amount) > 0 && date;

  if (isEditLoading) {
    return (
      <div className="max-w-lg w-full mx-auto" aria-busy="true">
        <Skeleton className="h-96 w-full rounded-2xl" />
      </div>
    );
  }

  return (
    <div className="max-w-lg w-full mx-auto bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl shadow-2xl p-8 transition-all duration-300">
      <div className="mb-8 text-center">
        <h2 className="text-2xl font-semibold text-slate-100 font-medium">{transactionId ? 'Edytuj transakcję' : 'Dodaj transakcję'}</h2>
        <p className="text-slate-400 mt-2 text-sm">{transactionId ? 'Edycja' : 'Nowa transakcja'}</p>
      </div>

      {error && (
        <div role="alert" className="mb-6 p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
          {error}
        </div>
      )}

      {success && (
        <div className="mb-6 p-4 bg-green-950/50 border border-green-800 rounded-lg text-green-300 text-sm">
          {transactionId ? 'Transakcja zaktualizowana pomyślnie!' : 'Transakcja dodana pomyślnie!'}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label htmlFor="type-select" className="block text-slate-300 text-sm font-semibold mb-2">
            Typ transakcji
          </label>
          <select
            id="type-select"
            className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
            value={type}
            onChange={(e) => setType(e.target.value as 'income' | 'expense' | 'transfer')}
          >
            <option value="expense">Wydatek</option>
            <option value="income">Przychód</option>
            <option value="transfer">Przelew</option>
          </select>
        </div>

        <div>
          <label htmlFor="account-select" className="block text-slate-300 text-sm font-semibold mb-2">
            Konto
          </label>
          <select
            id="account-select"
            className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
            value={accountId}
            onChange={(e) => setAccountId(e.target.value)}
          >
            {accounts.length === 0 && <option value="">Brak kont</option>}
            {accounts.map((a) => (
              <option key={a.id} value={a.id}>
                {a.name} ({a.currency})
              </option>
            ))}
          </select>
        </div>

        <div>
          <CategoryDropdown
            categories={categories}
            value={categoryId}
            onChange={setCategoryId}
            label="Kategoria"
            includeUncategorized={false}
            id="transaction-category-select"
          />
        </div>

        <div>
          <label htmlFor="amount-input" className="block text-slate-300 text-sm font-semibold mb-2">
            Kwota
          </label>
          <input
            id="amount-input"
            type="number"
            step="0.01"
            min="0.01"
            required
            placeholder="0.00"
            className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </div>

        <div>
          <label htmlFor="date-input" className="block text-slate-300 text-sm font-semibold mb-2">
            Data
          </label>
          <input
            id="date-input"
            type="date"
            required
            className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
            value={date}
            onChange={(e) => setDate(e.target.value)}
          />
        </div>

        <div>
          <label htmlFor="description-input" className="block text-slate-300 text-sm font-semibold mb-2">
            Opis
          </label>
          <input
            id="description-input"
            type="text"
            placeholder="Opis transakcji"
            className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
        </div>

        <button
          type="submit"
          disabled={!isFormValid || submitting}
          className={`w-full py-4 px-6 rounded-xl font-bold text-white shadow-lg transition-all duration-300 ${
            !isFormValid || submitting
              ? 'bg-slate-800 text-slate-500 cursor-not-allowed shadow-none'
              : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 hover:shadow-blue-500/20 active:scale-95'
          }`}
        >
          {submitting ? (
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
              Zapisywanie...
            </span>
          ) : (
            transactionId ? 'Zapisz zmiany' : 'Dodaj transakcję'
          )}
        </button>
      </form>
    </div>
  );
}
