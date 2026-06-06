import * as z from 'zod';

export const ClaudeInsightSchema = z.object({
  type: z.enum(['alert', 'tip', 'trend']),
  priority: z.enum(['high', 'medium', 'low']),
  title: z.string().min(1).max(500),
  content: z.string().min(1).max(2000),
});

export const ClaudeInsightsResponseSchema = z.object({
  insights: z.array(ClaudeInsightSchema),
});

export const R1ForecastSchema = z.object({
  category_name: z.string().min(1),
  predicted_spending: z.string().regex(/^\d+(\.\d{1,4})?$/, 'Amount must be positive decimal up to 4 places'),
  confidence: z.string().regex(/^\d+(\.\d{1,2})?$/, 'Confidence 0-100'),
  trend: z.enum(['up', 'down', 'flat']),
});

export const R1ForecastResponseSchema = z.object({
  forecasts: z.array(R1ForecastSchema),
});

export const ListInsightsQuerySchema = z.object({
  type: z.enum(['alert', 'tip', 'trend', 'forecast']).optional(),
  dismissed: z.coerce.boolean().optional(),
  page: z.coerce.number().int().min(1).default(1),
  per_page: z.coerce.number().int().min(1).max(100).default(20),
});

export const DismissInsightSchema = z.object({
  dismissed: z.literal(true),
});

export const GenerateInsightsSchema = z.object({});

export type ClaudeInsightInput = z.infer<typeof ClaudeInsightSchema>;
export type ClaudeInsightsResponse = z.infer<typeof ClaudeInsightsResponseSchema>;
export type R1ForecastInput = z.infer<typeof R1ForecastSchema>;
export type R1ForecastResponse = z.infer<typeof R1ForecastResponseSchema>;
export type ListInsightsQuery = z.infer<typeof ListInsightsQuerySchema>;
export type DismissInsightInput = z.infer<typeof DismissInsightSchema>;
export type GenerateInsightsInput = z.infer<typeof GenerateInsightsSchema>;
