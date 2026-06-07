import { describe, it, expect } from 'bun:test';
import React from 'react';
import { renderToString } from 'react-dom/server';
import ImportUpload from '../frontend/src/components/ImportUpload';
import ImportStatus from '../frontend/src/components/ImportStatus';
import InsightCard from '../frontend/src/components/InsightCard';
import InsightsTabs from '../frontend/src/components/InsightsTabs';
import MonthlyPage from '../frontend/src/pages/MonthlyPage';
import { filterAndSortTransactions, extractUniqueCategories } from '../frontend/src/pages/MonthlyPage';
import type { NormalizedTransaction } from '../frontend/src/components/TransactionTable';

describe('UI Component Rendering Tests', () => {
  it('renders ImportUpload component without crashing', () => {
    const html = renderToString(
      React.createElement(ImportUpload, {
        onImportStarted: () => {},
      })
    );
    expect(html).toContain('Import Transactions');
    expect(html).toContain('Select Account');
    expect(html).toContain('Upload CSV File');
    expect(html).toContain('Upload Statement');
  });

  it('renders ImportStatus component without crashing', () => {
    const html = renderToString(
      React.createElement(ImportStatus, {
        jobId: '3c8d1844-0b1a-4712-8bb4-098522a105c3',
        onBack: () => {},
      })
    );
    expect(html).toContain('Loading job status...');
  });

  it('renders InsightsTabs without crashing', () => {
    const html = renderToString(
      React.createElement(InsightsTabs, {
        activeType: 'all',
        onTypeChange: () => {},
      })
    );
    expect(html).toContain('All');
    expect(html).toContain('Alerts');
    expect(html).toContain('Trends');
    expect(html).toContain('Tips');
    expect(html).toContain('Forecasts');
  });

  it('renders InsightCard without crashing', () => {
    const html = renderToString(
      React.createElement(InsightCard, {
        insight: {
          id: 'test-id',
          user_id: 'test-user',
          type: 'alert',
          priority: 'high',
          title: 'Test Alert',
          content: 'Test content',
          dismissed: false,
          created_at: new Date().toISOString(),
          dedup_hash: 'abc',
          linked_transaction_ids: [],
          linked_category_ids: [],
        },
        onDismiss: () => {},
      })
    );
    expect(html).toContain('Test Alert');
    expect(html).toContain('Test content');
  });

  it('renders InsightCard dismissed state', () => {
    const html = renderToString(
      React.createElement(InsightCard, {
        insight: {
          id: 'test-id',
          user_id: 'test-user',
          type: 'alert',
          priority: 'high',
          title: 'Test Alert',
          content: 'Test content',
          dismissed: true,
          created_at: new Date().toISOString(),
          dedup_hash: 'abc',
          linked_transaction_ids: [],
          linked_category_ids: [],
        },
        onDismiss: () => {},
      })
    );
    expect(html).toContain('Dismissed');
  });

  it('renders MonthlyPage component in loading state', () => {
    const html = renderToString(
      React.createElement(MonthlyPage, {
        yearMonth: '2026-06',
      })
    );
    expect(html).toContain('Loading month view...');
  });
});

// ---------------------------------------------------------------------------
// Pure function tests for filterAndSortTransactions / extractUniqueCategories
// ---------------------------------------------------------------------------

