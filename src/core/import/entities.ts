// NUMERIC(19,4) columns are typed as string — postgres.js returns them as strings.
// Never use number for monetary fields.

export interface ImportJob {
  id: string;                          // UUID
  account_id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  total_rows: number | null;
  processed: number;
  errors: string[] | null;
  created_at: string;                  // TIMESTAMPTZ as ISO string
  updated_at: string;                  // TIMESTAMPTZ as ISO string
}

export interface ParsedTransaction {
  date: string;                        // DATE as ISO string
  amount: string;                      // positive decimal string
  description: string;
  raw_type: 'income' | 'expense' | 'transfer';
}
