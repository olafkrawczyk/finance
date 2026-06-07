import React from 'react';

type TabType = 'all' | 'alert' | 'trend' | 'tip' | 'forecast';

interface InsightsTabsProps {
  activeType: TabType;
  onTypeChange: (type: TabType) => void;
  counts?: Record<string, number>;
}

export default function InsightsTabs({ activeType, onTypeChange, counts = {} }: InsightsTabsProps) {
  const tabs: { type: TabType; label: string }[] = [
    { type: 'all', label: 'Wszystkie' },
    { type: 'alert', label: 'Alerty' },
    { type: 'trend', label: 'Trendy' },
    { type: 'tip', label: 'Wskazówki' },
    { type: 'forecast', label: 'Prognozy' },
  ];

  return (
    <div className="flex flex-wrap gap-1 mb-6">
      {tabs.map((tab) => {
        const isActive = activeType === tab.type;
        const count = counts[tab.type];

        return (
          <button
            key={tab.type}
            onClick={() => onTypeChange(tab.type)}
            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors flex items-center cursor-pointer ${
              isActive
                ? 'bg-slate-900 text-blue-400'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            {tab.label}
            {count !== undefined && count > 0 && (
              <span className={`ml-1.5 px-1.5 py-0.5 text-xs rounded-full ${isActive ? 'bg-blue-950 text-blue-300' : 'bg-slate-800 text-slate-400'}`}>
                {count}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}
