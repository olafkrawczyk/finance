# Spike Conventions

Patterns and stack choices established across spike sessions. New spikes follow these unless the question requires otherwise.

## Stack

- **Runtime:** Node.js / Bun
- **Frontend:** React + Vite + TailwindCSS
- **Backend:** Hono (Bun)
- **Database:** PostgreSQL via postgres.js
- **Validation:** Zod schemas

## Structure

- Spike directories: `.planning/spikes/NNN-name/`
- Each spike gets a `README.md` with frontmatter
- Source/test files alongside README

## Patterns

- **UI prototypes:** Build with TailwindCDN standalone HTML for quick iteration
- **DB changes:** Full SQL migration scripts in the spike artifact
- **Approach documents:** Use `approach.md` for tradeoff analysis
- **Hover-reveal actions:** Table row actions (edit, delete) revealed on hover for clean default state
- **Edit/delete modals:** Use modal overlay for editing all fields, confirmation dialog for deletion
- **Trigger modifications:** DB trigger changes documented with CREATE OR REPLACE + migration notes
- **Client-side filtering & sorting:** For datasets under 1000 items, implement filter/search/sort client-side (e.g. via React useMemo) to provide instant UI feedback without network latency
- **Chronological running balances:** When presenting running balances in descending/reverse order, compute the cumulative totals chronologically (ascending) first, then reverse the array before outputting or rendering
- **Dynamic Imports in Test Scripts:** Use dynamic `await import(...)` for scripts loading environment variables before importing the Hono app/Better Auth instance to prevent ES Module hoisting issues in Bun/Node.
- **Better Auth Endpoint Naming:** Better Auth translates camelCase API methods (like `signInSocial`) to kebab-case routes (like `/api/auth/sign-in/social`).
- **OAuth Callback Whitelisting:** Cross-origin callbacks must be whitelisted in `trustedOrigins` (and `TRUSTED_ORIGINS` environment variable) to avoid `403 INVALID_CALLBACK_URL` errors.

## Tools & Libraries

- `crypto.createHash('sha256')` — hashing (Node built-in)
