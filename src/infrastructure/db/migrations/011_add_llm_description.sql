-- 011_add_llm_description: Add llm_description TEXT column to categories

-- Up Migration

ALTER TABLE categories ADD COLUMN llm_description TEXT;

-- Down Migration

ALTER TABLE categories DROP COLUMN llm_description;
