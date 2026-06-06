import { describe, it, expect } from 'bun:test';
import { readFileSync } from 'fs';
import iconv from 'iconv-lite';
import {
  preprocessIngCsv,
  preprocessIpkoCsv,
  countTransactionRows,
  buildFewShotPrompt,
} from '../src/workers/import-worker';

describe('CSV Preprocessing & Parsing Tests', () => {
  it('preprocesses ING CSV correctly and extracts 83 rows', () => {
    const rawBuffer = readFileSync('.planning/sample-import/ing.csv');
    const decoded = iconv.decode(rawBuffer, 'windows-1250');
    
    const preprocessed = preprocessIngCsv(decoded);
    const firstLine = preprocessed.split('\n')[0];
    expect(firstLine).toContain('Data transakcji');
    expect(preprocessed).not.toContain('Lista transakcji'); // Metadata stripped
    
    const count = countTransactionRows(preprocessed, 'ing');
    expect(count).toBe(83);

    // Assert Polish diacritics are preserved (no mojibake)
    // "KANCELARIA PODATKOWO-GOSPODARCZA SPÓŁKA Z OGRANICZONĄ ODPOWIEDZIALNOŚCIĄ"
    expect(preprocessed).toContain('SPÓŁKA Z OGRANICZONĄ');
  });

  it('throws error when ING CSV header is missing', () => {
    expect(() => preprocessIngCsv('Some random text\nwithout header')).toThrow(
      'ING CSV header not found'
    );
  });

  it('preprocesses IPKO CSV correctly and filters Blokada rows, returning 252 rows', () => {
    const rawBuffer = readFileSync('.planning/sample-import/ipko.csv');
    const decoded = iconv.decode(rawBuffer, 'windows-1250');

    const preprocessed = preprocessIpkoCsv(decoded);
    expect(preprocessed).not.toContain('Blokada'); // Filtered out

    const count = countTransactionRows(preprocessed, 'ipko');
    expect(count).toBe(252);

    // Verify Polish diacritics like Płatność kartą
    expect(preprocessed).toContain('Płatność kartą');
  });

  it('builds few-shot prompts containing Polish transfer examples', () => {
    const prompt = buildFewShotPrompt('ing', '2026-06-01;...;100.00;PLN');
    expect(prompt).toContain('"raw_type":"income"');
    expect(prompt).toContain('"raw_type":"expense"');
    expect(prompt).toContain('"raw_type":"transfer"');
    expect(prompt).toContain('Wplata wlasna - Olaf Krawczyk');
  });
});
