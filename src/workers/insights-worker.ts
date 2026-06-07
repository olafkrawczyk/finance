import { createHash } from 'crypto';
import sql from '../infrastructure/db/client';
import { ClaudeInsightSchema, R1ForecastSchema } from '../application/schemas/insights';
import type { Insight, CategoryAggregate, ForecastResult, TransactionData } from '../core/insights/entities';
import { getInsightDataWindow, getCategoryAggregates, insertInsightBatch } from '../core/insights/use-cases';
import * as z from 'zod';

export const QUEUE_NAME = 'analysis_queue';
export const VISIBILITY_TIMEOUT = 300; // 5 minutes
export const POLL_INTERVAL_MS = 5000;
export const RECOVERY_INTERVAL_MS = 5 * 60 * 1000; // run stuck-job recovery every 5 minutes
export const MAX_RETRIES = 3;
export const DEDUP_WINDOW_DAYS = 14;
export const RATE_LIMIT_COOLDOWN_MS = 5 * 60 * 1000; // 5 minutes

export function computeInsightDedupHash(type: string, title: string, content: string): string {
  return createHash('sha256')
    .update(`${type}|${title}|${content}`)
    .digest('hex');
}

export function sanitizePromptText(text: string): string {
  return text.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
}

export function buildInsightsSystemPrompt(): string {
  return `You are a personal finance advisor analyzing a user's bank transaction history.
Your task is to generate useful, personalized financial insights as JSON.
Generate alerts, trends, and tips about spending patterns, budget, and financial habits.

Output language: POLISH. All title and content fields must be written in Polish.

Each insight must have:
- type: one of 'alert' (sudden spending spike), 'tip' (saving advice), 'trend' (category spending pattern)
- priority: one of 'high', 'medium', 'low'
- title: concise Polish title (max 100 characters)
- content: detailed Polish analysis (max 1000 characters)

Priority rules:
- high: actionable problem requiring immediate attention (e.g. >50% spending spike, recurring unexpected charge)
- medium: notable pattern worth reviewing
- low: general observation or minor tip

Example output:
{
  "insights": [
    {
      "type": "alert",
      "priority": "high",
      "title": "Wzrost wydatków na jedzenie na mieście",
      "content": "W ostatnich 3 miesiącach wydałeś o 60% więcej na restauracje niż w tym samym okresie rok temu. Rozważ ustalenie miesięcznego limitu."
    },
    {
      "type": "tip",
      "priority": "medium",
      "title": "Oszczędności na kawie",
      "content": "Wydajesz średnio 280 PLN miesięcznie na kawę. Parzenie kawy w domu mogłoby zaoszczędzić ok. 150 PLN miesięcznie."
    },
    {
      "type": "trend",
      "priority": "low",
      "title": "Stabilne wydatki na paliwo",
      "content": "Twoje wydatki na paliwo są stabilne i wynoszą ok. 600 PLN miesięcznie. Trend rok do roku: bez zmian."
    }
  ]
}

Rules:
- Respond ONLY with a valid JSON object. No markdown, no explanations outside JSON.
- Generate all insights you detect — do not limit to a fixed number.
- Be specific: use actual amounts and percentages from the data, not generic advice.
- Skip categories with no spending data.
`;
}

export function buildInsightsPrompt(transactions: TransactionData[]): string {
  const txList = transactions.map(t =>
    `- Date: ${t.date}, Amount: ${t.amount} PLN, Category: ${t.category_name ?? 'Uncategorized'}, Type: ${t.type}, Description: ${t.description ?? ''}`
  ).join('\n');
  return `Here are the user's transactions from the last 3 months plus the same period from last year for comparison:

${txList}

Analyze this data and generate financial insights, alerts, and trends. Write all insight text in Polish.`;
}

export function buildForecastSystemPrompt(): string {
  return `You are a mathematical forecasting engine.
Your task is to predict next month's spending per category based on historical aggregates and calculate trend directions.

Each forecast must contain:
- category_name: The exact name of the category.
- predicted_spending: Positive decimal string with up to 4 decimal places.
- confidence: Confidence level (0 to 100) as a decimal string.
- trend: One of: 'up', 'down', 'flat'.

Example output:
{
  "forecasts": [
    {
      "category_name": "Groceries",
      "predicted_spending": "1250.00",
      "confidence": "85.0",
      "trend": "up"
    }
  ]
}

Respond ONLY with valid JSON. No conversational text, no markdown.`;
}

