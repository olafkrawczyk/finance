# Transaction List Enhancements

## Requirements

- Client-side filtering and sorting must match the page cap size (500 transactions per page).
- Reversing the order of monthly summaries ("zbiorczo") must show the newest month first while ensuring running account balances (`stan_konta`) aggregate chronologically (oldest to newest) to remain mathematically correct.

## How to Build It

### 1. In-Memory Transaction Filtering, Searching & Sorting

For optimal responsiveness, implement searching, filtering, and sorting client-side in the frontend within [MonthlyPage.tsx](file:///home/olafk/finance/frontend/src/pages/MonthlyPage.tsx):

- **State Hook:** Maintain input states for search queries, active categories, transaction type, and the sorting field.
- **Computed Filters (`useMemo`):** Perform the operations reactively to avoid unnecessary recalculations:
  ```typescript
  const filteredAndSortedTransactions = useMemo(() => {
    if (!transactions) return [];

    let result = [...transactions];

    // 1. Text search (filter by description or category name)
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      result = result.filter(tx => 
        (tx.description && tx.description.toLowerCase().includes(q)) ||
        (tx.category_name && tx.category_name.toLowerCase().includes(q))
      );
    }

    // 2. Filter by type (income, expense, transfer)
    if (selectedType !== 'all') {
      result = result.filter(tx => tx.type === selectedType);
    }

    // 3. Filter by category
    if (selectedCategory !== 'all') {
      result = result.filter(tx => tx.category_name === selectedCategory);
    }

    // 4. Sort results
    result.sort((a, b) => {
      if (sortBy === 'date-desc') {
        return new Date(b.date).getTime() - new Date(a.date).getTime();
      } else if (sortBy === 'date-asc') {
        return new Date(a.date).getTime() - new Date(b.date).getTime();
      } else if (sortBy === 'amount-desc') {
        return b.amount - a.amount;
      } else if (sortBy === 'amount-asc') {
        return a.amount - b.amount;
      } else if (sortBy === 'description-asc') {
        return (a.description || '').localeCompare(b.description || '', 'pl');
      }
      return 0;
    });

    return result;
  }, [transactions, searchQuery, selectedType, selectedCategory, sortBy]);
  ```

### 2. Reverse Zbiorczo Ordering (Newest Month First)

To present the newest month first on the Zbiorczo view, reverse the array in the backend use-case so the API response is already correctly sorted.

Update `getMonthlySummary()` in [use-cases.ts](file:///home/olafk/finance/src/core/ledger/use-cases.ts):
```typescript
export async function getMonthlySummary(): Promise<MonthlySummaryRow[]> {
  // 1. Keep the SQL aggregation ordering by month ascending (ASC)
  const agg = await sql`
    SELECT
      TO_CHAR(t.date, 'YYYY-MM') AS month,
      ...
    ORDER BY month ASC
  `;

  // 2. Accumulate running balances chronologically (ascending)
  let currentRunningBalance = 0;
  const computedRows = agg.map((row) => {
    // ... compute values ...
    return {
      month: row.month,
      wydatki: wydatki.toFixed(4),
      przychody: przychody.toFixed(4),
      // ... other fields ...
      stan_konta: currentRunningBalance.toFixed(4),
    };
  });

  // 3. Reverse the calculated list right before returning
  return computedRows.reverse();
}
```

## What to Avoid

- **Do NOT sort database queries directly in descending order for cumulative sums.** Reversing query sort order in the database (e.g. `ORDER BY month DESC`) will break running balance logic unless the summation query window uses complex partitioned logic. Reversing post-calculation is simpler and error-free.
- **Do NOT trigger API calls on search keystrokes.** Since we use client-side filtering, changing state triggers local `useMemo` updates immediately, avoiding heavy server load.

## Constraints

- If the number of transactions per month exceeds the 500 cap, client-side search/filters will only work on the loaded 500 rows. Re-indexing or pagination is required if page limits are removed in the future.

## Origin

Synthesized from spikes: 004, 005
Source files available in: [sources/004-transaction-filters/](file:///home/olafk/finance/.agent/skills/spike-findings-finance/sources/004-transaction-filters/), [sources/005-reverse-zbiorczy-order/](file:///home/olafk/finance/.agent/skills/spike-findings-finance/sources/005-reverse-zbiorczy-order/)
