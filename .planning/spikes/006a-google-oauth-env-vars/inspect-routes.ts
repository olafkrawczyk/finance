process.env.GOOGLE_CLIENT_ID = "dummy-google-client-id";
process.env.GOOGLE_CLIENT_SECRET = "dummy-google-client-secret";

const { auth } = await import('../../../src/auth');

console.log("Auth keys:", Object.keys(auth));
console.log("Context keys:", Object.keys(auth.$context));
if (auth.$context.routes) {
  console.log("Context routes keys:", Object.keys(auth.$context.routes));
}
if (auth.$context.socialProviders) {
  console.log("Context social providers:", auth.$context.socialProviders);
}
// Let's print the handler source code or properties
console.log("Handler:", auth.handler.toString().slice(0, 300));
process.exit(0);
