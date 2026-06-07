---
spike: 006b
name: google-oauth-redirect-uri
type: standard
validates: "Given Google env variables, when signing in from frontend, then redirect and callback work without CORS or redirect URL mismatch"
verdict: VALIDATED
related: [006a]
tags: [auth, frontend, oauth]
---

# Spike 006b: Google OAuth Redirect URI

## What This Validates
Given Google environment variables are configured on the backend, when the client triggers Google OAuth signup/login from `http://localhost:5173`, the backend processes the social sign-in request and checks if the `callbackURL` matches the backend's trusted origins. If the callback URL is not in `TRUSTED_ORIGINS`, the backend returns `403 Forbidden` with the error `INVALID_CALLBACK_URL`. If it matches, the backend successfully responds with a `200 OK` JSON payload containing the Google OAuth URL.

## Research
We validated that:
1. Better Auth uses `trustedOrigins` configuration to validate where the user can be redirected after the OAuth flow.
2. In `src/auth.ts`, the default `trustedOrigins` is `['http://localhost:5173']` if `TRUSTED_ORIGINS` is not defined in env variables.
3. In `index.ts`, CORS middleware is configured to accept requests from the frontend URL (defaults to `http://localhost:5173`).
4. If a client attempts to use a callback URL that is not explicitly whitelisted in `TRUSTED_ORIGINS` or matches the default backend origin, Better Auth rejects the request with status code `403` and message `Invalid callbackURL`.

## How to Run
Run the test script:
```bash
bun run .planning/spikes/006b-google-oauth-redirect-uri/test-trusted-origins.ts
```

## What to Expect
- Testing untrusted callback URL `http://localhost:5173/dashboard` when `TRUSTED_ORIGINS` is set to `http://my-trusted-app.com` returns `403 Forbidden` with body `{"message":"Invalid callbackURL","code":"INVALID_CALLBACK_URL"}`.
- Testing trusted callback URL `http://my-trusted-app.com/dashboard` returns `200 OK` with JSON containing the redirect URL.

## Results
- **Verdict:** VALIDATED ✓
- Configured whitelists must match the client-facing host origin exactly. In development, this is `http://localhost:5173`, which is correctly set as default in `src/auth.ts`.
