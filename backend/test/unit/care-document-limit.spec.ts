import { describe, it, expect, beforeEach, vi } from 'vitest';
import { HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EncryptionService } from '../../src/common/encryption/encryption.service';
import { CareService } from '../../src/modules/care/care.service';
import { careDocumentRequests } from '../../src/database/schema/care.schema';

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
    const tx = { insert: next, select: next, update: next };
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
});
