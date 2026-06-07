-- Accounts: ING business + IPKO personal
CREATE TABLE IF NOT EXISTS accounts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('personal', 'business')),
  currency   TEXT NOT NULL DEFAULT 'PLN',
  user_id    TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Categories: 25 total (arval replaces auto; D-07)
CREATE TABLE IF NOT EXISTS categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  user_id       TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  is_fixed_cost BOOLEAN NOT NULL DEFAULT false,
  llm_description TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, name)
);

-- Single-entry ledger: income | expense | transfer
CREATE TABLE IF NOT EXISTS transactions (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id             UUID NOT NULL REFERENCES accounts(id),
  category_id            UUID REFERENCES categories(id),
  type                   TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  amount                 NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
  description            TEXT,
  date                   DATE NOT NULL,
  transfer_to_account_id UUID REFERENCES accounts(id),
  import_hash            TEXT,
  user_id                TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, import_hash)
);

-- Global monthly opening balance = total net worth (D-01, D-02)
-- NO account_id — tracks all asset classes combined
CREATE TABLE IF NOT EXISTS monthly_opening_balances (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  year            INT NOT NULL,
  month           INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  opening_balance NUMERIC(19, 4) NOT NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, year, month)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_tx_account_date ON transactions(account_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_tx_category     ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_tx_date_type    ON transactions(date, type);
CREATE INDEX IF NOT EXISTS idx_mob_year_month  ON monthly_opening_balances(year, month);

-- Immutability triggers (REQ-1.2) — modified to allow updates and deletes
CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RETURN NEW;  -- Allow all updates (immutability removed)
END;
$$;

DROP TRIGGER IF EXISTS trg_transactions_no_update ON transactions;
CREATE TRIGGER trg_transactions_no_update
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_immutable_change();

-- Remove delete block — hard deletes now allowed (D-07)
DROP TRIGGER IF EXISTS trg_transactions_no_delete ON transactions;
DROP FUNCTION IF EXISTS block_delete();

-- Add updated_at column for edit tracking (D-01)
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

-- Import jobs tracking table
CREATE TABLE IF NOT EXISTS import_jobs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    UUID NOT NULL REFERENCES accounts(id),
  user_id       TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  total_rows    INT,
  processed     INT NOT NULL DEFAULT 0,
  errors        TEXT[],
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_import_jobs_account ON import_jobs(account_id);
CREATE INDEX IF NOT EXISTS idx_import_jobs_status ON import_jobs(status);

-- Auto-update updated_at for import_jobs
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

-- Auto-update updated_at for transactions
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

-- Insights tracking table (AI-generated)
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

-- Indexes for performance and uniqueness checking
CREATE INDEX IF NOT EXISTS idx_insights_user_type ON insights(user_id, type);
CREATE INDEX IF NOT EXISTS idx_insights_user_dismiss ON insights(user_id, dismissed);
CREATE INDEX IF NOT EXISTS idx_insights_created_at ON insights(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_insights_dedup ON insights(dedup_hash, created_at);

-- Immutability trigger: only allows changing the dismissed flag
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

-- Manual asset lines (investments, cash, bonds, silver, etc.)
CREATE TABLE IF NOT EXISTS assets (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  user_id    TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  value      NUMERIC(19, 4) NOT NULL CHECK (value >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, name)
);

DROP TRIGGER IF EXISTS trg_assets_updated_at ON assets;
CREATE TRIGGER trg_assets_updated_at
  BEFORE UPDATE ON assets FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();


