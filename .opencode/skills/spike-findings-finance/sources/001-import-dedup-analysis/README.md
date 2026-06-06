---
spike: 001
name: import-dedup-analysis
type: standard
validates: "Given duplicate CSV rows, when imported, then only one transaction is created per unique date+amount+description hash"
verdict: PARTIAL
related: []
tags: [import, dedup, hash]
---

# Spike 001: Import Deduplication Analysis

## What This Validates

Given duplicate CSV rows in the same or subsequent imports, the dedup mechanism (SHA-256 hash of `date|amount|description` + `ON CONFLICT (import_hash) DO NOTHING`) prevents duplicate transaction entries.

## Research

**Current mechanism** (src/workers/import-worker.ts):
- `computeImportHash(date, amount, description)` → SHA-256 hex of `date|amount|description`
- DB column `import_hash TEXT UNIQUE` (nullable — multiple NULLs allowed)
- `INSERT ... ON CONFLICT (import_hash) DO NOTHING` in `insertBatch()`

**Approach considered:** Code analysis + hash test vectors (no DB needed for hash correctness).

## How to Run

```bash
node .planning/spikes/001-import-dedup-analysis/test-dedup.js
```

## What to Expect

Hash computation test covering 9 scenarios showing what deduplicates and what doesn't.

## Investigation Trail

**Test 1-4:** Basic hash uniqueness — different inputs produce different hashes. PASS.

**Test 5 (known limitation):** Two identical purchases same day/same amount/same description silently dedup. This is explicitly documented at import-worker.ts:80-82. The LLM-parsed description is the same for both, so they share a hash. The real CSV rows would have different transaction IDs but those aren't included in the hash.

**Test 6 (real risk):** `account_id` is NOT part of the hash. If the same CSV is imported to two different accounts, the second import would silently skip all rows. Example: importing ING business CSV to the personal account — every hash already exists from the business account import.

**Test 8-9:** Whitespace and amount format sensitivity means LLM output must be perfectly consistent or dedup will fail (either missing duplicates or creating false ones).

## Results

**Verdict: PARTIAL ⚠**

The mechanism works as implemented — identical rows produce matching hashes and the DB constraint prevents duplicates. However, two significant risks:

```
Risks:
  ⚠ account_id NOT in hash — cross-account dedup collision
  ⚠ Two genuinely separate purchases of same amount at same place = silently deduped
  ⚠ LLM inconsistency in formatting amounts/descriptions could cause missed dedups
```

**Key finding:** The hash should include `account_id` to scope dedup per-account. The `description` field is not always unique enough to distinguish same-day same-amount transactions.
