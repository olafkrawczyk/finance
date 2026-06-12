import { createHash } from 'crypto';
import { unlink } from 'fs/promises';
import * as XLSX from 'xlsx';
import sql from '../infrastructure/db/client';
import { ParsedTransactionSchema } from '../application/schemas/import';
import type { ParsedTransaction } from '../core/import/entities';
import {
  extractWorkbook,
  ING_BUSINESS_ACCOUNT_NAME,
  PKO_PERSONAL_ACCOUNT_NAME,
  type CategoryRecord,
} from '../core/import/excel-parser';

const QUEUE_NAME = 'import_queue';
const VISIBILITY_TIMEOUT = 300; // 5 minutes
const POLL_INTERVAL_MS = 5000;
const MAX_RETRIES = 3;
const BATCH_SIZE = 25;
const EXCEL_INSERT_BATCH_SIZE = 100;

/**
 * Strips ING CSV metadata lines above the header
 */
export function preprocessIngCsv(content: string): string {
  const lines = content.split(/\r?\n/);
  const headerIndex = lines.findIndex((line) => line.includes('Data transakcji'));
  if (headerIndex === -1) {
    throw new Error('ING CSV header not found');
  }
  const header = lines[headerIndex];
  // Keep only lines that start with a date — strips top metadata AND bottom footer rows
  const dataLines = lines.slice(headerIndex + 1).filter((l) => /^\d{4}-\d{2}-\d{2}/.test(l.trim()));
  return [header, ...dataLines].join('\n');
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

  // Reset PGMQ visibility timeout for messages stuck mid-flight so we don't wait out the full VT
  try {
    const stuck = await sql`
      SELECT msg_id FROM pgmq.q_import_queue WHERE vt > now() AND read_ct > 0
    `;
    for (const row of stuck) {
      await sql`SELECT pgmq.set_vt(${QUEUE_NAME}, ${row.msg_id}::bigint, 0)`;
      console.log(`[stuck recovery] Reset VT for PGMQ msg_id=${row.msg_id}`);
    }
  } catch (err) {
    console.error('[stuck recovery] Failed to reset PGMQ message VT:', err);
  }
}

/**
 * Computes the unique SHA-256 hash for deduplication.
 * WARNING: Because the hash only uses date, amount, description, and account_id,
 * legitimate identical transactions occurring on the same day at the same account
 * (e.g. two separate purchases of 15.00 PLN at the same coffee shop) will share
 * the same hash and be silently skipped. This is a known requirement-level limitation.
 */
export function computeImportHash(date: string, amount: string, description: string, accountId: string): string {
  return createHash('sha256')
    .update(`${date}|${amount}|${description}|${accountId}`)
    .digest('hex');
}

/**
 * Formats a few-shot prompt for the LLM based on format
 */
