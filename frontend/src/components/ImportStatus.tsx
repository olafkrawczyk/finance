import React, { useState, useEffect } from 'react';
import { getImportStatus } from '../api';

interface ImportJob {
  id: string;
  account_id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  total_rows: number | null;
  processed: number;
  errors: string[] | null;
  created_at: string;
  updated_at: string;
}

interface ImportStatusProps {
  jobId: string;
  onBack: () => void;
  onCategorize?: () => void;
}

export default function ImportStatus({ jobId, onBack, onCategorize }: ImportStatusProps) {
  const [job, setJob] = useState<ImportJob | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isErrorsExpanded, setIsErrorsExpanded] = useState<boolean>(false);

  useEffect(() => {
    let intervalId: any;
    const startTime = Date.now();
    const TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes

    const fetchStatus = () => {
      // Check timeout
      if (Date.now() - startTime > TIMEOUT_MS) {
        setError('Polling timed out: Ingestion took longer than 5 minutes.');
        clearInterval(intervalId);
        return;
      }

      getImportStatus(jobId)
        .then((data) => {
          setJob(data);
          if (data.status === 'completed' || data.status === 'failed') {
            clearInterval(intervalId);
          }
        })
        .catch((err) => {
          setError(err.message || 'Failed to poll job status');
          clearInterval(intervalId);
        });
    };

    // Initial fetch
    fetchStatus();

    // Set up polling every 2s
    intervalId = setInterval(fetchStatus, 2000);

    return () => clearInterval(intervalId);
  }, [jobId]);

  if (error) {
    return (
      <div className="max-w-lg w-full mx-auto bg-slate-900 border border-slate-800 rounded-2xl p-8 shadow-2xl">
        <div role="alert" aria-live="assertive" className="mb-6 p-4 bg-red-950/50 border border-red-800 rounded-lg text-red-300 text-sm">
          {error}
        </div>
        <button
          onClick={onBack}
          className="w-full py-3 px-6 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl font-semibold transition-colors"
        >
          Back to Imports
        </button>
      </div>
    );
  }

  if (!job) {
    return (
      <div className="max-w-lg w-full mx-auto bg-slate-900 border border-slate-800 rounded-2xl p-8 shadow-2xl flex flex-col items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500"></div>
        <p className="text-slate-400 mt-4 text-sm">Loading job status...</p>
      </div>
    );
  }

  const total = job.total_rows || 0;
  const processed = job.processed || 0;
  const percent = total > 0 ? Math.round((processed / total) * 100) : 0;

  // Status mapping
  const statusConfig = {
    pending: {
      text: 'Pending',
      bgClass: 'bg-yellow-500/10 border-yellow-500/20 text-yellow-400',
      description: 'Job enqueued. Waiting for worker to start...',
    },
    processing: {
      text: 'Processing',
      bgClass: 'bg-blue-500/10 border-blue-500/20 text-blue-400',
      description: 'AI model is parsing statements and inserting transactions...',
    },
    completed: {
      text: 'Completed',
      bgClass: 'bg-green-500/10 border-green-500/20 text-green-400',
      description: 'Ingestion finished successfully!',
    },
    failed: {
      text: 'Failed',
      bgClass: 'bg-red-500/10 border-red-500/20 text-red-400',
      description: 'Ingestion failed. See details below.',
    },
  };

  const currentStatus = statusConfig[job.status] || {
    text: job.status,
    bgClass: 'bg-slate-500/10 border-slate-500/20 text-slate-400',
    description: '',
  };

  const jobErrors = job.errors || [];

  return (
    <div className="max-w-lg w-full mx-auto bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl shadow-2xl p-8 transition-all duration-300">
      <div className="mb-8 text-center">
        <h2 className="text-3xl font-semibold text-slate-100">Import Status</h2>
        <p className="text-slate-400 mt-1 text-xs font-mono select-all">Job ID: {jobId}</p>
      </div>

      <div className="space-y-6">
        {/* Status Badge */}
        <div className="flex flex-col items-center justify-center p-6 bg-slate-950/40 border border-slate-800/80 rounded-xl text-center">
          <span
            role="status"
            aria-live="polite"
            className={`px-4 py-1.5 rounded-full border text-xs font-bold uppercase tracking-wider ${currentStatus.bgClass}`}
          >
            {currentStatus.text}
          </span>
          <p className="text-slate-300 mt-4 text-sm font-medium">
            {currentStatus.description}
          </p>
        </div>

        {/* Progress Section */}
        {job.status !== 'pending' && (
          <div className="space-y-2">
            <div className="flex justify-between items-center text-sm">
              <span className="text-slate-400">Ingestion Progress</span>
              <span className="text-slate-200 font-bold">{percent}%</span>
            </div>
            {/* Progress Bar Container */}
            <div className="w-full bg-slate-950 rounded-full h-3 overflow-hidden border border-slate-800">
              <div
                role="progressbar"
                aria-valuenow={processed}
                aria-valuemin={0}
                aria-valuemax={total}
                className="bg-gradient-to-r from-blue-500 to-indigo-500 h-full rounded-full transition-all duration-500 ease-out"
                style={{ width: `${percent}%` }}
              />
            </div>
            <div className="flex justify-between items-center text-xs text-slate-500 mt-1">
              <span>Processed: {processed} rows</span>
              <span>Total: {total} rows</span>
            </div>
          </div>
        )}

        {/* Error List */}
        {jobErrors.length > 0 && (
          <div role="alert" aria-live="assertive" className="border border-red-900/50 bg-red-950/10 rounded-xl overflow-hidden">
            <button
              onClick={() => setIsErrorsExpanded(!isErrorsExpanded)}
              className="w-full px-4 py-3 flex justify-between items-center text-sm font-semibold text-red-300 hover:bg-red-950/20 transition-colors"
            >
              <span>Ingestion Errors ({jobErrors.length})</span>
              <svg
                className={`w-4 h-4 transition-transform duration-300 ${isErrorsExpanded ? 'rotate-180' : ''}`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>
            {isErrorsExpanded && (
              <ul className="border-t border-red-900/30 p-4 max-h-48 overflow-y-auto space-y-2 text-xs text-red-400 font-mono">
                {jobErrors.map((err, idx) => (
                  <li key={idx} className="flex items-start">
                    <span className="text-red-500 mr-2">•</span>
                    <span>{err}</span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}

        {/* Actions */}
        {job.status === 'completed' && onCategorize && (
          <button
            onClick={onCategorize}
            className="w-full py-4 px-6 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl font-bold transition-all duration-300 active:scale-95 shadow-lg mb-3"
          >
            Categorize Transactions
          </button>
        )}
        <button
          onClick={onBack}
          className="w-full py-4 px-6 bg-slate-950 border border-slate-800 hover:bg-slate-900 text-slate-200 rounded-xl font-bold transition-all duration-300 active:scale-95 shadow-sm"
        >
          Back to Imports
        </button>
      </div>
    </div>
  );
}
