---
title: Dockerize the app for homelab deployment
date: 2026-06-07
priority: high
---

## Dockerize the app

- [ ] Create `Dockerfile` for the Bun app (multi-stage: build frontend, then combine API + static serving)
- [ ] Configure Hono to serve Vite-built `dist/` static files
- [ ] Update `docker-compose.yml` to include the app service alongside Postgres
- [ ] Ensure all 3 processes (API server, insights worker, frontend static serving) run inside the container
- [ ] Test locally with `docker compose up` before deploying to the T640

**Context:** Deploying to HP T640 homelab. Cloudflare Tunnel (system service) routes traffic to the container's exposed port.