export function buildFewShotPrompt(
  format: 'ing' | 'ipko',
  csvRows: string,
  categories: Array<{ name: string; llm_description: string | null }>
): string {
  const categoryGuide = categories
    .map(cat => `- ${cat.name}: ${cat.llm_description ?? ''}`)
    .join('\n');

  const ingExamples = `
Examples (ING format):
Input: 2026-05-27;2026-05-27;" SOFTWAREMILL";"NIP/6392015837/Faktura VAT FVS/4/05/2026";...;33495,98;PLN
Output: {"date":"2026-05-27","amount":"33495.98","description":"SoftwareMill - Faktura VAT FVS/4/05/2026","raw_type":"income","category_name":null}

Input: 2026-05-05;2026-05-05;" P4 sp. z o. o.";"9512120077-ref";...;-246,00;PLN
Output: {"date":"2026-05-05","amount":"246.00","description":"P4 - abonament telefoniczny","raw_type":"expense","category_name":"biuro"}

Input: 2026-05-16;2026-05-16;" Urząd Skarbowy";" /TI/N.../SFP/VAT7";...;-6113,00;PLN
Output: {"date":"2026-05-16","amount":"6113.00","description":"Urząd Skarbowy - VAT7","raw_type":"expense","category_name":"VAT"}

Input: 2026-05-13;2026-05-13;" Zakład Ubezpieczeń Społecznych";" Ubezpieczenie zdrowotne";...;-3476,12;PLN
Output: {"date":"2026-05-13","amount":"3476.12","description":"ZUS - ubezpieczenie zdrowotne","raw_type":"expense","category_name":"ZUS"}

Input: 2026-05-15;2026-05-15;" Arval Service Lease";"...";...;-2957,74;PLN
Output: {"date":"2026-05-15","amount":"2957.74","description":"Arval - leasing samochodu","raw_type":"expense","category_name":"auto"}

Input: 2026-05-26;2026-05-26;" ORLEN STACJA NR 4592";" Płatność BLIK";...;-142,72;PLN
Output: {"date":"2026-05-26","amount":"142.72","description":"ORLEN - paliwo","raw_type":"expense","category_name":"paliwo"}

Input: 2026-05-25;2026-05-25;" Olaf Krawczyk";" Wplata wlasna";...;-8000,00;PLN
Output: {"date":"2026-05-25","amount":"8000.00","description":"Wplata wlasna - Olaf Krawczyk","raw_type":"expense","category_name":null}

Input: 2026-05-13;2026-05-13;" GENERALI";" Prowizja Usługi IT";...;5864,08;PLN
Output: {"date":"2026-05-13","amount":"5864.08","description":"Generali - prowizja ubezpieczeniowa","raw_type":"income","category_name":null}
`;

  const ipkoExamples = `
Examples (IPKO format):
Input: "2026-05-25","2026-05-25","Przelew na konto","+8000.00","PLN","+8200.05","Tytu: Wplata wlasna"
Output: {"date":"2026-05-25","amount":"8000.00","description":"Wplata wlasna","raw_type":"income","category_name":null}

Input: "2026-05-04","2026-05-04","Platnosc karta","-11.99","PLN","+5421.49","Tytu: ZABKA Z0685 K.2"
Output: {"date":"2026-05-04","amount":"11.99","description":"Żabka","raw_type":"expense","category_name":"żabka"}

Input: "2026-05-10","2026-05-10","Platnosc karta","-142.00","PLN","...","Tytu: ORLEN STACJA 199"
Output: {"date":"2026-05-10","amount":"142.00","description":"ORLEN - paliwo","raw_type":"expense","category_name":"paliwo"}
`;

  return `
You are a financial transaction parser for Polish bank CSV exports.
Bank format: ${format === 'ing' ? 'ING (semicolon-delimited, comma decimal, windows-1250)' : 'IPKO (comma-quoted, UTF-8, signed amounts)'}

Rules:
- Date format: YYYY-MM-DD
- Amount: ALWAYS positive decimal string with dot separator (e.g., "123.45")
- Description: concise Polish description (remove transaction IDs, card numbers, raw bank codes)
- raw_type: "income" for money received (positive amount), "expense" for money spent (negative amount) — own-account transfers follow the same rule: money leaving = expense, money arriving = income
- category_name: use the category guide below — assign null if nothing clearly matches
${categoryGuide}

${format === 'ing' ? ingExamples : ipkoExamples}

Now parse these rows. Return ONLY a JSON object with a "transactions" array. No markdown, no explanations.
Each output row must correspond exactly to one input row — do not merge or split rows.

Rows to parse:
${csvRows}
`;
}

/**
 * Sends a batch of rows to OpenRouter for structured parsing
 */
