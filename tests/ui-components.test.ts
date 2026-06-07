import { describe, it, expect } from 'bun:test';
import React from 'react';
import { renderToString } from 'react-dom/server';
import ImportUpload from '../frontend/src/components/ImportUpload';
import ImportStatus from '../frontend/src/components/ImportStatus';
import InsightCard from '../frontend/src/components/InsightCard';
import InsightsTabs from '../frontend/src/components/InsightsTabs';
import MonthlyPage from '../frontend/src/pages/MonthlyPage';

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
