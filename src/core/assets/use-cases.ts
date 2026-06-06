import sql from '../../infrastructure/db/client';

export interface Asset {
  id: string;
  name: string;
  value: string; // Postgres numeric returns as string
  created_at: string;
  updated_at: string;
}

export async function listAssets(): Promise<Asset[]> {
  const rows = await sql`SELECT * FROM assets ORDER BY name ASC`;
  return rows as Asset[];
}

export async function createAsset(name: string, value: number): Promise<Asset> {
  const [row] = await sql`
    INSERT INTO assets (name, value)
    VALUES (${name}, ${value})
    RETURNING *
  `;
  return row as Asset;
}

export async function updateAsset(id: string, name: string, value: number): Promise<Asset | undefined> {
  const [row] = await sql`
    UPDATE assets
    SET name = ${name}, value = ${value}
    WHERE id = ${id}
    RETURNING *
  `;
  return row as Asset | undefined;
}

export async function deleteAsset(id: string): Promise<void> {
  await sql`DELETE FROM assets WHERE id = ${id}`;
}
