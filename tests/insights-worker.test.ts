import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';
import {
  computeInsightDedupHash,
  sanitizePromptText,
  buildForecastPrompt,
  processAnalysisMessage,
  recoverStuckInsightJobs,
} from '../src/workers/insights-worker';
import { insertInsightBatch, enqueueAnalysisJob } from '../src/core/insights/use-cases';
import type { CategoryAggregate } from '../src/core/insights/entities';

let mockServer: any;
let mockPort: number;
let userId: string;
let categoryId: string;
let categoryName: string;
let accountId: string;

beforeAll(async () => {
  // Clear insights table and queue
  await sql`TRUNCATE insights CASCADE`;
  await sql`DELETE FROM pgmq.q_analysis_queue`;

  // Ensure user exists
  const users = await sql`SELECT id FROM "user" LIMIT 1`;
  if (users.length > 0) {
    userId = users[0].id;
  } else {
    const [user] = await sql`
      INSERT INTO "user" (id, name, email, "emailVerified")
      VALUES ('test-user-insights', 'Test User', 'test-insights@example.com', true)
      RETURNING id
    `;
    userId = user.id;
  }

  // Ensure category exists
  const categories = await sql`SELECT id, name FROM categories LIMIT 1`;
  if (categories.length > 0) {
    categoryId = categories[0].id;
    categoryName = categories[0].name;
  } else {
    const [category] = await sql`
      INSERT INTO categories (name)
      VALUES ('Test Groceries')
      RETURNING id, name
    `;
    categoryId = category.id;
    categoryName = category.name;
  }

  // Ensure account exists
  const accounts = await sql`SELECT id FROM accounts LIMIT 1`;
  if (accounts.length > 0) {
    accountId = accounts[0].id;
  } else {
    const [account] = await sql`
      INSERT INTO accounts (name, type)
      VALUES ('Test Account', 'personal')
      RETURNING id
    `;
    accountId = account.id;
  }

  // Clear transactions and insert some dummy transactions in the 3-month window
  await sql`TRUNCATE transactions CASCADE`;
  await sql`
    INSERT INTO transactions (account_id, category_id, type, amount, description, date)
    VALUES
      (${accountId}, ${categoryId}, 'expense', '150.00', 'Supermarket spend', current_date - interval '10 days'),
      (${accountId}, ${categoryId}, 'expense', '250.00', 'Grocery shopping', current_date - interval '20 days')
  `;

  // Start OpenRouter mock server
  mockServer = Bun.serve({
    port: 0,
    async fetch(req) {
      const url = new URL(req.url);

      if (url.pathname === '/chat/completions') {
        const body = await req.json();
        const schemaName = body.response_format?.json_schema?.name;

        if (schemaName === 'insights_response') {
          const content = JSON.stringify({
            insights: [
              {
                type: 'alert',
                priority: 'high',
                title: `Spending alert ${categoryName}`,
                content: 'You spent 150.00 PLN on Supermarket spend.',
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
                category_name: categoryName,
                predicted_spending: '400.00',
                confidence: '85.0',
                trend: 'up',
              }
            ]
          });
          return new Response(
            JSON.stringify({ choices: [{ message: { content } }] }),
            { headers: { 'Content-Type': 'application/json' }, status: 200 }
          );
        }
      }

      return new Response('Not found', { status: 404 });
    }
  });

  mockPort = mockServer.port;
  process.env.OPENROUTER_API_KEY = 'test-key';
  process.env.OPENROUTER_BASE_URL = `http://localhost:${mockPort}`;
});

afterAll(async () => {
  mockServer.stop();
});

