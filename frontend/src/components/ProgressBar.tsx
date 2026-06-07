import React from 'react';

interface ProgressBarProps {
  percent: number;
  details?: string;
}

export default function ProgressBar({ percent, details }: ProgressBarProps) {
  const clamped = Math.min(100, Math.max(0, percent));

  return (
    <div className="w-full space-y-2">
      <div className="flex justify-between items-center text-sm">
        <span className="text-slate-400 font-normal">{details || ''}</span>
        <span className="text-slate-100 font-semibold">{Math.round(clamped)}%</span>
      </div>
      <div className="w-full bg-slate-950 rounded-full h-3 overflow-hidden border border-slate-800">
        <div
          role="progressbar"
          aria-valuenow={Math.round(clamped)}
          aria-valuemin={0}
          aria-valuemax={100}
          className="bg-gradient-to-r from-blue-600 to-indigo-600 h-full transition-all duration-300"
          style={{ width: `${clamped}%` }}
        />
      </div>
    </div>
  );
}
