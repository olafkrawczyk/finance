// NUMERIC(19,4) columns are typed as string — postgres.js returns them as strings.
// Never use number for monetary fields.

export interface Transaction {
  id: string                          // UUID
  account_id: string
  category_id: string | null
  type: 'income' | 'expense' | 'transfer'
  amount: string                      // NUMERIC(19,4) as string, e.g. "1234.5000"
  description: string | null
  date: string                        // DATE as ISO string, e.g. "2024-01-15"
  transfer_to_account_id: string | null
  import_hash: string | null
  created_at: string                  // TIMESTAMPTZ as ISO string
  updated_at: string | null           // TIMESTAMPTZ as ISO string, null until first edit
}

export interface MonthlyOpeningBalance {
  id: string
  year: number
  month: number
  opening_balance: string             // NUMERIC(19,4) as string
  notes: string | null
  created_at: string
}

export interface Account {
  id: string
  name: string
  type: 'personal' | 'business'
  currency: string
  created_at: string
}

export interface Category {
  id: string
  name: string
  is_fixed_cost: boolean
  created_at: string
}

// Summary row (computed in app layer from SQL aggregation)
export interface MonthlySummaryRow {
  month: string                       // "YYYY-MM"
  wydatki: string                     // total expenses (excluding transfers)
  przychody: string                   // total income
  fixed_cost_total: string            // sum of fixed-cost categories
  wydatki_bez_stalych: string         // wydatki - fixed_cost_total (computed)
  zaoszczedzone: string               // przychody - wydatki (computed)
  zaoszczedzone_log: string           // log10(zaoszczedzone) if > 0, else "0" (computed)
  stan_konta: string | null           // opening_balance + cumulative net (null if no opening balance set)
  wartosc_netto?: string              // stan_konta + forward-filled asset values from snapshots
}
