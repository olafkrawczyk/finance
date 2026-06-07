-- 008_add_user_id_columns: Add user_id FK to all domain tables

-- Up Migration

ALTER TABLE accounts
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE categories
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE transactions
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE monthly_opening_balances
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE assets
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE import_jobs
  ADD COLUMN user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE;

-- Down Migration

ALTER TABLE import_jobs DROP COLUMN user_id;
ALTER TABLE assets DROP COLUMN user_id;
ALTER TABLE monthly_opening_balances DROP COLUMN user_id;
ALTER TABLE transactions DROP COLUMN user_id;
ALTER TABLE categories DROP COLUMN user_id;
ALTER TABLE accounts DROP COLUMN user_id;
