import sql from '../../infrastructure/db/client';

export async function listAccounts(userId: string) {
  const rows = await sql`
    SELECT * FROM accounts WHERE user_id = ${userId} ORDER BY name
  `;
  return rows;
}

export async function listCategories(userId: string) {
  const rows = await sql`
    SELECT * FROM categories WHERE user_id = ${userId} ORDER BY name
  `;
  return rows;
}
