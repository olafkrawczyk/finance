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
