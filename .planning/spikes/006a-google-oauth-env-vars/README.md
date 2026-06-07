---
spike: 006a
name: google-oauth-env-vars
type: standard
validates: "Given backend server, when started without Google env variables, then Better Auth Google provider is not registered"
verdict: VALIDATED
related: []
tags: [auth, backend, oauth]
---

# Spike 006a: Google OAuth Env Vars

## What This Validates
Given the backend server, when started without Google environment variables (`GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`), then Better Auth does not register the Google social provider, and any social sign-in request to `POST /api/auth/sign-in/social` with `{ provider: 'google' }` fails with `404` and `{"message":"Provider not found","code":"PROVIDER_NOT_FOUND"}`.

## Research
We inspected `src/auth.ts` and noticed the Google social provider is conditionally loaded only if `process.env.GOOGLE_CLIENT_ID` and `process.env.GOOGLE_CLIENT_SECRET` are set.
The client makes a POST request to `/api/auth/sign-in/social` with `{ provider: 'google', callbackURL: '...' }` to initiate the OAuth flow.

## How to Run
Run the test script:
```bash
bun run .planning/spikes/006a-google-oauth-env-vars/test-handler.ts
```

## What to Expect
With env variables deleted:
- Better Auth prints `ERROR [Better Auth]: Provider not found. Make sure to add the provider in your auth config`
- HTTP Response status: `404`
- HTTP Response body: `{"message":"Provider not found","code":"PROVIDER_NOT_FOUND"}`

With env variables set:
- HTTP Response status: `200`
- Response body contains the Google login redirect URL.

## Investigation Trail
- Classic ES Modules gotcha: `import` statement was hoisted in Bun tests, requiring dynamic `await import` in scripts to set env variables before `auth.ts` evaluated.
- Discovered that the correct path is POST `/api/auth/sign-in/social` (matching kebab-case translation of `signInSocial`).

## Results
- **Verdict:** VALIDATED ✓
- Verified that missing credentials directly causes `PROVIDER_NOT_FOUND` 404 response on the server.
