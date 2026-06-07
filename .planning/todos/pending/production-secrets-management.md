---
title: Set up production secrets management
date: 2026-06-07
priority: medium
---

## Production secrets management

- [ ] Decide on approach: `.env` file on the T640, Docker secrets, or environment variables passed to the container
- [ ] Document required secrets:
  - `DATABASE_URL` (pointing to the Postgres container)
  - `BETTER_AUTH_SECRET`
  - `BETTER_AUTH_URL` (the public domain)
  - `OPENROUTER_API_KEY`
  - Any other env vars from `.env.example`
- [ ] Create a production `.env.production` (or equivalent) on the T640 host

**Note:** Secrets are currently not managed for production — this is needed before the app can run outside of dev.
