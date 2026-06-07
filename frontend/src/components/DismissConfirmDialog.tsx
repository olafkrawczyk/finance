import React from 'react';

interface DismissConfirmDialogProps {
  isOpen: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  insightTitle: string;
}

export default function DismissConfirmDialog({ isOpen, onConfirm, onCancel, insightTitle }: DismissConfirmDialogProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 max-w-sm w-full mx-4 shadow-2xl space-y-4">
        <div>
          <h3 className="text-lg font-semibold text-slate-100 mb-2">
            Odrzucić tę wskazówkę?
          </h3>
          <p className="text-sm text-slate-400">
            Nie pojawi się ona ponownie.
          </p>
          {insightTitle && (
            <p className="text-xs text-slate-500 italic mt-2 line-clamp-2">
              "{insightTitle}"
            </p>
          )}
        </div>
        
        <div className="flex justify-end gap-3 pt-2">
          <button
            onClick={onCancel}
            className="px-4 py-2 rounded-lg text-sm font-semibold text-slate-300 hover:text-slate-100 bg-slate-800 hover:bg-slate-700 transition-colors cursor-pointer"
          >
            Anuluj
          </button>
          <button
            onClick={onConfirm}
            className="px-4 py-2 rounded-lg text-sm font-semibold text-red-300 bg-red-950/50 border border-red-800 hover:bg-red-900/50 transition-colors cursor-pointer"
          >
            Odrzuć
          </button>
        </div>
      </div>
    </div>
  );
}
