import React, { useState, useEffect, useRef } from 'react';
import { startExcelMigration, getMigrationStatus } from '../api';
import DestructiveConfirmModal from '../components/DestructiveConfirmModal';
import ProgressBar from '../components/ProgressBar';

interface MigrationJob {
  id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  total_rows: number | null;
  processed: number;
  errors: string[] | null;
}

type PageState = 'idle' | 'processing' | 'success' | 'failed';

const MAX_FILE_SIZE_BYTES = 20 * 1024 * 1024; // 20MB
const POLL_INTERVAL_MS = 2000;

interface MigrationPageProps {
  onMigrationComplete?: () => void;
}

export default function MigrationPage({ onMigrationComplete }: MigrationPageProps) {
  const [pageState, setPageState] = useState<PageState>('idle');
  const [file, setFile] = useState<File | null>(null);
  const [isDragActive, setIsDragActive] = useState<boolean>(false);
  const [fileError, setFileError] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [job, setJob] = useState<MigrationJob | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const pollIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const stopPolling = () => {
    if (pollIntervalRef.current) {
      clearInterval(pollIntervalRef.current);
      pollIntervalRef.current = null;
    }
  };

  useEffect(() => {
    return () => stopPolling();
  }, []);

  const validateAndSetFile = (selectedFile: File) => {
    setFileError(null);
    if (!selectedFile.name.toLowerCase().endsWith('.xlsx')) {
      setFileError('Obsługiwane są tylko skoroszyty Excel .xlsx');
      setFile(null);
      return;
    }
    if (selectedFile.size >= MAX_FILE_SIZE_BYTES) {
      setFileError('Obsługiwane są tylko skoroszyty Excel .xlsx');
      setFile(null);
      return;
    }
    setFile(selectedFile);
  };

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setIsDragActive(true);
    } else if (e.type === 'dragleave') {
      setIsDragActive(false);
    }
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

  const clearSelection = (e: React.MouseEvent) => {
    e.stopPropagation();
    setFile(null);
    setFileError(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes >= 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
    return `${(bytes / 1024).toFixed(1)} KB`;
  };

  const pollStatus = (jobId: string) => {
    const fetchStatus = () => {
      getMigrationStatus(jobId)
        .then((data: MigrationJob) => {
          setJob(data);
          if (data.status === 'completed') {
            stopPolling();
            setPageState('success');
          } else if (data.status === 'failed') {
            stopPolling();
            const errs = data.errors || [];
            setErrorMessage(errs.length > 0 ? errs[errs.length - 1] : 'Unknown error');
            setPageState('failed');
          }
        })
        .catch((err: any) => {
          stopPolling();
          setErrorMessage(err.message || 'Nie udało się pobrać statusu migracji');
          setPageState('failed');
        });
    };

    pollIntervalRef.current = setInterval(fetchStatus, POLL_INTERVAL_MS);
    fetchStatus();
  };

  const handleStartIngestion = () => {
    if (!file) return;
    setIsModalOpen(true);
  };

  const handleConfirmMigration = async () => {
    if (!file) return;
    setIsModalOpen(false);
    setErrorMessage(null);
    setJob(null);
    setPageState('processing');
    try {
      const data = await startExcelMigration(file);
      pollStatus(data.job_id);
    } catch (err: any) {
      setErrorMessage(err.message || 'Nie udało się rozpocząć migracji');
      setPageState('failed');
    }
  };

  const handleTryAgain = () => {
    stopPolling();
    setJob(null);
    setErrorMessage(null);
    setFile(null);
    setFileError(null);
    setPageState('idle');
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleGoToDashboard = () => {
    if (onMigrationComplete) {
      onMigrationComplete();
    } else {
      window.location.pathname = '/dashboard';
    }
  };

  // ---- Processing State ----
  if (pageState === 'processing') {
    const total = job?.total_rows || 0;
    const processed = job?.processed || 0;
    const percent = total > 0 ? (processed / total) * 100 : 0;
    const details = total > 0
      ? `Przetwarzanie wiersza ${processed} z ${total}`
      : 'Przygotowywanie skoroszytu...';

    return (
      <div className="bg-slate-950 text-slate-100 min-h-screen p-8 flex flex-col items-center justify-center">
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-8 max-w-md w-full shadow-2xl space-y-6 text-center">
          <svg
            className="animate-spin h-12 w-12 text-blue-500 mx-auto"
            fill="none"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
          <div className="space-y-2">
            <h2 className="text-2xl font-semibold text-slate-100">Trwa importowanie danych z Excela...</h2>
            <p className="text-sm font-normal text-slate-400">
              Proszę trzymać tę kartę otwartą i nie opuszczać strony. Może to zająć do minuty.
            </p>
          </div>
          <ProgressBar percent={percent} details={details} />
        </div>
      </div>
    );
  }

  // ---- Success State ----
  if (pageState === 'success') {
    return (
      <div className="bg-slate-950 text-slate-100 min-h-screen p-8 flex flex-col items-center justify-center">
        <div className="bg-slate-900 border border-slate-800 p-8 rounded-xl max-w-md text-center space-y-4">
          <svg
            className="w-12 h-12 text-green-500 mx-auto"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
          <h2 className="text-2xl font-semibold text-slate-100">Migracja zakończona</h2>
          <p className="text-sm font-normal text-slate-400">
            Wszystkie arkusze historyczne zostały pomyślnie przetworzone. Istniejące dane zostały wyczyszczone i zastąpione historycznymi wpisami z pliku budget.xlsx.
          </p>
          <button
            onClick={handleGoToDashboard}
            className="w-full py-3 px-6 rounded-lg font-semibold text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 transition-all"
          >
            Przejdź do Dashboardu
          </button>
        </div>
      </div>
    );
  }

  // ---- Failed State ----
  if (pageState === 'failed') {
    return (
      <div className="bg-slate-950 text-slate-100 min-h-screen p-8 flex flex-col items-center justify-center">
        <div className="bg-slate-900 border border-slate-800 p-8 rounded-xl max-w-md text-center space-y-4">
          <svg
            className="w-12 h-12 text-red-500 mx-auto"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z" />
          </svg>
          <h2 className="text-2xl font-semibold text-slate-100">Migracja nie powiodła się</h2>
          <p className="text-sm font-normal text-slate-400">
            Wystąpił błąd podczas przetwarzania arkusza. Transakcja bazy danych została wycofana. Błąd: {errorMessage || 'Nieznany błąd'}
          </p>
          <button
            onClick={handleTryAgain}
            className="w-full py-3 px-6 rounded-lg font-semibold text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 transition-all"
          >
            Spróbuj ponownie
          </button>
        </div>
      </div>
    );
  }

  // ---- Idle / Dropzone State ----
  return (
    <div className="bg-slate-950 text-slate-100 min-h-screen p-8 flex flex-col items-center justify-center">
      <div className="max-w-xl w-full flex flex-col items-center gap-6">
        <div className="text-center space-y-1">
          <h1 className="text-2xl font-semibold text-slate-100">Migracja danych z pliku Excel</h1>
          <p className="text-sm font-normal text-slate-400">
            Przeciągnij i upuść budget.xlsx tutaj lub kliknij, aby wybrać z dysku
          </p>
        </div>

        <div
          onDragEnter={handleDrag}
          onDragOver={handleDrag}
          onDragLeave={handleDrag}
          onDrop={handleDrop}
          onClick={() => fileInputRef.current?.click()}
          className={`border-2 border-dashed p-12 rounded-xl text-center cursor-pointer max-w-xl w-full flex flex-col items-center gap-4 transition-all ${
            fileError
              ? 'border-red-800 bg-slate-900/50'
              : isDragActive
                ? 'border-blue-500 bg-blue-950/20'
                : 'border-slate-800 bg-slate-900/50'
          }`}
        >
          <input
            type="file"
            ref={fileInputRef}
            onChange={handleFileChange}
            accept=".xlsx"
            className="hidden"
            aria-label="Upload Excel workbook"
          />

          <svg
            className="w-12 h-12 text-slate-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
            />
          </svg>

          {file ? (
            <div className="flex items-center gap-3">
              <div className="text-center">
                <p className="text-sm font-semibold text-slate-100">{file.name}</p>
                <p className="text-sm font-normal text-slate-400">{formatFileSize(file.size)}</p>
              </div>
              <button
                onClick={clearSelection}
                aria-label="Remove file"
                className="text-slate-500 hover:text-red-400 transition-colors"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6M9 7V4a1 1 0 011-1h4a1 1 0 011 1v3M4 7h16"
                  />
                </svg>
              </button>
            </div>
          ) : (
            <div className="text-center space-y-1">
              <p className="text-sm font-normal text-slate-300">
                Przeciągnij i upuść budget.xlsx tutaj lub kliknij, aby wybrać z dysku
              </p>
              <p className="text-sm font-normal text-slate-500">
                Akceptowane są tylko arkusze .xlsx. Maksymalny rozmiar: 20MB.
              </p>
            </div>
          )}
        </div>

        {fileError && (
          <p role="alert" className="text-sm font-normal text-red-400">
            {fileError}
          </p>
        )}

        <button
          onClick={handleStartIngestion}
          disabled={!file}
          className={`w-full py-3 px-6 rounded-lg font-semibold text-white transition-all ${
            file
              ? 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 cursor-pointer'
              : 'bg-gradient-to-r from-blue-600 to-indigo-600 opacity-50 cursor-not-allowed'
          }`}
        >
          Rozpocznij import
        </button>
      </div>

      <DestructiveConfirmModal
        isOpen={isModalOpen}
        onConfirm={handleConfirmMigration}
        onClose={() => setIsModalOpen(false)}
      />
    </div>
  );
}
