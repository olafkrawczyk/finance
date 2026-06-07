# Phase 5: Polishing & Deployment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 5-polishing-deployment
**Areas discussed:** Dockerfile strategy, DB migration on deploy, Secrets management, E2E testing & security scope

---

## Dockerfile Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Single-entry orchestration | A Bun script that spawns all 3 processes concurrently | ✓ (with modification) |
| Separate entrypoints | Process manager like supervisord inside container | |
| Multi-container | 3 separate containers in docker-compose | |
| Multi-stage build | Stage 1: Node builds frontend, Stage 2: Bun runtime | ✓ |
| Single-stage build | Use Bun image throughout | |
| oven/bun:1 (slim) | Official slim image | |
| oven/bun:1 (alpine) | Alpine-based | |
| oven/bun:1 (full) | Full Bun image with build tooling | ✓ |

**User's choice:** Single-entry orchestration but include both workers (insights + import). Multi-stage build. Full Bun image.
**Notes:** User clarified there are 2 workers (import-worker + insights-worker), so 4 total processes to manage.

---

## DB Migration on Deploy

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-run on container start | Entrypoint runs schema.sql | |
| Manual SQL apply | SSH into host, run SQL manually | |
| Use a migration tool | Versioned, rollback-able migrations | ✓ |
| dbmate | Go-based single binary | |
| node-pg-migrate | Node/Bun native, JS-based | ✓ |
| golang-migrate | Go tool with Postgres support | |
| Rollback + redeploy | Down migrations, then deploy previous version | ✓ |
| Restore from backup | pg_dump restore | |
| Manual fix-forward | Write new migration, deploy forward | |
| Entrypoint step | Migrate before app starts, inside container | ✓ |
| Init container | Separate docker-compose migrate service | |
| Manual via SSH | SSH in after pushing | |

**User's choice:** node-pg-migrate with down migrations, run as container entrypoint step.
**Notes:** The user was clear about wanting proper migration tooling over manual SQL.

---

## Secrets Management

| Option | Description | Selected |
|--------|-------------|----------|
| .env on host + volume mount | .env.production on T640, mounted into container | ✓ |
| Docker --env-file | Pass .env via docker run flag | |
| Docker secrets (Swarm) | docker secret create | |
| Add all known secrets | Document full env var list | ✓ |
| Keep minimal | Only what's strictly needed | |
| .env.production on host | Clear naming convention | ✓ |
| .env in app directory | Plain .env in deployment dir | |
| Bun --env-file flag | Explicit --env-file flag in entrypoint | ✓ |
| APP_ENV variable | Load .env.${APP_ENV} | |
| Bun auto-detection | Bun loads .env by default | |

**User's choice:** .env.production on T640 host, volume-mounted, with all known secrets documented. Entrypoint uses `bun --env-file=.env.production`.

---

## E2E Testing & Security Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Critical flows only | Manual test checklist | |
| Playwright smoke tests | Automated critical flows | |
| Full Playwright suite | Every page and interaction | |
| Auth hardening only | Verify guard, sessions, 401 | ✓ |
| Plus secrets audit | Verify no secrets in git, file perms | |
| Full security review | npm audit, OWASP, rate limiting | |

**User's choice:** Auth hardening only. E2E testing descoped to its own phase.

---

## Deferred Ideas

- **E2E testing (Playwright):** Automated browser tests for all pages — deferred to its own phase.
- **Full security review:** npm audit, OWASP top-10, rate limiting — descoped.
