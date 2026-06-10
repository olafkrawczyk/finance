import React, { useState, useEffect, useRef } from 'react';

interface TypedDeleteConfirmModalProps {
  isOpen: boolean;
  accountName: string;
  onConfirm: () => void;
  onClose: () => void;
}

export default function TypedDeleteConfirmModal({
  isOpen,
  accountName,
  onConfirm,
  onClose,
}: TypedDeleteConfirmModalProps) {
  const [typedText, setTypedText] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);

  const challengePhrase = `DELETE ${accountName}`;
  const isMatch = typedText === challengePhrase;

  // Reset input when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      setTypedText('');
      // Auto-focus input on open
      setTimeout(() => {
        inputRef.current?.focus();
      }, 50);
    }
  }, [isOpen]);

  // Escape key listener
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  const handleOverlayClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  const handleConfirm = () => {
    if (!isMatch) return;
    setTypedText('');
    onConfirm();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && isMatch) {
      handleConfirm();
    }
  };

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 flex items-center justify-center p-4"
      onClick={handleOverlayClick}
    >
      <div className="bg-slate-900 border border-slate-800 rounded-xl p-8 max-w-md w-full shadow-2xl space-y-6">
        <h2 className="text-lg font-semibold text-slate-100">
          Usunięcie konta
        </h2>

        <div className="bg-red-950/50 border border-red-800 text-slate-100 rounded-lg p-4 flex gap-3 items-start">
          <div className="space-y-1">
            <p className="text-sm">
              Ta operacja jest nieodwracalna. Usunięcie konta trwale usunie wszystkie dane tego konta.
            </p>
            <p className="text-sm font-semibold text-red-300">
              Konto: {accountName}
            </p>
          </div>
        </div>

        <div>
          <p className="text-sm text-slate-300 mb-2">
            Aby potwierdzić, wpisz DELETE {accountName}:
          </p>
          <input
            ref={inputRef}
            type="text"
            value={typedText}
            onChange={(e) => setTypedText(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={`DELETE ${accountName}`}
            className="w-full bg-slate-950 border border-slate-800 rounded px-3 py-2 text-slate-100 outline-none focus:border-blue-500 text-sm"
          />
        </div>

        <div className="flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 rounded-lg text-sm font-semibold text-slate-300 bg-slate-900 border border-slate-800 hover:bg-slate-800 transition-colors"
          >
            Anuluj
          </button>
          <button
            onClick={handleConfirm}
            disabled={!isMatch}
            className={`flex-1 px-4 py-2 rounded-lg text-sm font-semibold text-white transition-colors ${
              isMatch
                ? 'bg-red-800 border border-red-800 hover:bg-red-700 cursor-pointer'
                : 'bg-red-800/50 border border-red-800 opacity-50 cursor-not-allowed'
            }`}
          >
            Usuń konto
          </button>
        </div>
      </div>
    </div>
  );
}
