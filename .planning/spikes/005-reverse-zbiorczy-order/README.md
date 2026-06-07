---
spike: 005
name: reverse-zbiorczy-order
type: standard
validates: "Given monthly summaries, when fetched/displayed on the Zbiorczo view, then they are ordered with the newest month first (descending)"
verdict: VALIDATED
related: []
tags: [frontend, summary, order]
---

# Spike 005: Reverse Zbiorczy Month Order

## What This Validates

This spike validates the logic required to reverse the display order of the monthly summaries list ("zbiorczo") to show the newest month first, while ensuring that chronological running account balance computations remain correct.

## Research

### Balance Calculation Constraints
In the database, the running balance `stan_konta` for each month depends on the previous month's balance + that month's savings (`zaoszczedzone`). Therefore, calculations must be executed chronologically (ascending: oldest to newest).

To present the newest month first without breaking the running balances, we have two options:
1. **API-level reversal (Chosen):** The use-case continues to query and calculate the aggregates in ascending order, then reverses the final array `agg.map(...).reverse()` right before returning the JSON payload.
2. **UI-level reversal:** The frontend retrieves the list chronologically and reverses it right before rendering.

API-level reversal is cleaner as it delivers the data in the exact order the user expects to consume it, without placing sorting/reversal responsibility on the frontend presentation components.

## How to Run

Open the prototype HTML in a browser:
```bash
open .planning/spikes/005-reverse-zbiorczy-order/prototype.html
```

## What to Expect

- The page defaults to showing the months in descending order: **Czerwiec 2026** at the top, down to **Styczeń 2026** at the bottom.
- Running balance (`stan_konta`) values correctly aggregate chronologically from older months forward (e.g. January starts at 10,800.00 and June finishes at 23,200.00).
- Toggle buttons let you switch back and forth between ascending (oldest first) and descending (newest first) to visually verify the balance calculations remain unchanged regardless of presentation order.

## Results

**Verdict: VALIDATED ✓**

The correct implementation plan is:
- Modify `getMonthlySummary()` in [use-cases.ts](file:///home/olafk/finance/src/core/ledger/use-cases.ts):
  ```typescript
  // Change return statement:
  return agg.map((row) => {
    // ... calculation logic ...
  }).reverse();
  ```
- This ensures the API naturally returns the newest month first.
