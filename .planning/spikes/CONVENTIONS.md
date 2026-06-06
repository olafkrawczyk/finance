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

## Tools & Libraries

- `crypto.createHash('sha256')` — hashing (Node built-in)
