import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['test/e2e/**/*.e2e-spec.ts'],
    env: { JWT_SECRET: 'e2e-only-jwt-secret-with-at-least-32-characters' },
    testTimeout: 30000,
    hookTimeout: 30000,
  },
});
