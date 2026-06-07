# Milestones

## v1.0 MVP (Shipped: 2026-06-07)

**Phases completed:** 11 phases, 37 plans, 88 tasks

**Key accomplishments:**

- Bun runtime config, Postgres+PGMQ container deployment, idempotent database migrations, transaction immutability triggers, and queue client test suites
- TypeScript ledger entities, Zod v4 validation schemas, atomic transaction enqueuing, transfer-excluding monthly summaries, and opening balance CRUD
- Bun + Hono HTTP server implementation, standard-enveloped API routes, opening balance CRUD endpoints, and HTTP integration tests
- Implemented the `PATCH /transactions/:id/category` Hono endpoint, updated the DB immutability trigger to allow NULL-to-non-null category assignment, and successfully ran the migration on PostgreSQL.
- Installed charting libraries, fixed Vite dev server proxies for transactions and balances, extended the API client with all data-fetching functions, and implemented a pure client-side Ordinary Least Squares linear regression utility.
- Created the four shared presentation components (`ZbiorczyTable`, `TransactionTable`, `MonthSidebar`, `CategoryDropdown`) in `frontend/src/components/`, matching exact design specifications, dark theme standards, and mobile horizontal scrolling behavior.
- Created the four Recharts-based chart components (`BalanceChart`, `ComboChart`, `SavingsChart`, `SavingsLogChart`) in `frontend/src/charts/` matching user constraints, responsive sizing requirements, and click-based navigation to monthly drill-down views.
- Created the three main data-display pages (`DashboardPage`, `ZbiorczyPage`, `MonthlyPage`) in `frontend/src/pages/`, connecting them to the API client, implementing loading/error handling states, and composing our custom presentation components.
- Created two interactive action-oriented pages: `CategorizePage` (for bulk category assignment) and `AddTransactionPage` (for manual transaction entry).
- Wired all Phase 3 pages into App.tsx router with 5-button nav, full-width layout, D-10 post-import categorize flow, and font-extrabold → font-semibold typography alignment.
- Created the database migration, schema definitions, TypeScript entities, Zod validation schemas, and unit tests for the AI Insights and Forecasting system.
- Implemented the PGMQ background worker process, OpenRouter narrative insights (Claude) and mathematical forecasting (DeepSeek-R1) clients, data privacy sanitizers, deduplication, and integration tests.
- Created the Hono API routes for insights listing, dismissal, dashboard data, forecast data, and manual triggers, mounted them on the index server, and validated them with comprehensive integration tests.
- Integrated the AI Insights widget and the dual prediction lines into the frontend dashboard, along with the necessary API client functions and helper utilities.
- Built the dedicated /insights page, type filtering tabs, confirmation dialogs, and completed the routing and navigation integration.
- Removed transaction immutability: schema migration (triggers, updated_at), three new API endpoints (GET/PUT/DELETE /transactions/:id), use-case functions, and updated test suite
- API client functions (getTransaction, updateTransaction, deleteTransaction), TransactionTable hover-reveal action buttons, AddTransactionPage edit mode with prefill, MonthlyPage edit/delete handlers with confirmation dialog, and /transactions/:id/edit route
- Schema migration, Zod validators, Hono API routes, and test suite for manual asset management (investments, cash, bonds, silver)
- Assets management CRUD page (AssetsPage), "Aktywa" navigation, Total Net Value and Current Month dashboard tiles, and pl-PL locale number formatting on all Recharts charts
- Better Auth React client instance and tabbed login/signup page with email/password forms and Google OAuth button
- Session-aware auth guard in App.tsx with three render modes, logout button with user email in header, and centralized apiFetch wrapper redirecting to /login on 401
- 1. [Rule 3 - Blocking issue] `xlsx` package not installed
- 1. [Rule 1 - Bug] Corrected migration upload endpoint path
- Input validation guard, retry-safe temp file cleanup, atomic outer transaction, and empty-workbook detection closing all four UAT-identified gaps in the Excel migration worker
- getMonthlySummary() now returns monthly summaries newest-month-first while maintaining correct chronological running balance calculations
- Updated error state to English per UI-SPEC copywriting contract, verified production build compiles with zero errors.
- Dashboard regression fix — re-reverse summary data to chronological order; immutability improvement with .toReversed()
- Always-visible filter panel, deterministic sort tiebreaker, Polish locale, "Nieskategoryzowane" uncategorized filter option, and 12 unit tests for extracted pure filter functions
- Multi-stage Dockerfile with Vite builder + Bun runtime, shell-based entrypoint managing API/workers, and updated docker-compose with app service
- node-pg-migrate integrated with programmatic runner, 001_initial_schema.sql baseline containing full current 11-table schema, and --fake applied against dev database marking all migrations as applied
- Hono serveStatic for Vite-built frontend, comprehensive .env.example with 11 vars, and DEPLOYMENT.md with full production setup guide
- Complete

---
