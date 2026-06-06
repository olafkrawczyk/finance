import { createHash } from 'crypto';
import sql from '../infrastructure/db/client';
import { ClaudeInsightSchema, R1ForecastSchema } from '../application/schemas/insights';
import type { Insight, CategoryAggregate, ForecastResult, TransactionData } from '../core/insights/entities';
import { getInsightDataWindow, getCategoryAggregates, insertInsightBatch } from '../core/insights/use-cases';
import * as z from 'zod';

export const QUEUE_NAME = 'analysis_queue';
export const VISIBILITY_TIMEOUT = 300; // 5 minutes
export const POLL_INTERVAL_MS = 5000;
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
  return `Jesteś profesjonalnym polskim doradcą finansowym analizującym historię transakcji użytkownika.
Twoim zadaniem jest wygenerowanie przydatnych, spersonalizowanych analiz w języku polskim w formacie JSON.
Generuj wskazówki (tip), trendy (trend) oraz alerty (alert) dotyczące wydatków, budżetu i nawyków finansowych.

Każda wskazówka musi zawierać:
- type: Jeden z: 'alert' (np. nagły wzrost wydatków), 'tip' (np. porady oszczędnościowe), 'trend' (np. analiza wydatków w kategoriach)
- priority: Jeden z: 'high', 'medium', 'low'
- title: Zwięzły tytuł (maksymalnie 100 znaków)
- content: Szczegółowa treść analizy (maksymalnie 1000 znaków)

Przykład wyjścia:
{
  "insights": [
    {
      "type": "alert",
      "priority": "high",
      "title": "Wzrost wydatków na artykuły spożywcze",
      "content": "W tym miesiącu Twoje wydatki na artykuły spożywcze wzrosły o 45% w porównaniu do poprzedniego okresu. Rozważ ustalenie limitu budżetowego."
    },
    {
      "type": "tip",
      "priority": "medium",
      "title": "Ograniczenie subskrypcji",
      "content": "Zauważyliśmy powtarzające się małe opłaty za usługi streamingowe. Anulowanie jednej z nich pozwoli zaoszczędzić około 30 PLN miesięcznie."
    }
  ]
}

Zasady:
- Odpowiadaj wyłącznie poprawnym obiektem JSON. Nie dodawaj żadnych wyjaśnień poza kodem JSON.
- Wygeneruj wszystkie wykryte analizy.
`;
}

export function buildInsightsPrompt(transactions: TransactionData[]): string {
  const txList = transactions.map(t =>
    `- Date: ${t.date}, Amount: ${t.amount} PLN, Category: ${t.category_name ?? 'Uncategorized'}, Type: ${t.type}, Description: ${t.description ?? ''}`
  ).join('\n');
  return `Oto lista transakcji z ostatnich 3 miesięcy wraz z okresem porównawczym z zeszłego roku:

${txList}

Przeanalizuj te dane i wygeneruj przydatne wskazówki finansowe, alerty oraz trendy w języku polskim.`;
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
  const model = process.env.OPENROUTER_INSIGHTS_MODEL ?? 'anthropic/claude-3.5-sonnet';

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
    throw new Error(`OpenRouter error: ${response.status}`);
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
  const model = process.env.OPENROUTER_FORECAST_MODEL ?? 'deepseek/deepseek-r1:free';

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
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'forecast_response',
            strict: true,
            schema: {
              type: 'object',
              properties: {
                forecasts: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      category_name: { type: 'string' },
                      predicted_spending: { type: 'string' },
                      confidence: { type: 'string' },
                      trend: { type: 'string', enum: ['up', 'down', 'flat'] }
                    },
                    required: ['category_name', 'predicted_spending', 'confidence', 'trend'],
                    additionalProperties: false
                  }
                }
              },
              required: ['forecasts'],
              additionalProperties: false
            }
          }
        },
        temperature: 0.1,
        max_tokens: 4096
      })
    });

    if (!response.ok) {
      console.warn(`OpenRouter R1 API error: ${response.status}`);
      return [];
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      return [];
    }

    const parsedJson = JSON.parse(content);
    const rawForecasts = parsedJson.forecasts;
    if (!Array.isArray(rawForecasts)) {
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

  const uniqueCategories = new Map<string, string>(); // name -> id
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
    console.error('[stuck recovery] Failed to recover stuck insights jobs:', err);
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
        console.log(`Skipping manual analysis for user ${userId} due to cooldown`);
        return;
      }
    }
  }

  // 1. Fetch transaction window
  const transactions = await getInsightDataWindow(userId);
  if (transactions.length === 0) {
    console.log(`No transactions found for user ${userId}. Skipping insights generation.`);
    return;
  }

  const txIds = transactions.map(t => t.id);

  // 2. Call Claude for narrative insights
  const narrativeInsightsRaw = await callClaudeForInsights(transactions);

  // 3. Call DeepSeek R1 for category forecasts
  const aggregates = await getCategoryAggregates(txIds);
  const forecasts = aggregates.length > 0 ? await callDeepSeekForForecast(aggregates) : [];

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
  console.log(`Inserted ${inserted} new insights for user ${userId}.`);
}

export async function insightsWorkerLoop(): Promise<void> {
  console.log('Insights worker starting. Recovering stuck jobs...');
  await recoverStuckInsightJobs();

  while (true) {
    try {
      const messages = await sql`
        SELECT * FROM pgmq.read(${QUEUE_NAME}, ${VISIBILITY_TIMEOUT}, 1)
      `;

      if (messages.length === 0) {
        await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
        continue;
      }

      const msg = messages[0];
      const readCount = Number(msg.read_ct);

      try {
        await processAnalysisMessage(msg);
        await sql`SELECT pgmq.archive(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
      } catch (err) {
        console.error(`Message ${msg.msg_id} failed (attempt ${readCount}):`, err);
        if (readCount >= MAX_RETRIES) {
          console.error(`Max retries reached for message ${msg.msg_id}. Deleting.`);
          await sql`SELECT pgmq.delete(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        }
      }
    } catch (err) {
      console.error('Insights worker loop error:', err);
      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    }
  }
}

if (import.meta.main) {
  insightsWorkerLoop();
}