export function buildForecastPrompt(aggregates: CategoryAggregate[]): string {
  const aggList = aggregates.map(a =>
    `- Category: ${a.category_name}, Spent: ${a.total_spent} PLN, % of Total: ${a.percentage_of_total}%, Trend: ${a.trend_direction} (${a.trend_percent}%), YoY: ${a.yoy_change_percent}%`
  ).join('\n');
  return `Here are the category spending aggregates from the recent 3-month window compared to last year:

${aggList}

Perform mathematical forecasting to predict next month's spending per category and estimate the trend direction.`;
}

export async function callClaudeForInsights(transactions: TransactionData[]): Promise<Array<z.infer<typeof ClaudeInsightSchema>>> {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey && process.env.NODE_ENV !== 'test') {
    throw new Error('OPENROUTER_API_KEY not set');
  }

  const baseUrl = process.env.OPENROUTER_BASE_URL ?? 'https://openrouter.ai/api/v1';
  const model = process.env.OPENROUTER_INSIGHTS_MODEL ?? 'anthropic/claude-sonnet-4.6';

  const sanitizedTx = transactions.map(t => ({
    ...t,
    description: t.description ? sanitizePromptText(t.description) : null
  }));

  const systemPrompt = buildInsightsSystemPrompt();
  const userPrompt = buildInsightsPrompt(sanitizedTx);

  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey || 'dummy-key'}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://github.com/olafkrawczyk/finance',
      'X-Title': 'Financial Ingestion App',
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'insights_response',
          strict: true,
          schema: {
            type: 'object',
            properties: {
              insights: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    type: { type: 'string', enum: ['alert', 'tip', 'trend'] },
                    priority: { type: 'string', enum: ['high', 'medium', 'low'] },
                    title: { type: 'string' },
                    content: { type: 'string' }
                  },
                  required: ['type', 'priority', 'title', 'content'],
                  additionalProperties: false
                }
              }
            },
            required: ['insights'],
            additionalProperties: false
          }
        }
      },
      temperature: 0.1,
      max_tokens: 4096
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenRouter error: ${response.status} — ${errorText}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('Empty message content returned from OpenRouter');
  }

  const parsedJson = JSON.parse(content);
  const rawInsights = parsedJson.insights;
  if (!Array.isArray(rawInsights)) {
    throw new Error('OpenRouter response did not contain an insights array');
  }

  const validInsights: Array<z.infer<typeof ClaudeInsightSchema>> = [];
  for (const item of rawInsights) {
    const validation = ClaudeInsightSchema.safeParse(item);
    if (validation.success) {
      validInsights.push(validation.data);
    } else {
      console.warn('Filtered out invalid insight from LLM:', item, validation.error.format());
    }
  }

  return validInsights;
}

export async function callDeepSeekForForecast(aggregates: CategoryAggregate[]): Promise<ForecastResult[]> {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey && process.env.NODE_ENV !== 'test') {
    return [];
  }

  const baseUrl = process.env.OPENROUTER_BASE_URL ?? 'https://openrouter.ai/api/v1';
  const model = process.env.OPENROUTER_FORECAST_MODEL ?? 'deepseek/deepseek-r1-0528';

  const systemPrompt = buildForecastSystemPrompt();
  const userPrompt = buildForecastPrompt(aggregates);

  try {
    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey || 'dummy-key'}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/olafkrawczyk/finance',
        'X-Title': 'Financial Ingestion App',
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        temperature: 0.1,
        max_tokens: 4096
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.warn(`[worker] DeepSeek API error: ${response.status} — ${errorText}`);
      return [];
    }

    const data = await response.json();
    // R1 puts the answer in content; reasoning goes to reasoning_content
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      console.warn('[worker] DeepSeek returned empty content. Full response:', JSON.stringify(data).slice(0, 500));
      return [];
    }

    // Extract JSON from response — R1 sometimes wraps in markdown fences
    const jsonMatch = content.match(/```json\s*([\s\S]*?)```/) || content.match(/(\{[\s\S]*\})/);
    const jsonStr = jsonMatch ? jsonMatch[1] : content;
    const parsedJson = JSON.parse(jsonStr);
    const rawForecasts = parsedJson.forecasts;
    if (!Array.isArray(rawForecasts)) {
      console.warn('[worker] DeepSeek response missing forecasts array. Parsed:', parsedJson);
      return [];
    }

    const validForecasts: ForecastResult[] = [];
    for (const item of rawForecasts) {
      const validation = R1ForecastSchema.safeParse(item);
      if (validation.success) {
        validForecasts.push(validation.data as ForecastResult);
      } else {
        console.warn('Filtered out invalid forecast from LLM:', item, validation.error.format());
      }
    }

    return validForecasts;
  } catch (err) {
    console.warn('DeepSeek R1 forecast failed (graceful degradation):', err);
    return [];
  }
}

