process.env.GOOGLE_CLIENT_ID = "dummy-google-client-id";
process.env.GOOGLE_CLIENT_SECRET = "dummy-google-client-secret";

console.log("Setting environment variables in test-api-directly.ts");

const { auth } = await import('../../../src/auth');

async function testDirectApi() {
  try {
    console.log("Calling auth.api.signInSocial...");
    
    // Note: Better Auth expects headers/request context in context, let's call it via API
    // The signature is usually auth.api.signInSocial({ body: { provider: 'google', callbackURL: '...' } })
    const res = await auth.api.signInSocial({
      body: {
        provider: 'google',
        callbackURL: 'http://localhost:5173/dashboard',
      },
    });

    console.log("Response:", res);
  } catch (error) {
    console.error("API call failed with error:", error);
  }
}

testDirectApi().then(() => process.exit(0));
