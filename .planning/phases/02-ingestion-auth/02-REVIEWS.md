---
phase: 2
reviewers: [antigravity]
reviewed_at: 2026-06-06T18:30:00+02:00
plans_reviewed:
  - 02-01-PLAN.md
  - 02-02-PLAN.md
  - 02-03-PLAN.md
  - 02-04-PLAN.md
  - 02-05-PLAN.md
reviewers_failed:
  claude: "Session limit reached — resets 3:40pm Europe/Warsaw"
  opencode: "Skipped (self-detected — running inside OpenCode)"
---

# Cross-AI Plan Review — Phase 2

## Antigravity Review

### Executive Summary

The proposed phase plan is exceptionally well-structured, logically divided into waves, and provides a clear path for implementing both user authentication (Better Auth) and LLM-powered bank CSV imports (OpenRouter). The test coverage is comprehensive and includes local mocks to prevent token expenditure during tests.

However, several critical technical risks and functional ambiguities must be addressed before execution to avoid database inconsistency, character corruption, and silent data loss.

---

### Core Findings & Risks

#### 1. Character Encoding Corruption (HIGH)
**Problem:** The plans suggest using `Buffer.from(await file.arrayBuffer()).toString('latin1')` to decode the CP1250-encoded CSV files from Polish banks. While `latin1` covers the CP1250 byte range without throwing errors, it does **not** map bytes to the correct Unicode code points for Polish diacritics. Byte `0xB1` represents `ą` in CP1250, but in `latin1` it is mapped to `±`. The string sent to OpenRouter will contain `±` instead of `ą`, causing incorrect parsing and messy descriptions.

**Mitigation:** Use the native Web API `TextDecoder` with the `'windows-1250'` encoding, which is supported out-of-the-box by Bun and Node.js without any third-party libraries:
```typescript
const buffer = Buffer.from(await file.arrayBuffer());
const content = new TextDecoder('windows-1250').decode(buffer);
```

#### 2. Transfer Representation & Deduplication (MEDIUM-HIGH)
**Problem:** Technical Requirements state: "No double-entry... Transfer type links account_id and transfer_to_account_id." However, `02-04-PLAN.md` inserts all imported transactions with `transfer_to_account_id = null`. If a user imports both `ing.csv` and `ipko.csv`, each transfer becomes **two independent, unlinked transfer records** in the database.

**Mitigation:** Since this is a two-account MVP, the worker should dynamically resolve the destination account ID. If `type = 'transfer'`, find the "other" account ID and set it as `transfer_to_account_id`. Document clearly whether transfers are kept as two separate rows or matched/merged.

#### 3. Collision of Legitimate Identical Transactions (MEDIUM)
**Problem:** `REQ-4.5` specifies `import_hash = SHA-256(date+amount+description)`. Because duplicate hashes are silently skipped, if a user makes two identical purchases on the same day (e.g., two separate coffees for 15.00 PLN at the same cafe), the second transaction will have the same hash and be **silently skipped**.

**Mitigation:** This is a requirement-level limitation. Document this risk. A future improvement would include a sequence or line counter in the hash calculation.

#### 4. LLM Row-Dropping & Hallucination (MEDIUM)
**Problem:** In batches of 50, the LLM might occasionally fail to return all rows (e.g., returning 48 items instead of 50). If the worker inserts the 48 rows, the other 2 rows are silently lost without generating an error.

**Mitigation:** The worker should assert that the number of parsed transactions returned by the LLM matches the number of input rows processed. If they do not match, the batch should fail, log an error to `import_jobs.errors`, and prevent silent data loss.

#### 5. Stuck Job Recovery (LOW-MEDIUM)
**Problem:** If the worker process crashes or is restarted while processing a job, that job's status in `import_jobs` will remain stuck in `'processing'` indefinitely.

**Mitigation:** Implement a simple timeout check. Any job in `'processing'` state with an `updated_at` older than 15 minutes should be failed or reclaimed.

---

