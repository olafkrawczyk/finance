---
title: Deployment architecture decisions
date: 2026-06-07
context: Socratic exploration of deployment options
---

## Architecture

- **Host:** HP T640 running Ubuntu (homelab)
- **Ingress:** Cloudflare Tunnel (running as system service on the host)
- **Domain:** Personal domain (already purchased)

## Container setup

- **App container:** Single container running Bun with 3 processes:
  - Hono API server
  - AI insights worker
  - Frontend static file serving (Hono serves Vite-built `dist/`)
- **Postgres container:** Existing `ghcr.io/pgmq/pg18-pgmq` image with PGMQ extension

## Rationale

- Single app container keeps deployment simple for a single-user app
- No need for Nginx or separate frontend server — Hono handles static serving
- Postgres already containerized with PGMQ; no changes needed there
- Cloudflared as system service avoids containerizing tunnel management

## Open questions

- Secrets management approach (`.env` vs Docker secrets vs other)
- Migration strategy for DB schema on deploy
- Rollback approach if a deploy breaks
