import { app } from '../../../index';

async function testGoogleSignIn() {
  console.log("Checking environment variables:");
  console.log("GOOGLE_CLIENT_ID:", process.env.GOOGLE_CLIENT_ID ? "SET" : "NOT SET");
  console.log("GOOGLE_CLIENT_SECRET:", process.env.GOOGLE_CLIENT_SECRET ? "SET" : "NOT SET");

  try {
    const res = await app.request('/api/auth/login/social', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        provider: 'google',
        callbackURL: 'http://localhost:5173/dashboard',
      }),
    });

    console.log("Response status:", res.status);
    const bodyText = await res.text();
    console.log("Response body:", bodyText);
  } catch (error) {
    console.error("Request failed with error:", error);
  }
}

testGoogleSignIn().then(() => process.exit(0));
