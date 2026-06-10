-- 013_add_accounts_unique_name: Add UNIQUE(user_id, name) constraint to accounts
-- Prevents duplicate account names per user (e.g., two "ING Business" accounts)

-- Up Migration

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_accounts_user_id_name') THEN
    ALTER TABLE accounts ADD CONSTRAINT uq_accounts_user_id_name UNIQUE(user_id, name);
  END IF;
END $$;

-- Down Migration

ALTER TABLE accounts DROP CONSTRAINT IF EXISTS uq_accounts_user_id_name;
