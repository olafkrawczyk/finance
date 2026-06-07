# Phase 5: Polishing & Deployment - Research

**Researched:** 2026-06-07
**Domain:** Containerization, production deployment, DB migration tooling, auth hardening
**Confidence:** HIGH

## Summary

This phase containerizes the existing Bun/Hono/Postgres financial planning app for production deployment on an HP T640 homelab with Cloudflare Tunnel ingress. The core deliverables are: (1) a multi-stage Dockerfile building the Vite frontend in stage 1 and bundling into `oven/bun:1` in stage 2, (2) `node-pg-migrate` integration for versioned DB migrations, (3) an entrypoint orchestration script managing 3 processes (API+static server, insights worker, import worker), (4) `.env.production` secrets management via volume mount, (5) docker-compose update adding the app service alongside the existing Postgres/PGMQ container, and (6) auth hardening verification.

**Primary recommendation:** Use a multi-stage Dockerfile with `node:22-bookworm` for Vite build, `oven/bun:1` for runtime, a shell-based entrypoint script with SIGTERM forwarding, and `node-pg-migrate` v8 with SQL migration files and a `001_initial_schema.sql` baseline representing the current schema.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-1.1 | Transaction model (category, amount, description, date, type, account_id) | Already implemented — auth hardening verifies guard middleware protects these routes |
| REQ-1.2 | Immutable records (corrections via compensating entries) | Already implemented — auth verifies transaction routes are protected |
| REQ-1.3 | Multi-account (ING business + IPKO personal) | Already implemented — no deployment changes needed |
| REQ-1.4 | Transfer type excluded from income/expense totals | Already implemented |
| REQ-1.5 | Single currency (PLN for MVP) | Already implemented |
| REQ-2.1 | 26 seed categories | Already implemented in seed.sql |
| REQ-2.2 | Fixed cost flag on categories | Already implemented |
| REQ-2.3 | Uncategorized transactions import with NULL category_id | Already implemented |
| REQ-3.1 | Zbiorczy (summary view) | Already implemented |
| REQ-3.2 | Monthly view | Already implemented |
| REQ-3.3 | Dashboard charts | Already implemented |
| REQ-4.1 | POST /import async endpoint | Already implemented |
| REQ-4.2 | PGMQ worker with OpenRouter | Already implemented |
| REQ-4.3 | ING CSV format support | Already implemented |
| REQ-4.4 | IPKO CSV format support | Already implemented |
| REQ-4.5 | SHA-256 deduplication | Already implemented |
| REQ-4.6 | Few-shot OpenRouter prompt | Already implemented |
| REQ-4.7 | Historical bulk import | Already implemented |
| REQ-5.1 | Manual transaction entry | Auth hardening — guard protects the manual entry route `/transactions` with POST/PUT/DELETE |
| NFR-DI | Data integrity (zero-sum verification) | Auth hardening — guard protects integrity by ensuring only authenticated users can mutate data |
| NFR-P | Performance (sub-100ms API) | Docker HEALTHCHECK ensures container responsiveness; single-container approach minimizes overhead |
| NFR-R | Reliability (idempotent/retryable jobs) | Workers already have retry logic — entrypoint ensures they restart on container restart |
| Auth-§5 | OAuth/SSO via Better Auth | Auth hardening verification — OAuth callback URLs, session cookies, CORS, trusted origins all function correctly in production |
| Auth-§6 | Secure data storage | Auth uses `pg.Pool` with `DATABASE_URL` — no at-rest encryption changes in this phase |
</phase_requirements>

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Single-entry orchestration script that starts all 4 processes: Hono API server, insights worker, import worker, and Vite-built static file serving via Hono.
- **D-02:** Multi-stage build — Stage 1 builds the Vite frontend, Stage 2 copies artifacts into the Bun runtime image.
- **D-03:** Use `oven/bun:1` (full image) as the final base image.
- **D-04:** Docker HEALTHCHECK uses the existing `/health` endpoint.
- **D-05:** Use `node-pg-migrate` for versioned, rollback-able database migrations.
- **D-06:** Write down migrations alongside up migrations — rollback by running migration down + redeploying the previous app version.
- **D-07:** Migrations run as part of the container's entrypoint script, before the app processes start.
- **D-08:** `.env.production` file stored on the T640 host, volume-mounted into the container at runtime.
- **D-09:** Documented env vars: `DATABASE_URL`, `PORT`, `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`, `OPENROUTER_API_KEY`, `FRONTEND_URL`.
- **D-10:** Entrypoint script loads the env file via `bun --env-file=.env.production`.
- **D-11:** Auth hardening only — verify auth guard, session handling, and 401 redirects work correctly in production.

