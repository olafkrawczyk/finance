import React, { useState, useEffect, useRef } from 'react';
import { getAccounts, startImport } from '../api';

interface Account {
  id: string;
  name: string;
  type: string;
  currency: string;
}

interface ImportUploadProps {
  onImportStarted: (jobId: string) => void;
}

export default function ImportUpload({ onImportStarted }: ImportUploadProps) {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [selectedAccount, setSelectedAccount] = useState<string>('');
  const [bankFormat, setBankFormat] = useState<'ing' | 'ipko'>('ing');
  const [file, setFile] = useState<File | null>(null);
  const [isDragActive, setIsDragActive] = useState<boolean>(false);
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    getAccounts()
      .then((data) => {
        setAccounts(data);
        if (data.length > 0) {
          setSelectedAccount(data[0].id);
        }
      })
      .catch((err) => {
        setError(err.message || 'Nie udało się załadować kont');
      });
  }, []);

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setIsDragActive(true);
    } else if (e.type === 'dragleave') {
      setIsDragActive(false);
    }
  };

  const validateAndSetFile = (selectedFile: File) => {
    setError(null);
    if (!selectedFile.name.endsWith('.csv')) {
      setError('Nieprawidłowy typ pliku: Akceptowane są tylko pliki CSV.');
      setFile(null);
      return;
    }
    if (selectedFile.size > 10 * 1024 * 1024) {
      setError('Plik jest zbyt duży: Maksymalny rozmiar to 10MB.');
      setFile(null);
      return;
    }
    setFile(selectedFile);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragActive(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      validateAndSetFile(e.dataTransfer.files[0]);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      validateAndSetFile(e.target.files[0]);
    }
  };

  const handleUpload = async () => {
    if (!file || !selectedAccount) return;
    setIsUploading(true);
    setError(null);
    try {
      const data = await startImport(file, selectedAccount, bankFormat);
      onImportStarted(data.job_id);
    } catch (err: any) {
      setError(err.message || 'Przesyłanie nie powiodło się');
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="max-w-lg w-full mx-auto bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl shadow-2xl p-8 transition-all duration-300">
      <div className="mb-8 text-center">
        <h2 className="text-3xl font-semibold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 via-indigo-400 to-purple-400">
          Importuj transakcje
        </h2>
        <p className="text-slate-400 mt-2 text-sm">
          Prześlij wyciąg bankowy CSV, aby przetworzyć i zaimportować transakcje.
        </p>
      </div>

      {error && (
        <div role="alert" className="mb-6 p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
          {error}
        </div>
      )}

      <div className="space-y-6">
        {/* Account Select */}
        <div>
          <label htmlFor="account-select" className="block text-slate-300 text-sm font-semibold mb-2">
            Wybierz konto
          </label>
          <select
            id="account-select"
            className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
            value={selectedAccount}
            onChange={(e) => setSelectedAccount(e.target.value)}
          >
            {accounts.map((acc) => (
              <option key={acc.id} value={acc.id}>
                {acc.name} ({acc.currency})
              </option>
            ))}
          </select>
        </div>

        {/* Bank Format Select */}
        <div>
          <label htmlFor="format-select" className="block text-slate-300 text-sm font-semibold mb-2">
            Format wyciągu bankowego
          </label>
          <select
            id="format-select"
            className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
            value={bankFormat}
            onChange={(e) => setBankFormat(e.target.value as 'ing' | 'ipko')}
          >
            <option value="ing">ING Bank Śląski</option>
            <option value="ipko">PKO BP (IPKO)</option>
          </select>
        </div>

        {/* File Dropzone */}
        <div>
          <label className="block text-slate-300 text-sm font-semibold mb-2">
            Prześlij plik CSV
          </label>
          <div
            onDragEnter={handleDrag}
            onDragOver={handleDrag}
            onDragLeave={handleDrag}
            onDrop={handleDrop}
            onClick={() => fileInputRef.current?.click()}
            className={`flex flex-col items-center justify-center border-2 border-dashed rounded-xl p-8 cursor-pointer transition-all duration-300 ${
              isDragActive
                ? 'border-blue-500 bg-blue-950/20'
                : 'border-slate-800 hover:border-slate-700 bg-slate-950/40 hover:bg-slate-950/60'
            }`}
          >
            <input
              type="file"
              ref={fileInputRef}
              onChange={handleFileChange}
              accept=".csv"
              className="hidden"
              aria-label="Upload CSV file"
            />

            <svg
              className="w-12 h-12 text-slate-500 mb-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
              />
            </svg>

            {file ? (
              <div className="text-center">
                <p className="text-slate-200 font-medium">{file.name}</p>
                <p className="text-slate-500 text-xs mt-1">
                  {(file.size / 1024).toFixed(1)} KB
                </p>
              </div>
            ) : (
              <div className="text-center">
                <p className="text-slate-300">Przeciągnij i upuść plik CSV tutaj lub kliknij, aby wybrać</p>
                <p className="text-slate-500 text-xs mt-2">Tylko pliki wyciągów .csv do 10MB</p>
              </div>
            )}
          </div>
        </div>

        {/* Upload Button */}
        <button
          onClick={handleUpload}
          disabled={!file || !selectedAccount || isUploading}
          className={`w-full py-4 px-6 rounded-xl font-bold text-white shadow-lg transition-all duration-300 ${
            !file || !selectedAccount || isUploading
              ? 'bg-slate-800 text-slate-500 cursor-not-allowed shadow-none'
              : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 hover:shadow-blue-500/20 active:scale-95'
          }`}
        >
          {isUploading ? (
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
              Uploading File...
            </span>
          ) : (
            'Prześlij wyciąg'
          )}
        </button>
      </div>
    </div>
  );
}
