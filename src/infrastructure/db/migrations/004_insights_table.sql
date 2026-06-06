-- 004_insights_table: Add AI-generated insights storage
-- Creates the insights table, its constraints, indexes, and an immutability trigger

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
  dedup_hash             TEXT NOT NULL,
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
