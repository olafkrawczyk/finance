import { describe, it, expect } from 'bun:test';
import { spawnSync } from 'child_process';

describe('UI Build Tests', () => {
  it('compiles the Vite + React + Tailwind production build successfully', () => {
    const result = spawnSync('bun', ['run', 'build:web'], {
      env: { ...process.env, PATH: `${process.env.HOME}/.bun/bin:${process.env.PATH}` },
    });

    if (result.status !== 0) {
      console.error('Build stderr:', result.stderr?.toString());
      console.error('Build stdout:', result.stdout?.toString());
    }

    expect(result.status).toBe(0);
  });
});
