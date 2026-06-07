process.env.GOOGLE_CLIENT_ID = "dummy-google-client-id";
process.env.GOOGLE_CLIENT_SECRET = "dummy-google-client-secret";

console.log("Setting environment variables in inspect-auth.ts");

const { auth } = await import('../../../src/auth');

console.dir(auth.options, { depth: null });
console.log("GOOGLE_CLIENT_ID:", process.env.GOOGLE_CLIENT_ID);
process.exit(0);
