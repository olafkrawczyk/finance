import { createHash } from 'crypto';
import sql from '../infrastructure/db/client';
import { ParsedTransactionSchema } from '../application/schemas/import';
import type { ParsedTransaction } from '../core/import/entities';

const QUEUE_NAME = 'import_queue';
const VISIBILITY_TIMEOUT = 300; // 5 minutes
const POLL_INTERVAL_MS = 5000;
const MAX_RETRIES = 3;
const BATCH_SIZE = 50;

/**
 * Strips ING CSV metadata lines above the header
 */
export function preprocessIngCsv(content: string): string {
  const lines = content.split(/\r?\n/);
  const headerIndex = lines.findIndex((line) => line.includes('Data transakcji'));
  if (headerIndex === -1) {
    throw new Error('ING CSV header not found');
  }
  return lines.slice(headerIndex).join('\n');
}

/**
 * Filters out IPKO "Blokada" rows
 */
export function preprocessIpkoCsv(content: string): string {
  const lines = content.split(/\r?\n/);
  const header = lines[0];
  const dataLines = lines.slice(1).filter((line) => !line.includes('"Blokada"'));
  return [header, ...dataLines].join('\n');
}

/**
 * Helper to count rows excluding the header and empty lines
 */
export function countTransactionRows(preprocessed: string, format: 'ing' | 'ipko'): number {
  const lines = preprocessed.split(/\r?\n/).filter((l) => l.trim().length > 0);
  return lines.length > 0 ? lines.length - 1 : 0;
}

/**
 * central table for stuck job timeout check (02-REVIEWS.md)
 */
export async function recoverStuckJobs(): Promise<void> {
  try {
    const result = await sql`
      UPDATE import_jobs
      SET status = 'failed', errors = array_append(COALESCE(errors, ARRAY[]::text[]), 'Job timed out / worker crashed')
      WHERE status = 'processing' AND updated_at < now() - interval '15 minutes'
    `;
    if (result.count > 0) {
      console.log(`[stuck recovery] Marked ${result.count} stuck jobs as failed.`);
    }
  } catch (err) {
    console.error('[stuck recovery] Failed to recover stuck jobs:', err);
  }
}

/**
 * Computes the unique SHA-256 hash for deduplication.
 * WARNING: Because the hash only uses date, amount, and description,
 * legitimate identical transactions occurring on the same day (e.g. two separate
 * purchases of 15.00 PLN at the same coffee shop) will share the same hash
 * and be silently skipped. This is a known requirement-level limitation.
 */
export function computeImportHash(date: string, amount: string, description: string): string {
  return createHash('sha256')
    .update(`${date}|${amount}|${description}`)
    .digest('hex');
}

/**
 * Formats a few-shot prompt for the LLM based on format
 */
export function buildFewShotPrompt(format: 'ing' | 'ipko', csvRows: string): string {
  const ingExamples = `
Example 1:
Input: 2026-05-27;2026-05-27;" SOFTWAREMILL";"NIP/6392015837/Faktura VAT nr FVS/4 /05/2026";...;33495,98;PLN
Output: {"date":"2026-05-27","amount":"33495.98","description":"SoftwareMill - Faktura VAT FVS/4/05/2026","raw_type":"income"}

Example 2:
Input: 2026-05-05;2026-05-05;" P4 sp. z o. o.";"9512120077-20260603-041168C00305-0D";...;-246,00;PLN
Output: {"date":"2026-05-05","amount":"246.00","description":"P4 sp. z o.o. - 9512120077-20260603-041168C00305-0D","raw_type":"expense"}

Example 3:
Input: 2026-05-25;2026-05-25;" Olaf Krawczyk";"Wplata wlasna";...;-8000,00;PLN
Output: {"date":"2026-05-25","amount":"8000.00","description":"Wplata wlasna - Olaf Krawczyk","raw_type":"transfer"}
`;

  const ipkoExamples = `
Example 1:
Input: "2026-05-25","2026-05-25","Przelew na konto","+8000.00","PLN","+8200.05","Tytu: Wplata wlasna"
Output: {"date":"2026-05-25","amount":"8000.00","description":"Wplata wlasna","raw_type":"transfer"}

Example 2:
Input: "2026-05-04","2026-05-04","Patno kart","-11.99","PLN","+5421.49","Tytu: ZABKA Z0685 K.2"
Output: {"date":"2026-05-04","amount":"11.99","description":"ZABKA Z0685 K.2","raw_type":"expense"}
`;

  return `
You are a financial transaction parser for Polish bank CSV exports.
Bank format: ${format === 'ing' ? 'ING (semicolon-delimited, comma decimal, windows-1250)' : 'IPKO (comma-quoted, UTF-8, signed amounts)'}

Rules:
- Date format: YYYY-MM-DD
- Amount: ALWAYS positive decimal string with dot separator (e.g., "123.45")
- Description: concise, clean description (remove transaction IDs, card numbers, bank names)
- raw_type: "income" for money received, "expense" for money spent, "transfer" for between own accounts

${format === 'ing' ? ingExamples : ipkoExamples}

Now parse these rows. Return ONLY a JSON object with a "transactions" array. No markdown, no explanations.

Rows to parse:
${csvRows}
`;
}

