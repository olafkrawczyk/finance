process.env.GOOGLE_CLIENT_ID = "dummy-google-client-id";
process.env.GOOGLE_CLIENT_SECRET = "dummy-google-client-secret";

console.log("Setting environment variables in test-with-env.ts");

const { app } = await import('../../../index');

async function testGoogleSignIn() {
  try {
    // 1. Try with port 3000 URL
    const url1 = 'http://localhost:3000/api/auth/login/social/google?callbackURL=http://localhost:5173/dashboard';
    console.log(`\nTesting GET to: ${url1}`);
    const res1 = await app.request(url1, {
      method: 'GET',
    });

    console.log("Response 1 status:", res1.status);
    console.log("Response 1 headers:");
    res1.headers.forEach((val, key) => {
      console.log(`  ${key}: ${val}`);
    });
    console.log("Response 1 body:", await res1.text());

    // 2. Try with localhost:5173 origin header
    const url2 = '/api/auth/login/social/google?callbackURL=http://localhost:5173/dashboard';
    console.log(`\nTesting GET to: ${url2} with Host header`);
    const res2 = await app.request(url2, {
      method: 'GET',
      headers: {
        'Host': 'localhost:3000',
      }
    });

    console.log("Response 2 status:", res2.status);
    console.log("Response 2 headers:");
    res2.headers.forEach((val, key) => {
      console.log(`  ${key}: ${val}`);
    });
    console.log("Response 2 body:", await res2.text());

  } catch (error) {
    console.error("Request failed with error:", error);
  }
}

testGoogleSignIn().then(() => process.exit(0));
