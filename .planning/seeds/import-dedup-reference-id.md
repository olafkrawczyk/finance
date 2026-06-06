---
title: "Import dedup — add reference_id to hash"
trigger_condition: "When starting the next phase on import or transaction dedup improvements"
planted_date: "2026-06-06"
---

LLM should extract transaction reference IDs from bank CSV and include in dedup hash.

## What

- Add `reference_id TEXT` column to `transactions` table
- Have LLM extract bank reference number from CSV during parsing
- Include `reference_id` in the SHA-256 dedup hash: `date|amount|description|reference_id`
- This prevents false deduplication of same-day same-amount purchases (e.g., multiple car washes, identical Żabka visits)

## Source Data

- **ING:** Column "Nr transakcji" — e.g., `202615697201368307`
- **IPKO:** In "Opis transakcji" under "Tytuł:" prefix, or "Numer referencyjny" column — e.g., `P425125132753026427324339`

## Requirements

- `reference_id` is optional (null for manual entries, existing rows)
- Only affects new imports — existing rows are untouched
- Dedup hash stays `date|amount|description` for rows without `reference_id`