### Detailed Plan-by-Plan Critique

#### 02-01-PLAN.md (Auth Foundation)
**Status:** Approved with minor feedback.

**Strengths:** Excellent testability setup using `emailAndPassword: { enabled: true }` in tests. Properly protects all Phase 1 routes.

**Feedback:** Ensure that Google and GitHub OAuth secrets are conditionally loaded so the backend still starts up in local test environments where they might not be configured.

#### 02-02-PLAN.md (Import Schema & Domain)
**Status:** Critical fix required.

**Strengths:** Correctly identifies Pitfall 9 (the breaking health check assertion in `api.test.ts`) and includes a task to fix it.

**Feedback:** The `import_jobs` table should include an `updated_at` column, which is updated via a trigger or manually by the worker. This is essential for detecting stuck jobs.

#### 02-03-PLAN.md (Import API)
**Status:** Fix required.

**Strengths:** Atomic use-cases that combine database insertions and PGMQ enqueues inside `sql.begin`.

**Feedback:** Update the file upload handler to use `new TextDecoder('windows-1250')` instead of `latin1` decoding (see Core Finding #1).

#### 02-04-PLAN.md (Import Worker)
**Status:** Action required.

**Strengths:** Batching in chunks of 50 is a reasonable balance. Good usage of Bun.serve mocks for OpenRouter tests to prevent token expenditure.

**Feedback:**
- Implement the LLM output row-count assertion (Core Finding #4).
- Resolve the transfer linking logic (Core Finding #2).

#### 02-05-PLAN.md (Import UI)
**Status:** Approved.

**Strengths:** Scaffolds Vite, React, and Tailwind without breaking the Bun backend. Follows the UI-SPEC requirements and configures Vite proxy correctly to bypass cross-origin cookie issues.

---

### Actionable Recommendations

**Recommendation A:** Proper Character Decoding — Replace `latin1` decode with `new TextDecoder('windows-1250')` in `src/interface-adapters/api/import.ts`.

**Recommendation B:** Row-Count Validation in Worker — In `src/workers/import-worker.ts`, add a check before inserting batches:
```typescript
const parsed = await callOpenRouter(batch.join('\n'), bank_format);
if (parsed.length !== batch.length) {
  throw new Error(`LLM returned ${parsed.length} transactions, but input had ${batch.length} rows. Retrying.`);
}
```

**Recommendation C:** Resolving Transfer Destination Accounts — During batch insertion, if `tx.raw_type === 'transfer'`, resolve the target account dynamically and populate `transfer_to_account_id`.

---

## Consensus Summary

*Only one reviewer (Antigravity/Gemini) completed the review. Claude Code was unavailable due to session limits.*

### Agreed Strengths
- Excellent wave-based structure with clear dependencies
- Comprehensive test coverage with local mocks (Bun.serve for OpenRouter, emailAndPassword for auth)
- Thorough RESEARCH.md document identifying 10 pitfalls upfront
- Atomic operations via `sql.begin` for enqueue + insert guarantees
- Good identification of Pitfall 9 (health check assertion breaking)

### Agreed Concerns
1. **HIGH — Character encoding:** `latin1` decode is incorrect for CP1250 Polish diacritics. Must use `TextDecoder('windows-1250')`.
2. **MEDIUM-HIGH — Transfer linking:** `transfer_to_account_id` is never populated, creating unlinked transfer records when both accounts are imported.
3. **MEDIUM — Silent data loss:** LLM may drop rows silently; row-count validation is missing in the worker.
4. **MEDIUM — Identical transaction collision:** SHA-256 hash dedup can silently skip legitimate duplicate purchases on the same day.
5. **LOW-MEDIUM — Stuck job recovery:** No timeout mechanism for jobs stuck in `'processing'` state.

### Divergent Views
N/A — single reviewer. A second reviewer could catch different blind spots.

---

## Next Steps

To incorporate this feedback into planning:
```
/gsd-plan-phase 2 --reviews
```
