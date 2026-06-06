# Requirements: Financial Planning App

## Core Objective
Deliver a robust, ledger-first financial planning application that provides users with accurate tracking, budgeting, and AI-driven insights while maintaining high data integrity.

## Functional Requirements

### 1. Ledger & Transaction Management
- **Double-Entry Bookkeeping:** All financial movements must be recorded as double-entry transactions (debit/credit).
- **Immutable Ledger:** Transactions cannot be deleted or modified; only corrected via new transactions.
- **Support for Multiple Currencies:** (MVP focus on single currency, but schema should support ISO codes).
- **Categorization:** Hierarchical category system for tracking expenses and income.

### 2. Budgeting & Goal Planning
- **Budget Frameworks:** Support for common frameworks like 50/30/20 and zero-based budgeting.
- **Alerts:** Notifications when categories approach or exceed limits.
- **Savings Goals:** Track progress toward specific savings targets (e.g., "Emergency Fund", "House Down Payment").

### 3. Data Ingestion & Job Queue
- **CSV/Bank Import:** Ability to import transactions from CSV files.
- **PGMQ Integration:** Use Postgres Message Queue for background processing of large imports and AI tasks.
- **Background Workers:** Bun-based workers to poll and process PGMQ tasks.

### 4. AI Insights (OpenRouter)
- **Spending Analysis:** AI-driven insights into spending habits and potential savings.
- **Forecasting:** Predictive analysis of future balances based on current trends.
- **Structured Output:** All AI responses must be parsed as JSON for consistency.

### 5. Authentication & Security
- **OAuth/SSO:** Integration with providers (Google/GitHub) via Better Auth.
- **Secure Data Storage:** Encryption of sensitive user data at rest.

## Technical Requirements

### 1. Database
- **Postgres:** Primary data store.
- **Numeric Precision:** Use `NUMERIC(19, 4)` for all currency fields to avoid floating-point errors.
- **PGMQ Extension:** Must be installed and configured for background tasks.

### 2. Backend
- **Bun + Hono:** High-performance runtime and framework.
- **Zod:** Strict schema validation for all API inputs and outputs.
- **Better Auth:** Framework for managing authentication sessions.

### 3. Frontend
- **React + Tailwind CSS:** For a responsive and modern user interface.
- **State Management:** (e.g., TanStack Query for data fetching).

## Non-Functional Requirements
- **Data Integrity:** Zero-sum transaction verification at the database level.
- **Performance:** Sub-100ms API response times for standard queries.
- **Reliability:** Background jobs must be idempotent and retryable.
