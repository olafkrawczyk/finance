-- 014_add_asset_value_snapshots: Create asset_value_snapshots table
-- Provides append-only value history for asset lines (investments, cash, bonds, silver)
-- Combined with bank balance for net worth computation

-- Up Migration

CREATE TABLE IF NOT EXISTS asset_value_snapshots (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id   UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  value      NUMERIC(19,4) NOT NULL,
  date       DATE NOT NULL,
  notes      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_asset_value_snapshots_asset_id_date
  ON asset_value_snapshots(asset_id, date);

-- Down Migration

DROP TABLE IF EXISTS asset_value_snapshots CASCADE;
