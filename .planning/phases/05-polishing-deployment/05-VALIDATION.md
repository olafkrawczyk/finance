---
phase: 5
slug: polishing-deployment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-07
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest |
| **Config file** | `package.json` (scripts section) |
| **Quick run command** | `bun test` |
| **Full suite command** | `bun test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bun test`
- **After every plan wave:** Run `bun test` + `docker compose build`
- **Before `/gsd-verify-work`:** Full suite must be green; Docker image must build
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | REQ-3.3 | T-05-01 / T-05-03 | Dockerfile has no secrets in build layers | build check | `docker build -t finance-app .` | N/A | ⬜ pending |
| 05-01-02 | 01 | 1 | REQ-3.3 | T-05-02 | Entrypoint traps SIGTERM/SIGINT | review | `grep -q 'trap' entrypoint.sh` | `entrypoint.sh` | ⬜ pending |
| 05-01-03 | 01 | 1 | REQ-3.1 | T-05-01 | Compose starts, healthcheck passes | integration | `docker compose up -d && curl -f http://localhost:3000/health` | `docker-compose.yml` | ⬜ pending |
| 05-02-01 | 02 | 1 | REQ-1.1 | — | Migrations install, runner compiles | unit | `bun run src/infrastructure/db/migrate.ts --help` | `migrate.ts` | ⬜ pending |
| 05-02-02 | 02 | 1 | REQ-1.1 | — | Migration SQL parses correctly | unit | `bun test --test-name-pattern=migration` | `001_initial_schema.sql` | ⬜ pending |
| 05-02-03 | 02 | 1 | REQ-1.2 | — | Fake-baseline against prod DB | manual | `bun run src/infrastructure/db/migrate.ts up --fake` | N/A | ⬜ pending |
| 05-03-01 | 03 | 1 | REQ-3.3 | T-05-01 | serveStatic serves frontend | integration | `curl -f http://localhost:3000/` | `index.ts` | ⬜ pending |
| 05-03-02 | 03 | 1 | REQ-1.1 | T-05-01 | .env.example lists all production vars | review | `grep -c 'DATABASE_URL\|PORT\|BETTER_AUTH_SECRET\|BETTER_AUTH_URL\|OPENROUTER_API_KEY\|FRONTEND_URL' .env.example` | `.env.example` | ⬜ pending |
| 05-03-03 | 03 | 1 | REQ-1.1 | — | DEPLOYMENT.md has deploy steps | review | `grep -q '## Deployment' DEPLOYMENT.md` | `DEPLOYMENT.md` | ⬜ pending |
| 05-04-01 | 04 | 2 | REQ-5.1 | T-05-04 | Docker builds, container healthy, SPA fallback works | manual | `docker compose up -d && curl -f http://localhost:3000/month/2026-01` | N/A | ⬜ pending |
| 05-04-02 | 04 | 2 | REQ-5.1 | T-05-04 / T-05-05 | Auth flows V-01 through V-11 all pass | manual | Per checklist in plan | N/A | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test framework needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Auth hardening: auth guard, login, logout, 401, Google OAuth, SPA routing | REQ-5.1 | Requires browser interaction and visual verification | Follow V-01 through V-11 checklist in 05-04-PLAN.md |
| Docker compose up — full lifecycle | REQ-3.1 / REQ-3.3 | Requires Docker daemon and network access | `docker compose up -d && docker compose ps && docker compose logs` |
| Migration fake-baseline against production DB | REQ-1.2 | One-time operation on existing production data | `docker compose run --rm app bun run src/infrastructure/db/migrate.ts up --fake` |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