export async function callOpenRouter(csvRows: string, format: 'ing' | 'ipko', categories: Array<{ name: string; llm_description: string | null }> = []): Promise<ParsedTransaction[]> {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey && process.env.NODE_ENV !== 'test') {
    throw new Error('OPENROUTER_API_KEY not set');
  }

  const baseUrl = process.env.OPENROUTER_BASE_URL ?? 'https://openrouter.ai/api/v1';
  const model = process.env.OPENROUTER_MODEL ?? 'openai/gpt-4o-mini';

  const prompt = buildFewShotPrompt(format, csvRows, categories);

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
                    raw_type: { type: 'string', enum: ['income', 'expense'] },
                    category_name: { type: ['string', 'null'] },
                  },
                  required: ['date', 'amount', 'description', 'raw_type', 'category_name'],
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
      max_tokens: 8192,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenRouter error: ${response.status} ${errorText}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) {
    console.error('[import] OpenRouter returned empty content. Model:', model, 'Response:', JSON.stringify(data).slice(0, 500));
    throw new Error(`Empty content from OpenRouter (model: ${model}). Check worker logs for full response.`);
  }

  // Extract JSON — some models wrap in markdown fences even when asked not to
  const jsonMatch = content.match(/```json\s*([\s\S]*?)```/) || content.match(/(\{[\s\S]*\})/);
  const jsonStr = jsonMatch ? jsonMatch[1] : content;
  const parsedJson = JSON.parse(jsonStr);
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
export async function insertBatch(
  accountId: string,
  transactions: ParsedTransaction[],
  categoryMap: Map<string, string> = new Map(),
  userId: string
): Promise<void> {
  const accounts = await sql`SELECT id FROM accounts WHERE user_id = ${userId}`;
  const otherAccount = accounts.find((a) => a.id !== accountId);
  const otherAccountId = otherAccount?.id ?? null;

  await sql.begin(async (sql) => {
    for (const tx of transactions) {
      const hash = computeImportHash(tx.date, tx.amount, tx.description, accountId);
      const transferToAccountId = tx.raw_type === 'transfer' ? otherAccountId : null;
      const categoryId = tx.category_name ? (categoryMap.get(tx.category_name.toLowerCase()) ?? null) : null;

      await sql`
        INSERT INTO transactions (
          account_id,
          category_id,
          type,
          amount,
          description,
          date,
          transfer_to_account_id,
          import_hash,
          user_id
        )
        VALUES (
          ${accountId},
          ${categoryId},
          ${tx.raw_type},
          ${tx.amount},
          ${tx.description},
          ${tx.date},
          ${transferToAccountId},
          ${hash},
          ${userId}
        )
        ON CONFLICT (user_id, import_hash) DO NOTHING
      `;
    }
  });
}

/**
 * Processes an enqueued `excel_migration` job: loads the workbook from disk,
 * parses all monthly sheets chronologically, ingests opening balances and
 * transactions (mapping categories and routing accounts), and updates job
 * progress dynamically. Always cleans up the temporary upload file.
 */
