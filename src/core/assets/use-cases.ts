import sql from '../../infrastructure/db/client';

export interface Asset {
  id: string;
  name: string;
  value: string; // Postgres numeric returns as string
  created_at: string;
  updated_at: string;
}

export async function listAssets(userId: string): Promise<Asset[]> {
  const rows = await sql`
    SELECT * FROM assets WHERE user_id = ${userId} ORDER BY name ASC
  `;
  return rows as Asset[];
}

export async function createAsset(name: string, value: number, userId: string): Promise<Asset> {
  const [row] = await sql`
    INSERT INTO assets (name, value, user_id)
    VALUES (${name}, ${value}, ${userId})
    RETURNING *
  `;
  return row as Asset;
}

export async function updateAsset(id: string, name: string, value: number, userId: string): Promise<Asset | undefined> {
  const [row] = await sql`
    UPDATE assets
    SET name = ${name}, value = ${value}
    WHERE id = ${id} AND user_id = ${userId}
    RETURNING *
  `;
  return row as Asset | undefined;
}

export async function deleteAsset(id: string, userId: string): Promise<void> {
  await sql`DELETE FROM assets WHERE id = ${id} AND user_id = ${userId}`;
}
