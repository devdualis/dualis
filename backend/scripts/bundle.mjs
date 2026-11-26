// Bundles the compiled backend (dist/src/main.js, output of `nest build`)
// into a single file, dist/bundle/main.js.
//
// Why: on Cloud Run, loading ~1650 small JS files from node_modules took
// about 4.5 s of a 5.3 s cold start. One file loads much faster.
//
// esbuild runs on the JavaScript that tsc already emitted, so the decorator
// metadata Nest needs for dependency injection (emitDecoratorMetadata) is
// kept. esbuild itself cannot emit that metadata from TypeScript.
import { build } from 'esbuild';
import { createRequire } from 'node:module';
import { writeFileSync } from 'node:fs';
import path from 'node:path';

// Kept outside the bundle and loaded from node_modules at runtime.
const external = [
  'argon2', // native addon (.node file)
  'pino-pretty', // development-only log transport, runs in a worker thread
];

// Nest and some libraries `require` optional packages inside try/catch
// (for example @nestjs/microservices, @nestjs/websockets, bufferutil).
// When such a package is not installed, leave the require in place so it
// fails at runtime exactly as it does without the bundle.
const optionalMissing = {
  name: 'optional-missing',
  setup(b) {
    b.onResolve({ filter: /^[^./]/ }, (args) => {
      if (args.kind !== 'require-call' && args.kind !== 'dynamic-import') return;
      try {
        createRequire(path.join(args.resolveDir, 'x.js')).resolve(args.path);
        return undefined;
      } catch {
        return { path: args.path, external: true };
      }
    });
  },
};

const result = await build({
  entryPoints: ['dist/src/main.js'],
  outfile: 'dist/bundle/main.js',
  bundle: true,
  platform: 'node',
  target: 'node22',
  format: 'cjs',
  // Nest resolves providers and logs contexts by class name.
  keepNames: true,
  external,
  plugins: [optionalMissing],
  logLevel: 'warning',
  metafile: true,
});

// Which packages take up the bundle; inspect with https://esbuild.github.io/analyze/
writeFileSync('dist/bundle/meta.json', JSON.stringify(result.metafile));
