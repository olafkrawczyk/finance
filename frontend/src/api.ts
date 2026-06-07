function redirectToLogin() {
  if (window.location.pathname !== '/login') {
    window.location.pathname = '/login';
  }
}

async function apiFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const res = await fetch(input, { credentials: 'include', ...init });
  if (res.status === 401) {
    redirectToLogin();
    throw new Error('Session expired — redirecting to login');
  }
  return res;
}

export async function getAccounts() {
  const res = await apiFetch('/accounts');
  if (!res.ok) {
    throw new Error(`Failed to fetch accounts: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function startImport(file: File, accountId: string, bankFormat?: 'ing' | 'ipko') {
  const formData = new FormData();
  formData.append('csv', file);
  formData.append('account_id', accountId);
  if (bankFormat) {
    formData.append('bank_format', bankFormat);
  }

  const res = await apiFetch('/import', {
    method: 'POST',
    body: formData,
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Upload failed: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data; // returns { job_id }
}

export async function startExcelMigration(file: File) {
  const formData = new FormData();
  formData.append('file', file);

  const res = await apiFetch('/api/migration/excel', {
    method: 'POST',
    body: formData,
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Migration upload failed: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data; // returns { job_id }
}

export async function getMigrationStatus(jobId: string) {
  const res = await apiFetch(`/import/${jobId}`);
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to get migration status: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data; // returns ImportJob object
}

export async function getImportStatus(jobId: string) {
  const res = await apiFetch(`/import/${jobId}`);
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to get status: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data; // returns ImportJob object
}

export async function getMonthlySummary() {
  const res = await apiFetch('/transactions/summary');
  if (!res.ok) {
    throw new Error(`Failed to fetch summary: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function getTransactions(params?: {
  account_id?: string;
  type?: 'income' | 'expense' | 'transfer';
  date_from?: string;
  date_to?: string;
  page?: number;
  per_page?: number;
  uncategorized?: boolean;
}) {
  const searchParams = new URLSearchParams();
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.set(key, String(value));
    });
  }
  const qs = searchParams.toString();
  const res = await apiFetch(`/transactions${qs ? '?' + qs : ''}`);
  if (!res.ok) {
    throw new Error(`Failed to fetch transactions: ${res.statusText}`);
  }
  const json = await res.json();
  return { data: json.data, meta: json.meta };
}

export async function getCategories() {
  const res = await apiFetch('/categories');
  if (!res.ok) {
    throw new Error(`Failed to fetch categories: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function createTransaction(data: {
  account_id: string;
  category_id?: string | null;
  type: 'income' | 'expense' | 'transfer';
  amount: string;
  description?: string | null;
  date: string;
}) {
  const res = await apiFetch('/transactions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to create transaction: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function getTransaction(id: string) {
  const res = await apiFetch(`/transactions/${id}`);
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to fetch transaction: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function updateTransaction(id: string, data: {
  account_id: string;
  category_id?: string | null;
  type: 'income' | 'expense' | 'transfer';
  amount: string;
  description?: string | null;
  date: string;
  transfer_to_account_id?: string | null;
}) {
  const res = await apiFetch(`/transactions/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to update transaction: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function deleteTransaction(id: string) {
  const res = await apiFetch(`/transactions/${id}`, {
    method: 'DELETE',
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to delete transaction: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function assignCategory(transactionId: string, categoryId: string) {
  const res = await apiFetch(`/transactions/${transactionId}/category`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ category_id: categoryId }),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to assign category: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function getOpeningBalance(year?: number, month?: number) {
  const searchParams = new URLSearchParams();
  if (year != null) searchParams.set('year', String(year));
  if (month != null) searchParams.set('month', String(month));
  const qs = searchParams.toString();
  const res = await apiFetch(`/opening-balance${qs ? '?' + qs : ''}`);
  if (!res.ok) {
    throw new Error(`Failed to fetch opening balance: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function getInsights(params?: {
  type?: 'alert' | 'tip' | 'trend' | 'forecast';
  dismissed?: boolean;
  page?: number;
  per_page?: number;
}) {
  const searchParams = new URLSearchParams();
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.set(key, String(value));
    });
  }
  const qs = searchParams.toString();
  const res = await apiFetch(`/insights${qs ? '?' + qs : ''}`);
  if (!res.ok) {
    throw new Error(`Failed to fetch insights: ${res.statusText}`);
  }
  const json = await res.json();
  return { data: json.data, meta: json.meta };
}

export async function dismissInsight(insightId: string) {
  const res = await apiFetch(`/insights/${insightId}/dismiss`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ dismissed: true }),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to dismiss insight: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function generateInsights() {
  const res = await apiFetch('/insights/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to generate insights: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function getInsightsForecast() {
  const res = await apiFetch('/insights/forecast');
  if (!res.ok) {
    throw new Error(`Failed to fetch forecasts: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function getAssets() {
  const res = await apiFetch('/assets');
  if (!res.ok) {
    throw new Error(`Failed to fetch assets: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function createAsset(data: { name: string; value: number }) {
  const res = await apiFetch('/assets', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to create asset: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function updateAsset(id: string, data: { name: string; value: number }) {
  const res = await apiFetch(`/assets/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to update asset: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function deleteAsset(id: string) {
  const res = await apiFetch(`/assets/${id}`, {
    method: 'DELETE',
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to delete asset: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}
