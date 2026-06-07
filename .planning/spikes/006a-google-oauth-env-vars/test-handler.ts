// Ensure env variables are NOT set
delete process.env.GOOGLE_CLIENT_ID;
delete process.env.GOOGLE_CLIENT_SECRET;

const { auth } = await import('../../../src/auth');

async function checkRoute(path: string, method: string = 'GET', body: any = null) {
  const url = `http://localhost:3000${path}`;
  console.log(`\n--- Checking ${method} ${url} ---`);
  const reqInit: RequestInit = {
    method,
    headers: {
      'Content-Type': 'application/json',
    }
  };
  if (body) {
    reqInit.body = JSON.stringify(body);
  }
  const req = new Request(url, reqInit);
  const res = await auth.handler(req);
  console.log("Status:", res.status);
  console.log("Headers:");
  res.headers.forEach((val, key) => console.log(`  ${key}: ${val}`));
  console.log("Body:", await res.text());
}

// Test sign-in/social POST endpoint
await checkRoute('/api/auth/sign-in/social', 'POST', { provider: 'google', callbackURL: 'http://localhost:5173/dashboard' });

process.exit(0);
