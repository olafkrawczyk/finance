import React from 'react';
import { formatRelativeTime, getPriorityColor, getTypeLabel } from '../lib/insights';

interface Insight {
  id: string;
  user_id: string;
  type: 'alert' | 'tip' | 'trend' | 'forecast';
  priority: 'high' | 'medium' | 'low';
  title: string;
  content: string;
  dismissed: boolean;
  created_at: string;
  linked_transaction_ids?: string[];
  linked_category_ids?: string[];
}

interface InsightCardProps {
  insight: Insight;
  onDismiss: (id: string) => void;
}

export default function InsightCard({ insight, onDismiss }: InsightCardProps) {
  const { id, type, priority, title, content, dismissed, created_at, linked_transaction_ids } = insight;
  const colorConfig = getPriorityColor(priority);
  const typeLabel = getTypeLabel(type);
  const timeStr = formatRelativeTime(created_at);

  const handleEvidenceClick = (e: React.MouseEvent) => {
    e.preventDefault();
    window.history.pushState(null, '', '/transactions');
    window.dispatchEvent(new PopStateEvent('popstate'));
  };

  return (
    <div className={`bg-slate-900/80 border border-slate-800 rounded-2xl p-6 space-y-3 relative ${dismissed ? 'opacity-50 pointer-events-none' : ''}`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className={`w-2.5 h-2.5 rounded-full ${colorConfig.dot}`} />
          <span className="text-xs px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 font-medium">
            {typeLabel}
          </span>
        </div>
        <span className="text-xs text-slate-500">{timeStr}</span>
      </div>

      <h3 className="text-base font-semibold text-slate-100">{title}</h3>
      <p className="text-sm text-slate-300 leading-relaxed">{content}</p>

      <div className="flex items-center justify-between pt-2 border-t border-slate-800/60">
        <div>
          {linked_transaction_ids && linked_transaction_ids.length > 0 && (
            <a
              href="/transactions"
              onClick={handleEvidenceClick}
              className="text-xs text-blue-400 hover:text-blue-300 cursor-pointer transition-colors font-medium"
            >
              See related transactions
            </a>
          )}
        </div>
        
        {dismissed ? (
          <span className="text-xs font-semibold text-slate-500 bg-slate-800 px-2 py-0.5 rounded">
            Dismissed
          </span>
        ) : (
          <button
            onClick={() => onDismiss(id)}
            className="text-xs text-slate-500 hover:text-red-400 transition-colors font-medium cursor-pointer"
          >
            Dismiss
          </button>
        )}
      </div>
    </div>
  );
}
