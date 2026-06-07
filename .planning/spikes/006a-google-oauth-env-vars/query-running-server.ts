async function testRunningServer() {
  try {
    const targetUrl = 'http://localhost:3000/api/auth/login/social/google?callbackURL=http://localhost:5173/dashboard';
    console.log(`Sending HTTP GET to already running server: ${targetUrl}`);
    
    const res = await fetch(targetUrl, {
      method: 'GET',
      redirect: 'manual',
    });

    console.log("Response status:", res.status);
    console.log("Response headers:");
    res.headers.forEach((val, key) => {
      console.log(`  ${key}: ${val}`);
    });
    console.log("Response body:", await res.text());
  } catch (error) {
    console.error("Fetch failed with error:", error);
  }
}

testRunningServer().then(() => process.exit(0));