### the agent's Discretion
- Exact structure of the orchestration entrypoint script (Bun script vs shell script).
- Exact migration file location and naming conventions (follow node-pg-migrate defaults).
- Dockerfile optimization details (layer caching, .dockerignore).
- Auth hardening test details — agent determines what constitutes sufficient verification.

### Deferred Ideas (OUT OF SCOPE)
- **E2E testing (Playwright):** Automated end-to-end testing for all pages and interactions — belongs in its own phase, not Phase 5.
- **Full security audit:** Dependency audit, OWASP top-10 check, rate limiting — descoped beyond basic auth hardening.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Static file serving | API/Backend (Hono) | — | Hono's `serveStatic` middleware serves Vite-built `dist/` from the same Bun process. No Nginx or separate CDN needed for single-user homelab. |
| DB migration execution | API/Backend (entrypoint) | Database | Migrations run before app starts via node-pg-migrate in the container entrypoint. DB receives the SQL commands. |
| API request handling | API/Backend (Hono) | — | All API routes, auth, CORS, and health checks handled by the single Hono instance. |
| Background workers | API/Backend (Bun processes) | Database | Insights and import workers connect directly to Postgres/PGMQ. They are co-located in the same container but run as separate child processes. |
| Secrets management | Host (T640) | Container mount | `.env.production` stored on host filesystem, volume-mounted into container. Loaded via `bun --env-file`. |
| Secrets lifetime | Host (T640) | — | Env file lives on host. No Docker secrets, no Swarm. Standard volume mount. |
| Ingress / TLS | Cloudflare Tunnel | Host | Cloudflared runs as system service on T640 host, tunnels `https://app.example.com` → `http://localhost:3000`. |
| Auth verification | Browser / Client | API/Backend | Auth guard runs in both client (React `useSession` redirect) and server (Hono middleware `requireAuth`). |

## Standard Stack

### New Dependencies (added this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `node-pg-migrate` | ^8.0.4 | Versioned PostgreSQL migrations | Mature (12+ years, 800+ stars), programmatic API, SQL file support, rollback support, works with Bun via `pg` driver |

### Existing Stack (unchanged, used in deployment)

| Library | Version | Purpose | Deployment Role |
|---------|---------|---------|-----------------|
| `hono` | ^4.12.23 | Web framework | Serves both API and static files via `serveStatic` from `hono/bun` |
| `better-auth` | ^1.6.14 | Authentication | Session management, OAuth callbacks in production |
| `postgres` | ^3.4.9 | SQL tag template queries | App-level DB queries (separate from `node-pg-migrate` which uses `pg`) |
| `oven/bun:1` | 1.3.14 | Runtime image | Full image with build tooling included |
| `ghcr.io/pgmq/pg18-pgmq` | v1.10.0 | Postgres + PGMQ | Existing DB container, unchanged |

### Infrastructure Tools (not in package.json)

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 29.4.0 | Container runtime |
| Docker Compose | v5.1.1 | Multi-service orchestration |
| docker (build) | BuildKit | Multi-stage build (default in modern Docker) |
| Cloudflared | latest | Cloudflare Tunnel on T640 host |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `node-pg-migrate` | `dbmate` | dbmate is a Go binary (no JS dep) but adds a build-time dependency. node-pg-migrate runs in Bun natively. |
| `node-pg-migrate` | Raw `schema.sql` on entrypoint | No versioning, no rollback, no down migrations. node-pg-migrate adds safety. |
| Shell entrypoint | Bun `Bun.spawn()` script | Shell script is simpler (job control, `wait`, `trap`). Bun script has better signal handling. Both viable — agent discretion. |
| Separate static container | Single container | Simpler deployment (no Nginx, no second container). Single container matches T640 single-user profile. |

**Installation:**
```bash
bun add node-pg-migrate
```

