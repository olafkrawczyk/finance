export function formatRelativeTime(createdAt: string): string {
  const date = new Date(createdAt);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHrs = Math.floor(diffMin / 60);
  const diffDays = Math.floor(diffHrs / 24);

  if (diffSec < 60) {
    return 'przed chwilą';
  } else if (diffMin < 60) {
    return `${diffMin} min temu`;
  } else if (diffHrs < 24) {
    return `${diffHrs} godz. temu`;
  } else if (diffDays === 1) {
    return 'wczoraj';
  } else if (diffDays < 7) {
    return `${diffDays} dni temu`;
  } else {
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    return `${day}.${month}.${year}`;
  }
}

export function getPriorityColor(priority: 'high' | 'medium' | 'low'): { dot: string; text: string } {
  switch (priority) {
    case 'high':
      return { dot: 'bg-red-400', text: 'text-red-400' };
    case 'medium':
      return { dot: 'bg-amber-400', text: 'text-amber-400' };
    case 'low':
      return { dot: 'bg-blue-400', text: 'text-blue-400' };
    default:
      return { dot: 'bg-slate-400', text: 'text-slate-400' };
  }
}

export function getTypeLabel(type: 'alert' | 'tip' | 'trend' | 'forecast'): string {
  switch (type) {
    case 'alert':
      return 'Alert';
    case 'tip':
      return 'Porada';
    case 'trend':
      return 'Trend';
    case 'forecast':
      return 'Prognoza';
    default:
      return type;
  }
}

export function getTypeIcon(type: 'alert' | 'tip' | 'trend' | 'forecast'): string {
  switch (type) {
    case 'alert':
      return 'exclamation-triangle';
    case 'trend':
      return 'trending-up';
    case 'tip':
      return 'lightbulb';
    case 'forecast':
      return 'chart-line';
    default:
      return 'info-circle';
  }
}
