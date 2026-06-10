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

export async function createAccount(
  name: string,
  type: string,
  currency: string,
  starting_balance: number,
  starting_balance_date: string | null | undefined,
  userId: string
) {
  const [row] = await sql`
    INSERT INTO accounts (name, type, currency, starting_balance, starting_balance_date, user_id)
    VALUES (${name}, ${type}, ${currency}, ${starting_balance}, ${starting_balance_date ?? null}, ${userId})
    RETURNING *
  `;
  return row;
}

export async function updateAccount(
  id: string,
  name: string | undefined,
  starting_balance: number | undefined,
  starting_balance_date: string | null | undefined,
  userId: string
) {
  const [row] = await sql`
    UPDATE accounts
    SET
      name = COALESCE(${name ?? null}, name),
      starting_balance = COALESCE(${starting_balance ?? null}, starting_balance),
      starting_balance_date = COALESCE(${starting_balance_date ?? null}, starting_balance_date)
    WHERE id = ${id} AND user_id = ${userId}
    RETURNING *
  `;
  return row;
}

export async function deleteAccount(id: string, userId: string) {
  const [countResult] = await sql`
    SELECT COUNT(*)::int AS count FROM transactions
    WHERE account_id = ${id} OR transfer_to_account_id = ${id}
  `;
  if (countResult.count > 0) {
    throw new Error(`Cannot delete account with ${countResult.count} transaction(s)`);
  }
  const [result] = await sql`
    DELETE FROM accounts WHERE id = ${id} AND user_id = ${userId} RETURNING id
  `;
  return !!result;
}
