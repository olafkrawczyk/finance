import { describe, it, expect } from 'bun:test';
import {
  CreateTransactionSchema,
  CreateOpeningBalanceSchema,
  UpdateOpeningBalanceSchema,
  ListTransactionsQuerySchema,
} from '../src/application/schemas/ledger';

describe('CreateTransactionSchema', () => {
  it('accepts valid transaction', () => {
    const result = CreateTransactionSchema.safeParse({
      account_id: '3c8d1844-0b1a-4712-8bb4-098522a105c3',
      type: 'expense',
      amount: '42.5000',
      date: '2024-01-15',
    });
    expect(result.success).toBe(true);
  });

  it('rejects invalid uuid with z.uuid()', () => {
    const result = CreateTransactionSchema.safeParse({
      account_id: 'not-a-uuid',
      type: 'expense',
      amount: '10.00',
      date: '2024-01-15',
    });
    expect(result.success).toBe(false);
  });

  it('rejects negative amount or more than 4 decimals', () => {
    const resultNeg = CreateTransactionSchema.safeParse({
      account_id: '3c8d1844-0b1a-4712-8bb4-098522a105c3',
      type: 'expense',
      amount: '-5.00',
      date: '2024-01-15',
    });
    expect(resultNeg.success).toBe(false);

    const resultDec = CreateTransactionSchema.safeParse({
      account_id: '3c8d1844-0b1a-4712-8bb4-098522a105c3',
      type: 'expense',
      amount: '1.23456',
      date: '2024-01-15',
    });
    expect(resultDec.success).toBe(false);
  });
});

describe('CreateOpeningBalanceSchema', () => {
  it('accepts negative opening_balance (net worth can be negative)', () => {
    const result = CreateOpeningBalanceSchema.safeParse({
      year: 2024,
      month: 1,
      opening_balance: '-500.0000',
    });
    expect(result.success).toBe(true);
  });

  it('rejects month out of range or year out of range', () => {
    const resultMonth = CreateOpeningBalanceSchema.safeParse({
      year: 2024,
      month: 13,
      opening_balance: '1000.00',
    });
    expect(resultMonth.success).toBe(false);

    const resultYear = CreateOpeningBalanceSchema.safeParse({
      year: 1999,
      month: 1,
      opening_balance: '1000.00',
    });
    expect(resultYear.success).toBe(false);
  });
});

describe('UpdateOpeningBalanceSchema', () => {
  it('accepts empty object (partial schema)', () => {
    const result = UpdateOpeningBalanceSchema.safeParse({});
    expect(result.success).toBe(true);
  });
});

describe('ListTransactionsQuerySchema', () => {
  it('coerces parameters and sets defaults', () => {
    const result = ListTransactionsQuerySchema.safeParse({
      page: '2',
      per_page: '100',
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.page).toBe(2);
      expect(result.data.per_page).toBe(100);
    }
  });

  it('uses defaults when values are missing', () => {
    const result = ListTransactionsQuerySchema.safeParse({});
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.page).toBe(1);
      expect(result.data.per_page).toBe(50);
    }
  });
});
