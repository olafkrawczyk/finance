import { describe, it, expect } from 'bun:test';
import {
  ClaudeInsightSchema,
  ClaudeInsightsResponseSchema,
  R1ForecastSchema,
  R1ForecastResponseSchema,
  ListInsightsQuerySchema,
  DismissInsightSchema,
  GenerateInsightsSchema,
} from '../src/application/schemas/insights';
import { healthDb } from '../src/infrastructure/db/health';

describe('Insights Schema Tests', () => {
  describe('ClaudeInsightSchema', () => {
    it('accepts a valid insight', () => {
      const result = ClaudeInsightSchema.safeParse({
        type: 'alert',
        priority: 'high',
        title: 'Spending Spike',
        content: 'Your spending on groceries has spiked by 40% this month.',
      });
      expect(result.success).toBe(true);
    });

    it('rejects missing title', () => {
      const result = ClaudeInsightSchema.safeParse({
        type: 'alert',
        priority: 'high',
        content: 'Groceries spike',
      });
      expect(result.success).toBe(false);
    });

    it('rejects empty string title', () => {
      const result = ClaudeInsightSchema.safeParse({
        type: 'alert',
        priority: 'high',
        title: '',
        content: 'Groceries spike',
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid type', () => {
      const result = ClaudeInsightSchema.safeParse({
        type: 'prediction',
        priority: 'high',
        title: 'Spending Spike',
        content: 'Your spending on groceries has spiked.',
      });
      expect(result.success).toBe(false);
    });

    it('rejects priority misspelling', () => {
      const result = ClaudeInsightSchema.safeParse({
        type: 'alert',
        priority: 'highh',
        title: 'Spending Spike',
        content: 'Your spending on groceries has spiked.',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('ClaudeInsightsResponseSchema', () => {
    it('accepts valid insights array', () => {
      const result = ClaudeInsightsResponseSchema.safeParse({
        insights: [
          {
            type: 'alert',
            priority: 'high',
            title: 'Spending Spike',
            content: 'Your spending on groceries has spiked.',
          },
          {
            type: 'tip',
            priority: 'medium',
            title: 'Savings Option',
            content: 'Consider cancelling unused subscriptions.',
          }
        ]
      });
      expect(result.success).toBe(true);
    });

    it('accepts empty insights array', () => {
      const result = ClaudeInsightsResponseSchema.safeParse({
        insights: [],
      });
      expect(result.success).toBe(true);
    });

    it('rejects missing insights key', () => {
      const result = ClaudeInsightsResponseSchema.safeParse({});
      expect(result.success).toBe(false);
    });

    it('rejects non-array insights', () => {
      const result = ClaudeInsightsResponseSchema.safeParse({
        insights: 'not-an-array',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('R1ForecastSchema', () => {
    it('accepts valid forecast', () => {
      const result = R1ForecastSchema.safeParse({
        category_name: 'Groceries',
        predicted_spending: '1250.50',
        confidence: '85.50',
        trend: 'up',
      });
      expect(result.success).toBe(true);
    });

    it('rejects negative predicted_spending', () => {
      const result = R1ForecastSchema.safeParse({
        category_name: 'Groceries',
        predicted_spending: '-1250.50',
        confidence: '85.50',
        trend: 'up',
      });
      expect(result.success).toBe(false);
    });

    it('rejects non-numeric confidence', () => {
      const result = R1ForecastSchema.safeParse({
        category_name: 'Groceries',
        predicted_spending: '1250.50',
        confidence: 'high',
        trend: 'up',
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid trend', () => {
      const result = R1ForecastSchema.safeParse({
        category_name: 'Groceries',
        predicted_spending: '1250.50',
        confidence: '85.50',
        trend: 'skyrocketing',
      });
      expect(result.success).toBe(false);
    });

    it('rejects empty category_name', () => {
      const result = R1ForecastSchema.safeParse({
        category_name: '',
        predicted_spending: '1250.50',
        confidence: '85.50',
        trend: 'up',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('R1ForecastResponseSchema', () => {
    it('accepts valid forecasts array', () => {
      const result = R1ForecastResponseSchema.safeParse({
        forecasts: [
          {
            category_name: 'Groceries',
            predicted_spending: '1200.00',
            confidence: '90.00',
            trend: 'up',
          }
        ]
      });
      expect(result.success).toBe(true);
    });

    it('rejects missing forecasts key', () => {
      const result = R1ForecastResponseSchema.safeParse({});
      expect(result.success).toBe(false);
    });
  });

  describe('ListInsightsQuerySchema', () => {
    it('coerces parameters and sets defaults', () => {
      const result = ListInsightsQuerySchema.safeParse({});
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.page).toBe(1);
        expect(result.data.per_page).toBe(20);
        expect(result.data.type).toBeUndefined();
        expect(result.data.dismissed).toBe(false);
      }
    });

    it('accepts explicit page/per_page', () => {
      const result = ListInsightsQuerySchema.safeParse({
        page: '2',
        per_page: '30',
        type: 'alert',
        dismissed: 'true',
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.page).toBe(2);
        expect(result.data.per_page).toBe(30);
        expect(result.data.type).toBe('alert');
        expect(result.data.dismissed).toBe(true);
      }
    });

    it('rejects per_page=0', () => {
      const result = ListInsightsQuerySchema.safeParse({
        per_page: 0,
      });
      expect(result.success).toBe(false);
    });

    it('rejects per_page=101', () => {
      const result = ListInsightsQuerySchema.safeParse({
        per_page: 101,
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid type', () => {
      const result = ListInsightsQuerySchema.safeParse({
        type: 'prediction',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('DismissInsightSchema', () => {
    it('accepts dismissed: true', () => {
      const result = DismissInsightSchema.safeParse({
        dismissed: true,
      });
      expect(result.success).toBe(true);
    });

    it('rejects dismissed: false', () => {
      const result = DismissInsightSchema.safeParse({
        dismissed: false,
      });
      expect(result.success).toBe(false);
    });

    it('rejects missing dismissed key', () => {
      const result = DismissInsightSchema.safeParse({});
      expect(result.success).toBe(false);
    });
  });

  describe('GenerateInsightsSchema', () => {
    it('accepts empty object', () => {
      const result = GenerateInsightsSchema.safeParse({});
      expect(result.success).toBe(true);
    });
  });

  describe('Database Health Check', () => {
    it('reports analysis_queue as true', async () => {
      const health = await healthDb();
      expect(health.pgmq).toBe(true);
    });
  });
});
