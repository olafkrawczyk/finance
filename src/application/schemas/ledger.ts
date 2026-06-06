import * as z from 'zod';

// POST /transactions
export const CreateTransactionSchema = z.object({
  account_id: z.uuid(),
  category_id: z.uuid().nullable().optional(),
  type: z.enum(['income', 'expense', 'transfer']),
  amount: z.string().regex(/^\d+(\.\d{1,4})?$/, 'Amount must be a positive decimal with up to 4 places'),
  description: z.string().max(2000).nullable().optional(),
  date: z.iso.date(),
  transfer_to_account_id: z.uuid().nullable().optional(),
});

// POST /opening-balance
export const CreateOpeningBalanceSchema = z.object({
  year: z.number().int().min(2000).max(2100),
  month: z.number().int().min(1).max(12),
  opening_balance: z.string().regex(/^-?\d+(\.\d{1,4})?$/, 'opening_balance must be a decimal with up to 4 places'),
  notes: z.string().max(1000).nullable().optional(),
});

// PUT /opening-balance/:id
export const UpdateOpeningBalanceSchema = CreateOpeningBalanceSchema.partial();

// PATCH /transactions/:id/category
// NOTE: category assignment is one-way (null → UUID). Once set, category_id
// cannot be cleared through this endpoint. The DB trigger enforces this at
// the persistence layer. A separate migration would be required to allow
// removing a category assignment.
export const AssignCategorySchema = z.object({
  category_id: z.uuid(), // must be a non-null UUID; null is intentionally not accepted
});

// GET /transactions query params
export const ListTransactionsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  per_page: z.coerce.number().int().min(1).max(500).default(50),
  account_id: z.uuid().optional(),
  type: z.enum(['income', 'expense', 'transfer']).optional(),
  date_from: z.iso.date().optional(),
  date_to: z.iso.date().optional(),
  uncategorized: z.coerce.boolean().optional(),
});

export type CreateTransactionInput = z.infer<typeof CreateTransactionSchema>;
export type CreateOpeningBalanceInput = z.infer<typeof CreateOpeningBalanceSchema>;
export type UpdateOpeningBalanceInput = z.infer<typeof UpdateOpeningBalanceSchema>;
export type ListTransactionsQuery = z.infer<typeof ListTransactionsQuerySchema>;
