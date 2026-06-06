export async function getAccounts() {
  const res = await fetch('/accounts', {
    credentials: 'include',
  });
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

  const res = await fetch('/import', {
    method: 'POST',
    credentials: 'include',
    body: formData,
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Upload failed: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data; // returns { job_id }
}

export async function getImportStatus(jobId: string) {
  const res = await fetch(`/import/${jobId}`, {
    credentials: 'include',
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to get status: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data; // returns ImportJob object
}

export async function getMonthlySummary() {
  const res = await fetch('/transactions/summary', { credentials: 'include' });
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
  const res = await fetch(`/transactions${qs ? '?' + qs : ''}`, { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch transactions: ${res.statusText}`);
  }
  const json = await res.json();
  return { data: json.data, meta: json.meta };
}

export async function getCategories() {
  const res = await fetch('/categories', { credentials: 'include' });
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
  const res = await fetch('/transactions', {
    method: 'POST',
    credentials: 'include',
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
  const res = await fetch(`/transactions/${id}`, { credentials: 'include' });
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
  const res = await fetch(`/transactions/${id}`, {
    method: 'PUT',
    credentials: 'include',
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
  const res = await fetch(`/transactions/${id}`, {
    method: 'DELETE',
    credentials: 'include',
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to delete transaction: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function assignCategory(transactionId: string, categoryId: string) {
  const res = await fetch(`/transactions/${transactionId}/category`, {
    method: 'PATCH',
    credentials: 'include',
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
  const res = await fetch(`/opening-balance${qs ? '?' + qs : ''}`, { credentials: 'include' });
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
  const res = await fetch(`/insights${qs ? '?' + qs : ''}`, { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch insights: ${res.statusText}`);
  }
  const json = await res.json();
  return { data: json.data, meta: json.meta };
}

export async function dismissInsight(insightId: string) {
  const res = await fetch(`/insights/${insightId}/dismiss`, {
    method: 'PATCH',
    credentials: 'include',
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
  const res = await fetch('/insights/generate', {
    method: 'POST',
    credentials: 'include',
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
  const res = await fetch('/insights/forecast', { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch forecasts: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function getAssets() {
  const res = await fetch('/assets', { credentials: 'include' });
  if (!res.ok) {
    throw new Error(`Failed to fetch assets: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}

export async function createAsset(data: { name: string; value: number }) {
  const res = await fetch('/assets', {
    method: 'POST',
    credentials: 'include',
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
  const res = await fetch(`/assets/${id}`, {
    method: 'PUT',
    credentials: 'include',
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
  const res = await fetch(`/assets/${id}`, {
    method: 'DELETE',
    credentials: 'include',
  });
  if (!res.ok) {
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(errorJson.error?.message || `Failed to delete asset: ${res.statusText}`);
  }
  const json = await res.json();
  return json.data;
}


