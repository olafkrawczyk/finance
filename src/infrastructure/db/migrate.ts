import { runner } from 'node-pg-migrate';

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error('FATAL: DATABASE_URL environment variable is not set');
  process.exit(1);
}

const direction = (process.argv[2] || 'up') as 'up' | 'down';
const isFake = process.argv.includes('--fake');

async function main() {
  console.log(`Running migrations [${direction}]${isFake ? ' (fake mode)' : ''}...`);
  await runner({
    databaseUrl: DATABASE_URL,
    dir: 'src/infrastructure/db/migrations',
    direction,
    migrationsTable: 'pgmigrations',
    migrationFileLanguage: 'sql',
    fake: isFake,
    log: (msg) => console.log(`[migrate] ${msg}`),
  });
  console.log('Migrations complete.');
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
