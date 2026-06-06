# Plan 02-01 Summary: Auth Foundation

Completed on 2026-06-06.

## Deliverables
- [x] **src/auth.ts**: Configured Better Auth with separate PostgreSQL `Pool`, `emailAndPassword` enabled, and Google + GitHub OAuth providers conditionally loaded to avoid startup crashes in local testing environments.
- [x] **src/interface-adapters/api/auth.ts**: Created `requireAuth` middleware returning standardized 401 response envelopes.
- [x] **index.ts**: Added global session middleware, CORS settings, typed variables context, and mounted `/api/auth/*` endpoint handlers.
- [x] **src/interface-adapters/api/ledger.ts**: Protected all ledger routes.
- [x] **src/interface-adapters/api/opening-balance.ts**: Protected all opening balance routes.
- [x] **src/interface-adapters/api/reference.ts**: Protected reference routes.
- [x] **tests/auth.test.ts**: Added integration tests proving route protection works and sessions authenticate correctly.
- [x] **tests/api.test.ts**: Updated existing API tests to handle session cookie auth and extended health check fields.

## Verification Results
- `bun test tests/auth.test.ts tests/api.test.ts` passed successfully.
- Full test suite (30 assertions) runs green.
