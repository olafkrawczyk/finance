# Roadmap: Financial Planning App

## Phase 1: Foundation (Core Ledger & DB)
**Goal:** Establish the immutable ledger and database schema.
**Plans:** 3 plans

Plans:
- [ ] 01-01-PLAN.md — Environment & Project Initialization (Walking Skeleton)
- [ ] 01-02-PLAN.md — Ledger Schema & Database Logic
- [ ] 01-03-PLAN.md — Ledger Core API

## Phase 2: Ingestion & Auth
**Goal:** Implement user authentication and background data processing.

- [ ] Integrate Better Auth for OAuth/SSO (Google/GitHub).
- [ ] Setup PGMQ workers in Bun for background job processing.
- [ ] Implement CSV transaction import via background workers.
- [ ] Build UI for file upload and import status tracking.
- [ ] **Verification:** Import 1000+ transactions and verify ledger consistency.

## Phase 3: Tracking & Budgeting
**Goal:** Build the core user-facing financial logic.

- [ ] Implement Budgeting logic (50/30/20, limits).
- [ ] Create Goal tracking system (savings targets).
- [ ] Build Frontend Dashboard with React + Tailwind.
- [ ] Implement transaction categorization and filtering.
- [ ] **Verification:** End-to-end flow from import to budget visualization.

## Phase 4: AI Insights & Forecasting
**Goal:** Integrate OpenRouter for advanced financial analysis.

- [ ] Setup OpenRouter API integration.
- [ ] Implement AI worker for spending analysis.
- [ ] Build forecasting models using AI insights.
- [ ] Create AI-driven "Recommendations" UI component.
- [ ] **Verification:** Generate insights for a sample dataset and verify JSON parsing.

## Phase 5: Polishing & Deployment
**Goal:** Prepare for production use.

- [ ] Comprehensive E2E testing.
- [ ] Performance tuning for Postgres queries.
- [ ] Security audit and hardening.
- [ ] Final UI/UX polish.
