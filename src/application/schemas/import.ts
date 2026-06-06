import * as z from 'zod';

export const ImportUploadSchema = z.object({
  account_id: z.uuid(),
  bank_format: z.enum(['ing', 'ipko']).optional(),
});

export const ImportStatusQuerySchema = z.object({
  job_id: z.uuid(),
});

export const ParsedTransactionSchema = z.object({
  date: z.iso.date(),
  amount: z.string().regex(/^\d+(\.\d{1,4})?$/, 'Amount must be a positive decimal with up to 4 places'),
  description: z.string().min(1).max(2000),
  raw_type: z.enum(['income', 'expense', 'transfer']),
});

export type ImportUploadInput = z.infer<typeof ImportUploadSchema>;
export type ImportStatusQuery = z.infer<typeof ImportStatusQuerySchema>;
export type ParsedTransaction = z.infer<typeof ParsedTransactionSchema>;
