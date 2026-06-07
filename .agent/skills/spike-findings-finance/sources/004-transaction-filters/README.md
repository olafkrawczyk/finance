---
spike: 004
name: transaction-filters
type: standard
validates: "Given a list of transactions, when we filter by text search, category, type, and sort by date or amount, then the table updates dynamically and correctly"
verdict: VALIDATED
related: []
tags: [frontend, filter, search, sort]
---

# Spike 004: Transaction Filters, Sorting, and Search

## What This Validates

This spike validates the client-side user interface and logic for filtering, sorting, and searching a list of transactions in-memory.

## Research

### Approach Comparison

| Approach | Tool/Library | Pros | Cons | Status |
|----------|-------------|------|------|--------|
| **Client-Side Filtering & Sorting** | React `useState` & `useMemo` | Instantaneous UX, no backend requests required, simple | Doesn't scale past ~5000 transactions without slight lag | **Chosen** |
| **Server-Side API Filtering** | Hono endpoints with SQL query parameters | Scalable to arbitrary number of rows, lower initial transfer size | Laggy UI on typing, requires server round-trip for every keystroke/option change | Alternative |

## How to Run

Open the prototype HTML in a browser:
```bash
open .planning/spikes/004-transaction-filters/prototype.html
```

## What to Expect

- **Text Search:** Filter transactions as you type by searching through the description and category name fields.
- **Type Filter:** Dropdown to select only expenses, income, transfers, or all.
- **Category Filter:** Dynamic dropdown lists all categories found in the transaction set.
- **Sorting Options:** Dropdown to sort by Date (ascending/descending) and Amount (ascending/descending), or description alphabetically.
- **Reset Button:** Quickly clear all controls to return to the default state.
- **Interactive Counters:** Shows a badge tracking how many transactions are currently visible out of the total.

## Investigation Trail

- Implemented standard Tailwind UI components matching modern dark-mode aesthetics.
- Hooked input triggers (`input` and `change`) to automatically filter mock transactions array.
- Sorting logic ensures float parsing for amounts and date-object comparisons for dates to avoid string-sorting errors.
- Reset button resets control elements and triggers UI reflow immediately.

## Results

**Verdict: VALIDATED ✓**

The prototype demonstrates that client-side filtering is extremely responsive and robust for page-size limits (under 500 rows). To implement in the real app:
- Integrate state in [MonthlyPage.tsx](file:///home/olafk/finance/frontend/src/pages/MonthlyPage.tsx) around the `transactions` array.
- Add search input, dropdowns for type/category, and a sort select above `<TransactionTable>`.
- Perform the filter/sort using a `useMemo` hook based on the active inputs to keep it performant.
