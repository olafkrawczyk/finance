process.env.GOOGLE_CLIENT_ID = "dummy-google-client-id";
process.env.GOOGLE_CLIENT_SECRET = "dummy-google-client-secret";

// Let's set TRUSTED_ORIGINS to something else to test validation failure
process.env.TRUSTED_ORIGINS = "http://my-trusted-app.com";

const { auth } = await import('../../../src/auth');

async function testTrustedOrigins() {
  try {
    console.log("1. Testing callbackURL http://localhost:5173/dashboard (Should fail since it's not in TRUSTED_ORIGINS):");
    const req1 = new Request('http://localhost:3000/api/auth/sign-in/social', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        provider: 'google',
        callbackURL: 'http://localhost:5173/dashboard',
      }),
    });

    const res1 = await auth.handler(req1);
    console.log("Status:", res1.status);
    console.log("Response body:", await res1.text());

    console.log("\n2. Testing callbackURL http://my-trusted-app.com/dashboard (Should succeed since it matches TRUSTED_ORIGINS):");
    const req2 = new Request('http://localhost:3000/api/auth/sign-in/social', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        provider: 'google',
        callbackURL: 'http://my-trusted-app.com/dashboard',
      }),
    });

    const res2 = await auth.handler(req2);
    console.log("Status:", res2.status);
    if (res2.status === 200) {
      const body = await res2.json();
      console.log("Success! Redirect URL:", body.url ? "Generated successfully" : "Missing");
    } else {
      console.log("Failed! Body:", await res2.text());
    }

  } catch (error) {
    console.error("Test failed with error:", error);
  }
}

testTrustedOrigins().then(() => process.exit(0));
