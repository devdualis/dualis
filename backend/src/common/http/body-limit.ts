import { RouteConfig } from '@nestjs/platform-fastify';
import type { FastifyInstance } from 'fastify';

/** Request body limit of every route that does not raise its own with @BodyLimit. */
export const DEFAULT_BODY_LIMIT = 1024 * 1024;

/** Raises the request body limit of one route (exam documents, profile pictures). */
export const BodyLimit = (bytes: number) => RouteConfig({ bodyLimit: bytes });

/**
 * Fastify reads a route's body limit from its route options, not from its config, so
 * this copies the @BodyLimit value there. Call it before the application registers routes.
 */
export function applyRouteBodyLimits(fastify: FastifyInstance): void {
  fastify.addHook('onRoute', (route) => {
    const bytes = (route.config as { bodyLimit?: number } | undefined)?.bodyLimit;
    if (bytes) route.bodyLimit = bytes;
  });
}
