import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { callClaudeForInsights, callDeepSeekForForecast } from '../src/workers/insights-worker';
import type { CategoryAggregate } from '../src/core/insights/entities';

let mockServer: any;
let mockPort: number;

beforeAll(() => {
  mockServer = Bun.serve({
    port: 0,
    async fetch(req) {
      const url = new URL(req.url);

      if (url.pathname === '/chat/completions') {
        const body = await req.json();

        // Check auth
        const authHeader = req.headers.get('authorization');
        if (!authHeader || authHeader !== 'Bearer test-key') {
          return new Response('Unauthorized', { status: 401 });
        }

        if (body.response_format?.type !== 'json_schema') {
          return new Response('Bad Request: Expected json_schema', { status: 400 });
        }

        const schemaName = body.response_format.json_schema.name;

        if (schemaName === 'insights_response') {
          const content = JSON.stringify({
            insights: [
              {
                type: 'alert',
                priority: 'high',
                title: 'Valid Alert',
                content: 'This is a valid financial alert content.',
              },
              {
                type: 'prediction', // Invalid type: must be alert, tip, or trend
                priority: 'high',
                title: 'Invalid Alert',
                content: 'Invalid alert because of type.',
              },
              {
                type: 'alert',
                priority: 'high',
                title: '', // Invalid empty title
                content: 'Invalid alert because of empty title.',
              }
            ]
          });
          return new Response(
            JSON.stringify({ choices: [{ message: { content } }] }),
            { headers: { 'Content-Type': 'application/json' }, status: 200 }
          );
        }

        if (schemaName === 'forecast_response') {
          const content = JSON.stringify({
            forecasts: [
              {
                category_name: 'Groceries',
                predicted_spending: '1200.50',
                confidence: '95.0',
                trend: 'up',
              },
              {
                category_name: 'Rent',
                predicted_spending: '-500.00', // Invalid: negative spending
                confidence: '99.0',
                trend: 'flat',
              },
              {
                category_name: 'Transport',
                predicted_spending: '200.00',
                confidence: 'high', // Invalid: non-numeric confidence
                trend: 'down',
              }
            ]
          });
          return new Response(
            JSON.stringify({ choices: [{ message: { content } }] }),
            { headers: { 'Content-Type': 'application/json' }, status: 200 }
          );
        }
      }

      if (url.pathname === '/error/chat/completions') {
        return new Response('Internal Server Error', { status: 500 });
      }

      return new Response('Not found', { status: 404 });
    }
  });

  mockPort = mockServer.port;
  process.env.OPENROUTER_API_KEY = 'test-key';
  process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
});

afterAll(() => {
  mockServer.stop();
});

describe('Insights LLM Integration Tests', () => {
  it('callClaudeForInsights filters invalid insights using Zod schema', async () => {
    const transactions: any[] = [
      { id: '1', amount: '100.00', date: '2026-06-01', description: 'test', type: 'expense' }
    ];
    const results = await callClaudeForInsights(transactions);

    // Only 1 of 3 insights is valid, others filtered
    expect(results).toHaveLength(1);
    expect(results[0].type).toBe('alert');
    expect(results[0].priority).toBe('high');
    expect(results[0].title).toBe('Valid Alert');
  });

  it('callClaudeForInsights throws on API errors', async () => {
    process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}/error`;
    expect(callClaudeForInsights([])).rejects.toThrow('OpenRouter error: 500');
    process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
  });

  it('callDeepSeekForForecast filters invalid forecasts using Zod schema', async () => {
    const aggregates: CategoryAggregate[] = [
      {
        category_name: 'Groceries',
        total_spent: '1000.00',
        percentage_of_total: '50.0',
        trend_direction: 'up',
        trend_percent: '10.0',
        yoy_change_percent: '15.0',
      }
    ];
    const results = await callDeepSeekForForecast(aggregates);

    // Only 1 of 3 forecasts is valid
    expect(results).toHaveLength(1);
    expect(results[0].category_name).toBe('Groceries');
    expect(results[0].predicted_spending).toBe('1200.50');
    expect(results[0].confidence).toBe('95.0');
    expect(results[0].trend).toBe('up');
  });

  it('callDeepSeekForForecast gracefully degrades to empty array on errors', async () => {
    process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}/error`;
    const results = await callDeepSeekForForecast([]);
    expect(results).toEqual([]);
    process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
  });
});