export function findLinks(
  title: string,
  content: string,
  transactions: TransactionData[]
): { transactionIds: string[]; categoryIds: string[] } {
  const transactionIds: string[] = [];
  const categoryIds: string[] = [];

  const textToSearch = `${title} ${content}`.toLowerCase();

  const uniqueCategories = new Map<string, string>();
  for (const t of transactions) {
    if (t.category_id && t.category_name) {
      uniqueCategories.set(t.category_name.toLowerCase(), t.category_id);
    }
  }
  for (const [name, id] of uniqueCategories.entries()) {
    if (textToSearch.includes(name)) {
      categoryIds.push(id);
    }
  }

  for (const t of transactions) {
    if (t.description && t.description.length > 3) {
      if (textToSearch.includes(t.description.toLowerCase())) {
        transactionIds.push(t.id);
        continue;
      }
    }
    const amountStr = parseFloat(t.amount).toFixed(2);
    if (textToSearch.includes(amountStr)) {
      transactionIds.push(t.id);
    }
  }

  return {
    transactionIds: Array.from(new Set(transactionIds)),
    categoryIds: Array.from(new Set(categoryIds)),
  };
}

export async function recoverStuckInsightJobs(): Promise<void> {
  // Reset VT for messages stuck mid-flight so we don't wait out the full 5-minute VT
  try {
    const inFlight = await sql`
      SELECT msg_id FROM pgmq.q_analysis_queue WHERE vt > now() AND read_ct > 0
    `;
    for (const row of inFlight) {
      await sql`SELECT pgmq.set_vt('analysis_queue', ${row.msg_id}::bigint, 0)`;
      console.log(`[stuck recovery] Reset VT for PGMQ msg_id=${row.msg_id}`);
    }
  } catch (err) {
    console.error('[stuck recovery] Failed to reset PGMQ message VT:', err);
  }

  // Delete messages that have been retried too many times or are very old
  try {
    const stuck = await sql`
      SELECT msg_id FROM pgmq.q_analysis_queue
      WHERE read_ct > 0 AND enqueued_at < now() - interval '15 minutes'
    `;
    for (const row of stuck) {
      await sql`SELECT pgmq.delete('analysis_queue', ${row.msg_id}::bigint)`;
      console.log(`[stuck recovery] Deleted stuck message ${row.msg_id} from analysis_queue`);
    }
  } catch (err) {
    console.error('[stuck recovery] Failed to clean up stuck insights jobs:', err);
  }
}

