import { join } from 'path';
import sql from './client';

export async function applySchema() {
  const schemaPath = join(import.meta.dir, 'schema.sql');
  const seedPath = join(import.meta.dir, 'seed.sql');

  const schemaSql = await Bun.file(schemaPath).text();
  const seedSql = await Bun.file(seedPath).text();

  console.log('Applying schema.sql...');
  await sql.unsafe(schemaSql);

  console.log('Applying seed.sql...');
  await sql.unsafe(seedSql);

  console.log('Database schema and seed applied successfully.');
}

if (import.meta.main) {
  try {
    await applySchema();
  } catch (error) {
    console.error('Error applying schema/seed:', error);
    process.exit(1);
  } finally {
    await sql.end();
  }
}
