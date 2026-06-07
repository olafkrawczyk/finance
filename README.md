# Finance

Personal finance tracker for ING (business) and IPKO (personal) accounts.

## Stack

- **Backend**: Bun + Hono + PostgreSQL + PGMQ
- **Frontend**: React + Vite + Recharts + Tailwind
- **AI**: OpenRouter (Claude Sonnet for narrative insights, DeepSeek-R1 for forecasts)
- **Auth**: better-auth (email/password)

## Prerequisites

- Bun
- PostgreSQL running locally on port 5432 (database: `finance`)
- `.env` file with `DATABASE_URL` and `PORT` (see `.env.example`)

## Setup

```bash
# Apply schema and base seed (categories, accounts, PGMQ queues)
bun src/infrastructure/db/apply.ts
```

## Dev data reset

Wipes all data and reloads transactions + opening balances from the pre-generated dev seed (derived from `budget.xlsx`):

```bash
bun scripts/seed-dev.ts
```

After running, register a new account at http://localhost:5173. The DB schema is preserved — only data is reset.

To regenerate `seed-dev.sql` from a new version of `budget.xlsx`, re-run the import script and replace `src/infrastructure/db/seed-dev.sql`.

## Running

```bash
# Backend API + AI insights worker together (port 3000)
bun run dev

# Frontend dev server (port 5173)
bun run dev:web
```

Or individually:

```bash
bun run dev:api     # backend only
bun run dev:worker  # insights worker only
```

The insights worker must be running for the "Generate" button to produce results. Without it, analysis jobs queue in PGMQ but never process.

## Tests

```bash
bun test
```