export async function processAnalysisMessage(msg: { message: any }): Promise<void> {
  const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;
  const userId = payload.user_id;
  const triggeredBy = payload.triggered_by;

  if (!userId) {
    throw new Error('Message payload missing user_id');
  }

  // Rate limit check for manual triggers
  if (triggeredBy === 'manual') {
    const lastInsight = await sql`
      SELECT created_at FROM insights
      WHERE user_id = ${userId}
      ORDER BY created_at DESC
      LIMIT 1
    `;
    if (lastInsight.length > 0) {
      const lastTime = new Date(lastInsight[0].created_at).getTime();
      if (Date.now() - lastTime < RATE_LIMIT_COOLDOWN_MS) {
        console.log(`[insights] Rate limit: skipping manual analysis for user ${userId} (cooldown active)`);
        return;
      }
    }
  }

  // 1. Fetch transaction window
  const transactions = await getInsightDataWindow(userId);
  if (transactions.length === 0) {
    console.log(`[insights] No transactions found for user ${userId} — skipping`);
    return;
  }
  console.log(`[insights] Processing ${transactions.length} transactions for user ${userId}`);

  const txIds = transactions.map(t => t.id);

  // 2. Call Claude for narrative insights
  console.log(`[worker] Calling Claude for narrative insights (${transactions.length} transactions)...`);
  const narrativeInsightsRaw = await callClaudeForInsights(transactions);
  console.log(`[worker] Claude returned ${narrativeInsightsRaw.length} insights`);

  // 3. Call DeepSeek R1 for category forecasts
  const aggregates = await getCategoryAggregates(txIds, userId);
  console.log(`[worker] Calling DeepSeek R1 for forecasts (${aggregates.length} categories)...`);
  const forecasts = aggregates.length > 0 ? await callDeepSeekForForecast(aggregates) : [];
  console.log(`[worker] DeepSeek returned ${forecasts.length} forecasts`);

  // 4. Map and link narrative insights
  const mappedInsights = narrativeInsightsRaw.map(ni => {
    const links = findLinks(ni.title, ni.content, transactions);
    const dedupHash = computeInsightDedupHash(ni.type, ni.title, ni.content);
    return {
      user_id: userId,
      type: ni.type as string,
      priority: ni.priority as string,
      title: ni.title,
      content: ni.content,
      linked_transaction_ids: links.transactionIds,
      linked_category_ids: links.categoryIds,
      dedup_hash: dedupHash
    };
  });

  // 5. Map forecasts to insights
  const categoryMap = new Map<string, string>();
  for (const t of transactions) {
    if (t.category_id && t.category_name) {
      categoryMap.set(t.category_name.toLowerCase(), t.category_id);
    }
  }

  const forecastInsights = forecasts.map(f => {
    const title = `Prognoza wydatków: ${f.category_name}`;
    const content = `Prognozowane wydatki w kategorii ${f.category_name} na kolejny miesiąc wynoszą ${parseFloat(f.predicted_spending).toFixed(2)} PLN (pewność: ${parseFloat(f.confidence).toFixed(1)}%). Oczekiwany trend: ${f.trend === 'up' ? 'wzrostowy' : f.trend === 'down' ? 'spadkowy' : 'stabilny'}.`;
    const dedupHash = computeInsightDedupHash('forecast', title, content);
    const catId = categoryMap.get(f.category_name.toLowerCase());
    return {
      user_id: userId,
      type: 'forecast',
      priority: 'low',
      title,
      content,
      linked_transaction_ids: [] as string[],
      linked_category_ids: catId ? [catId] : ([] as string[]),
      dedup_hash: dedupHash
    };
  });

  // 6. Insert batch
  const allInsights = [...mappedInsights, ...forecastInsights];
  const inserted = await insertInsightBatch(allInsights);
  console.log(`[insights] Done — inserted ${inserted} new insights for user ${userId} (${allInsights.length - inserted} duplicates skipped)`);
}

export async function insightsWorkerLoop(): Promise<void> {
  console.log('Insights worker starting. Recovering stuck jobs...');
  await recoverStuckInsightJobs();

  let lastRecoveryAt = Date.now();

  while (true) {
    try {
      // Periodic stuck-job recovery (not just on startup)
      if (Date.now() - lastRecoveryAt > RECOVERY_INTERVAL_MS) {
        await recoverStuckInsightJobs();
        lastRecoveryAt = Date.now();
      }

      const messages = await sql`
        SELECT * FROM pgmq.read(${QUEUE_NAME}, ${VISIBILITY_TIMEOUT}, 1)
      `;

      if (messages.length === 0) {
        await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
        continue;
      }

      const msg = messages[0];
      const readCount = Number(msg.read_ct);

      console.log(`[worker] Picked up message ${msg.msg_id} (attempt ${readCount + 1}/${MAX_RETRIES})`);

      try {
        await processAnalysisMessage(msg);
        await sql`SELECT pgmq.archive(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        console.log(`[worker] Message ${msg.msg_id} processed and archived`);
      } catch (err) {
        console.error(`[worker] Message ${msg.msg_id} failed (attempt ${readCount + 1}):`, err);
        if (readCount + 1 >= MAX_RETRIES) {
          console.error(`[worker] Max retries reached for message ${msg.msg_id}. Deleting.`);
          await sql`SELECT pgmq.delete(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        } else {
          console.log(`[worker] Message ${msg.msg_id} will retry after ${VISIBILITY_TIMEOUT}s`);
        }
      }
    } catch (err) {
      console.error('[worker] Loop error:', err);
      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    }
  }
}

if (import.meta.main) {
  insightsWorkerLoop();
}
