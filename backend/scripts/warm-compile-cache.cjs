// Runs at image build time. Loads the bundle once with Node's compile cache
// enabled so the V8 code cache for dist/bundle/main.js ships inside the image
// (directory from NODE_COMPILE_CACHE). At runtime Node reuses that cache and
// skips most of the parsing and compiling on a cold start.
//
// Requiring the bundle also calls bootstrap(), which fails without the real
// environment. That failure is asynchronous and irrelevant here: the process
// exits right after the synchronous load, once the cache is written.
const nodeModule = require('node:module');

const dir = process.env.NODE_COMPILE_CACHE;
if (!dir) {
  throw new Error('NODE_COMPILE_CACHE must point to the cache directory.');
}

// NODE_COMPILE_CACHE in the environment already enables the cache at startup,
// which reports ALREADY_ENABLED here; both states are fine.
const { status, message } = nodeModule.enableCompileCache(dir);
const { ENABLED, ALREADY_ENABLED } = nodeModule.constants.compileCacheStatus;
if (status !== ENABLED && status !== ALREADY_ENABLED) {
  throw new Error(`Compile cache not enabled (status ${status}): ${message ?? ''}`);
}
process.on('unhandledRejection', () => {});
require('../dist/bundle/main.js');
nodeModule.flushCompileCache();
process.exit(0);