/**
 * Sends a batch of rows to OpenRouter for structured parsing
 */
export async function callOpenRouter(csvRows: string, format: 'ing' | 'ipko'): Promise<ParsedTransaction[]> {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey && process.env.NODE_ENV !== 'test') {
    throw new Error('OPENROUTER_API_KEY not set');
  }

  const baseUrl = process.env.OPENROUTER_BASE_URL ?? 'https://openrouter.ai/api/v1';
  const model = process.env.OPENROUTER_MODEL ?? 'openai/gpt-4o-mini';

  const prompt = buildFewShotPrompt(format, csvRows);

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
      messages: [{ role: 'user', content: prompt }],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'transactions_response',
          strict: true,
          schema: {
            type: 'object',
            properties: {
              transactions: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    date: { type: 'string' },
                    amount: { type: 'string' },
                    description: { type: 'string' },
                    raw_type: { type: 'string', enum: ['income', 'expense', 'transfer'] },
                  },
                  required: ['date', 'amount', 'description', 'raw_type'],
                  additionalProperties: false,
                },
              },
            },
            required: ['transactions'],
            additionalProperties: false,
          },
        },
      },
      temperature: 0.1,
      max_tokens: 4096,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenRouter error: ${response.status} ${errorText}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('Empty message content returned from OpenRouter');
  }

  const parsedJson = JSON.parse(content);
  const rawTransactions = parsedJson.transactions;
  if (!Array.isArray(rawTransactions)) {
    throw new Error('OpenRouter response did not contain a transactions array');
  }

  const validTransactions: ParsedTransaction[] = [];
  for (const tx of rawTransactions) {
    const validation = ParsedTransactionSchema.safeParse(tx);
    if (validation.success) {
      validTransactions.push(validation.data as ParsedTransaction);
    } else {
      console.warn('Filtered out invalid transaction from LLM:', tx, validation.error.format());
    }
  }

  return validTransactions;
}

/**
 * Inserts a batch of transactions with de-duplication and transfer account linking
 */
export async function insertBatch(accountId: string, transactions: ParsedTransaction[]): Promise<void> {
  // Fetch all accounts to dynamically link transfer destinations (02-REVIEWS.md)
  const accounts = await sql`SELECT id FROM accounts`;
  const otherAccount = accounts.find((a) => a.id !== accountId);
  const otherAccountId = otherAccount?.id ?? null;

  await sql.begin(async (sql) => {
    for (const tx of transactions) {
      const hash = computeImportHash(tx.date, tx.amount, tx.description);
      const transferToAccountId = tx.raw_type === 'transfer' ? otherAccountId : null;

      await sql`
        INSERT INTO transactions (
          account_id,
          category_id,
          type,
          amount,
          description,
          date,
          transfer_to_account_id,
          import_hash
        )
        VALUES (
          ${accountId},
          null,
          ${tx.raw_type},
          ${tx.amount},
          ${tx.description},
          ${tx.date},
          ${transferToAccountId},
          ${hash}
        )
        ON CONFLICT (import_hash) DO NOTHING
      `;
    }
  });
}

/**
 * Processes an enqueued import job
 */
