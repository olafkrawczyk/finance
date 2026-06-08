export const queryKeys = {
  user: (userId: string) => ['user', userId] as const,

  transactions: {
    all: (userId: string) => ['user', userId, 'transactions'] as const,
    list: (userId: string, filters?: Record<string, unknown>) =>
      ['user', userId, 'transactions', { ...filters }] as const,
    detail: (userId: string, id: string) =>
      ['user', userId, 'transactions', id] as const,
  },

  categories: {
    all: (userId: string) => ['user', userId, 'categories'] as const,
  },

  accounts: {
    all: (userId: string) => ['user', userId, 'accounts'] as const,
  },

  assets: {
    all: (userId: string) => ['user', userId, 'assets'] as const,
  },

  summary: {
    all: (userId: string) => ['user', userId, 'summary'] as const,
    monthly: (userId: string, year: number, month: number) =>
      ['user', userId, 'summary', { year, month }] as const,
  },

  openingBalance: {
    byMonth: (userId: string, year: number, month: number) =>
      ['user', userId, 'openingBalance', { year, month }] as const,
  },

  insights: {
    all: (userId: string) => ['user', userId, 'insights'] as const,
    list: (userId: string, filters?: Record<string, unknown>) =>
      ['user', userId, 'insights', { ...filters }] as const,
    forecast: (userId: string) => ['user', userId, 'insights', 'forecast'] as const,
  },

  importStatus: (userId: string, jobId: string) =>
    ['user', userId, 'imports', jobId] as const,

  migration: {
    status: (userId: string, jobId: string) =>
      ['user', userId, 'migration', jobId] as const,
  },
};
