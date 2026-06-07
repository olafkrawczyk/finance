-- 009_update_uniques: Drop global UNIQUE → Add per-user composite UNIQUE

-- Up Migration

-- Categories: name uniqueness scoped to user
ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_name_key;
ALTER TABLE categories ADD CONSTRAINT categories_user_id_name_key UNIQUE(user_id, name);

-- Assets: name uniqueness scoped to user
ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_name_key;
ALTER TABLE assets ADD CONSTRAINT assets_user_id_name_key UNIQUE(user_id, name);

-- Transactions: import_hash uniqueness scoped to user
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_import_hash_key;
ALTER TABLE transactions ADD CONSTRAINT transactions_user_id_import_hash_key UNIQUE(user_id, import_hash);

-- Monthly opening balances: (year, month) uniqueness scoped to user
ALTER TABLE monthly_opening_balances DROP CONSTRAINT IF EXISTS monthly_opening_balances_year_month_key;
ALTER TABLE monthly_opening_balances ADD CONSTRAINT monthly_opening_balances_user_id_year_month_key UNIQUE(user_id, year, month);

-- Down Migration
-- NOTE: Uses DO blocks with pg_constraint checks for idempotency because
-- ADD CONSTRAINT IF NOT EXISTS is not valid PostgreSQL syntax (pre-PG 18).

DO $$
BEGIN
  ALTER TABLE monthly_opening_balances DROP CONSTRAINT IF EXISTS monthly_opening_balances_user_id_year_month_key;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'monthly_opening_balances_year_month_key') THEN
    ALTER TABLE monthly_opening_balances ADD CONSTRAINT monthly_opening_balances_year_month_key UNIQUE(year, month);
  END IF;
END $$;

DO $$
BEGIN
  ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_user_id_import_hash_key;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'transactions_import_hash_key') THEN
    ALTER TABLE transactions ADD CONSTRAINT transactions_import_hash_key UNIQUE(import_hash);
  END IF;
END $$;

DO $$
BEGIN
  ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_user_id_name_key;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assets_name_key') THEN
    ALTER TABLE assets ADD CONSTRAINT assets_name_key UNIQUE(name);
  END IF;
END $$;

DO $$
BEGIN
  ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_user_id_name_key;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'categories_name_key') THEN
    ALTER TABLE categories ADD CONSTRAINT categories_name_key UNIQUE(name);
  END IF;
END $$;