export async function processJob(payload: {
  job_id: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, account_id, csv_content, bank_format } = payload;
  const errors: string[] = [];
  let totalProcessed = 0;

  try {
    // 1. Update status to 'processing'
    await sql`
      UPDATE import_jobs
      SET status = 'processing', updated_at = now()
      WHERE id = ${job_id}
    `;

    // 2. Preprocess CSV
    const preprocessed = bank_format === 'ing'
      ? preprocessIngCsv(csv_content)
      : preprocessIpkoCsv(csv_content);

    const totalRows = countTransactionRows(preprocessed, bank_format);
    await sql`
      UPDATE import_jobs
      SET total_rows = ${totalRows}, updated_at = now()
      WHERE id = ${job_id}
    `;

    const lines = preprocessed.split(/\r?\n/).filter((l) => l.trim().length > 0);
    const header = lines[0];
    const dataRows = lines.slice(1);

    // 3. Process batches of 50
    for (let i = 0; i < dataRows.length; i += BATCH_SIZE) {
      const batch = dataRows.slice(i, i + BATCH_SIZE);
      const batchCsvText = [header, ...batch].join('\n');

      try {
        const parsed = await callOpenRouter(batchCsvText, bank_format);

        // MITIGATION: Assert LLM returned row count equals input row count (02-REVIEWS.md)
        if (parsed.length !== batch.length) {
          throw new Error(`LLM returned ${parsed.length} transactions, but input had ${batch.length} rows.`);
        }

        await insertBatch(account_id, parsed);
        totalProcessed += batch.length;

        await sql`
          UPDATE import_jobs
          SET processed = ${totalProcessed}, updated_at = now()
          WHERE id = ${job_id}
        `;
      } catch (batchErr) {
        const errMsg = batchErr instanceof Error ? batchErr.message : 'Unknown batch error';
        console.error(`Error processing batch at row ${i}:`, errMsg);
        errors.push(`Row ${i}-${i + batch.length}: ${errMsg}`);

        await sql`
          UPDATE import_jobs
          SET errors = array_append(COALESCE(errors, ARRAY[]::text[]), ${errMsg}), updated_at = now()
          WHERE id = ${job_id}
        `;
      }
    }

    // 4. Final status update
    const finalStatus = errors.length > 0 && totalProcessed === 0 ? 'failed' : 'completed';
    await sql`
      UPDATE import_jobs
      SET status = ${finalStatus}, updated_at = now()
      WHERE id = ${job_id}
    `;

    return { processed: totalProcessed, errors };
  } catch (err) {
    const errMsg = err instanceof Error ? err.message : 'Unknown job error';
    console.error(`Fatal job processing error on job ${job_id}:`, errMsg);
    errors.push(`Fatal: ${errMsg}`);

    await sql`
      UPDATE import_jobs
      SET status = 'failed', errors = array_append(COALESCE(errors, ARRAY[]::text[]), ${errMsg}), updated_at = now()
      WHERE id = ${job_id}
    `;

    return { processed: totalProcessed, errors };
  }
}

/**
 * Worker polling loop
 */
async function workerLoop(): Promise<void> {
  console.log('Import worker starting. Recovering stuck jobs...');
  await recoverStuckJobs();

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
      const payload = typeof msg.message === 'string' ? JSON.parse(msg.message) : msg.message;

      try {
        const { processed, errors } = await processJob(payload);
        if (errors.length > 0 && processed === 0) {
          throw new Error('All batches failed');
        }
        await sql`SELECT pgmq.archive(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
      } catch (err) {
        console.error(`Job ${msg.msg_id} failed (attempt ${readCount}):`, err);
        if (readCount >= MAX_RETRIES) {
          console.error(`Max retries reached for job ${msg.msg_id}. Deleting.`);
          await sql`
            UPDATE import_jobs
            SET status = 'failed', errors = array_append(COALESCE(errors, ARRAY[]::text[]), 'Max retries exceeded')
            WHERE id = ${payload.job_id}
          `;
          await sql`SELECT pgmq.delete(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        }
      }
    } catch (err) {
      console.error('Worker loop error:', err);
      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    }
  }
}

if (import.meta.main) {
  workerLoop();
}
