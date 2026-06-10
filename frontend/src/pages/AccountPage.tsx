import React, { useState, useMemo, useEffect, useRef } from 'react';
import { useAccounts } from '../lib/query/hooks';
import { useMutation } from '@tanstack/react-query';
import { queryClient } from '../lib/query/client';
import { useUserId } from '../lib/query/provider';
import Skeleton from '../components/Skeleton';
import TypedDeleteConfirmModal from '../components/TypedDeleteConfirmModal';
import * as api from '../api';

interface Account {
  id: string;
  name: string;
  type: string;
  currency: string;
  starting_balance: number;
  starting_balance_date: string | null;
}

function formatDate(dateStr: string | null): string {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString('pl-PL', { year: 'numeric', month: '2-digit', day: '2-digit' });
  } catch {
    return dateStr;
  }
}

function toDateInputValue(dateStr: string | null): string {
  if (!dateStr) return '';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return '';
    return d.toISOString().split('T')[0];
  } catch {
    return dateStr;
  }
}

function todayStr(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export default function AccountPage() {
  const { data: accountsData, isPending } = useAccounts();
  const userId = useUserId();

  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Create form state
  const [newName, setNewName] = useState<string>('');
  const [newType, setNewType] = useState<string>('personal');
  const [newStartingBalance, setNewStartingBalance] = useState<string>('');
  const [newStartingBalanceDate, setNewStartingBalanceDate] = useState<string>(todayStr());
  const [submitting, setSubmitting] = useState<boolean>(false);

  // Inline edit state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editingName, setEditingName] = useState<string>('');
  const [editingBalance, setEditingBalance] = useState<string>('');
  const [editingBalanceDate, setEditingBalanceDate] = useState<string>('');
  const [savingId, setSavingId] = useState<string | null>(null);

  // Delete state
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; name: string } | null>(null);
  const [deleting, setDeleting] = useState<boolean>(false);

  // Auto-clear success/error banners
  const errorTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const successTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (error) {
      if (errorTimer.current) clearTimeout(errorTimer.current);
      errorTimer.current = setTimeout(() => setError(null), 4000);
    }
    return () => {
      if (errorTimer.current) clearTimeout(errorTimer.current);
    };
  }, [error]);

  useEffect(() => {
    if (success) {
      if (successTimer.current) clearTimeout(successTimer.current);
      successTimer.current = setTimeout(() => setSuccess(null), 4000);
    }
    return () => {
      if (successTimer.current) clearTimeout(successTimer.current);
    };
  }, [success]);

  // Data normalization
  const accounts = useMemo(() => {
    return (accountsData ?? []).map((a: any) => ({
      id: a.id,
      name: a.name,
      type: a.type || 'personal',
      currency: a.currency || 'PLN',
      starting_balance: parseFloat(a.starting_balance || '0'),
      starting_balance_date: a.starting_balance_date || null,
    }));
  }, [accountsData]);

  // Mutations
  const createMutation = useMutation({
    mutationFn: (data: Parameters<typeof api.createAccount>[0]) => api.createAccount(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Parameters<typeof api.updateAccount>[1] }) =>
      api.updateAccount(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.deleteAccount(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });

  // Handlers
  const handleAddAccount = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) {
      setError('Nazwa konta nie może być pusta');
      return;
    }
    const bal = newStartingBalance.trim() === '' ? 0 : parseFloat(newStartingBalance);
    if (newStartingBalance.trim() !== '' && isNaN(bal)) {
      setError('Saldo początkowe musi być liczbą');
      return;
    }
    if (bal < 0) {
      setError('Saldo początkowe nie może być ujemne');
      return;
    }

    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      await createMutation.mutateAsync({
        name: newName.trim(),
        type: newType,
        starting_balance: String(bal),
        starting_balance_date: newStartingBalanceDate || null,
      });
      setSuccess('Pomyślnie dodano nowe konto');
      setNewName('');
      setNewType('personal');
      setNewStartingBalance('');
      setNewStartingBalanceDate(todayStr());
    } catch (err: any) {
      setError(err.message || 'Nie udało się dodać konta');
    } finally {
      setSubmitting(false);
    }
  };

  const handleStartEdit = (account: Account) => {
    setEditingId(account.id);
    setEditingName(account.name);
    setEditingBalance(String(account.starting_balance));
    setEditingBalanceDate(toDateInputValue(account.starting_balance_date));
    setError(null);
    setSuccess(null);
  };

  const handleCancelEdit = () => {
    setEditingId(null);
    setEditingName('');
    setEditingBalance('');
    setEditingBalanceDate('');
  };

  const handleSaveEdit = async (id: string) => {
    if (!editingName.trim()) {
      setError('Nazwa konta nie może być pusta');
      return;
    }
    const bal = parseFloat(editingBalance);
    if (isNaN(bal)) {
      setError('Saldo początkowe musi być liczbą');
      return;
    }
    if (bal < 0) {
      setError('Saldo początkowe nie może być ujemne');
      return;
    }

    setSavingId(id);
    setError(null);
    setSuccess(null);

    try {
      await updateMutation.mutateAsync({
        id,
        data: {
          name: editingName.trim(),
          starting_balance: String(bal),
          starting_balance_date: editingBalanceDate || null,
        },
      });
      setSuccess('Pomyślnie zaktualizowano konto');
      handleCancelEdit();
    } catch (err: any) {
      setError(err.message || 'Nie udało się zaktualizować konta');
    } finally {
      setSavingId(null);
    }
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    setError(null);
    setSuccess(null);

    try {
      await deleteMutation.mutateAsync(deleteTarget.id);
      setSuccess('Pomyślnie usunięto konto');
      setDeleteTarget(null);
    } catch (err: any) {
      setDeleteTarget(null);
      // Try to extract transaction count from server error for 409
      const countMatch = err.message.match(/\d+/);
      if (countMatch) {
        setError(`Nie można usunąć konta, ponieważ ma ${countMatch[0]} transakcji`);
      } else {
        setError(err.message || 'Nie udało się usunąć konta');
      }
    } finally {
      setDeleting(false);
    }
  };

  const formatPln = (val: number) => {
    return new Intl.NumberFormat('pl-PL', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(val);
  };

  const totalBalance = accounts.reduce((sum, account) => sum + account.starting_balance, 0);

  // Loading skeleton
  if (isPending) {
    return (
      <div className="space-y-6 max-w-6xl mx-auto w-full px-4" aria-busy="true">
        <div className="space-y-2">
          <Skeleton className="h-8 w-64" />
          <Skeleton className="h-4 w-80" />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-4">
            <Skeleton className="h-96 w-full rounded-2xl" />
          </div>
          <div>
            <Skeleton className="h-80 w-full rounded-2xl" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-6xl mx-auto w-full px-4">
      <div>
        <h2 className="text-2xl font-semibold text-slate-100">Zarządzanie kontami</h2>
        <p className="text-slate-400 text-sm">Zarządzaj swoimi kontami bankowymi i saldami początkowymi</p>
      </div>

      {error && (
        <div role="alert" className="p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
          {error}
        </div>
      )}

      {success && (
        <div className="p-4 bg-emerald-950/50 border border-emerald-800 rounded-lg text-emerald-300 text-sm">
          {success}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left panel — Account list table */}
        <div className="lg:col-span-2 space-y-4">
          <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 shadow-xl">
            <h3 className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider">
              Lista kont
            </h3>

            {accounts.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-slate-400 text-sm font-semibold mb-1">Brak zapisanych kont</p>
                <p className="text-slate-500 text-xs">Dodaj pierwsze konto, aby rozpocząć śledzenie sald.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-300">
                  <thead className="text-xs uppercase bg-slate-950 text-slate-400 border-b border-slate-800">
                    <tr>
                      <th className="px-4 py-3 font-semibold">Nazwa</th>
                      <th className="px-4 py-3 font-semibold">Typ</th>
                      <th className="px-4 py-3 font-semibold text-center">Waluta</th>
                      <th className="px-4 py-3 font-semibold text-right">Saldo początkowe</th>
                      <th className="px-4 py-3 font-semibold text-right">Data salda</th>
                      <th className="px-4 py-3 font-semibold text-center">Akcje</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/40">
                    {accounts.map((account) => {
                      const isEditing = editingId === account.id;
                      return (
                        <tr key={account.id} className="hover:bg-slate-900/30 transition-colors">
                          <td className="px-4 py-3">
                            {isEditing ? (
                              <input
                                type="text"
                                className="w-full bg-slate-950 border border-slate-800 rounded px-2 py-1 text-slate-200 outline-none focus:border-blue-500 text-sm"
                                value={editingName}
                                onChange={(e) => setEditingName(e.target.value)}
                              />
                            ) : (
                              <span className="font-medium text-slate-200">{account.name}</span>
                            )}
                          </td>
                          <td className="px-4 py-3">
                            {account.type === 'business' ? (
                              <span className="inline-block bg-blue-950/50 text-blue-400 border border-blue-900/60 text-xs px-2 py-0.5 rounded-full font-semibold">
                                Firmowe
                              </span>
                            ) : (
                              <span className="inline-block bg-emerald-950/50 text-emerald-400 border border-emerald-900/60 text-xs px-2 py-0.5 rounded-full font-semibold">
                                Osobiste
                              </span>
                            )}
                          </td>
                          <td className="px-4 py-3 text-center text-slate-400">
                            {account.currency}
                          </td>
                          <td className="px-4 py-3 text-right">
                            {isEditing ? (
                              <input
                                type="number"
                                step="0.01"
                                min="0"
                                className="w-28 bg-slate-950 border border-slate-800 rounded px-2 py-1 text-slate-200 outline-none focus:border-blue-500 text-sm text-right"
                                value={editingBalance}
                                onChange={(e) => setEditingBalance(e.target.value)}
                              />
                            ) : (
                              <span className="font-semibold text-emerald-400">
                                {formatPln(account.starting_balance)} PLN
                              </span>
                            )}
                          </td>
                          <td className="px-4 py-3 text-right">
                            {isEditing ? (
                              <input
                                type="date"
                                className="w-36 bg-slate-950 border border-slate-800 rounded px-2 py-1 text-slate-200 outline-none focus:border-blue-500 text-sm"
                                value={editingBalanceDate}
                                onChange={(e) => setEditingBalanceDate(e.target.value)}
                              />
                            ) : (
                              <span className="text-slate-400">{formatDate(account.starting_balance_date)}</span>
                            )}
                          </td>
                          <td className="px-4 py-3 text-center">
                            {isEditing ? (
                              <div className="flex justify-center space-x-2">
                                <button
                                  onClick={() => handleSaveEdit(account.id)}
                                  disabled={savingId === account.id}
                                  className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-500 disabled:bg-slate-800 disabled:text-slate-500 rounded text-xs text-white font-semibold transition-colors"
                                >
                                  {savingId === account.id ? 'Zapisywanie...' : 'Zapisz'}
                                </button>
                                <button
                                  onClick={handleCancelEdit}
                                  disabled={savingId === account.id}
                                  className="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 disabled:opacity-50 rounded text-xs text-slate-300 font-semibold transition-colors"
                                >
                                  Anuluj
                                </button>
                              </div>
                            ) : (
                              <div className="flex justify-center space-x-2">
                                <button
                                  onClick={() => handleStartEdit(account)}
                                  className="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 rounded text-xs text-blue-400 font-semibold transition-colors border border-slate-700/50"
                                >
                                  Edytuj
                                </button>
                                <button
                                  onClick={() => setDeleteTarget({ id: account.id, name: account.name })}
                                  className="px-2.5 py-1 bg-red-950/40 hover:bg-red-900/40 border border-red-900/60 rounded text-xs text-red-400 font-semibold transition-colors"
                                >
                                  Usuń
                                </button>
                              </div>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Total balance summary */}
          {accounts.length > 0 && (
            <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 flex justify-between items-center shadow-lg">
              <span className="text-sm font-semibold text-slate-400 uppercase tracking-wider">
                Całkowite saldo początkowe
              </span>
              <span className="text-2xl font-bold text-slate-100">
                {formatPln(totalBalance)} PLN
              </span>
            </div>
          )}
        </div>

        {/* Right panel — Create form */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 shadow-xl h-fit">
          <h3 className="text-sm font-semibold text-slate-400 mb-6 uppercase tracking-wider">
            Dodaj nowe konto
          </h3>
          <form onSubmit={handleAddAccount} className="space-y-4">
            <div>
              <label htmlFor="account-name" className="block text-slate-300 text-xs font-semibold mb-2">
                Nazwa konta
              </label>
              <input
                id="account-name"
                type="text"
                required
                placeholder="np. ING Business, IPKO Personal"
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
              />
            </div>

            <div>
              <label htmlFor="account-type" className="block text-slate-300 text-xs font-semibold mb-2">
                Typ konta
              </label>
              <select
                id="account-type"
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
                value={newType}
                onChange={(e) => setNewType(e.target.value)}
              >
                <option value="personal">Osobiste</option>
                <option value="business">Firmowe</option>
              </select>
            </div>

            <div>
              <label htmlFor="account-currency" className="block text-slate-300 text-xs font-semibold mb-2">
                Waluta
              </label>
              <input
                id="account-currency"
                type="text"
                disabled
                value="PLN"
                className="w-full bg-slate-950/60 border border-slate-800 rounded-lg px-4 py-3 text-slate-500 text-sm"
              />
            </div>

            <div>
              <label htmlFor="account-balance" className="block text-slate-300 text-xs font-semibold mb-2">
                Saldo początkowe (PLN)
              </label>
              <input
                id="account-balance"
                type="number"
                step="0.01"
                min="0"
                placeholder="0.00"
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
                value={newStartingBalance}
                onChange={(e) => setNewStartingBalance(e.target.value)}
              />
            </div>

            <div>
              <label htmlFor="account-balance-date" className="block text-slate-300 text-xs font-semibold mb-2">
                Data salda początkowego
              </label>
              <input
                id="account-balance-date"
                type="date"
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
                value={newStartingBalanceDate}
                onChange={(e) => setNewStartingBalanceDate(e.target.value)}
              />
            </div>

            <button
              type="submit"
              disabled={
                submitting ||
                !newName.trim() ||
                (newStartingBalance.trim() !== '' && (isNaN(parseFloat(newStartingBalance)) || parseFloat(newStartingBalance) < 0))
              }
              className={`w-full py-3 px-6 rounded-xl font-semibold text-white shadow-lg transition-all duration-300 ${
                submitting || !newName.trim() || (newStartingBalance.trim() !== '' && (isNaN(parseFloat(newStartingBalance)) || parseFloat(newStartingBalance) < 0))
                  ? 'bg-slate-800 text-slate-500 cursor-not-allowed shadow-none'
                  : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 hover:shadow-blue-500/20 active:scale-95'
              }`}
            >
              {submitting ? 'Dodawanie...' : 'Dodaj konto'}
            </button>
          </form>
        </div>
      </div>

      {/* Delete confirmation modal */}
      {deleteTarget && (
        <TypedDeleteConfirmModal
          isOpen={!!deleteTarget}
          accountName={deleteTarget.name}
          onConfirm={handleDeleteConfirm}
          onClose={() => setDeleteTarget(null)}
        />
      )}
    </div>
  );
}
