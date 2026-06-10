# Deployment Guide — FinanceFlow

## Architecture Overview

FinanceFlow runs on a single HP T640 Ubuntu homelab with the following architecture:

- **Host:** HP T640 (Ubuntu)
- **Ingress:** Cloudflare Tunnel for HTTPS termination
- **Container Stack:** Docker Compose with 2 services
  - `finance-postgres` — Postgres 18 with PGMQ extension
  - `finance-app` — Bun/Hono application serving both API and frontend
- **Static Serving:** Hono's `serveStatic` middleware serves the Vite-built frontend

```
Browser ──HTTPS──→ Cloudflare ──TCP──→ Cloudflared (host) ──HTTP──→ Docker app:3000
```

## Prerequisites

- **Docker** 29.4+
- **Docker Compose** v5.1+
- **Git** access to the repository
- **Cloudflared** installed on the T640 host (for production HTTPS ingress)
- **Domain name** pointed to Cloudflare (DNS proxied)

## Environment Setup (First Time)

1. Clone the repository on the T640 host:
   ```bash
   git clone <repository-url> /opt/finance
   cd /opt/finance
   ```

2. Create `.env.production` from the template:
   ```bash
   cp .env.example .env.production
   ```

3. Fill in all values in `.env.production`:

   | Variable | Required | How to Get It |
   |----------|----------|---------------|
   | `DATABASE_URL` | Yes | Connection string to your Postgres instance. For Docker network: `postgres://postgres:postgres@db:5432/finance` |
   | `BETTER_AUTH_SECRET` | Yes | Run `openssl rand -hex 32` — use a strong random string |
   | `BETTER_AUTH_URL` | Yes | Your public domain, e.g. `https://finance.yourdomain.com` |
   | `FRONTEND_URL` | Yes | Same as `BETTER_AUTH_URL` for same-origin deployment |
   | `TRUSTED_ORIGINS` | Yes | Same as `BETTER_AUTH_URL` |
   | `OPENROUTER_API_KEY` | Yes | From [OpenRouter dashboard](https://openrouter.ai/keys) |
   | Google/GitHub OAuth | No | Optional — see OAuth provider sections in `.env.example` |

   > **Important:** `BETTER_AUTH_URL`, `FRONTEND_URL`, and `TRUSTED_ORIGINS` must all match your public domain (e.g., `https://finance.yourdomain.com`). Session cookies are scoped to this domain. If these values don't match the browser-visible URL, authentication will fail.

## First Deployment

1. Ensure the Postgres container is running:
   ```bash
   docker compose up -d db
   ```

2. Wait for Postgres to be healthy:
   ```bash
   docker ps  # Look for "healthy" status on finance-postgres
   ```

3. Build and start the app:
   ```bash
   docker compose up -d app
   ```
   This will:
   - Build the Vite frontend in a `node:22-bookworm` build stage
   - Copy built artifacts into the `oven/bun:1` runtime image
   - Run database migrations via the entrypoint
   - Start the API server, insights worker, and import worker

4. Check container logs:
   ```bash
   docker compose logs app
   ```

5. Verify health:
   ```bash
   curl http://localhost:3000/health
   ```

## Database Migrations

Migrations run automatically on container start via the entrypoint script. The system uses `node-pg-migrate` for versioned, rollback-able migrations.

### First Run on Existing Database

If the database already has the current schema (e.g., migrated from development), the baseline migration must be faked to avoid conflicts:

```bash
docker compose exec app bun run db:migrate:fake
```

This marks migration `001` as applied without running it. Subsequent migrations will apply normally.

### Normal Migration Flow

For future schema changes:

1. Create a new SQL migration file in `src/infrastructure/db/migrations/`:
   - `002_add_column.sql` with `-- migrate:up` and `-- migrate:down` sections
2. Deploy the updated code — the entrypoint runs migrations automatically
3. Verify: `docker compose logs app | grep migrate`

### Rollback

To roll back the last migration:

```bash
docker compose exec app bun run db:migrate:down
```

To roll back to a specific version:

```bash
docker compose exec app bun run db:migrate:down --to 001
```

## Updating

1. Pull the latest code:
   ```bash
   git pull
   ```

2. Rebuild and restart the app:
   ```bash
   docker compose up -d --build app
   ```

3. Follow the logs:
   ```bash
   docker compose logs -f app
   ```

4. Verify health:
   ```bash
   curl http://localhost:3000/health
   ```

## Rollback

If a deployment causes issues:

1. Run the down migration:
   ```bash
   docker compose exec app bun run db:migrate:down
   ```

2. Deploy the previous version:
   ```bash
   git checkout <previous-tag>
   docker compose up -d --build app
   ```

3. Verify:
   ```bash
   curl http://localhost:3000/health
   ```

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | — | Postgres connection string (e.g., `postgres://user:pass@host:5432/finance`) |
| `PORT` | No | `3000` | App server port |
| `NODE_ENV` | No | — | Set to `production` in Docker Compose |
| `BETTER_AUTH_SECRET` | Yes | — | Strong random string, at least 32 characters. Generate with `openssl rand -hex 32` |
| `BETTER_AUTH_URL` | Yes | — | Public URL of the app (must match browser-visible URL, e.g., `https://finance.yourdomain.com`) |
| `FRONTEND_URL` | Yes | — | Frontend URL (same as `BETTER_AUTH_URL` for same-origin deployment) |
| `TRUSTED_ORIGINS` | No | `http://localhost:5173` | Comma-separated list of trusted CORS origins |
| `OPENROUTER_API_KEY` | Yes | — | OpenRouter API key for AI-powered insights |
| `GOOGLE_CLIENT_ID` | No | — | Google OAuth client ID (from Google Cloud Console) |
| `GOOGLE_CLIENT_SECRET` | No | — | Google OAuth client secret |
| `GITHUB_CLIENT_ID` | No | — | GitHub OAuth client ID (from GitHub Developer Settings) |
| `GITHUB_CLIENT_SECRET` | No | — | GitHub OAuth client secret |

## Secret Management

- `.env.production` is stored on the T640 host filesystem (outside the repo)
- Volume-mounted into the container at `/app/.env.production` (read-only)
- The entrypoint script loads the env file before starting processes
- The file is listed in `.gitignore` and `.dockerignore` to prevent accidental commits
- Never commit secrets to the repository

## Container Management

- **Entrypoint** manages 4 processes:
  1. API server (Hono, serves both API and static frontend)
  2. Insights worker (AI-powered financial insights)
  3. Import worker (CSV/Excel transaction import)
- **HEALTHCHECK** hits `/health` every 30 seconds with 3 retries and 5s timeout
- **Restart policy:** `unless-stopped` — container restarts automatically after crashes or host reboot
- **Fail-fast:** The container exits if migrations fail, preventing a schema-mismatched app from running
- **Logs:** View all process logs with `docker compose logs -f app`

## Ingress (Cloudflare Tunnel)

Cloudflared runs as a systemd service on the T640 host, providing HTTPS termination and tunneling.

### Quick Start (Ad-Hoc Tunnel)

```bash
cloudflared tunnel --url http://localhost:3000
```

### Permanent Setup

1. Install cloudflared on the T640 host:
   ```bash
   # Debian/Ubuntu
   sudo apt install cloudflared
   ```

2. Authenticate and create a named tunnel:
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create finance-app
   ```

3. Configure the tunnel in `~/.cloudflared/config.yml`:
   ```yaml
   tunnel: <tunnel-uuid>
   credentials-file: /home/ubuntu/.cloudflared/<tunnel-uuid>.json
   ingress:
     - hostname: finance.yourdomain.com
       service: http://localhost:3000
     - service: http_status:404
   ```

4. Configure DNS:
   ```bash
   cloudflared tunnel route dns <tunnel-uuid> finance.yourdomain.com
   ```

5. Install as a system service:
   ```bash
   sudo cloudflared service install
   sudo systemctl start cloudflared
   sudo systemctl enable cloudflared
   ```

6. Verify:
   ```bash
   curl https://finance.yourdomain.com/health
   ```

Reference: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/

### Adding a New Hostname to an Existing Tunnel

If cloudflared is already installed as a system service, **edit `/etc/cloudflared/config.yml`** — not `~/.cloudflared/config.yml`. The systemd service starts with `--config /etc/cloudflared/config.yml` and ignores the user-level file.

```bash
sudo nano /etc/cloudflared/config.yml   # add ingress rule here
cloudflared tunnel route dns <tunnel-name> <new-hostname>
sudo systemctl restart cloudflared
```

## Troubleshooting

### Migration fails: `relation "X" does not exist`

**Symptom:** The app container exits with a migration error referencing a table that should have been created by an earlier migration.

**Cause:** node-pg-migrate SQL files require `-- Up Migration` / `-- Down Migration` as section separators (case-insensitive, matches `--[\\s-]*up\\s+migration`). Custom comment styles (e.g. `-- ↑↑↑ UP MIGRATION ↑↑↑`) are not recognised — the entire file including the DOWN `DROP` statements runs as the UP migration, dropping all tables immediately after creating them.

**Fix:** Use the standard markers in all SQL migration files:
```sql
-- Up Migration
... CREATE statements ...

-- Down Migration
... DROP statements ...
```

### Migration fails: `Not run migration NNN is preceding already run migration MMM`

**Symptom:** After adding a new migration file, the app exits with an ordering error.

**Cause:** node-pg-migrate enforces strict ordering — you cannot insert a migration with a number lower than the highest already-applied migration.

**Fix:** Always number new migrations higher than the last existing file. If migrations 001–006 are applied, the next must be 007 or higher.

### Workers fail: `schema "pgmq" does not exist`

**Symptom:** The API server starts but the insights and import workers crash immediately.

**Cause:** The PGMQ extension (`CREATE EXTENSION pgmq`) was never part of the migration history — development used `apply.ts` to set it up directly. A fresh production database has no `pgmq` schema.

**Fix:** Ensure migration `007_setup_pgmq.sql` exists (already committed). It creates the extension and initialises the `analysis_queue` and `import_queue`. If it somehow gets skipped, run manually:
```bash
docker compose exec app bun run db:migrate
```

### App loads but has no styles (blank/unstyled page)

**Symptom:** The page loads with correct HTML but no CSS styling; the network tab shows the CSS file returning 200 but `@tailwind utilities;` is present literally in the output.

**Cause:** `postcss.config.js` was not copied into the Docker builder stage, so Vite skipped the `@tailwindcss/postcss` plugin and left the `@tailwind utilities;` directive uncompiled.

**Fix:** The Dockerfile builder stage must include `postcss.config.js`:
```dockerfile
COPY vite.config.ts tsconfig.json postcss.config.js ./
```
This is already present in the current Dockerfile. If styles break again after adding a new build-config file, check that it is copied here.

### Database reset (wipe all data)

To start completely fresh (destroys all data):
```bash
docker compose down -v          # stops containers and removes pgdata volume
docker compose up -d db         # wait for healthy
docker compose up -d app        # migrations run automatically
```

## Development vs. Production

| Aspect | Development | Production |
|--------|-------------|------------|
| **Frontend** | Vite dev server (port 5173) | Hono `serveStatic` from `frontend/dist/` |
| **API proxy** | Vite proxy to `localhost:3000` | Same origin (no proxy needed) |
| **Workers** | Via `concurrently` or manually | Entrypoint manages both workers |
| **Database** | Local Docker Postgres | Same Docker Compose `db` service |
| **Migrations** | Manual (`bun run db:migrate`) | Auto on container start via entrypoint |
| **Environment** | `.env` file (dev values) | `.env.production` volume-mounted |
| **HTTPS** | None (plain HTTP) | Cloudflare Tunnel (TLS termination) |
| **Restart** | Manual | `unless-stopped` Docker policy |
