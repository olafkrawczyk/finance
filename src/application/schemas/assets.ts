import { z } from 'zod';

export const CreateAssetSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  value: z.number().min(0, 'Value must be non-negative'),
});

export const UpdateAssetSchema = CreateAssetSchema;

export type CreateAssetInput = z.infer<typeof CreateAssetSchema>;
export type UpdateAssetInput = z.infer<typeof UpdateAssetSchema>;
