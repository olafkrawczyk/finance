import React, { useState, useEffect } from 'react';
import { getAssets, createAsset, updateAsset, deleteAsset } from '../api';

interface Asset {
  id: string;
  name: string;
  value: number;
}

export default function AssetsPage() {
  const [assets, setAssets] = useState<Asset[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // New Asset form state
  const [newName, setNewName] = useState<string>('');
  const [newValue, setNewValue] = useState<string>('');
  const [submitting, setSubmitting] = useState<boolean>(false);

  // Inline editing state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editingName, setEditingName] = useState<string>('');
  const [editingValue, setEditingValue] = useState<string>('');
  const [savingId, setSavingId] = useState<string | null>(null);

  useEffect(() => {
    fetchAssets();
  }, []);

  const fetchAssets = () => {
    setLoading(true);
    setError(null);
    getAssets()
      .then((data) => {
        const parsed = (data ?? []).map((a: any) => ({
          id: a.id,
          name: a.name,
          value: parseFloat(a.value),
        }));
        setAssets(parsed);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'Failed to load assets');
        setLoading(false);
      });
  };

  const handleAddAsset = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) {
      setError('Nazwa aktywa nie może być pusta');
      return;
    }
    const val = parseFloat(newValue);
    if (isNaN(val) || val < 0) {
      setError('Wartość musi być liczbą większą lub równą 0');
      return;
    }

    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const created = await createAsset({
        name: newName.trim(),
        value: val,
      });
      setSuccess('Pomyślnie dodano nowe aktywo');
      setNewName('');
      setNewValue('');
      setAssets((prev) => [...prev, { id: created.id, name: created.name, value: parseFloat(created.value) }]);
    } catch (err: any) {
      setError(err.message || 'Nie udało się dodać aktywa');
    } finally {
      setSubmitting(false);
    }
  };

  const handleStartEdit = (asset: Asset) => {
    setEditingId(asset.id);
    setEditingName(asset.name);
    setEditingValue(String(asset.value));
    setError(null);
    setSuccess(null);
  };

  const handleCancelEdit = () => {
    setEditingId(null);
    setEditingName('');
    setEditingValue('');
  };

  const handleSaveEdit = async (id: string) => {
    if (!editingName.trim()) {
      setError('Nazwa aktywa nie może być pusta');
      return;
    }
    const val = parseFloat(editingValue);
    if (isNaN(val) || val < 0) {
      setError('Wartość musi być liczbą większą lub równą 0');
      return;
    }

    setSavingId(id);
    setError(null);
    setSuccess(null);

    try {
      const updated = await updateAsset(id, {
        name: editingName.trim(),
        value: val,
      });
      setAssets((prev) =>
        prev.map((a) => (a.id === id ? { ...a, name: updated.name, value: parseFloat(updated.value) } : a))
      );
      setSuccess('Pomyślnie zaktualizowano aktywo');
      handleCancelEdit();
    } catch (err: any) {
      setError(err.message || 'Nie udało się zaktualizować aktywa');
    } finally {
      setSavingId(null);
    }
  };

  const handleDeleteAsset = async (id: string) => {
    if (!window.confirm('Czy na pewno chcesz usunąć to aktywo?')) {
      return;
    }

    setError(null);
    setSuccess(null);

    try {
      await deleteAsset(id);
      setAssets((prev) => prev.filter((a) => a.id !== id));
      setSuccess('Pomyślnie usunięto aktywo');
    } catch (err: any) {
      setError(err.message || 'Nie udało się usunąć aktywa');
    }
  };

  const formatPln = (val: number) => {
    return new Intl.NumberFormat('pl-PL', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(val);
  };

  const totalSum = assets.reduce((sum, asset) => sum + asset.value, 0);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
        <p className="text-slate-400 mt-4 text-sm font-medium">Ładowanie aktywów...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-6xl mx-auto w-full px-4">
      <div>
        <h2 className="text-2xl font-semibold text-slate-100 font-medium">Zarządzanie aktywami</h2>
        <p className="text-slate-400 text-sm">Śledź ręcznie swoje aktywa i oszczędności</p>
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Assets List */}
        <div className="lg:col-span-2 space-y-4">
          <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 shadow-xl">
            <h3 className="text-sm font-semibold text-slate-400 mb-4 uppercase tracking-wider">
              Lista aktywów
            </h3>

            {assets.length === 0 ? (
              <div className="text-center py-8 text-slate-500 text-sm">
                Brak zapisanych aktywów. Dodaj pierwsze aktywo po prawej stronie.
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-300">
                  <thead className="text-xs uppercase bg-slate-950 text-slate-400 border-b border-slate-800">
                    <tr>
                      <th className="px-4 py-3 font-semibold">Nazwa</th>
                      <th className="px-4 py-3 font-semibold text-right">Wartość</th>
                      <th className="px-4 py-3 font-semibold text-center w-40">Akcje</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/40">
                    {assets.map((asset) => {
                      const isEditing = editingId === asset.id;
                      return (
                        <tr key={asset.id} className="hover:bg-slate-900/30 transition-colors">
                          <td className="px-4 py-3">
                            {isEditing ? (
                              <input
                                type="text"
                                className="w-full bg-slate-950 border border-slate-800 rounded px-2 py-1 text-slate-200 outline-none focus:border-blue-500 text-sm"
                                value={editingName}
                                onChange={(e) => setEditingName(e.target.value)}
                              />
                            ) : (
                              <span className="font-medium text-slate-200">{asset.name}</span>
                            )}
                          </td>
                          <td className="px-4 py-3 text-right">
                            {isEditing ? (
                              <input
                                type="number"
                                step="0.01"
                                min="0"
                                className="w-32 bg-slate-950 border border-slate-800 rounded px-2 py-1 text-slate-200 outline-none focus:border-blue-500 text-sm text-right"
                                value={editingValue}
                                onChange={(e) => setEditingValue(e.target.value)}
                              />
                            ) : (
                              <span className="font-semibold text-emerald-400">
                                {formatPln(asset.value)} PLN
                              </span>
                            )}
                          </td>
                          <td className="px-4 py-3 text-center">
                            {isEditing ? (
                              <div className="flex justify-center space-x-2">
                                <button
                                  onClick={() => handleSaveEdit(asset.id)}
                                  disabled={savingId === asset.id}
                                  className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-500 disabled:bg-slate-800 disabled:text-slate-500 rounded text-xs text-white font-medium transition-colors"
                                >
                                  {savingId === asset.id ? 'Zapisywanie...' : 'Zapisz'}
                                </button>
                                <button
                                  onClick={handleCancelEdit}
                                  disabled={savingId === asset.id}
                                  className="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 disabled:opacity-50 rounded text-xs text-slate-300 font-medium transition-colors"
                                >
                                  Anuluj
                                </button>
                              </div>
                            ) : (
                              <div className="flex justify-center space-x-2">
                                <button
                                  onClick={() => handleStartEdit(asset)}
                                  className="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 rounded text-xs text-blue-400 font-medium transition-colors border border-slate-700/50"
                                >
                                  Edytuj
                                </button>
                                <button
                                  onClick={() => handleDeleteAsset(asset.id)}
                                  className="px-2.5 py-1 bg-red-950/40 hover:bg-red-900/40 border border-red-900/60 rounded text-xs text-red-400 font-medium transition-colors"
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

          {/* Sum Summary Card */}
          <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 flex justify-between items-center shadow-lg">
            <span className="text-sm font-semibold text-slate-400 uppercase tracking-wider">
              Całkowita wartość aktywów
            </span>
            <span className="text-2xl font-bold text-slate-100">
              {formatPln(totalSum)} PLN
            </span>
          </div>
        </div>

        {/* Add Asset Form Card */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-6 shadow-xl h-fit">
          <h3 className="text-sm font-semibold text-slate-400 mb-6 uppercase tracking-wider">
            Dodaj nowe aktywo
          </h3>
          <form onSubmit={handleAddAsset} className="space-y-4">
            <div>
              <label htmlFor="asset-name" className="block text-slate-300 text-xs font-semibold mb-2">
                Nazwa aktywa
              </label>
              <input
                id="asset-name"
                type="text"
                required
                placeholder="np. Portfel akcji, Oszczędności w gotówce"
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
              />
            </div>

            <div>
              <label htmlFor="asset-value" className="block text-slate-300 text-xs font-semibold mb-2">
                Wartość (PLN)
              </label>
              <input
                id="asset-value"
                type="number"
                step="0.01"
                min="0"
                required
                placeholder="0.00"
                className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
                value={newValue}
                onChange={(e) => setNewValue(e.target.value)}
              />
            </div>

            <button
              type="submit"
              disabled={submitting || !newName.trim() || !newValue || parseFloat(newValue) < 0}
              className={`w-full py-3 px-6 rounded-xl font-semibold text-white shadow-lg transition-all duration-300 ${
                submitting || !newName.trim() || !newValue || parseFloat(newValue) < 0
                  ? 'bg-slate-800 text-slate-500 cursor-not-allowed shadow-none'
                  : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 hover:shadow-blue-500/20 active:scale-95'
              }`}
            >
              {submitting ? 'Dodawanie...' : 'Dodaj aktywo'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
