// Just-in-time test database — Bun test preload (wired in bunfig.toml).
//
// Spins up an ephemeral Postgres+PGMQ container, runs the project migrations
// against it, and OVERRIDES process.env.DATABASE_URL so every test file connects
// to the throwaway database. Because this preload runs before any test file
// imports the postgres client, tests can never reach the real database — no
// matter what .env contains. The container is removed when the run exits.

import { afterAll } from 'bun:test';

const IMAGE = 'ghcr.io/pgmq/pg18-pgmq:v1.10.0'; // matches docker-compose.yml
const CONTAINER = `finance-test-db-${process.pid}-${Date.now()}`;
const DB_NAME = 'finance_test';
const READY_TIMEOUT_MS = 60_000;

function run(cmd: string[]): { ok: boolean; stdout: string; stderr: string } {
  const p = Bun.spawnSync(cmd, { stdout: 'pipe', stderr: 'pipe' });
  return {
    ok: p.exitCode === 0,
    stdout: p.stdout.toString().trim(),
    stderr: p.stderr.toString().trim(),
  };
}

let torndown = false;
function teardown() {
  if (torndown) return;
  torndown = true;
  run(['docker', 'rm', '-f', CONTAINER]);
}

async function setup() {
  console.log(`[test-db] starting ephemeral container ${CONTAINER} from ${IMAGE}`);

  const started = run([
    'docker', 'run', '-d', '--rm',
    '--name', CONTAINER,
    '-e', 'POSTGRES_PASSWORD=postgres',
    '-e', `POSTGRES_DB=${DB_NAME}`,
    '-p', '127.0.0.1::5432',
    IMAGE,
  ]);
  if (!started.ok) {
    throw new Error(`[test-db] docker run failed: ${started.stderr || started.stdout}`);
  }

  // Primary cleanup: a global afterAll runs after the whole suite (Bun applies
  // preload lifecycle hooks to all tests). The process handlers are fallbacks for
  // interrupts/crashes where afterAll never runs.
  afterAll(teardown);
  process.on('exit', teardown);
  process.on('SIGINT', () => { teardown(); process.exit(130); });
  process.on('SIGTERM', () => { teardown(); process.exit(143); });

  // Resolve the Docker-assigned host port.
  const portRes = run([
    'docker', 'inspect',
    '--format', '{{ (index (index .NetworkSettings.Ports "5432/tcp") 0).HostPort }}',
    CONTAINER,
  ]);
  const port = portRes.stdout;
  if (!portRes.ok || !/^\d+$/.test(port)) {
    throw new Error(`[test-db] could not resolve host port: ${portRes.stderr || portRes.stdout}`);
  }

  // Wait until Postgres is *really* ready. The official image starts a temporary
  // server to run init scripts, then shuts it down and restarts for real, so
  // "ready to accept connections" appears twice. Connecting after only the first
  // one races the restart ("Connection terminated unexpectedly"). Require two.
  const deadline = Date.now() + READY_TIMEOUT_MS;
  let ready = false;
  while (Date.now() < deadline) {
    const logs = run(['docker', 'logs', CONTAINER]);
    const readyCount = (logs.stdout + logs.stderr).split('ready to accept connections').length - 1;
    if (readyCount >= 2) {
      ready = true;
      break;
    }
    await Bun.sleep(500);
  }
  if (!ready) {
    throw new Error(`[test-db] database not ready within ${READY_TIMEOUT_MS}ms`);
  }

  const url = `postgres://postgres:postgres@127.0.0.1:${port}/${DB_NAME}`;
  process.env.DATABASE_URL = url;
  console.log(`[test-db] DATABASE_URL overridden -> 127.0.0.1:${port}/${DB_NAME}`);

  // Apply the production migrations (creates schema + pgmq extension + queues).
  // Retry on transient connection errors during the startup window.
  let lastErr = '';
  for (let attempt = 1; attempt <= 5; attempt++) {
    const migrate = Bun.spawn(['bun', 'run', 'src/infrastructure/db/migrate.ts'], {
      env: { ...process.env, DATABASE_URL: url },
      stdout: 'pipe',
      stderr: 'pipe',
    });
    await migrate.exited;
    if (migrate.exitCode === 0) {
      console.log('[test-db] migrations applied — ready');
      return;
    }
    const out = await new Response(migrate.stdout).text();
    const err = await new Response(migrate.stderr).text();
    lastErr = `${out}\n${err}`;
    await Bun.sleep(1000);
  }
  throw new Error(`[test-db] migrations failed after retries:\n${lastErr}`);
}

await setup();
