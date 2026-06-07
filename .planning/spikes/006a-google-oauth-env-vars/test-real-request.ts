process.env.GOOGLE_CLIENT_ID = "dummy-google-client-id";
process.env.GOOGLE_CLIENT_SECRET = "dummy-google-client-secret";
// Set PORT to 3001
process.env.PORT = "3001";
process.env.BETTER_AUTH_URL = "http://localhost:3001";

console.log("Setting environment variables in test-real-request.ts");

const { app } = await import('../../../index');

// Start the Bun server on port 3001
const server = Bun.serve({
  port: 3001,
  fetch: app.fetch,
});

console.log(`Server started on http://localhost:${server.port}`);

try {
  const targetUrl = 'http://localhost:3001/api/auth/login/social/google?callbackURL=http://localhost:5173/dashboard';
  console.log(`Sending real HTTP GET to: ${targetUrl}`);
  
  const res = await fetch(targetUrl, {
    method: 'GET',
    redirect: 'manual', // do not follow redirect so we can inspect the redirect headers!
  });

  console.log("Response status:", res.status);
  console.log("Response headers:");
  res.headers.forEach((val, key) => {
    console.log(`  ${key}: ${val}`);
  });
  console.log("Response body:", await res.text());
} catch (error) {
  console.error("Fetch failed with error:", error);
} finally {
  server.stop();
  console.log("Server stopped");
  process.exit(0);
}
