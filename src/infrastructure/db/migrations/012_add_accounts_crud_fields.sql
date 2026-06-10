-- 012_add_accounts_crud_fields: Add starting_balance + starting_balance_date to accounts
-- Provides per-account starting balance for balance-over-time computation

-- Up Migration

ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS starting_balance NUMERIC(19,4) NOT NULL DEFAULT 0;

ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS starting_balance_date DATE;

-- Down Migration

ALTER TABLE accounts DROP COLUMN IF EXISTS starting_balance_date;
ALTER TABLE accounts DROP COLUMN IF EXISTS starting_balance;
