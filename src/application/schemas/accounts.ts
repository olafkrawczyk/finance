import { z } from 'zod';

export const CreateAccountSchema = z.object({
  name: z.string().min(1).max(100),
  type: z.enum(['business', 'personal']),
  currency: z.string().default('PLN'),
  starting_balance: z.coerce.number().min(0).default(0),
  starting_balance_date: z.iso.date().nullable().optional(),
});

export const UpdateAccountSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  starting_balance: z.coerce.number().min(0).optional(),
  starting_balance_date: z.iso.date().nullable().optional(),
});

export type CreateAccountParams = z.infer<typeof CreateAccountSchema>;
export type UpdateAccountParams = z.infer<typeof UpdateAccountSchema>;
