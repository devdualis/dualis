import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['test/security/**/*.spec.ts'],
    testTimeout: 30000,
    hookTimeout: 30000,
    // Specs share one test database (TRUNCATE, migrations): never run files in parallel.
    fileParallelism: false,
  },
});
