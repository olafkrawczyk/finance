import { describe, it, expect } from 'bun:test';
import React from 'react';
import { renderToString } from 'react-dom/server';
import ImportUpload from '../frontend/src/components/ImportUpload';
import ImportStatus from '../frontend/src/components/ImportStatus';

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
});
