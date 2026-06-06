---
title: "Reference ID sources by bank"
date: "2026-06-06"
context: "Import dedup exploration"
---

During exploration of import deduplication, confirmed the source of unique transaction identifiers per bank format:

## ING (semicolon CSV)

Column index 7 ("Nr transakcji") contains a unique transaction number.
Example values: `202615697201368307`, `202615697201367777`
These are numeric strings unique per transaction in an account.

## IPKO (comma-quoted CSV)

Two sources:
1. **"Opis transakcji"** column — contains "Tytuł:" prefix followed by a reference like `P425125132753026427324339`
2. **"Numer referencyjny"** column — used for withdrawals and BLIK, e.g., `3967 00000094136959479`

The "Opis transakcji" column also includes location data (Lokalizacja) which may help with distinguishing same-day same-amount purchases even without the reference ID.

## Implication

Both banks provide per-transaction unique identifiers that can be extracted by the LLM during parsing and stored as a `reference_id` column for more accurate deduplication.
