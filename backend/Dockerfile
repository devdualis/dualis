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

# Build production bundle (outputs to dist/src/main.js)
RUN npm run build

# Remove development dependencies to keep final image small
RUN npm prune --omit=dev

# --- Stage 2: Production Runtime ---
FROM node:22-slim AS runner

WORKDIR /app

# Runtime environment settings
ENV NODE_ENV=production
# Google Cloud Run provides PORT dynamically; default to 8080
ENV PORT=8080

# Run container as non-root node user for security
USER node

# Copy production dependencies and compiled artifacts
COPY --chown=node:node --from=builder /app/package*.json ./
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist

# Document default listening port
EXPOSE 8080

# Start Fastify NestJS application
CMD ["node", "dist/src/main.js"]
