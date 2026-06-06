import { describe, it, expect } from 'bun:test';
import {
  ImportUploadSchema,
  ImportStatusQuerySchema,
  ParsedTransactionSchema,
} from '../src/application/schemas/import';
import { healthDb } from '../src/infrastructure/db/health';

describe('Import Schema Tests', () => {
  describe('ParsedTransactionSchema', () => {
    it('accepts a valid parsed transaction', () => {
      const result = ParsedTransactionSchema.safeParse({
        date: '2026-05-05',
        amount: '246.00',
        description: 'P4',
        raw_type: 'expense',
      });
      expect(result.success).toBe(true);
    });

    it('rejects negative amounts', () => {
      const result = ParsedTransactionSchema.safeParse({
        date: '2026-05-05',
        amount: '-246.00',
        description: 'P4',
        raw_type: 'expense',
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid raw_types', () => {
      const result = ParsedTransactionSchema.safeParse({
        date: '2026-05-05',
        amount: '246.00',
        description: 'P4',
        raw_type: 'refund',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('ImportUploadSchema', () => {
    it('accepts valid input', () => {
      const result = ImportUploadSchema.safeParse({
        account_id: '3c8d1844-0b1a-4712-8bb4-098522a105c3',
        bank_format: 'ing',
      });
      expect(result.success).toBe(true);
    });

    it('rejects non-uuid account_id', () => {
      const result = ImportUploadSchema.safeParse({
        account_id: 'not-a-uuid',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('ImportStatusQuerySchema', () => {
    it('accepts valid job_id uuid', () => {
      const result = ImportStatusQuerySchema.safeParse({
        job_id: '3c8d1844-0b1a-4712-8bb4-098522a105c3',
      });
      expect(result.success).toBe(true);
    });

    it('rejects non-uuid job_id', () => {
      const result = ImportStatusQuerySchema.safeParse({
        job_id: 'abc',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('Database Health Check', () => {
    it('reports import_queue as true', async () => {
      const health = await healthDb();
      expect(health.import_queue).toBe(true);
    });
  });
});