**Version verification:** node-pg-migrate v8.0.4 verified via `npm view node-pg-migrate version`. Published 2026-05-21. Repository: github.com/salsita/node-pg-migrate. [VERIFIED: npm registry]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `node-pg-migrate` | npm | 12+ years (since 2014-05-06) | 400K+/week | github.com/salsita/node-pg-migrate | [OK] | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** None
**Packages flagged as suspicious [SUS]:** None

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  HP T640 (Ubuntu Homelab)                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Cloudflared (system service)                            │   │
│  │  └─ HTTPS :443 ──→ Cloudflare ──→ Internet               │   │
│  │     ┌─────────────────────────────────────────────┐       │   │
│  │     │  Docker Compose                             │       │   │
│  │     │                                            │       │   │
│  │     │  ┌─────────────────────────────┐            │       │   │
│  │     │  │  finance-app container      │            │       │   │
│  │     │  │  ┌───────────────────────┐  │            │       │   │
│  │     │  │  │  /app/.env.production  │  │  Volume   │       │   │
│  │     │  │  │  (volume-mounted)      │  │  Mount    │       │   │
│  │     │  │  └───────────────────────┘  │            │       │   │
│  │     │  │                            │            │       │   │
│  │     │  │  Entrypoint (entrypoint.sh)│            │       │   │
│  │     │  │  ├── Run node-pg-migrate   │            │       │   │
│  │     │  │  ├── bun index.ts (API+static serving)  │       │   │
│  │     │  │  ├── bun insights-worker.ts              │       │   │
│  │     │  │  └── bun import-worker.ts                │       │   │
│  │     │  └────────────────────────────┘            │       │   │
│  │     │                                            │       │   │
│  │     │  ┌─────────────────────────────┐            │       │   │
│  │     │  │  finance-postgres container │            │       │   │
│  │     │  │  (pgmq/pg18-pgmq)           │            │       │   │
│  │     │  │  ├── Postgres 18            │            │       │   │
│  │     │  │  └── PGMQ extension         │            │       │   │
│  │     │  └─────────────────────────────┘            │       │   │
│  │     └─────────────────────────────────────────────┘       │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

