import { describe, it, expect, beforeEach, vi } from 'vitest';
import { HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EncryptionService } from '../../src/common/encryption/encryption.service';
import { CareService } from '../../src/modules/care/care.service';
import { careDocumentRequests } from '../../src/database/schema/care.schema';
import { PgDialect } from 'drizzle-orm/pg-core';
import type { SQL } from 'drizzle-orm';

const KEY = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

/** A query builder stand-in: every call returns itself, awaiting it gives `result`. */
function chain(result: unknown) {
  const calls: Record<string, unknown[][]> = {};
  const proxy: any = new Proxy(
    {},
    {
      get(_, prop: string) {
        if (prop === 'then') return (resolve: (v: unknown) => void) => resolve(result);
        if (prop === 'calls') return calls;
        return (...args: unknown[]) => {
          (calls[prop] ??= []).push(args);
          return proxy;
        };
      },
    },
  );
  return proxy;
}

describe('CareService daily document limit (uploads and re-reads)', () => {
  const encryption = new EncryptionService(new ConfigService({ ENCRYPTION_MASTER_KEY: KEY }));
  const file = Buffer.from('%PDF-1.7 exame');
  const now = new Date('2026-10-30T12:00:00Z');
  let queue: unknown[];
  let builders: any[];
  let db: { withRls: ReturnType<typeof vi.fn> };

  const row = (over: Record<string, unknown> = {}) => ({
    id: 'doc-1',
    userId: 'usr-1',
    profileId: 'prof-1',
    kind: 'lab',
    mime: 'application/pdf',
    sizeBytes: file.length,
    status: 'review',
    data: encryption.encrypt(JSON.stringify({ title: 'Hemograma' })),
    error: null,
    createdAt: now,
    updatedAt: now,
    ...over,
  });

  const serviceWith = (config?: Record<string, string>) => {
    const service = new CareService(db as any, encryption, { read: vi.fn() } as any, config && new ConfigService(config));
    vi.spyOn(service, 'readDocument').mockResolvedValue();
    return service;
  };

  const upload = (service: CareService) =>
    service.uploadDocument('usr-1', 'prof-1', { kind: 'lab', mime: 'application/pdf', fileBase64: file.toString('base64'), read: true });

  beforeEach(() => {
    queue = [];
    builders = [];
    const next = (...args: unknown[]) => {
      const builder = chain(queue.shift());
      builders.push({ builder, args });
      return builder;
    };
    const tx = { insert: next, select: next, update: next, execute: vi.fn().mockResolvedValue(undefined) };
    db = { withRls: vi.fn(async (_user: string, fn: (t: unknown) => unknown) => fn(tx)) };
  });

  it('records the upload and stores the document while under the limit', async () => {
    queue.push([{ requests: 29 }], undefined, [row({ status: 'processing' })]);
    const result = await upload(serviceWith());

    expect(result.id).toBe('doc-1');
    expect(builders[1].args[0]).toBe(careDocumentRequests);
    expect(builders[1].builder.calls.values[0][0]).toEqual({ userId: 'usr-1' });
  });

  it('answers 429 and stores nothing once 30 documents were requested in 24 hours', async () => {
    queue.push([{ requests: 30 }]);
    await expect(upload(serviceWith())).rejects.toMatchObject({ status: HttpStatus.TOO_MANY_REQUESTS });
    expect(builders).toHaveLength(1);
  });

  it('counts re-reads against the same limit', async () => {
    queue.push([row({ status: 'review' })], [{ requests: 30 }]);
    await expect(serviceWith().reprocessDocument('usr-1', 'prof-1', 'doc-1')).rejects.toMatchObject({
      status: HttpStatus.TOO_MANY_REQUESTS,
    });
    expect(builders).toHaveLength(2);
  });

  it('takes the limit from CARE_DAILY_DOCUMENT_LIMIT', async () => {
    queue.push([{ requests: 2 }]);
    await expect(upload(serviceWith({ CARE_DAILY_DOCUMENT_LIMIT: '2' }))).rejects.toMatchObject({
      status: HttpStatus.TOO_MANY_REQUESTS,
    });
  });

  it.each(['upload', 're-read'])('reserves the last daily slot only once during concurrent %s requests', async (operation) => {
    let committedRequests = 29;
    let lockTail = Promise.resolve();
    const dialect = new PgDialect();
    db.withRls.mockImplementation(async (userId: string, fn: (tx: unknown) => Promise<unknown>) => {
      let pendingRequests = 0;
      let unlock = () => {};
      const tx = {
        execute: async (statement: SQL) => {
          const query = dialect.sqlToQuery(statement);
          expect(query.sql).toContain('pg_advisory_xact_lock');
          expect(query.params).toContain(userId);
          const previous = lockTail;
          lockTail = new Promise<void>((resolve) => { unlock = resolve; });
          await previous;
        },
        select: () => ({ from: (table: unknown) => table === careDocumentRequests
          ? { where: async () => {
              const requests = committedRequests;
              // Other transactions may count before this one commits, as in PostgreSQL.
              await new Promise((resolve) => setImmediate(resolve));
              return [{ requests }];
            } }
          : chain([row({ file: encryption.encryptBuffer(file) })]),
        }),
        insert: (table: unknown) => table === careDocumentRequests
          ? { values: async () => { pendingRequests++; } }
          : chain([row({ status: 'processing' })]),
        update: () => chain([row({ status: 'processing' })]),
      };
      try {
        const result = await fn(tx);
        committedRequests += pendingRequests;
        return result;
      } finally {
        // Transaction advisory locks are released on commit and rollback alike.
        unlock();
      }
    });
    const service = serviceWith();
    const request = () => operation === 'upload'
      ? upload(service)
      : service.reprocessDocument('usr-1', 'prof-1', 'doc-1');
    const results = await Promise.allSettled([request(), request()]);
    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(results.find((result) => result.status === 'rejected')).toMatchObject({
      reason: { status: HttpStatus.TOO_MANY_REQUESTS },
    });
    expect(committedRequests).toBe(30);
    await new Promise((resolve) => setImmediate(resolve));
    expect(service.readDocument).toHaveBeenCalledTimes(1);
  });
});
