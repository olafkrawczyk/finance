#!/bin/bash
set -e

# Forward signals to child processes for graceful shutdown
cleanup() {
  echo "Shutting down..."
  kill -TERM $(jobs -p) 2>/dev/null || true
  wait
  echo "All processes exited."
}
trap cleanup SIGTERM SIGINT

# Load .env.production if present (volume-mounted from host per D-08)
if [ -f /app/.env.production ]; then
  echo "Loading .env.production..."
  set -a
  source /app/.env.production
  set +a
fi

# Run database migrations (D-07: migrations run before app processes start)
echo "=== Running database migrations ==="
bun run src/infrastructure/db/migrate.ts
echo "=== Migrations complete ==="

# Start all processes (D-01: single-entry orchestration)
PORT=${PORT:-3000}
echo "=== Starting API server (port $PORT) ==="
bun index.ts &

echo "=== Starting insights worker ==="
bun src/workers/insights-worker.ts &

echo "=== Starting import worker ==="
bun src/workers/import-worker.ts &

# Wait for any process to exit
echo "=== All processes started ==="
wait
