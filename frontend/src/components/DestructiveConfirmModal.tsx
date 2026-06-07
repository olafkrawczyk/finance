import React, { useState } from 'react';

interface DestructiveConfirmModalProps {
  isOpen: boolean;
  onConfirm: () => void;
  onClose: () => void;
}

const CHALLENGE_PHRASE = 'MIGRATE';

export default function DestructiveConfirmModal({ isOpen, onConfirm, onClose }: DestructiveConfirmModalProps) {
  const [challengeInput, setChallengeInput] = useState<string>('');

  if (!isOpen) return null;

  const isConfirmEnabled = challengeInput === CHALLENGE_PHRASE;

  const handleCancel = () => {
    setChallengeInput('');
    onClose();
  };

  const handleConfirm = () => {
    if (!isConfirmEnabled) return;
    setChallengeInput('');
    onConfirm();
  };

  return (
    <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-xl p-8 max-w-md w-full shadow-2xl space-y-6">
        <div className="bg-red-950/50 border border-red-800 text-slate-100 rounded-lg p-4 flex gap-3 items-start">
          <svg
            className="w-6 h-6 text-red-400 flex-shrink-0 mt-0.5"
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
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
          <div className="space-y-2">
            <h3 className="text-sm font-semibold">⚠️ Permanent Data Reset</h3>
            <p className="text-sm font-normal">
              This action is highly destructive and cannot be undone. Initiating the migration will permanently wipe all existing transactions, monthly opening balances, AI insights, and import jobs from the database. A clean initialization will then proceed using the data from the uploaded Excel workbook. Are you absolutely sure you want to proceed?
            </p>
          </div>
        </div>

        <div className="space-y-2">
          <label htmlFor="migrate-challenge-input" className="block text-sm font-semibold text-slate-300">
            Type 'MIGRATE' to confirm:
          </label>
          <input
            id="migrate-challenge-input"
            type="text"
            value={challengeInput}
            onChange={(e) => setChallengeInput(e.target.value)}
            className="border border-slate-800 bg-slate-950 text-slate-100 px-3 py-2 rounded focus:outline-none focus:border-blue-500 w-full"
            autoComplete="off"
            spellCheck={false}
          />
        </div>

        <div className="flex gap-3">
          <button
            onClick={handleCancel}
            className="flex-1 px-4 py-2 rounded-lg text-sm font-semibold text-slate-300 bg-slate-900 border border-slate-800 hover:bg-slate-800 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleConfirm}
            disabled={!isConfirmEnabled}
            className={`flex-1 px-4 py-2 rounded-lg text-sm font-semibold text-white bg-red-800 border border-red-800 transition-colors ${
              isConfirmEnabled ? 'hover:bg-red-700 cursor-pointer' : 'opacity-50 cursor-not-allowed'
            }`}
          >
            Yes, Wipe Data and Migrate
          </button>
        </div>
      </div>
    </div>
  );
}