export async function processExcelMigrationJob(payload: {
  job_id: string;
  type: 'excel_migration';
  file_path: string;
  user_id: string;
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, file_path, user_id } = payload;
  const errors: string[] = [];

  try {
    // 1. Update status to 'processing'
    await sql`
      UPDATE import_jobs
      SET status = 'processing', updated_at = now()
      WHERE id = ${job_id} AND user_id = ${user_id}
    `;

    // 2. Load categories and resolve account IDs
    const dbCategories = (await sql`
      SELECT id, name FROM categories WHERE user_id = ${user_id}
    `) as unknown as CategoryRecord[];

    const [ingAccount] = await sql`SELECT id FROM accounts WHERE name = ${ING_BUSINESS_ACCOUNT_NAME} AND user_id = ${user_id} LIMIT 1`;
    const [pkoAccount] = await sql`SELECT id FROM accounts WHERE name = ${PKO_PERSONAL_ACCOUNT_NAME} AND user_id = ${user_id} LIMIT 1`;
    if (!ingAccount) throw new Error(`Seeded account "${ING_BUSINESS_ACCOUNT_NAME}" not found`);
    if (!pkoAccount) throw new Error(`Seeded account "${PKO_PERSONAL_ACCOUNT_NAME}" not found`);

    const accountIdByRoute: Record<'ing_business' | 'pko_personal', string> = {
      ing_business: ingAccount.id,
      pko_personal: pkoAccount.id,
    };

    // 3. Load workbook and parse all monthly sheets chronologically
    const fileBuffer = await Bun.file(file_path).arrayBuffer();
    const workbook = XLSX.read(fileBuffer, { type: 'buffer', cellDates: false });
    const sheets = extractWorkbook(workbook, dbCategories);

    // 4. Compute total rows for progress tracking (BEFORE outer transaction)
    const totalRows = sheets.reduce((sum, sheet) => sum + sheet.transactions.length, 0);
    await sql`
      UPDATE import_jobs
      SET total_rows = ${totalRows}, updated_at = now()
      WHERE id = ${job_id} AND user_id = ${user_id}
    `;

    // 5. Empty workbook guard — no parseable data found (GAP-04)
    if (totalRows === 0) {
      const errMsg = 'No parseable data found in workbook';
      await sql`
        UPDATE import_jobs
        SET status = 'failed', errors = array_append(ARRAY[]::text[], ${errMsg}), processed = 0, updated_at = now()
        WHERE id = ${job_id} AND user_id = ${user_id}
      `;
      return { processed: 0, errors: [errMsg] };
    }

    // 6. Outer transaction — all data operations are atomic (GAP-03)
    await sql.begin(async (tx) => {
      for (const sheet of sheets) {
        try {
          if (sheet.openingBalance !== null) {
            await tx`
              INSERT INTO monthly_opening_balances (year, month, opening_balance, user_id)
              VALUES (${sheet.meta.year}, ${sheet.meta.month}, ${sheet.openingBalance}, ${user_id})
              ON CONFLICT (user_id, year, month) DO NOTHING
            `;
          }

          const transactions = sheet.transactions;
          for (let i = 0; i < transactions.length; i += EXCEL_INSERT_BATCH_SIZE) {
            const batch = transactions.slice(i, i + EXCEL_INSERT_BATCH_SIZE);
            for (const txn of batch) {
              const accountId = accountIdByRoute[txn.routedAccount];
              const categoryId = txn.category?.id ?? null;

              await tx`
                INSERT INTO transactions (
                  account_id,
                  category_id,
                  type,
                  amount,
                  description,
                  date,
                  import_hash,
                  user_id
                )
                VALUES (
                  ${accountId},
                  ${categoryId},
                  ${txn.type},
                  ${txn.amount},
                  ${txn.description},
                  ${txn.date},
                  ${txn.importHash},
                  ${user_id}
                )
                ON CONFLICT (user_id, import_hash) DO NOTHING
              `;
            }
          }
        } catch (sheetErr) {
          const errMsg = sheetErr instanceof Error ? sheetErr.message : 'Unknown sheet error';
          console.error(`Error processing sheet "${sheet.meta.sheetName}":`, errMsg);
          throw new Error(`Sheet ${sheet.meta.sheetName}: ${errMsg}`);
        }
      }
    });

    // 7. Outer transaction committed — all data persisted atomically
    await sql`
      UPDATE import_jobs
      SET status = 'completed', processed = ${totalRows}, updated_at = now()
      WHERE id = ${job_id} AND user_id = ${user_id}
    `;

    // Success path: delete temp file only on completion (GAP-02)
    try {
      await unlink(file_path);
    } catch (cleanupErr) {
      if ((cleanupErr as NodeJS.ErrnoException)?.code !== 'ENOENT') {
        console.error(`Failed to delete temp upload ${file_path}:`, cleanupErr);
      }
    }

    return { processed: totalRows, errors: [] };
  } catch (err) {
    const errMsg = err instanceof Error ? err.message : 'Unknown migration job error';
    console.error(`Fatal Excel migration error on job ${job_id}:`, errMsg);
    errors.push(`Fatal: ${errMsg}`);

    await sql`
      UPDATE import_jobs
      SET status = 'failed', errors = array_append(COALESCE(errors, ARRAY[]::text[]), ${errMsg}), updated_at = now()
      WHERE id = ${job_id} AND user_id = ${user_id}
    `;

    // Do NOT delete temp file on failure — it must persist for PGMQ retries (GAP-02)

    return { processed: 0, errors };
  }
}

/**
 * Processes an enqueued import job
 */
