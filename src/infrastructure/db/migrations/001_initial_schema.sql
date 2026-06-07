-- 001_initial_schema.sql
-- Baseline: full current schema from schema.sql
-- Applied via node-pg-migrate with migrationFileLanguage: 'sql'

-- ↑↑↑ UP MIGRATION ↑↑↑

CREATE TABLE IF NOT EXISTS accounts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('personal', 'business')),
  currency   TEXT NOT NULL DEFAULT 'PLN',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL UNIQUE,
  is_fixed_cost BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS transactions (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id             UUID NOT NULL REFERENCES accounts(id),
  category_id            UUID REFERENCES categories(id),
  type                   TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  amount                 NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
  description            TEXT,
  date                   DATE NOT NULL,
  transfer_to_account_id UUID REFERENCES accounts(id),
  import_hash            TEXT UNIQUE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS monthly_opening_balances (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  year            INT NOT NULL,
  month           INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  opening_balance NUMERIC(19, 4) NOT NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (year, month)
);

CREATE INDEX IF NOT EXISTS idx_tx_account_date ON transactions(account_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_tx_category     ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_tx_date_type    ON transactions(date, type);
CREATE INDEX IF NOT EXISTS idx_mob_year_month  ON monthly_opening_balances(year, month);

-- Immutability triggers (modified to allow updates/deletes)
CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_transactions_no_update ON transactions;
CREATE TRIGGER trg_transactions_no_update
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_immutable_change();

DROP TRIGGER IF EXISTS trg_transactions_no_delete ON transactions;
DROP FUNCTION IF EXISTS block_delete();

ALTER TABLE transactions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- Better Auth tables
CREATE TABLE IF NOT EXISTS "user" (
  "id"          TEXT NOT NULL PRIMARY KEY,
  "name"        TEXT NOT NULL,
  "email"       TEXT NOT NULL UNIQUE,
  "emailVerified" BOOLEAN NOT NULL,
  "image"       TEXT,
  "createdAt"   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updatedAt"   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS "session" (
  "id"          TEXT NOT NULL PRIMARY KEY,
  "expiresAt"   TIMESTAMPTZ NOT NULL,
  "token"       TEXT NOT NULL UNIQUE,
  "createdAt"   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updatedAt"   TIMESTAMPTZ NOT NULL,
  "ipAddress"   TEXT,
  "userAgent"   TEXT,
  "userId"      TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "account" (
  "id"          TEXT NOT NULL PRIMARY KEY,
  "accountId"   TEXT NOT NULL,
  "providerId"  TEXT NOT NULL,
  "userId"      TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  "accessToken" TEXT,
  "refreshToken" TEXT,
  "idToken"     TEXT,
  "accessTokenExpiresAt" TIMESTAMPTZ,
  "refreshTokenExpiresAt" TIMESTAMPTZ,
  "scope"       TEXT,
  "password"    TEXT,
  "createdAt"   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updatedAt"   TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS "verification" (
  "id"          TEXT NOT NULL PRIMARY KEY,
  "identifier"  TEXT NOT NULL,
  "value"       TEXT NOT NULL,
  "expiresAt"   TIMESTAMPTZ NOT NULL,
  "createdAt"   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updatedAt"   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS "session_userId_idx" ON "session" ("userId");
CREATE INDEX IF NOT EXISTS "account_userId_idx" ON "account" ("userId");
CREATE INDEX IF NOT EXISTS "verification_identifier_idx" ON "verification" ("identifier");

-- Import jobs table
CREATE TABLE IF NOT EXISTS import_jobs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    UUID NOT NULL REFERENCES accounts(id),
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  total_rows    INT,
  processed     INT NOT NULL DEFAULT 0,
  errors        TEXT[],
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_import_jobs_account ON import_jobs(account_id);
CREATE INDEX IF NOT EXISTS idx_import_jobs_status ON import_jobs(status);

-- Auto-update triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trg_update_import_jobs_updated_at ON import_jobs;
CREATE TRIGGER trg_update_import_jobs_updated_at
  BEFORE UPDATE ON import_jobs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION update_transaction_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_transactions_updated_at ON transactions;
CREATE TRIGGER trg_transactions_updated_at
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION update_transaction_timestamp();

-- Insights table
CREATE TABLE IF NOT EXISTS insights (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  type                   TEXT NOT NULL CHECK (type IN ('alert', 'tip', 'trend', 'forecast')),
  priority               TEXT NOT NULL CHECK (priority IN ('high', 'medium', 'low')),
  title                  TEXT NOT NULL,
  content                TEXT NOT NULL,
  linked_transaction_ids UUID[] NOT NULL DEFAULT '{}',
  linked_category_ids    UUID[] NOT NULL DEFAULT '{}',
  dismissed              BOOLEAN NOT NULL DEFAULT false,
  dedup_hash             TEXT NOT NULL UNIQUE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_insights_user_type ON insights(user_id, type);
CREATE INDEX IF NOT EXISTS idx_insights_user_dismiss ON insights(user_id, dismissed);
CREATE INDEX IF NOT EXISTS idx_insights_created_at ON insights(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_insights_dedup ON insights(dedup_hash, created_at);

CREATE OR REPLACE FUNCTION block_insight_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.id = NEW.id
     AND OLD.user_id = NEW.user_id
     AND OLD.type = NEW.type
     AND OLD.priority = NEW.priority
     AND OLD.title = NEW.title
     AND OLD.content = NEW.content
     AND OLD.linked_transaction_ids = NEW.linked_transaction_ids
     AND OLD.linked_category_ids = NEW.linked_category_ids
     AND OLD.dedup_hash = NEW.dedup_hash
     AND OLD.created_at = NEW.created_at THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'Insights are mostly immutable. Only the dismissed flag can be changed.';
END;
$$;

DROP TRIGGER IF EXISTS trg_insights_no_update ON insights;
CREATE TRIGGER trg_insights_no_update
  BEFORE UPDATE ON insights FOR EACH ROW
  EXECUTE FUNCTION block_insight_immutable_change();

-- Assets table
CREATE TABLE IF NOT EXISTS assets (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL UNIQUE,
  value      NUMERIC(19, 4) NOT NULL CHECK (value >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_assets_updated_at ON assets;
CREATE TRIGGER trg_assets_updated_at
  BEFORE UPDATE ON assets FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ↓↓↓ DOWN MIGRATION ↓↓↓

DROP TABLE IF EXISTS assets CASCADE;
DROP TABLE IF EXISTS insights CASCADE;
DROP TABLE IF EXISTS import_jobs CASCADE;
DROP TABLE IF EXISTS verification CASCADE;
DROP TABLE IF EXISTS account CASCADE;
DROP TABLE IF EXISTS session CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;
DROP TABLE IF EXISTS monthly_opening_balances CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
