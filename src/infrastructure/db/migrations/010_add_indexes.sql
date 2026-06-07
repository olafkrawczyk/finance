-- 010_add_indexes: Document that UNIQUE constraints cover index needs

-- Up Migration

-- Per D-04 (Minimal Essential Indexes), no additional composite indexes
-- are needed beyond those automatically created by the UNIQUE constraints
-- in migration 009:
--
--   categories(user_id, name)               — btree from UNIQUE(user_id, name)
--   assets(user_id, name)                   — btree from UNIQUE(user_id, name)
--   transactions(user_id, import_hash)      — btree from UNIQUE(user_id, import_hash)
--   monthly_opening_balances(user_id, year, month) — btree from UNIQUE(user_id, year, month)
--
-- The existing idx_mob_year_month index on monthly_opening_balances(year, month)
-- is retained for now. It may become redundant after Phase 7 when all queries
-- include user_id filtering, but removal is deferred.

-- Down Migration

-- No indexes were added in this migration, so none need to be dropped.
-- The idx_mob_year_month index (if dropped later) would need its own migration.