describe('filterAndSortTransactions', () => {
  const mockTxs: NormalizedTransaction[] = [
    { id: '1', date: '2026-06-10', description: 'Salary',     category_name: 'salary', type: 'income',  amount: 5000 },
    { id: '2', date: '2026-06-10', description: 'Bonus',      category_name: 'salary', type: 'income',  amount: 1000 },
    { id: '3', date: '2026-06-05', description: 'groceries',  category_name: 'food',   type: 'expense', amount: -150 },
    { id: '4', date: '2026-06-15', description: 'FUN event',  category_name: 'fun',    type: 'expense', amount: -75  },
    { id: '5', date: '2026-06-01', description: 'Transfer to savings', category_name: null,  type: 'transfer', amount: -200 },
    { id: '6', date: '2026-06-12', description: 'Dining out', category_name: null,     type: 'expense', amount: -45  },
  ];

  const defaultFilters = { searchTerm: '', selectedType: 'all', selectedCategory: 'all', sortBy: 'date-desc' };

  it('returns empty array for null input', () => {
    expect(filterAndSortTransactions(null, defaultFilters)).toEqual([]);
  });

  it('returns all transactions with default filters', () => {
    const result = filterAndSortTransactions(mockTxs, defaultFilters);
    expect(result).toHaveLength(6);
    // Default sort is date-desc: newest first
    expect(result[0].date).toBe('2026-06-15');
    expect(result[5].date).toBe('2026-06-01');
  });

  it('filters by type', () => {
    const result = filterAndSortTransactions(mockTxs, { ...defaultFilters, selectedType: 'income' });
    expect(result).toHaveLength(2);
    result.forEach((t) => expect(t.type).toBe('income'));
  });

  it('filters by category', () => {
    const result = filterAndSortTransactions(mockTxs, { ...defaultFilters, selectedCategory: 'fun' });
    expect(result).toHaveLength(1);
    expect(result[0].category_name).toBe('fun');
  });

  it('filters uncategorized', () => {
    const result = filterAndSortTransactions(mockTxs, { ...defaultFilters, selectedCategory: 'uncategorized' });
    expect(result).toHaveLength(2);
    result.forEach((t) => expect(t.category_name).toBeNull());
  });

  it('searches description case-insensitively', () => {
    const result = filterAndSortTransactions(mockTxs, { ...defaultFilters, searchTerm: 'salary' });
    expect(result).toHaveLength(2);
    // Matches 'Salary' description and 'salary' category_name
    expect(result.map((t) => t.description)).toContain('Salary');
    expect(result.map((t) => t.description)).toContain('Bonus');
  });

  it('searches category_name case-insensitively', () => {
    const result = filterAndSortTransactions(mockTxs, { ...defaultFilters, searchTerm: 'fun' });
    expect(result).toHaveLength(1);
    // Matches 'fun' category_name only (FUN event has description 'FUN event' but category_name is 'fun')
    expect(result[0].category_name).toBe('fun');
  });

  it('sorts by amount descending', () => {
    const result = filterAndSortTransactions(mockTxs, { ...defaultFilters, sortBy: 'amount-desc' });
    expect(result[0].amount).toBe(5000);
    expect(result[result.length - 1].amount).toBe(-200);
    // Verify all amounts are in descending order
    for (let i = 1; i < result.length; i++) {
      expect(result[i].amount).toBeLessThanOrEqual(result[i - 1].amount);
    }
  });

  it('sorts by description ascending with Polish locale', () => {
    const result = filterAndSortTransactions(mockTxs, { ...defaultFilters, sortBy: 'description-asc' });
    // After sorting A->Z: Bonus, Dining out, FUN event, groceries, Salary, Transfer to savings
    expect(result[0].description).toBe('Bonus');
    expect(result[1].description).toBe('Dining out');
    expect(result[2].description).toBe('FUN event');
    expect(result[3].description).toBe('groceries');
    expect(result[4].description).toBe('Salary');
    expect(result[5].description).toBe('Transfer to savings');
  });

  it('uses ID tiebreaker for same-date transactions', () => {
    // Both id=1 and id=2 have date='2026-06-10'.
    // With date-desc sort: b.id.localeCompare(a.id) means higher ID wins on tie.
    const result = filterAndSortTransactions(mockTxs, defaultFilters);
    // Locate the two items with date 2026-06-10
    const idx1 = result.findIndex((t) => t.id === '1');
    const idx2 = result.findIndex((t) => t.id === '2');
    // They should be adjacent
    expect(Math.abs(idx1 - idx2)).toBe(1);
    // With date-desc: tie goes to higher ID first (since b.id.localeCompare(a.id))
    expect(idx2).toBeLessThan(idx1);
  });
});

describe('extractUniqueCategories', () => {
  const mockTxs: NormalizedTransaction[] = [
    { id: '1', date: '2026-06-10', description: 'Salary',     category_name: 'salary', type: 'income',  amount: 5000 },
    { id: '2', date: '2026-06-10', description: 'Bonus',      category_name: 'salary', type: 'income',  amount: 1000 },
    { id: '3', date: '2026-06-05', description: 'groceries',  category_name: 'food',   type: 'expense', amount: -150 },
    { id: '4', date: '2026-06-15', description: 'FUN event',  category_name: 'fun',    type: 'expense', amount: -75  },
    { id: '5', date: '2026-06-01', description: 'Transfer to savings', category_name: null,  type: 'transfer', amount: -200 },
    { id: '6', date: '2026-06-12', description: 'Dining out', category_name: null,     type: 'expense', amount: -45  },
  ];

  it('returns sorted unique non-null categories', () => {
    const result = extractUniqueCategories(mockTxs);
    expect(result).toEqual(['food', 'fun', 'salary']);
    // Verify sorted alphabetically with Polish locale
    expect(result[0]).toBe('food');
    expect(result[1]).toBe('fun');
    expect(result[2]).toBe('salary');
  });

  it('returns empty array for null input', () => {
    expect(extractUniqueCategories(null)).toEqual([]);
  });
});
