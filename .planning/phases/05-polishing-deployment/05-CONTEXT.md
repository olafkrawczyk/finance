# Phase 5: Polishing & Deployment - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase prepares the single-user financial planning app for production deployment on a homelab and applies targeted polish. It delivers:

1. **Dockerization** — Multi-stage Docker build with single-entry orchestration for all 4 processes (API server, insights worker, import worker, static file serving).
2. **DB migration tooling** — node-pg-migrate integration with rollback support, run on container start.
3. **Secrets management** — `.env.production` on host volume-mounted into container, with all required env vars documented.
4. **Auth hardening** — Ensure auth guard works correctly, session handling is solid, 401 redirects function.
5. **Folded todos** — "Dockerize the app" and "Set up production secrets management" from the pending todos.

</domain>

<decisions>
## Implementation Decisions

### Dockerfile Strategy
- **D-01:** Single-entry orchestration script that starts all 4 processes: Hono API server, insights worker, import worker, and Vite-built static file serving via Hono.
- **D-02:** Multi-stage build — Stage 1 builds the Vite frontend, Stage 2 copies artifacts into the Bun runtime image.
- **D-03:** Use `oven/bun:1` (full image) as the final base image.
- **D-04:** Docker HEALTHCHECK uses the existing `/health` endpoint.

### DB Migration on Deploy
- **D-05:** Use `node-pg-migrate` for versioned, rollback-able database migrations.
- **D-06:** Write down migrations alongside up migrations — rollback by running migration down + redeploying the previous app version.
- **D-07:** Migrations run as part of the container's entrypoint script, before the app processes start.

### Secrets Management
- **D-08:** `.env.production` file stored on the T640 host, volume-mounted into the container at runtime.
- **D-09:** Documented env vars: `DATABASE_URL`, `PORT`, `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`, `OPENROUTER_API_KEY`, `FRONTEND_URL`.
- **D-10:** Entrypoint script loads the env file via `bun --env-file=.env.production`.

### Security Hardening
- **D-11:** Auth hardening only — verify auth guard, session handling, and 401 redirects work correctly in production.

### the agent's Discretion
- Exact structure of the orchestration entrypoint script (Bun script vs shell script).
- Exact migration file location and naming conventions (follow node-pg-migrate defaults).
- Dockerfile optimization details (layer caching, .dockerignore).
- Auth hardening test details — agent determines what constitutes sufficient verification.

### Folded Todos
- **Dockerize the app:** `.planning/todos/pending/dockerize-app.md` — directly folded into Phase 5 scope.
- **Set up production secrets management:** `.planning/todos/pending/production-secrets-management.md` — directly folded into Phase 5 scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Deployment Architecture
- `.planning/notes/deployment-architecture-decisions.md` — Locked architecture: HP T640, Cloudflare Tunnel, single Bun container, Postgres with PGMQ, no Nginx.

### Current Infrastructure
- `docker-compose.yml` — Existing Postgres-only docker-compose. Must be updated to include the app service.
- `index.ts` — Hono server entry, Bun-native export, static serving not yet configured.
- `vite.config.ts` — Vite proxy config for dev. Prod uses Hono to serve `dist/`.
- `package.json` — Build/run scripts, dependency list.

### Schema & Migrations
- `src/infrastructure/db/schema.sql` — Full DB schema. node-pg-migrate will manage future changes.

### Secrets Template
- `.env.example` — Current dev-only env template. Expand for production.

### Auth Foundation
- `src/auth.ts` — Better Auth config with session management.
- `src/interface-adapters/api/auth.ts` — requireAuth middleware.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `index.ts` — Bun-native server export with Hono. Just needs static file serving added for `frontend/dist/`.
- `docker-compose.yml` — Existing Postgres service config. Add app service alongside it.

### Established Patterns
- **Single-container approach:** All app processes in one container. No Nginx. Consistent with documented architecture.
- **Hono static serving:** Hono's built-in `serveStatic` can serve the Vite-built `dist/` directory.

### Integration Points
- Entrypoint script must start: Hono API (bun index.ts), insights worker (bun src/workers/insights-worker.ts), import worker (bun src/workers/import-worker.ts), and static file serving (same Hono instance).
- Migrations run before any process starts — must complete successfully or container exits.

</code_context>

<specifics>
## Specific Ideas

- The orchestration entrypoint could be a simple shell script or a Bun script using `Bun.spawn()`.
- For local dev, the existing `concurrently` approach remains unchanged.
- Migration files should live in `src/infrastructure/db/migrations/` following node-pg-migrate conventions.
- `.env.production` should be documented in a `DEPLOYMENT.md` or README section.

</specifics>

<deferred>
## Deferred Ideas

- **E2E testing (Playwright):** Automated end-to-end testing for all pages and interactions — belongs in its own phase, not Phase 5.
- **Full security audit:** Dependency audit, OWASP top-10 check, rate limiting — descoped beyond basic auth hardening.

</deferred>

---

*Phase: 5-polishing-deployment*
*Context gathered: 2026-06-07*
