/**
 * Wipes all data and reloads dev seed from seed-dev.sql (generated from budget.xlsx).
 * After running, register a new account at http://localhost:5173
 *
 * Usage: bun scripts/seed-dev.ts
 */
import { join } from 'path';
import sql from '../src/infrastructure/db/client';

const ROOT = join(import.meta.dir, '..');

async function main() {
  console.log('Wiping all data...');
  await sql`
    TRUNCATE
      insights,
      import_jobs,
      transactions,
      monthly_opening_balances,
      "session",
      "account",
      "verification",
      "user",
      accounts,
      categories
    RESTART IDENTITY CASCADE
  `;

  console.log('Applying seed.sql (categories, accounts, queues)...');
  const seedSql = await Bun.file(join(ROOT, 'src/infrastructure/db/seed.sql')).text();
  await sql.unsafe(seedSql);

  console.log('Applying seed-dev.sql (transactions, opening balances)...');
  const seedDevSql = await Bun.file(join(ROOT, 'src/infrastructure/db/seed-dev.sql')).text();
  await sql.unsafe(seedDevSql);

  console.log('Done. Register a new account at http://localhost:5173');
}

await main().finally(() => sql.end());