export async function processJob(payload: {
  job_id: string;
  type?: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
  user_id: string;
} | {
  job_id: string;
  type: 'excel_migration';
  file_path: string;
  user_id: string;
}): Promise<{ processed: number; errors: string[] }> {
  if ((payload as { type?: string }).type === 'excel_migration') {
    return processExcelMigrationJob(payload as { job_id: string; type: 'excel_migration'; file_path: string; user_id: string });
  }

  return processCsvImportJob(payload as {
    job_id: string;
    account_id: string;
    csv_content: string;
    bank_format: 'ing' | 'ipko';
    user_id: string;
  });
}

/**
 * Processes an enqueued CSV (LLM-based) import job — the original pipeline.
 */
async function processCsvImportJob(payload: {
  job_id: string;
  account_id: string;
  csv_content: string;
  bank_format: 'ing' | 'ipko';
  user_id: string;
}): Promise<{ processed: number; errors: string[] }> {
  const { job_id, account_id, csv_content, bank_format, user_id } = payload;
  const errors: string[] = [];
  let totalProcessed = 0;

  try {
    // 0. Input validation guard: prevent crash when csv_content is missing (GAP-01)
    if (typeof csv_content !== 'string' || csv_content.length === 0) {
      throw new Error(`Invalid or missing csv_content for job ${job_id}`);
    }

    // Validate account_id belongs to user (D-02: implicit SQL WHERE)
    const [account] = await sql`
      SELECT id FROM accounts WHERE id = ${account_id} AND user_id = ${user_id}
    `;
    if (!account) {
      console.error(`Account ${account_id} not found for user ${user_id} — skipping job`);
      return { processed: 0, errors: [`Account ${account_id} not found for user ${user_id}`] };
    }

    // 1. Update status to 'processing'
    await sql`
      UPDATE import_jobs
      SET status = 'processing', updated_at = now()
      WHERE id = ${job_id} AND user_id = ${user_id}
    `;

    // 2. Load categories for LLM classification
    const categoryRows = await sql`SELECT id, name, llm_description FROM categories WHERE user_id = ${user_id}`;
    const categoryMap = new Map<string, string>(categoryRows.map((r) => [r.name.toLowerCase(), r.id]));
    const categoryNames = categoryRows.map((r) => ({ name: r.name as string, llm_description: r.llm_description as string | null }));

    // 3. Preprocess CSV
    const preprocessed = bank_format === 'ing'
      ? preprocessIngCsv(csv_content)
      : preprocessIpkoCsv(csv_content);

    const totalRows = countTransactionRows(preprocessed, bank_format);
    await sql`
      UPDATE import_jobs
      SET total_rows = ${totalRows}, updated_at = now()
      WHERE id = ${job_id} AND user_id = ${user_id}
    `;

    const lines = preprocessed.split(/\r?\n/).filter((l) => l.trim().length > 0);
    const header = lines[0];
    const dataRows = lines.slice(1);

    console.log(`[import] Job ${job_id} started — ${totalRows} rows to process`);

    // 3. Process batches of 50
    for (let i = 0; i < dataRows.length; i += BATCH_SIZE) {
      const batch = dataRows.slice(i, i + BATCH_SIZE);
      const batchCsvText = [header, ...batch].join('\n');

      try {
        const MAX_BATCH_RETRIES = 3;
        let parsed: ParsedTransaction[] | null = null;
        let lastErr: unknown;
        for (let attempt = 1; attempt <= MAX_BATCH_RETRIES; attempt++) {
          try {
            const result = await callOpenRouter(batchCsvText, bank_format, categoryNames);
            if (result.length === batch.length) {
              parsed = result;
              break;
            }
            console.warn(`[import] Batch rows ${i}–${i + batch.length - 1} attempt ${attempt}/${MAX_BATCH_RETRIES}: LLM returned ${result.length}, expected ${batch.length}`);
          } catch (callErr) {
            lastErr = callErr;
            console.warn(`[import] Batch rows ${i}–${i + batch.length - 1} attempt ${attempt}/${MAX_BATCH_RETRIES}: ${callErr instanceof Error ? callErr.message : callErr}`);
          }
        }
        if (!parsed) {
          const reason = lastErr instanceof Error ? lastErr.message : `wrong row count`;
          throw new Error(`LLM failed for batch rows ${i}–${i + batch.length - 1} after ${MAX_BATCH_RETRIES} attempts: ${reason}`);
        }

        await insertBatch(account_id, parsed, categoryMap, user_id);
        totalProcessed += batch.length;
        console.log(`[import] Batch rows ${i}–${i + batch.length - 1}: ${parsed.length} transactions saved`);

        await sql`
          UPDATE import_jobs
          SET processed = ${totalProcessed}, updated_at = now()
          WHERE id = ${job_id} AND user_id = ${user_id}
        `;
      } catch (batchErr) {
        const errMsg = batchErr instanceof Error ? batchErr.message : 'Unknown batch error';
        console.error(`[import] Batch rows ${i}–${i + batch.length - 1} failed:`, errMsg);
        errors.push(`Row ${i}-${i + batch.length}: ${errMsg}`);

        await sql`
          UPDATE import_jobs
          SET errors = array_append(COALESCE(errors, ARRAY[]::text[]), ${errMsg}), updated_at = now()
          WHERE id = ${job_id} AND user_id = ${user_id}
        `;
      }
    }

    // 4. Final status update
    const finalStatus = errors.length > 0 && totalProcessed === 0 ? 'failed' : 'completed';
    await sql`
      UPDATE import_jobs
      SET status = ${finalStatus}, updated_at = now()
      WHERE id = ${job_id} AND user_id = ${user_id}
    `;
    console.log(`[import] Job ${job_id} ${finalStatus} — ${totalProcessed}/${totalRows} rows, ${errors.length} batch error(s)`);

    return { processed: totalProcessed, errors };
  } catch (err) {
    const errMsg = err instanceof Error ? err.message : 'Unknown job error';
    console.error(`[import] Job ${job_id} fatal error:`, errMsg);
    errors.push(`Fatal: ${errMsg}`);

    await sql`
      UPDATE import_jobs
      SET status = 'failed', errors = array_append(COALESCE(errors, ARRAY[]::text[]), ${errMsg}), updated_at = now()
      WHERE id = ${job_id} AND user_id = ${user_id}
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

      console.log(`[import] Picked up job ${payload.job_id} (msg=${msg.msg_id}, attempt ${readCount + 1}/${MAX_RETRIES})`);

      try {
        const { processed, errors } = await processJob(payload);
        if (errors.length > 0 && processed === 0) {
          throw new Error('All batches failed');
        }
        await sql`SELECT pgmq.archive(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        console.log(`[import] Archived msg=${msg.msg_id}`);
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : String(err);
        console.error(`[import] Job ${payload.job_id} failed (attempt ${readCount + 1}/${MAX_RETRIES}): ${errMsg}`);
        if (readCount + 1 >= MAX_RETRIES) {
          console.error(`[import] Max retries reached for job ${payload.job_id}. Deleting msg=${msg.msg_id}.`);

          // Clean up temp file for excel_migration payloads on max retries exhausted (GAP-02)
          if ((payload as { type?: string }).type === 'excel_migration') {
            const file_path = (payload as { file_path?: string }).file_path;
            if (file_path) {
              try {
                await unlink(file_path);
              } catch (cleanupErr) {
                if ((cleanupErr as NodeJS.ErrnoException)?.code !== 'ENOENT') {
                  console.error(`Failed to delete temp upload ${file_path} on max retries:`, cleanupErr);
                }
              }
            }
          }

          await sql`
            UPDATE import_jobs
            SET status = 'failed', errors = array_append(COALESCE(errors, ARRAY[]::text[]), 'Max retries exceeded')
            WHERE id = ${payload.job_id}
          `;
          await sql`SELECT pgmq.delete(${QUEUE_NAME}, ${msg.msg_id}::bigint)`;
        } else {
          console.log(`[import] Will retry after ${VISIBILITY_TIMEOUT}s`);
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
