import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'forks',
    coverage: {
      provider: 'v8',
    },
    include: ['packages/**/*.test.ts', 'workers/**/*.test.ts'],
  },
});
