import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import { callOpenRouter } from '../src/workers/import-worker';

let mockServer: any;
let mockPort: number;

beforeAll(() => {
  // Start a local mock OpenRouter server
  mockServer = Bun.serve({
    port: 0, // Automatically choose a free port
    async fetch(req) {
      const url = new URL(req.url);

      if (url.pathname === '/chat/completions') {
        const body = await req.json();

        // Check auth header
        const authHeader = req.headers.get('authorization');
        if (!authHeader || authHeader !== 'Bearer test-key') {
          return new Response('Unauthorized', { status: 401 });
        }

        // Check if strict schema was requested
        if (body.response_format?.type !== 'json_schema') {
          return new Response('Bad Request: Expected json_schema response_format', { status: 400 });
        }

        // Return a simulated response with one valid and one invalid transaction
        const content = JSON.stringify({
          transactions: [
            {
              date: '2026-06-01',
              amount: '120.00',
              description: 'Valid expense',
              raw_type: 'expense',
            },
            {
              date: 'invalid-date', // Should be filtered out by Zod (iso date check)
              amount: '50.00',
              description: 'Invalid date expense',
              raw_type: 'expense',
            },
            {
              date: '2026-06-02',
              amount: '-45.00', // Should be filtered out by Zod (regex positive decimal check)
              description: 'Negative amount expense',
              raw_type: 'expense',
            },
          ],
        });

        return new Response(
          JSON.stringify({
            choices: [
              {
                message: {
                  content: content,
                },
              },
            ],
          }),
          {
            headers: { 'Content-Type': 'application/json' },
            status: 200,
          }
        );
      }

      if (url.pathname === '/error/chat/completions') {
        return new Response('Internal Server Error', { status: 500 });
      }

      return new Response('Not found', { status: 404 });
    },
  });

  mockPort = mockServer.port;
  process.env.OPENROUTER_API_KEY = 'test-key';
  process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
});

afterAll(() => {
  mockServer.stop();
});

describe('OpenRouter Integration Tests', () => {
  it('successfully fetches and filters transactions using Zod schema', async () => {
    const parsed = await callOpenRouter('dummy csv rows', 'ing');
    
    // Expecting only the 1 valid transaction, other 2 should be filtered out by Zod
    expect(parsed).toHaveLength(1);
    expect(parsed[0].date).toBe('2026-06-01');
    expect(parsed[0].amount).toBe('120.00');
    expect(parsed[0].description).toBe('Valid expense');
    expect(parsed[0].raw_type).toBe('expense');
  });

  it('throws an error when the OpenRouter API returns an error status', async () => {
    // Override base URL to point to error endpoint
    process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}/error`;

    expect(callOpenRouter('dummy csv rows', 'ing')).rejects.toThrow(
      'OpenRouter error: 500'
    );

    // Reset base URL
    process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
  });
});
