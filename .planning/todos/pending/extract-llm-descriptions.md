---
title: Extract LLM descriptions from prompt to seed data
date: 2026-06-07
priority: high
---

Extract the 25 category descriptions from the `buildFewShotPrompt` function in `src/workers/import-worker.ts` (lines 103–128) and move them into the `llm_description` column of the categories seed data.

**Acceptance criteria:**
- [ ] `llm_description` column exists on `categories` table
- [ ] Seed SQL includes the description text for each default category
- [ ] `buildFewShotPrompt` reads descriptions from DB instead of hardcoding them
- [ ] LLM prompt for CSV import dynamically fetches user's active categories with descriptions
