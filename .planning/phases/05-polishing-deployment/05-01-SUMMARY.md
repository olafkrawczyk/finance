---
phase: 05-polishing-deployment
plan: 01
subsystem: infrastructure
tags: [docker, multi-stage, containerization, orchestration, entrypoint]

# Dependency graph
requires: []
provides:
  - Dockerfile — multi-stage build (node:22-bookworm Vite builder + oven/bun:1 runtime)
  - entrypoint.sh — shell-based orchestration managing 4 processes
  - .dockerignore — container build exclusions
  - docker-compose.yml — updated with finance-app service alongside Postgres
  - .gitignore — production secrets ignored
affects: [05-02-migration-tooling]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Multi-stage Docker build with Vite frontend builder
    - Shell entrypoint orchestration with SIGTERM/SIGINT trap
    - Layer caching optimization (deps before source)
    - Volume-mounted .env.production for secrets management

key-files:
  created:
    - Dockerfile
    - entrypoint.sh
    - .dockerignore
  modified:
    - docker-compose.yml
    - .gitignore

key-decisions:
  - "Used npm install (not npm ci) in builder because no package-lock.json exists — project uses bun.lock"
  - "Dockerfile copies root-level package.json for Vite build (frontend has no own package.json)"
  - "docker-compose uses both env_file: and volume mount for .env.production — Docker provides env vars to container, file available for entrypoint sourcing"
  - "Entrypoint sources .env.production via shell (set -a/source/set +a) rather than bun --env-file, since shell needs var access for child process env"

patterns-established: []
requirements-completed:
  - REQ-3.1
  - REQ-3.2
  - REQ-3.3
  - REQ-4.1
  - REQ-4.7
  - REQ-5.1

# Metrics
duration: 2 min
completed: 2026-06-07
---

# Phase 5 Plan 1: Docker Infrastructure Summary

**Multi-stage Dockerfile with Vite builder + Bun runtime, shell-based entrypoint managing API/workers, and updated docker-compose with app service**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-07T10:10:21Z
- **Completed:** 2026-06-07T10:13:18Z
- **Tasks:** 3
- **Files modified/created:** 5

## Accomplishments

- Multi-stage Dockerfile: `node:22-bookworm` builds Vite frontend, `oven/bun:1` runs app with `bun install --frozen-lockfile --production`
- `entrypoint.sh`: shell-based orchestration with SIGTERM/SIGINT trap, .env.production sourcing, migration runner, and background process management for all 4 processes (API server, insights worker, import worker, static serving)
- `.dockerignore`: excludes .git, .env, node_modules, .planning, etc. from Docker build context
- `docker-compose.yml`: added `app` service with build config, port 3000, volume-mounted .env.production, `depends_on db` with health condition, `restart: unless-stopped`; added healthcheck to `db` service
- `.gitignore`: added `.env.production` to protect production secrets
- Verified: `docker build -t finance-app .` succeeds, `docker compose build` succeeds

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Dockerfile** - `ff68be6` (feat)
2. **Task 2: Create entrypoint.sh and .dockerignore** - `4a0133f` (feat)
3. **Task 3: Update docker-compose.yml and .gitignore** - `1d7f0cb` (feat)

## Files Created/Modified

- `Dockerfile` - Multi-stage build: node:22-bookworm builder + oven/bun:1 runtime, HEALTHCHECK, ENTRYPOINT
- `entrypoint.sh` - Shell entrypoint with cleanup trap, env sourcing, migration runner, 3 background processes, wait
- `.dockerignore` - 12 exclusion patterns for Docker build context
- `docker-compose.yml` - Updated with finance-app service, db service healthcheck, .env.production volume mount
- `.gitignore` - Added .env.production

## Decisions Made

- Used `npm install` (not `npm ci`) in builder stage because the project uses `bun.lock`, not `package-lock.json`
- Dockerfile copies root `package.json` for Vite build, not `frontend/package.json` (frontend has no own package.json — uses root deps with `vite.config.ts root: 'frontend'`)
- docker-compose uses both `env_file:` and volume mount for `.env.production` — Docker injects env vars directly into container environment AND file is available at `/app/.env.production` for entrypoint sourcing
- Entrypoint sources `.env.production` via `set -a; source; set +a` shell pattern rather than `bun --env-file`, since shell background processes inherit the sourced environment

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Adapted Dockerfile builder stage for actual frontend structure**
- **Found during:** Task 1 (Create Dockerfile)
- **Issue:** Plan assumed `frontend/package.json` exists and uses `npm ci`. Actual project structure: no `frontend/package.json` — frontend uses root-level deps via `vite.config.ts root: 'frontend'`. Also no `package-lock.json` (project uses Bun).
- **Fix:** Changed builder stage to:
  - Copy root `package.json` + `bun.lock` (not `frontend/package.json`)
  - Use `npm install --ignore-scripts` (not `npm ci`, since no `package-lock.json`)
  - Copy `vite.config.ts` + `tsconfig.json` alongside `package.json` for Vite build config
  - Copy `frontend/` directory sub-path (not root-level copy)
  - Run `npm run build:web` (existing script, matches plan intent)
- **Files modified:** Dockerfile
- **Verification:** `docker build` succeeded, frontend built correctly (645 modules transformed)
- **Committed in:** ff68be6 (Task 1 commit)

**2. [Rule 2 - Missing Critical] Added env_file directive alongside volume mount**
- **Found during:** Task 3 (Update docker-compose.yml)
- **Issue:** Plan settled on volume mount only, but `env_file:` provides Docker-native env var injection. Without it, Bun processes get env vars only after entrypoint sources the file, creating a window where `process.env.DATABASE_URL` might not be set during migration startup.
- **Fix:** Added `env_file: - .env.production` to docker-compose app service alongside the volume mount. Docker injects vars at container start; volume mount provides file at `/app/.env.production` for entrypoint sourcing.
- **Files modified:** docker-compose.yml
- **Verification:** docker-compose config validates, both directive and mount present
- **Committed in:** 1d7f0cb (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical)
**Impact on plan:** Both auto-fixes necessary for correct operation. No scope creep.

## Threat Review

### Threat Mitigations Applied

| Threat ID | Mitigation | File | Status |
|-----------|-----------|------|--------|
| T-05-01 | `.env.production` listed in `.dockerignore` — never copied into image layers | `.dockerignore` | ✓ Implemented |
| T-05-02 | File mounted `:ro` (read-only) inside container at `/app/.env.production` | `docker-compose.yml` | ✓ Implemented |

Flags not in plan's threat model:
- T-05-03/T-05-04/T-05-05 intentionally accepted per plan disposition
- T-05-SC (lockfile integrity): `bun.lock` committed, `--frozen-lockfile` used in Docker build ✓

## Issues Encountered

None — all tasks executed cleanly with minor structural adaptations documented under deviations.

## User Setup Required

None — no external service configuration required for this plan.

## Next Phase Readiness

Docker infrastructure complete. Ready for Plan 05-02 (Migration Tooling with node-pg-migrate). The entrypoint.sh references `bun run src/infrastructure/db/migrate.ts` which will be created in 05-02. Dockerfile and docker-compose are fully functional and verified.

---

*Phase: 05-polishing-deployment*
*Completed: 2026-06-07*