describe('Insights Worker Operations', () => {
  it('computeInsightDedupHash is deterministic', () => {
    const hash1 = computeInsightDedupHash('alert', 'Title', 'Content');
    const hash2 = computeInsightDedupHash('alert', 'Title', 'Content');
    const hash3 = computeInsightDedupHash('alert', 'Title', 'Different Content');

    expect(hash1).toBe(hash2);
    expect(hash1).not.toBe(hash3);
  });

  it('sanitizePromptText removes control characters', () => {
    const input = 'Hello\x00World\x0BTest';
    expect(sanitizePromptText(input)).toBe('HelloWorldTest');
  });

  it('privacy boundary: buildForecastPrompt does not contain transaction descriptions', () => {
    const aggregates: CategoryAggregate[] = [
      {
        category_name: 'Groceries',
        total_spent: '400.00',
        percentage_of_total: '100.0',
        trend_direction: 'up',
        trend_percent: '0.0',
        yoy_change_percent: '0.0',
      }
    ];

    const prompt = buildForecastPrompt(aggregates);
    expect(prompt).toContain('Groceries');
    expect(prompt).toContain('400.00');
    // Ensure raw descriptions are NOT present
    expect(prompt).not.toContain('Supermarket spend');
    expect(prompt).not.toContain('Grocery shopping');
  });

  it('performs full queue round-trip and inserts insights', async () => {
    // 1. Enqueue analysis job
    const { msg_id } = await enqueueAnalysisJob(userId);
    expect(msg_id).toBeGreaterThan(0);

    // 2. Read message from PGMQ
    const messages = await sql`
      SELECT * FROM pgmq.read('analysis_queue', 300, 1)
    `;
    expect(messages).toHaveLength(1);
    const msg = messages[0];

    // 3. Process the message
    await processAnalysisMessage(msg);

    // 4. Archive message
    await sql`SELECT pgmq.archive('analysis_queue', ${msg.msg_id}::bigint)`;

    // 5. Verify insights table contains inserted rows
    const insights = await sql`
      SELECT * FROM insights WHERE user_id = ${userId} ORDER BY type
    `;
    // We expect 2 insights: 1 narrative alert from Claude, 1 forecast from R1
    expect(insights.length).toBeGreaterThanOrEqual(1);

    const alertInsight = insights.find(i => i.type === 'alert');
    expect(alertInsight).toBeDefined();
    expect(alertInsight?.title).toBe(`Spending alert ${categoryName}`);
    expect(alertInsight?.linked_transaction_ids).toHaveLength(1); // should link to Supermarket spend because of amount 150.00
    expect(alertInsight?.linked_category_ids).toHaveLength(1); // should link categoryId because category name is matched or inside content

    const forecastInsight = insights.find(i => i.type === 'forecast');
    expect(forecastInsight).toBeDefined();
    expect(forecastInsight?.title).toContain(categoryName);
    expect(forecastInsight?.linked_category_ids).toContain(categoryId);
  });

  it('insertInsightBatch respects ON CONFLICT DO NOTHING', async () => {
    const hash = computeInsightDedupHash('tip', 'Duplicate Title', 'Duplicate Content');
    const insights = [
      {
        user_id: userId,
        type: 'tip',
        priority: 'low',
        title: 'Duplicate Title',
        content: 'Duplicate Content',
        dedup_hash: hash,
      }
    ];

    const firstCount = await insertInsightBatch(insights);
    expect(firstCount).toBe(1);

    const secondCount = await insertInsightBatch(insights);
    expect(secondCount).toBe(0); // Duplicate, should be skipped
  });

  it('recovers stuck jobs correctly', async () => {
    // Insert a stuck message manually in q_analysis_queue
    const [msg] = await sql`
      INSERT INTO pgmq.q_analysis_queue (message, read_ct, enqueued_at, vt)
      VALUES ('{"user_id": "test", "triggered_by": "manual"}', 1, now() - interval '20 minutes', now() - interval '20 minutes')
      RETURNING msg_id
    `;

    // Trigger recovery
    await recoverStuckInsightJobs();

    // Verify it was deleted from pgmq.q_analysis_queue
    const remaining = await sql`
      SELECT msg_id FROM pgmq.q_analysis_queue WHERE msg_id = ${msg.msg_id}::bigint
    `;
    expect(remaining).toHaveLength(0);
  });
});
