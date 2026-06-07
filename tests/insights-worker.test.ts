import { describe, it, expect, beforeAll, afterAll } from 'bun:test';
import sql from '../src/infrastructure/db/client';
import {
  computeInsightDedupHash,
  sanitizePromptText,
  buildForecastPrompt,
  processAnalysisMessage,
  recoverStuckInsightJobs,
} from '../src/workers/insights-worker';
import { insertInsightBatch, enqueueAnalysisJob, getInsightDataWindow } from '../src/core/insights/use-cases';
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
      INSERT INTO categories (name, user_id)
      VALUES ('Test Groceries', ${userId})
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
      INSERT INTO accounts (name, type, user_id)
      VALUES ('Test Account', 'personal', ${userId})
      RETURNING id
    `;
    accountId = account.id;
  }

  // Clear transactions and insert some dummy transactions in the 3-month window
  await sql`TRUNCATE transactions CASCADE`;
  await sql`
    INSERT INTO transactions (account_id, category_id, type, amount, description, date, user_id)
    VALUES
      (${accountId}, ${categoryId}, 'expense', '150.00', 'Supermarket spend', current_date - interval '10 days', ${userId}),
      (${accountId}, ${categoryId}, 'expense', '250.00', 'Grocery shopping', current_date - interval '20 days', ${userId})
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

        // DeepSeek R1 forecast endpoint does NOT send response_format — match by model name
        if (schemaName === 'forecast_response' || body.model?.includes('deepseek')) {
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

// ── Insights Worker Per-User Isolation (TEST-03, D-10) ──

describe('Insights Worker Per-User Isolation — D-10', () => {
  let userBId: string;
  let userBCategoryId: string;
  let userBAccountId: string;

  beforeAll(async () => {
    // Create/fetch User B
    const existingB = await sql`SELECT id FROM "user" WHERE email = 'insights-iso-b@test.com'`;
    if (existingB.length > 0) {
      userBId = existingB[0].id;
    } else {
      const [u] = await sql`
        INSERT INTO "user" (id, name, email, "emailVerified")
        VALUES ('insights-iso-b', 'Insights Iso B', 'insights-iso-b@test.com', true)
        RETURNING id
      `;
      userBId = u.id;
    }

    // Create a category for User B
    const bCats = await sql`SELECT id FROM categories WHERE user_id = ${userBId} LIMIT 1`;
    if (bCats.length > 0) {
      userBCategoryId = bCats[0].id;
    } else {
      const [cat] = await sql`
        INSERT INTO categories (name, user_id) VALUES ('Insights B Cat', ${userBId}) RETURNING id
      `;
      userBCategoryId = cat.id;
    }

    // Create an account for User B
    const bAccs = await sql`SELECT id FROM accounts WHERE user_id = ${userBId} LIMIT 1`;
    if (bAccs.length > 0) {
      userBAccountId = bAccs[0].id;
    } else {
      const [acct] = await sql`
        INSERT INTO accounts (name, type, user_id) VALUES ('Insights B Account', 'personal', ${userBId}) RETURNING id
      `;
      userBAccountId = acct.id;
    }
  });

  afterAll(async () => {
    // Clean up User B's data
    await sql`DELETE FROM insights WHERE user_id = ${userBId}`;
    await sql`DELETE FROM transactions WHERE user_id = ${userBId}`;
    await sql`DELETE FROM categories WHERE id = ${userBCategoryId}`;
    await sql`DELETE FROM accounts WHERE id = ${userBAccountId}`;
    await sql`DELETE FROM "user" WHERE id = ${userBId}`;
  });

  // D-10: Insights worker scoped window — processAnalysisMessage creates insights only for correct user
  it('D-10: processAnalysisMessage creates insights only for the correct user', async () => {
    // Seed a transaction for User B that could accidentally match User A's window
    await sql`
      INSERT INTO transactions (account_id, category_id, type, amount, description, date, user_id)
      VALUES (${userBAccountId}, ${userBCategoryId}, 'expense', '500.00', 'User B exclusive', current_date - interval '5 days', ${userBId})
    `;

    // Insert an extra transaction for User A (userId from parent scope) — they already have 2 from outer beforeAll
    await sql`
      INSERT INTO transactions (account_id, category_id, type, amount, description, date, user_id)
      VALUES (${accountId}, ${categoryId}, 'expense', '300.00', 'User A extra', current_date - interval '3 days', ${userId})
    `;

    // Enqueue and process for User A only
    const { msg_id } = await enqueueAnalysisJob(userId);
    const messages = await sql`SELECT * FROM pgmq.read('analysis_queue', 300, 1)`;
    expect(messages).toHaveLength(1);

    await processAnalysisMessage(messages[0]);

    await sql`SELECT pgmq.archive('analysis_queue', ${messages[0].msg_id}::bigint)`;

    // Verify insights created only for User A
    const aInsights = await sql`
      SELECT * FROM insights WHERE user_id = ${userId}
    `;
    expect(aInsights.length).toBeGreaterThanOrEqual(1);

    // User B should have NO new insights from User A's analysis
    const bInsights = await sql`
      SELECT * FROM insights WHERE user_id = ${userBId}
    `;
    // User B's insights should be empty (User B was never analyzed)
    expect(bInsights).toHaveLength(0);

    // Clean up test transactions
    await sql`DELETE FROM transactions WHERE description = 'User B exclusive'`;
    await sql`DELETE FROM transactions WHERE description = 'User A extra'`;
    await sql`DELETE FROM insights WHERE user_id = ${userId} AND title LIKE 'Spending alert%'`;
  });

  // D-10 regression: getInsightDataWindow returns per-user results (Phase 8 D-09/D-10 fix)
  it('D-10 regression: getInsightDataWindow returns only the correct user transactions', async () => {
    // This verifies the Phase 8 fix — getInsightDataWindow must scope by user_id
    // Insert one recent transaction for each user with distinct amounts
    await sql`
      INSERT INTO transactions (account_id, category_id, type, amount, description, date, user_id)
      VALUES (${accountId}, ${categoryId}, 'expense', '999.99', 'User A window test', current_date - interval '1 day', ${userId})
    `;
    await sql`
      INSERT INTO transactions (account_id, category_id, type, amount, description, date, user_id)
      VALUES (${userBAccountId}, ${userBCategoryId}, 'expense', '888.88', 'User B window test', current_date - interval '1 day', ${userBId})
    `;

    // Call getInsightDataWindow directly for both users to verify per-user scoping
    const aWindow = await getInsightDataWindow(userId);
    const bWindow = await getInsightDataWindow(userBId);

    // User A's window should contain User A's window test, not User B's
    const aHasOwn = aWindow.some(t => t.description === 'User A window test');
    expect(aHasOwn).toBe(true);
    const aHasOther = aWindow.some(t => t.description === 'User B window test');
    expect(aHasOther).toBe(false);

    // User B's window should contain User B's window test, not User A's
    const bHasOwn = bWindow.some(t => t.description === 'User B window test');
    expect(bHasOwn).toBe(true);
    const bHasOther = bWindow.some(t => t.description === 'User A window test');
    expect(bHasOther).toBe(false);

    // Clean up
    await sql`DELETE FROM transactions WHERE description IN ('User A window test', 'User B window test')`;
  });
});
