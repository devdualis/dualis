import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ConfigService } from '@nestjs/config';
import { PgDialect } from 'drizzle-orm/pg-core';
import type { SQL } from 'drizzle-orm';
import { EncryptionService } from '../../src/common/encryption/encryption.service';
import { CareService, sameExams } from '../../src/modules/care/care.service';
import { DocumentData } from '../../src/modules/care/care.dto';

const KEY = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const OTHER_KEY = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

/** A query builder stand-in: every call returns itself, awaiting it gives `result`. */
function chain(result: unknown) {
  const calls: Record<string, unknown[][]> = {};
  const proxy: any = new Proxy(
    {},
    {
      get(_, prop: string) {
        if (prop === 'then') return (resolve: (v: unknown) => void, reject: (err: unknown) => void) =>
          Promise.resolve().then(() => typeof result === 'function' ? result(calls) : result).then(resolve, reject);
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

const lab = (values: [string, string][], collectedOn?: string): DocumentData => ({
  ...(collectedOn && { collectedOn }),
  values: values.map(([item, value]) => ({ item, value, confirmed: true })),
});

describe('EncryptionService.fingerprint', () => {
  it('gives the same value for the same file and depends on the server key', () => {
    const a = new EncryptionService(new ConfigService({ ENCRYPTION_MASTER_KEY: KEY }));
    const b = new EncryptionService(new ConfigService({ ENCRYPTION_MASTER_KEY: OTHER_KEY }));
    const file = Buffer.from('%PDF-1.7 hemograma');
    expect(a.fingerprint(file)).toBe(a.fingerprint(Buffer.from(file)));
    expect(a.fingerprint(file)).toMatch(/^[0-9a-f]{64}$/);
    expect(a.fingerprint(file)).not.toBe(a.fingerprint(Buffer.from('%PDF-1.7 hemograma ')));
    expect(a.fingerprint(file)).not.toBe(b.fingerprint(file));
  });
});

describe('sameExams', () => {
  const base: [string, string][] = [
    ['Hemácias', '4,85'],
    ['Hemoglobina', '14,2'],
    ['Hematócrito', '42'],
    ['Leucócitos', '6.300'],
    ['Plaquetas', '250.000'],
  ];

  it('matches another reading of the same report despite case, accents, punctuation and decimal comma', () => {
    const again = lab(
      [
        ['HEMACIAS:', '4.85'],
        ['Hemoglobina', '14.2'],
        ['Hematocrito', '42'],
        ['Leucocitos', '6.300'],
        ['Plaquetas', '250.000'],
      ],
      '2026-05-21',
    );
    expect(sameExams(lab(base, '2026-05-21'), again)).toBe(true);
  });

  it('matches when one reading has no date or misses a row', () => {
    expect(sameExams(lab(base), lab(base.slice(0, 4), '2026-05-21'))).toBe(true);
  });

  it('does not match different collection dates, even with equal values', () => {
    expect(sameExams(lab(base, '2026-05-21'), lab(base, '2026-06-21'))).toBe(false);
  });

  it('does not match when most values differ', () => {
    const next = lab([
      ['Hemácias', '4,60'],
      ['Hemoglobina', '13,1'],
      ['Hematócrito', '40'],
      ['Leucócitos', '6.300'],
      ['Plaquetas', '250.000'],
    ]);
    expect(sameExams(lab(base), next)).toBe(false);
  });

  it('needs at least three shared results', () => {
    expect(sameExams(lab(base.slice(0, 2)), lab(base.slice(0, 2)))).toBe(false);
  });
});

describe('CareService repeated documents', () => {
  let encryption: EncryptionService;
  let reader: { read: ReturnType<typeof vi.fn> };
  let db: { withRls: ReturnType<typeof vi.fn> };
  let service: CareService;
  let queue: unknown[];
  let builders: any[];
  const now = new Date('2026-10-30T12:00:00Z');
  const file = Buffer.from('%PDF-1.7 exame');

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

  beforeEach(() => {
    encryption = new EncryptionService(new ConfigService({ ENCRYPTION_MASTER_KEY: KEY }));
    reader = { read: vi.fn() };
    queue = [];
    builders = [];
    const next = () => {
      const builder = chain(queue.shift());
      builders.push(builder);
      return builder;
    };
    const tx = { insert: next, select: next, update: next };
    db = { withRls: vi.fn(async (_user: string, fn: (t: unknown) => unknown) => fn(tx)) };
    service = new CareService(db as any, encryption, reader as any);
    vi.spyOn(service, 'readDocument').mockResolvedValue();
    // The daily limit has its own tests (care-document-limit.spec.ts).
    vi.spyOn(service as any, 'recordDocumentRequest').mockResolvedValue(undefined);
  });

  const upload = (read = true, kind: 'lab' | 'other' = 'lab') =>
    service.uploadDocument('usr-1', 'prof-1', { kind, mime: 'application/pdf', fileBase64: file.toString('base64'), read });

  it('stores a new file with its fingerprint and reads it', async () => {
    queue.push([row({ status: 'processing' })]);
    const result = await upload();
    await new Promise((r) => setImmediate(r));

    expect(builders[0].calls.values[0][0]).toMatchObject({ fileHmac: encryption.fingerprint(file) });
    expect(result.duplicate).toBeUndefined();
    expect(service.readDocument).toHaveBeenCalledTimes(1);
  });

  it('returns the stored document for the same file and does not read it again', async () => {
    queue.push([], [row({ status: 'ready' })]);
    const result = await upload();
    await new Promise((r) => setImmediate(r));

    expect(result).toMatchObject({ id: 'doc-1', status: 'ready', duplicate: true });
    expect(service.readDocument).not.toHaveBeenCalled();
  });

  it('reads a file that was first stored without reading', async () => {
    queue.push([], [row({ status: 'archived', kind: 'other' })], [row({ status: 'processing' })]);
    const result = await upload();
    await new Promise((r) => setImmediate(r));

    expect(builders[2].calls.set[0][0]).toMatchObject({ kind: 'lab', status: 'processing' });
    expect(result.duplicate).toBeUndefined();
    expect(service.readDocument).toHaveBeenCalledWith('usr-1', 'doc-1', 'lab', 'application/pdf', file, { title: 'Hemograma' });
  });

  it('starts only one reading when concurrent uploads both see the archived file', async () => {
    let stored = row({ status: 'archived', kind: 'other' });
    let selections = 0;
    let release!: () => void;
    const bothSelected = new Promise<void>((resolve) => { release = resolve; });
    const dialect = new PgDialect();
    const tx = {
      insert: () => chain([]),
      select: () => chain(async () => {
        const snapshot = { ...stored };
        if (selections < 2) {
          if (++selections === 2) release();
          await bothSelected;
        }
        return [snapshot];
      }),
      update: () => chain((calls: Record<string, unknown[][]>) => {
        const query = dialect.sqlToQuery(calls.where[0][0] as SQL);
        // Apply the actual UPDATE predicate to shared state, like competing DB transactions.
        const expectedStatus = query.sql.includes('"care_documents"."status"') ? query.params.at(-1) : undefined;
        if (expectedStatus !== undefined && stored.status !== expectedStatus) return [];
        stored = { ...stored, ...calls.set[0][0] as object };
        return [{ ...stored }];
      }),
    };
    db.withRls.mockImplementation(async (_user: string, fn: (t: unknown) => unknown) => fn(tx));

    const results = await Promise.all([upload(), upload()]);
    await new Promise((resolve) => setImmediate(resolve));

    expect(service.readDocument).toHaveBeenCalledTimes(1);
    expect(results.filter((result) => result.duplicate)).toHaveLength(1);
    expect(results.every((result) => result.id === 'doc-1' && result.status === 'processing')).toBe(true);
  });

  it('marks a new reading that holds the same exams as an older document', async () => {
    vi.mocked(service.readDocument).mockRestore();
    const values = [
      { item: 'Hemácias', value: '4,85' },
      { item: 'Hemoglobina', value: '14,2' },
      { item: 'Leucócitos', value: '6.300' },
    ];
    reader.read.mockResolvedValue({ collectedOn: '2026-05-21', values });
    const older = row({ id: 'doc-old', status: 'ready', data: encryption.encrypt(JSON.stringify(lab(values.map((v) => [v.item, v.value]), '2026-05-21'))) });
    queue.push([{ profileId: 'prof-1' }], [older], undefined);

    await service.readDocument('usr-1', 'doc-new', 'lab', 'application/pdf', file, {});

    const saved = JSON.parse(encryption.decrypt(builders[2].calls.set[0][0].data));
    expect(saved.possibleDuplicateOf).toBe('doc-old');
    expect(saved.values).toHaveLength(3);
  });

  it('clears the flag when the person saves the review', async () => {
    const flagged = row({ data: encryption.encrypt(JSON.stringify({ title: 'Hemograma', possibleDuplicateOf: 'doc-old' })) });
    queue.push([flagged], [row({ status: 'ready' })]);

    await service.reviewDocument('usr-1', 'prof-1', 'doc-1', { title: 'Hemograma' });

    const saved = JSON.parse(encryption.decrypt(builders[1].calls.set[0][0].data));
    expect(saved.possibleDuplicateOf).toBeUndefined();
  });
});
