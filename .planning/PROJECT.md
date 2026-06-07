# Project Context: Financial Planning App

## Overview
A comprehensive financial planning application with both backend and frontend components, focusing on tracking, budgeting, goal planning, and AI-driven insights.

## Tech Stack
- **Backend:** Bun, Hono, Zod
- **Frontend:** React + Tailwind CSS
- **Database:** Postgres (locally hosted)
- **Queue System:** `pgmq` (Postgres extension)
- **AI Integration:** OpenRouter API
- **Auth:** Better Auth (email/password + Google/GitHub OAuth)

## Current State (v1.0 — Shipped 2026-06-07)

Shipped with 10 phases, 37 plans across a full financial tracking application:

### Validated
- ✓ Immutable ledger with single-entry accounting — v1.0
- ✓ Bank CSV import via LLM (ING + IPKO formats) — v1.0
- ✓ Excel budget workbook migration — v1.0
- ✓ Monthly summary views (Zbiorczy, dashboard charts, drill-down) — v1.0
- ✓ AI narrative insights + spending forecasts — v1.0
- ✓ Category assignment + transaction CRUD — v1.0
- ✓ Asset tracking (Total Net Value dashboard) — v1.0
- ✓ Transaction filters (search, type, category, sort) — v1.0
- ✓ User authentication (email/password + OAuth) — v1.0
- ✓ Docker deployment with automated DB migrations — v1.0

### Active (for next milestone)
- [ ] Multi-tenant data isolation (user-scoped categories, accounts, transactions)

### Out of Scope
- Mobile app — web-first approach
- Recurring transactions — manual entry only
- Budget alerts — future milestone

## Infrastructure
- Locally hosted Postgres with PGMQ.
- Docker Compose deployment.
- Background workers for import + insights.

---

*Last updated: 2026-06-07 after v1.0 milestone*
