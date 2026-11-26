# ==============================================================================
# DualisCheckUp NestJS Backend - Production Dockerfile for Google Cloud Run
# Multi-stage build for optimal image size, security, and fast cold-start
# ==============================================================================

# --- Stage 1: Build ---
FROM node:22-slim AS builder

WORKDIR /app

# Install build dependencies for native modules (e.g., argon2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy package manifests first for efficient layer caching
COPY package*.json ./

# Install all dependencies including devDependencies for build
RUN npm ci

# Copy TypeScript configuration and sources
COPY tsconfig*.json ./
COPY src/ ./src/
COPY test/ ./test/
COPY scripts/ ./scripts/

# Compile TypeScript (dist/src/main.js), then bundle it into one file
# (dist/bundle/main.js) so a cold start reads 1 file instead of ~1650.
RUN npm run build && npm run bundle

# Remove development dependencies to keep final image small
RUN npm prune --omit=dev

# --- Stage 2: Production Runtime ---
FROM node:22-slim AS runner

WORKDIR /app

# Runtime environment settings
ENV NODE_ENV=production
# Google Cloud Run provides PORT dynamically; default to 8080
ENV PORT=8080

# Directory for the V8 compile cache, writable by the node user
RUN mkdir -p /app/.node-compile-cache && chown node:node /app/.node-compile-cache

# Run container as non-root node user for security
USER node

# Copy production dependencies and compiled artifacts.
# node_modules stays for the packages left out of the bundle (argon2).
COPY --chown=node:node --from=builder /app/package*.json ./
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist

# Ship the V8 code cache for the bundle so a cold start skips most of the
# parsing and compiling. Node reads NODE_COMPILE_CACHE at runtime too.
ENV NODE_COMPILE_CACHE=/app/.node-compile-cache
COPY --chown=node:node scripts/warm-compile-cache.cjs ./scripts/warm-compile-cache.cjs
RUN node scripts/warm-compile-cache.cjs && test -n "$(ls -A $NODE_COMPILE_CACHE)"

# Document default listening port
EXPOSE 8080

# Start Fastify NestJS application
CMD ["node", "dist/bundle/main.js"]
