export type InsightType = 'alert' | 'tip' | 'trend' | 'forecast';
export type PriorityType = 'high' | 'medium' | 'low';

export interface Insight {
  id: string;
  user_id: string;
  type: InsightType;
  priority: PriorityType;
  title: string;
  content: string;
  linked_transaction_ids: string[];
  linked_category_ids: string[];
  dismissed: boolean;
  dedup_hash: string;
  created_at: string;
}

export interface CategoryAggregate {
  category_name: string;
  total_spent: string; // postgres NUMERIC is string in JS/TS
  percentage_of_total: string; // postgres NUMERIC is string in JS/TS
  trend_direction: 'up' | 'down' | 'flat';
  trend_percent: string; // postgres NUMERIC is string in JS/TS
  yoy_change_percent: string; // postgres NUMERIC is string in JS/TS
}

export interface ForecastResult {
  category_name: string;
  predicted_spending: string; // postgres NUMERIC is string in JS/TS
  confidence: string; // postgres NUMERIC is string in JS/TS
  trend: 'up' | 'down' | 'flat';
}
