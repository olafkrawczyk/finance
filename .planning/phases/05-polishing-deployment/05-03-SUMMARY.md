---
phase: 05-polishing-deployment
plan: 03
subsystem: deployment
tags: [hono, serve-static, env-vars, deployment-docs, docker, production]
requires:
  - phase: 05-polishing-deployment
    plan: 01
    provides: Dockerfile, docker-compose with app service, entrypoint
  - phase: 05-polishing-deployment
    plan: 02
    provides: node-pg-migrate integration, migration runner, baseline migration
provides:
  - Production static file serving via Hono serveStatic
  - Complete .env.example with all 11 production environment variables
  - DEPLOYMENT.md with full deployment guide
affects: []
tech-stack:
  added: []
  patterns:
    - Hono serveStatic for production frontend serving with SPA fallback
    - API-first route ordering: API → static assets → SPA catch-all
key-files:
  created:
    - DEPLOYMENT.md
  modified:
    - index.ts
    - .env.example
key-decisions:
  - "NODE_ENV gating for serveStatic instead of async Bun.file check to avoid top-level await complications"
  - "serveStatic from hono/bun (Bun-native import path) for production static serving"
  - "API routes registered first, before static middleware, to prevent static fallback catching API calls"
  - ".env.example documents 11 vars with OAuth providers commented out as optional"
  - "DEPLOYMENT.md includes Cloudflare Tunnel permanent setup instructions alongside ad-hoc"
patterns-established:
  - "Production static serving uses NODE_ENV gate with three-tier route ordering: API → /assets/* → *"
  - "Environment variables are documented in .env.example and expanded in DEPLOYMENT.md reference table"
requirements-completed:
  - REQ-3.1
  - REQ-3.2
  - REQ-3.3
  - REQ-5.1
duration: 1 min
completed: 2026-06-07
---

# Phase 05 Plan 03: Production Static Serving & Deployment Docs Summary

**Hono serveStatic for Vite-built frontend, comprehensive .env.example with 11 vars, and DEPLOYMENT.md with full production setup guide**

## Performance

- **Duration:** 1 min
- **Started:** 2026-06-07T10:19:01Z
- **Completed:** 2026-06-07T10:20:04Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added Hono `serveStatic` from `hono/bun` for production static file serving of Vite-built frontend assets
- Three-tier route ordering: API routes (existing) → `/assets/*` (hashed filenames) → `*` catch-all (SPA `index.html` fallback)
- All static serving gated behind `process.env.NODE_ENV === 'production'` guard
- All existing routes, middleware, and exports preserved unchanged
- `.env.example` expanded from 2 to 11 documented environment variables with descriptions and generation instructions
- OAuth provider vars (Google, GitHub) included as commented-out optional entries
- `DEPLOYMENT.md` created with 12 sections covering architecture, prerequisites, deployment, migrations, rollback, secrets, ingress, and dev vs production comparison

## Task Commits

Each task was committed atomically:

1. **Task 1: Add serveStatic to index.ts** - `9bd8592` (feat)
2. **Task 2: Update .env.example** - `0ce3ad9` (feat)
3. **Task 3: Create DEPLOYMENT.md** - `ba2cfbd` (docs)

**Plan metadata:** pending (after SUMMARY.md commit)

## Files Created/Modified

- `index.ts` - Added `import { serveStatic } from 'hono/bun'`, production static serving block for `/assets/*` and SPA `*` catch-all, gated by `NODE_ENV === 'production'`
- `.env.example` - Complete production env template with 11 variables, descriptions, and `openssl` generation instructions
- `DEPLOYMENT.md` - Full deployment guide (264 lines, 12 sections)

## Decisions Made

- **NODE_ENV gating over async file check:** Used `process.env.NODE_ENV === 'production'` instead of `await Bun.file().exists()` to avoid top-level await complexity. The production env is set in Docker Compose and Dockerfile.
- **serveStatic from hono/bun:** Used the Bun-native import path for optimal Bun runtime compatibility.
- **API-first route ordering:** API routes registered first (as they were in existing index.ts), then `/assets/*` for hashed static files, then `*` catch-all for SPA fallback — prevents static serving from intercepting API calls.
- **11 env vars documented:** All vars read by `src/auth.ts` and the application are documented. OAuth provider vars are commented out as optional.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required. The `.env.example` is a template, and `DEPLOYMENT.md` provides full setup instructions.

## Next Phase Readiness

- Plan 3 (static serving, env docs, deployment guide) complete
- Remaining: Plan 4 (auth hardening verification)
- No blockers — ready for Plan 4

## Self-Check: PASSED

| Check | Status |
|-------|--------|
| index.ts has serveStatic import from hono/bun | PASS |
| index.ts has NODE_ENV production gate | PASS |
| index.ts has /assets/* and * catch-all routes | PASS |
| index.ts has all existing routes preserved | PASS |
| .env.example has all required vars (DATABASE_URL, PORT, BETTER_AUTH_SECRET, BETTER_AUTH_URL, FRONTEND_URL, TRUSTED_ORIGINS, OPENROUTER_API_KEY) | PASS |
| .env.example has optional OAuth vars (commented) | PASS |
| .env.example has openssl generation instructions | PASS |
| DEPLOYMENT.md exists with all 12 sections | PASS |
| DEPLOYMENT.md has env var reference table | PASS |
| DEPLOYMENT.md has Cloudflare ingress setup | PASS |
| DEPLOYMENT.md has migration/docs/rollback sections | PASS |
| All 3 task commits exist | PASS |
| SUMMARY.md exists | PASS |

---

*Phase: 05-polishing-deployment*
*Completed: 2026-06-07*