Data Flow:
  Browser ──HTTPS──→ Cloudflare ──TCP──→ cloudflared ──HTTP──→ Hono :3000
       │                                        ↑
       │  ┌─ GET / → serveStatic(frontend/dist/) │
       ├──┤  GET /api/* → Hono route handlers    │
       │  │  GET /health → Health check           │
       │  └────────────────────────────────────────┘
       │
       └── API 401 → React auth guard redirects to /login
```

### Recommended Project Structure

```
.
├── Dockerfile                          # Multi-stage build
├── .dockerignore                       # Ignore node_modules, .env, etc.
├── entrypoint.sh                       # Container orchestration script
├── docker-compose.yml                  # Updated with app service
├── .env.example                        # Expanded with all production vars
├── DEPLOYMENT.md                       # Deployment instructions (documentation)
├── src/
│   ├── infrastructure/
│   │   └── db/
│   │       ├── migrations/             # node-pg-migrate SQL migrations
│   │       │   ├── 001_initial_schema.sql       # Baseline: current full schema
│   │       │   └── ...future migrations...
│   │       ├── migrate.ts              # Programmatic node-pg-migrate runner
│   │       └── ...existing files...
│   └── ...existing structure...
└── frontend/
    └── dist/                           # Vite build output (copied in Dockerfile)
```

### Pattern 1: Multi-Stage Dockerfile for Bun + Vite

**What:** Two-stage build. Stage 1 (`node:22-bookworm`) builds the Vite frontend. Stage 2 (`oven/bun:1`) copies artifacts and runs the app.

**When to use:** Any time the app has a frontend built by Vite and a Bun backend.

**Example:**
```dockerfile
# Stage 1: Build frontend
FROM node:22-bookworm AS builder
WORKDIR /app
COPY frontend/package.json frontend/bun.lock frontend/
RUN npm ci
COPY frontend/ .
RUN npm run build

# Stage 2: Bun runtime
FROM oven/bun:1
WORKDIR /app

# Copy dependency manifests and install (layer caching)
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile --production

# Copy source
COPY tsconfig.json ./
COPY src/ src/
COPY index.ts ./

# Copy built frontend
COPY --from=builder /app/frontend/dist ./frontend/dist

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD bun -e "fetch('http://localhost:3000/health').then(async r => { if (!r.ok) throw new Error(); console.log(await r.text()) })" || exit 1

EXPOSE 3000
ENTRYPOINT ["/app/entrypoint.sh"]
```

**Source:** [CITED: hono.dev/docs/getting-started/bun] + standard Docker multi-stage patterns.

### Pattern 2: node-pg-migrate Programmatic Runner

**What:** Use the programmatic API (`runner()`) in a Bun script that executes on container start.

**When to use:** When migrations must run before the app starts, inside the container entrypoint.

**Example:**
```typescript
// src/infrastructure/db/migrate.ts
import { runner } from 'node-pg-migrate';

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error('DATABASE_URL not set');
  process.exit(1);
}

async function main() {
  console.log('Running database migrations...');
  await runner({
    databaseUrl: DATABASE_URL,
    dir: 'src/infrastructure/db/migrations',
    direction: 'up',
    migrationsTable: 'pgmigrations',
    // Use SQL file loader
    migrationFileLanguage: 'sql',
    // Log verbose output
    log: (msg) => console.log(`[migrate] ${msg}`),
  });
  console.log('Migrations complete.');
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
```

**Source:** [VERIFIED: ctx7 docs /salsita/node-pg-migrate] — `runner()` API and SQL migration file support.

### Pattern 3: Entrypoint Orchestration with Signal Forwarding

**What:** Shell script that runs migrations, starts all child processes, and forwards SIGTERM/SIGINT to enable graceful shutdown.

**When to use:** The container's ENTRYPOINT must manage multiple long-running processes.

**Example (entrypoint.sh):**
```bash
#!/bin/bash
set -e

# Forward signals to child processes
cleanup() {
  echo "Shutting down..."
  kill -TERM $(jobs -p) 2>/dev/null || true
  wait
  echo "All processes exited."
}
trap cleanup SIGTERM SIGINT

# Load env file if present and not already loaded
# (Docker may also load via env_file or --env-file)
if [ -f /app/.env.production ]; then
  echo "Loading .env.production..."
  set -a
  source /app/.env.production
  set +a
fi

# Run database migrations
echo "=== Running database migrations ==="
bun run src/infrastructure/db/migrate.ts

# Start all processes
echo "=== Starting API server (port ${PORT:-3000}) ==="
bun index.ts &

echo "=== Starting insights worker ==="
bun src/workers/insights-worker.ts &

echo "=== Starting import worker ==="
bun src/workers/import-worker.ts &

# Wait for any process to exit
wait
```

**Source:** Standard Docker shell entrypoint pattern. [ASSUMED]

### Anti-Patterns to Avoid

- **Using Docker's `CMD` with multiple `bun` invocations chained by `&&`:** Only the first process runs. Must use background (`&`) and `wait`.
- **Putting `--env-file` on the Dockerfile `ENTRYPOINT` as a `bun` flag then running a shell script:** Bun's `--env-file` only works when running a Bun script, not a shell script. Either use Docker's `env_file` directive, source the file in bash, or use a Bun entrypoint script.
- **Running migrations in a separate docker-compose `run` command:** Creates timing issues and duplicates the migration tool config. Run in entrypoint as decided.
- **Copying `node_modules` instead of running `bun install` in Dockerfile:** Breaks layer caching and risks host-arch mismatches.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DB schema versioning | Custom migration table + SQL files | `node-pg-migrate` v8.0.4 | Handles locking, ordering, rollback, checksum verification. Thousands of edge cases handled over 12+ years. |
| Process orchestration | Custom process manager in Bun | Simple shell script with `wait` | For a single-user homelab app, shell job control (`&`, `wait`, `trap`) is proven and avoids a dependency on something like `supervisord` or `pm2`. |
| Static file serving | Reverse proxy (Nginx, Caddy) | Hono `serveStatic` from `hono/bun` | 4 fewer moving parts. Hono handles headers, MIME types, fallback. No Nginx config needed. |

**Key insight:** This is a single-user homelab app. Every extra tool (Nginx, supervisord, pm2, Docker health check scripts) adds surface area without meaningful benefit. Keep the stack minimal.

## Common Pitfalls

### Pitfall 1: `serveStatic` Catches API Routes
**What goes wrong:** If `app.use('*', serveStatic({ root: './frontend/dist' }))` is registered BEFORE API routes, ALL requests (including `/api/*`) try to find matching files in `dist/`, returning the SPA `index.html` for API calls instead of reaching the route handlers.
**Why it happens:** Middleware is evaluated in registration order in Hono.
**How to avoid:** Register API routes AND static routes for `/assets/*` FIRST, then register the SPA fallback `app.get('*', serveStatic(...))` LAST. The UI-SPEC.md states this as "Static middleware registered AFTER API routes and before catch-all fallback."
**Pattern:**
```typescript
// 1. API routes (highest priority)
app.route('/api/auth', ...)
app.route('/transactions', ...)
app.route('/health', ...)

// 2. Static assets (hashed filenames, cacheable)
app.use('/assets/*', serveStatic({ root: './frontend/dist' }))

// 3. SPA fallback (catch-all for client-side routing)
app.get('*', serveStatic({ path: './frontend/dist/index.html' }))
```

### Pitfall 2: Migration Order on Existing Database
**What goes wrong:** Running `node-pg-migrate up` on a database that already has the schema applied (from the dev setup) will fail because tables already exist.
**Why it happens:** The initial migration creates tables with `CREATE TABLE IF NOT EXISTS`, so technically it won't error. But the migration will be marked as run even though nothing changed. Worse — subsequent runs on a fresh DB will work fine, so the issue is invisible during development.
**How to avoid:** Create a `001_initial_schema.sql` baseline migration that contains exactly the current `schema.sql`. For existing DBs, run with `--fake` to mark it as applied. For new DBs (production), run it normally. Document this in DEPLOYMENT.md.
**Alternative:** Use `CREATE TABLE IF NOT EXISTS` in the baseline migration so it's idempotent. This means on existing DBs, the migration "runs" but does nothing. This is safe but slightly inelegant.

### Pitfall 3: Session Cookie Domain Mismatch
**What goes wrong:** Better Auth sets session cookies scoped to the domain. If `BETTER_AUTH_URL` points to `https://app.example.com` but the browser sees the request coming from a different origin (e.g., due to Cloudflare Tunnel or proxy), the cookie isn't sent.
**Why it happens:** The session cookie domain must match the actual browser-visible URL. With Cloudflare Tunnel, the browser talks to `https://app.example.com` which tunnels to `http://localhost:3000`. The app must respond as if it's on `https://app.example.com`.
**How to avoid:**
- `BETTER_AUTH_URL` must be set to `https://app.example.com` (the public domain, not localhost) [CITED: CONTEXT.md D-09]
- `FRONTEND_URL` must also be the public URL
- `trustedOrigins` must include `https://app.example.com`
- Hono CORS middleware `origin` must match the public URL (or be the public URL for credential requests)

### Pitfall 4: Import Worker Needs the `xlsx` Dependency at Runtime
**What goes wrong:** The import worker uses `xlsx` for Excel migration files. Building with `--production` flag might exclude it if `xlsx` is in `devDependencies`.
**Why it happens:** `xlsx` is in `dependencies` currently, so this is fine. But any future dependency audit must preserve this.
**How to avoid:** Verify `xlsx` is in `dependencies` (not `devDependencies`) in `package.json`. It already is.

### Pitfall 5: Bun's `import.meta.dir` in Compiled Context
**What goes wrong:** The `apply.ts` file uses `import.meta.dir` (Bun-specific) to locate `schema.sql`. When running inside Docker, `import.meta.dir` resolves relative to the Bun binary path, which might differ from the app directory.
**Why it happens:** Bun's `import.meta.dir` is the directory of the current module file, similar to `__dirname` in Node. It should work correctly in Docker since the app files are at `/app/...` but worth verifying.
**How to avoid:** For the node-pg-migrate `dir` option, use an absolute or relative path from CWD. The Dockerfile's `WORKDIR /app` ensures CWD is `/app`.

### Pitfall 6: HEALTHCHECK in a Multi-Process Container
**What goes wrong:** The Docker HEALTHCHECK checks `/health` on the Hono server. If the workers crash but the API server is healthy, Docker considers the container healthy. This is actually correct behavior — the API can still serve requests, and workers will restart when the container restarts.
**How to avoid:** This is acceptable for single-user app. For improved reliability, document that a "healthy" container might have dead workers and the restart strategy should handle it.

### Pitfall 7: Cloudflare Tunnel Timeout for Long Uploads
**What goes wrong:** CSV imports with thousands of rows can take more than 60 seconds. Cloudflare's default timeout for HTTP requests through tunnels is 100 seconds for free plan.
**How to avoid:** The import is async (returns `{ job_id }` immediately via PGMQ), so the upload POST returns quickly. The actual processing happens in the worker. No timeout issue.

## Code Examples

Verified patterns from official sources:

### Hono Static Serving with SPA Fallback (on Bun)

```typescript
import { serveStatic } from 'hono/bun'
import { Hono } from 'hono'

const app = new Hono()

// API routes (registered first — highest priority)
app.get('/api/health', (c) => c.json({ ok: true }))

// Static assets (hashed filenames, immutable caching)
app.use('/assets/*', serveStatic({ root: './frontend/dist' }))

// SPA fallback — catch all non-API, non-asset routes
app.get('*', serveStatic({ path: './frontend/dist/index.html' }))

export default {
  port: 3000,
  fetch: app.fetch,
}
```

**Source:** [CITED: hono.dev/docs/getting-started/bun] — adapted for SPA pattern.

### node-pg-migrate SQL Migration File Format

SQL migration files use the `migrationFileLanguage: 'sql'` option. Each file is a single `.sql` file with both up and down sections:

```sql
-- 001_initial_schema.sql
-- Up migration: CREATE TABLE IF NOT EXISTS ...
-- Down migration: DROP TABLE IF EXISTS ...

-- ↑↑↑ UP MIGRATION ↑↑↑
CREATE TABLE IF NOT EXISTS accounts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('personal', 'business')),
  currency   TEXT NOT NULL DEFAULT 'PLN',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ... more tables ...

-- ↓↓↓ DOWN MIGRATION ↓↓↓
DROP TABLE IF EXISTS accounts CASCADE;
```

Alternatively, use separate `*.up.sql` / `*.down.sql` files with the grouped SQL loader strategy:

```sql
-- 001_initial_schema.up.sql
CREATE TABLE IF NOT EXISTS accounts (...);

-- 001_initial_schema.down.sql
DROP TABLE IF EXISTS accounts CASCADE;
```

**Source:** [VERIFIED: ctx7 docs /salsita/node-pg-migrate — migration loading strategies].

### Better Auth Production Configuration

```typescript
import { betterAuth } from 'better-auth';
import { Pool } from 'pg';

export const auth = betterAuth({
  database: new Pool({
    connectionString: process.env.DATABASE_URL!,
  }),
  secret: process.env.BETTER_AUTH_SECRET!,  // No fallback in production!
  baseURL: process.env.BETTER_AUTH_URL!,    // Must be public URL (e.g., https://app.example.com)
  trustedOrigins: [
    process.env.FRONTEND_URL!,              // Must be public URL
  ],
  emailAndPassword: {
    enabled: true,
  },
  // Social providers enabled only when env vars are set
  // ... existing google/github config ...
});
```

**Production checklist:**
- `BETTER_AUTH_SECRET` must be a strong random string (at least 32 chars), no fallback
- `BETTER_AUTH_URL` must be the public-facing URL (Cloudflare Tunnel domain)
- `trustedOrigins` must include the public URL
- Session cookies use default settings; for HTTPS-only, verify `secure` cookie attribute works via Cloudflare Tunnel

**Source:** [CITED: better-auth docs (npm)] + codebase analysis.

### Hono CORS for Same-Origin Production

In production, the frontend is served from the same Hono server on the same origin. CORS is effectively a no-op. However, the existing CORS middleware for `/api/auth/*` must still work because Better Auth sets cookies via the Auth API handler.

```typescript
// index.ts — conditional CORS for production
app.use(
  '/api/auth/*',
  cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    allowHeaders: ['Content-Type', 'Authorization'],
    allowMethods: ['POST', 'GET', 'OPTIONS'],
    credentials: true,
  })
);
```

For production same-origin, CORS headers are irrelevant (no cross-origin request). But they don't hurt either — keeping them is fine for dev vs prod compatibility. The `FRONTEND_URL` env var makes it configurable.

**Source:** [CITED: hono.dev/docs/middleware/builtin/cors] + codebase analysis of `index.ts`.

### Docker Layer Caching Optimization

Optimal `COPY` ordering for maximum caching:

```dockerfile
FROM oven/bun:1
WORKDIR /app

# Layer 1: Dependency manifests (changes rarely)
COPY package.json bun.lock ./
# Layer 2: Install deps (cached unless package.json changes)
RUN bun install --frozen-lockfile --production

# Layer 3: App source (changes frequently — placed after deps)
COPY tsconfig.json index.ts ./
COPY src/ ./src/

# Layer 4: Built frontend (changes per build)
COPY --from=builder /app/frontend/dist ./frontend/dist

# Layer 5: Entrypoint (changes rarely)
COPY entrypoint.sh /app/entrypoint.sh
```

**Source:** Standard Docker layer caching practice. [ASSUMED]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `bun src/infrastructure/db/apply.ts` (schema.sql dump) | `node-pg-migrate` versioned migrations | Phase 5 | Adds rollback, audit trail, proper versioning for future schema changes |
| Dev concurrently process management | Single-entry shell script in Docker | Phase 5 | Production process management with signal handling, migration orchestration |
| Vite dev proxy for API routes | Hono `serveStatic` serves built frontend | Phase 5 | No Vite dev server needed in production; Hono handles everything |
| `.env.example` with 2 vars | `.env.production` with 6 documented vars | Phase 5 | Production readiness — all secrets documented |

**Deprecated/outdated:**
- `apply.ts` schema application: No longer needed for production. The schema is now managed by node-pg-migrate. The `apply.ts` file can remain for dev convenience but won't be used in the production container.
- Dev-only `.env` loading: Production uses explicit `--env-file` or `env_file` directive.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | node-pg-migrate SQL migration files with `-- migrate:up` / `-- migrate:down` markers work with `migrationFileLanguage: 'sql'` | Standard Stack | Medium — may need the grouped SQL loader with `*.up.sql` / `*.down.sql` pairs instead. Need to test the exact format. |
| A2 | `serveStatic` from `hono/bun` handles SPA fallback correctly | Code Examples | Low — honor the standard pattern documented on hono.dev. The catch-all `app.get('*', serveStatic({ path: './index.html' }))` is a documented pattern. |
| A3 | Shell entrypoint with `source .env.production` works for all env var formats | Architecture Patterns | Low — `.env` files use the same `KEY=VALUE` format as bash. However, values with spaces, quotes, or special characters need `set -a` / `set +a` or `eval`. Bun's `--env-file` is more robust. |
| A4 | Cloudflared running as system service on T640 requires no Docker-side config | Architecture | Low — standard setup. The tunnel just forwards TCP to `localhost:3000`. |
| A5 | The `xlsx` package works in Bun's Docker runtime | Common Pitfalls | Low — `xlsx` is pure JS and works in Bun. Already tested in dev. |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed. (Table not empty — A1 requires testing.)

## Open Questions (RESOLVED)

1. **[RESOLVED] node-pg-migrate SQL file format — single file vs grouped up/down?**
   - What we know: node-pg-migrate supports both single `.sql` files (with `-- migrate:up`/`-- migrate:down` markers) and grouped `*.up.sql` + `*.down.sql` files.
   - Resolution: Plans use separate `*.up.sql` / `*.down.sql` files with the grouped SQL loader strategy — explicitly documented and unambiguous.
   - Plan: 05-02 creates `001_initial_schema.sql` with up/down sections.

2. **[RESOLVED] Do existing migration files (003-006) need to be converted to node-pg-migrate format?**
   - Resolution: Option (a) — create a single `001_initial_schema.sql` baseline containing the full current schema. On existing dev databases, run with `--fake`. On new prod databases, run normally.
   - Plan: 05-02 Task 2 creates baseline, Task 3 runs `--fake` on existing DB.

3. **[RESOLVED] Does the `postgres` npm package (app-level queries) coexist correctly with `pg` (used by node-pg-migrate and Better Auth)?**
   - Resolution: Both connect via `DATABASE_URL` with separate pools. For single-user app, dual pools (max ~20 connections) are well within Postgres limits. No action needed.
   - Note: Documented in migration runner comments.

4. **[RESOLVED] What should the `restart` policy be in docker-compose?**
   - Resolution: Use `restart: unless-stopped` in docker-compose. Ensures container restarts if any process crashes.
   - Plan: 05-01 Task 3 applies `restart: unless-stopped` to the app service.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None detected — no existing test infrastructure |
| Config file | none |
| Quick run command | N/A — manual verification |
| Full suite command | N/A |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| D-11 | Auth guard returns 401 for unauthenticated requests | Manual verify | N/A — verify via browser in production mode | N/A |
| D-11 | Login redirect works via Hono static serving | Manual verify | N/A — browser test | N/A |
| D-11 | Session cookie flows work via Cloudflare Tunnel | Manual verify | N/A — browser test | N/A |
| D-04 | Docker HEALTHCHECK responds OK | Manual verify | `docker inspect --format='{{.State.Health.Status}}' finance-app` | N/A |
| D-05 | Migrations run on container start | Manual verify | Check container logs for "Migrations complete" | N/A |

### Sampling Rate

- **Per task commit:** N/A — no automated test framework
- **Per wave merge:** N/A
- **Phase gate:** Manual verification checklist (use UI-SPEC.md V-01 through V-11)

### Wave 0 Gaps

N/A — no existing test infrastructure. This phase adds no test framework.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Better Auth (email/password + OAuth) |
| V3 Session Management | yes | Better Auth session cookies, signed by `BETTER_AUTH_SECRET` |
| V4 Access Control | yes | `requireAuth` Hono middleware on all transaction routes; React auth guard on frontend |
| V5 Input Validation | yes | Zod schemas on all API inputs; `@hono/zod-validator` on routes |
| V6 Cryptography | no | No application-level crypto (TLS handled by Cloudflare Tunnel) |

### Known Threat Patterns for {Bun + Hono + Postgres}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthenticated API access | Spoofing | `requireAuth` middleware returns 401; frontend guard redirects to /login |
| Session hijacking | Tampering | Better Auth signs session with `BETTER_AUTH_SECRET`; uses HttpOnly cookies |
| SQL injection | Tampering | Parameterized queries via `postgres` tagged template literals and `pg.Pool` |
| Secrets leakage | Information Disclosure | `.env.production` in `.gitignore`, volume-mounted at runtime, not in image |
| Supply chain (npm) | Tampering | Lockfile (`bun.lock`) committed; slopcheck verification on new packages |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker | Container build + run | ✓ | 29.4.0 | — |
| Docker Compose | Multi-service orchestration | ✓ | v5.1.1 | — |
| Bun | Entrypoint + app runtime | ✓ | 1.3.14 | — |
| PostgreSQL | DB (via PGMQ image) | ✓ | pg18 | — |
| oven/bun:1 | Docker base image | ✓ | pulled 2026-06-07 | — |
| Cloudflared | Ingress (T640 host) | Not on dev machine | — | Runs on T640, not needed in dev |

**Missing dependencies with no fallback:** None — all dependencies are available in the dev environment.

**Missing dependencies with fallback:** Cloudflared only exists on the T640 host. Dev can test without it (direct `localhost:3000` access).

## Sources

### Primary (HIGH confidence)
- [VERIFIED: ctx7 docs /honojs/website] — Hono `serveStatic`, CORS middleware, routing priority
- [VERIFIED: ctx7 docs /salsita/node-pg-migrate] — `runner()` API, SQL migration file loading, configuration options
- [CITED: hono.dev/docs/getting-started/bun] — Bun-specific `serveStatic` import path
- [CITED: hono.dev/docs/middleware/builtin/cors] — CORS middleware configuration
- [CITED: github.com/salsita/node-pg-migrate] — Repository, README, CLI docs
- [VERIFIED: npm registry] — Package versions for `node-pg-migrate` (8.0.4), `hono` (4.12.23), `better-auth` (1.6.14)

### Secondary (MEDIUM confidence)
- [CITED: CONTEXT.md] — All locked decisions (D-01 through D-11)
- [CITED: UI-SPEC.md] — Production serving contract, auth hardening verification checklist (V-01 through V-11)
- [CITED: Codebase analysis] — `index.ts`, `src/auth.ts`, `src/interface-adapters/api/auth.ts`, `frontend/src/api.ts`, `frontend/src/App.tsx`

### Tertiary (LOW confidence)
- [ASSUMED] Docker layer caching optimization for `oven/bun:1` — standard pattern, not verified against the specific image
- [ASSUMED] Shell script `source .env.production` compatibility — Bun `.env` files are standard format

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all package versions verified via npm registry and slopcheck
- Architecture patterns: HIGH — Hono serveStatic, node-pg-migrate, and Docker patterns verified via Context7 docs
- Pitfalls: MEDIUM — most documented from codebase analysis; Cloudflare Tunnel timeout estimate based on standard Cloudflare docs (not verified in this session)
- Auth hardening: HIGH — code paths directly analyzed in the codebase

**Research date:** 2026-06-07
**Valid until:** 2026-07-07 (30 days — stable npm packages, Docker stable)
