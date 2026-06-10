import sql from '../../infrastructure/db/client';

export interface Asset {
  id: string;
  name: string;
  value: string; // Postgres numeric returns as string
  created_at: string;
  updated_at: string;
}

export interface AssetValueSnapshot {
  id: string;
  asset_id: string;
  value: string; // Postgres numeric returns as string
  date: string;
  notes: string | null;
  created_at: string;
}

export async function listAssets(userId: string): Promise<Asset[]> {
  const rows = await sql`
    SELECT * FROM assets WHERE user_id = ${userId} ORDER BY name ASC
  `;
  return rows as Asset[];
}

export async function getAsset(id: string, userId: string): Promise<Asset | undefined> {
  const [row] = await sql`
    SELECT * FROM assets WHERE id = ${id} AND user_id = ${userId}
  `;
  return row as Asset | undefined;
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
  // Auto-snapshot: capture old value before overwriting (D-10)
  const [current] = await sql`
    SELECT value FROM assets WHERE id = ${id} AND user_id = ${userId}
  `;
  if (current) {
    const oldValue = parseFloat(current.value);
    if (oldValue !== value) {
      const today = new Date().toISOString().split('T')[0];
      await sql`
        INSERT INTO asset_value_snapshots (asset_id, value, date)
        VALUES (${id}, ${oldValue}, ${today})
      `;
    }
  }

  const [row] = await sql`
    UPDATE assets
    SET name = ${name}, value = ${value}
    WHERE id = ${id} AND user_id = ${userId}
    RETURNING *
  `;
  return row as Asset | undefined;
}

export async function deleteAsset(id: string, userId: string): Promise<boolean> {
  const [result] = await sql`
    DELETE FROM assets WHERE id = ${id} AND user_id = ${userId} RETURNING id
  `;
  return !!result;
}

// Asset value snapshot functions

export async function createAssetSnapshot(
  assetId: string,
  value: number,
  date: string,
  notes?: string
): Promise<AssetValueSnapshot> {
  const [row] = await sql`
    INSERT INTO asset_value_snapshots (asset_id, value, date, notes)
    VALUES (${assetId}, ${value}, ${date}, ${notes ?? null})
    RETURNING *
  `;
  return row as AssetValueSnapshot;
}

export async function listAssetSnapshots(assetId: string): Promise<AssetValueSnapshot[]> {
  const rows = await sql`
    SELECT * FROM asset_value_snapshots
    WHERE asset_id = ${assetId}
    ORDER BY date ASC, created_at ASC
  `;
  return rows as AssetValueSnapshot[];
}
