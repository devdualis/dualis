import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { ProfilesService, ageInYears } from '../../src/modules/profiles/profiles.service';
import { ConfirmLegalBasisDto, CreateDependentDto } from '../../src/modules/profiles/dto/create-dependent.dto';
import { UpdateProfileDto } from '../../src/modules/profiles/dto/update-profile.dto';
import { ClaimProfileDto } from '../../src/modules/profiles/dto/claim-profile.dto';
import { INVITE_CODE_CHARS } from '../../src/modules/profiles/family-sharing.service';
import { profiles } from '../../src/database/schema/profiles.schema';
import { legalGuardianships } from '../../src/database/schema/legal-guardianships.schema';
import { SHARE_CATEGORIES } from '../../src/database/schema/shared-access-grants.schema';

const USER_ID = '11111111-1111-4111-8111-111111111111';
const OTHER_USER_ID = '22222222-2222-4222-8222-222222222222';

const ADULT_MESSAGE = 'Para maiores de 18 anos, escolha curatela ou tomada de decisão apoiada.';
const MINOR_MESSAGE = 'Para menores de 18 anos, escolha poder familiar ou tutela.';

/** YYYY-MM-DD for someone who turned `years` on 1 January of this year. */
function bornYearsAgo(years: number): string {
  return `${new Date().getUTCFullYear() - years}-01-01`;
}

function profileRow(overrides: Record<string, unknown> = {}) {
  return {
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    accountOwnerId: USER_ID,
    profileType: 'primary',
    name: 'Ana Souza',
    dateOfBirth: '1990-04-12',
    gender: 'feminino',
    avatarUrl: null,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-01T00:00:00Z'),
    ...overrides,
  };
}

/**
 * Chainable Drizzle-like query mock. Every builder method returns the chain;
 * awaiting the chain resolves to the next queued result for that operation kind.
 */
function createTx(results: {
  select?: unknown[][];
  insert?: unknown[][];
  update?: unknown[][];
  delete?: unknown[][];
  /** Raw tx.execute results; an Error entry is thrown instead. */
  execute?: unknown[];
}) {
  const executeQueue = [...(results.execute ?? [])];
  const queues = {
    select: [...(results.select ?? [])],
    insert: [...(results.insert ?? [])],
    update: [...(results.update ?? [])],
    delete: [...(results.delete ?? [])],
  };
  const calls = {
    insertTables: [] as unknown[],
    insertValues: [] as unknown[],
    updateSets: [] as unknown[],
    deleteTables: [] as unknown[],
  };

  const chain = (kind: keyof typeof queues) => {
    const c: any = {};
    for (const m of ['from', 'where', 'innerJoin', 'leftJoin', 'limit', 'orderBy', 'returning', 'onConflictDoNothing']) {
      c[m] = vi.fn(() => c);
    }
    c.values = vi.fn((v: unknown) => {
      calls.insertValues.push(v);
      return c;
    });
    c.set = vi.fn((v: unknown) => {
      calls.updateSets.push(v);
      return c;
    });
    c.then = (resolve: (v: unknown) => unknown, reject: (e: unknown) => unknown) =>
      Promise.resolve(queues[kind].shift() ?? []).then(resolve, reject);
    return c;
  };

  const tx: any = {
    execute: vi.fn(async () => {
      const next = executeQueue.shift();
      if (next instanceof Error) throw next;
      return next ?? { rows: [] };
    }),
    // Nested transaction (SAVEPOINT): runs the callback on the same mock.
    transaction: vi.fn(async (cb: (sp: unknown) => unknown) => cb(tx)),
    select: vi.fn(() => chain('select')),
    insert: vi.fn((table: unknown) => {
      calls.insertTables.push(table);
      return chain('insert');
    }),
    update: vi.fn(() => chain('update')),
    delete: vi.fn((table: unknown) => {
      calls.deleteTables.push(table);
      return chain('delete');
    }),
  };

  return { tx, calls };
}

describe('ProfilesService Unit Tests', () => {
  let service: ProfilesService;
  let mockDatabaseService: any;
  let mockEmailService: { sendHandoverDueEmail: ReturnType<typeof vi.fn> };

  const runWith = (tx: unknown) =>
    mockDatabaseService.withRls.mockImplementation(async (_userId: string, cb: any) => cb(tx));

  beforeEach(() => {
    mockDatabaseService = { withRls: vi.fn() };
    mockEmailService = { sendHandoverDueEmail: vi.fn().mockResolvedValue(undefined) };
    service = new ProfilesService(mockDatabaseService, mockEmailService as any);
  });

  const validDependent = (overrides: Partial<CreateDependentDto> = {}): CreateDependentDto => ({
    name: 'Lucas Souza',
    dateOfBirth: '2018-06-01',
    gender: 'masculino',
    relationshipType: 'parent',
    lgpdConsent: true,
    ...overrides,
  });

  describe('createDependent', () => {
    it('rejects payload without LGPD consent with 400 at the validation layer', async () => {
      const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
      const body = { ...validDependent(), lgpdConsent: false };

      await expect(
        pipe.transform(body, { type: 'body', metatype: CreateDependentDto }),
      ).rejects.toBeInstanceOf(BadRequestException);

      const { lgpdConsent: _omitted, ...withoutConsent } = validDependent();
      await expect(
        pipe.transform(withoutConsent, { type: 'body', metatype: CreateDependentDto }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects missing consent with 400 in the service and never opens a transaction', async () => {
      await expect(
        service.createDependent(USER_ID, validDependent({ lgpdConsent: false as unknown as true })),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(mockDatabaseService.withRls).not.toHaveBeenCalled();
    });

    it('records the legal guardianship with LGPD consent timestamp in the same RLS transaction', async () => {
      const created = profileRow({
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        profileType: 'dependent_minor',
        name: 'Lucas Souza',
        dateOfBirth: '2018-06-01',
        gender: 'masculino',
      });
      const { tx, calls } = createTx({ insert: [[created], []] });
      runWith(tx);

      const before = Date.now();
      const result = await service.createDependent(
        USER_ID,
        validDependent({ lgpdLegalBasisNotes: 'Certidão de nascimento' }),
      );

      expect(mockDatabaseService.withRls).toHaveBeenCalledTimes(1);
      expect(mockDatabaseService.withRls).toHaveBeenCalledWith(USER_ID, expect.any(Function));
      expect(calls.insertTables).toEqual([profiles, legalGuardianships]);

      const guardianship = calls.insertValues[1] as any;
      expect(guardianship.guardianUserId).toBe(USER_ID);
      expect(guardianship.dependentProfileId).toBe(created.id);
      expect(guardianship.relationshipType).toBe('parent');
      expect(guardianship.lgpdLegalBasisNotes).toBe('Certidão de nascimento');
      expect(guardianship.lgpdConsentRecordedAt).toBeInstanceOf(Date);
      expect(guardianship.lgpdConsentRecordedAt.getTime()).toBeGreaterThanOrEqual(before);

      expect(result).toEqual({
        id: created.id,
        name: 'Lucas Souza',
        profileType: 'dependent_minor',
        dateOfBirth: '2018-06-01',
        gender: 'masculino',
        ownership: 'dependent',
        accessLevel: 'OWNER',
        readableCategories: [...SHARE_CATEGORIES],
        writableCategories: [...SHARE_CATEGORIES],
        relationshipType: 'parent',
        lgpdLegalBasis: 'lgpd_art_14',
        legalBasisNeedsConfirmation: false,
      });
    });

    it('stores an adult under supported decision with LGPD Art. 11, I and the notes', async () => {
      const dateOfBirth = `${new Date().getUTCFullYear() - 40}-01-01`;
      const created = profileRow({
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        profileType: 'dependent_adult',
        name: 'Carlos Souza',
        dateOfBirth,
      });
      const { tx, calls } = createTx({ insert: [[created], []] });
      runWith(tx);

      const result = await service.createDependent(
        USER_ID,
        validDependent({
          name: 'Carlos Souza',
          dateOfBirth,
          relationshipType: 'supported_decision',
          lgpdLegalBasisNotes: 'Processo 123',
        }),
      );

      expect((calls.insertValues[0] as any).profileType).toBe('dependent_adult');
      const guardianship = calls.insertValues[1] as any;
      expect(guardianship.relationshipType).toBe('supported_decision');
      expect(guardianship.lgpdLegalBasis).toBe('lgpd_art_11_i');
      expect(guardianship.lgpdLegalBasisNotes).toBe('Processo 123');
      expect(result).toMatchObject({
        profileType: 'dependent_adult',
        relationshipType: 'supported_decision',
        lgpdLegalBasis: 'lgpd_art_11_i',
        legalBasisNeedsConfirmation: false,
      });
    });

    it('stores a minor under tutela with LGPD Art. 14', async () => {
      const dateOfBirth = `${new Date().getUTCFullYear() - 10}-01-01`;
      const { tx, calls } = createTx({ insert: [[profileRow({ profileType: 'dependent_minor', dateOfBirth })], []] });
      runWith(tx);

      await service.createDependent(USER_ID, validDependent({ dateOfBirth, relationshipType: 'legal_guardian' }));

      expect((calls.insertValues[1] as any).lgpdLegalBasis).toBe('lgpd_art_14');
    });

    it('accepts supported_decision and uses a basis-neutral consent message at the validation layer', async () => {
      const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });

      await expect(
        pipe.transform(validDependent({ relationshipType: 'supported_decision' }), {
          type: 'body',
          metatype: CreateDependentDto,
        }),
      ).resolves.toMatchObject({ relationshipType: 'supported_decision' });

      const error = await pipe
        .transform({ ...validDependent(), lgpdConsent: false }, { type: 'body', metatype: CreateDependentDto })
        .catch((e: BadRequestException) => e);
      expect(JSON.stringify((error as BadRequestException).getResponse())).toContain('Consentimento LGPD é obrigatório.');

      await expect(
        pipe.transform(validDependent({ lgpdLegalBasisNotes: 'x'.repeat(2001) }), {
          type: 'body',
          metatype: CreateDependentDto,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('classifies under-18 as dependent_minor and 18+ as dependent_adult', async () => {
      const { tx: txMinor, calls: minorCalls } = createTx({ insert: [[profileRow()], []] });
      runWith(txMinor);
      await service.createDependent(USER_ID, validDependent({ dateOfBirth: '2015-03-10' }));
      expect((minorCalls.insertValues[0] as any).profileType).toBe('dependent_minor');

      const { tx: txAdult, calls: adultCalls } = createTx({ insert: [[profileRow()], []] });
      runWith(txAdult);
      await service.createDependent(
        USER_ID,
        validDependent({ dateOfBirth: '1950-03-10', relationshipType: 'curator' }),
      );
      expect((adultCalls.insertValues[0] as any).profileType).toBe('dependent_adult');
    });

    it('rejects a future date of birth with 400', async () => {
      await expect(
        service.createDependent(USER_ID, validDependent({ dateOfBirth: '2999-01-01' })),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('ageInYears', () => {
    it('turns 18 exactly on the birthday', () => {
      const now = new Date('2026-10-15T12:00:00Z');
      expect(ageInYears('2008-10-15', now)).toBe(18);
      expect(ageInYears('2008-10-16', now)).toBe(17);
    });
  });

  describe('getProfilesForUser', () => {
    it('merges primary, owned dependents and accepted shared profiles in that order', async () => {
      const primary = profileRow();
      const dependent = profileRow({
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        profileType: 'dependent_minor',
        name: 'Lucas',
        createdAt: new Date('2026-02-01T00:00:00Z'),
      });
      const sharedProfile = profileRow({
        id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        accountOwnerId: OTHER_USER_ID,
        name: 'Mariana',
        avatarUrl: 'https://tracker.example/pixel.png',
      });
      const { tx } = createTx({
        select: [
          [dependent, primary],
          [
            { profile: sharedProfile, accessLevel: 'VIEW_ONLY' },
            { profile: sharedProfile, accessLevel: 'CO_MANAGE' },
          ],
        ],
      });
      runWith(tx);

      const result = await service.getProfilesForUser(USER_ID);

      expect(result.map((p) => [p.id, p.ownership, p.accessLevel])).toEqual([
        [primary.id, 'own', 'OWNER'],
        [dependent.id, 'dependent', 'OWNER'],
        [sharedProfile.id, 'shared', 'CO_MANAGE'],
      ]);
      // No guardianship row returned for the dependent: nothing to show, nothing to confirm.
      expect(result[1]).toMatchObject({ relationshipType: null, lgpdLegalBasis: null, legalBasisNeedsConfirmation: false });
      expect(result[2]).toMatchObject({ relationshipType: null, lgpdLegalBasis: null, legalBasisNeedsConfirmation: false });
      // A stored picture link is never served: the app would load it on every phone.
      expect(result.every((p) => !('avatarUrl' in p))).toBe(true);
      expect(tx.insert).not.toHaveBeenCalled();
    });

    it('lazily creates the primary profile from the users row when missing', async () => {
      const createdPrimary = profileRow({ id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd' });
      const { tx, calls } = createTx({
        select: [
          [],
          [{ name: 'Ana Souza', gender: 'feminino', dateOfBirth: '1990-04-12' }],
          [],
        ],
        insert: [[createdPrimary]],
      });
      runWith(tx);

      const result = await service.getProfilesForUser(USER_ID);

      expect(calls.insertTables).toEqual([profiles]);
      expect(calls.insertValues[0]).toEqual({
        accountOwnerId: USER_ID,
        profileType: 'primary',
        name: 'Ana Souza',
        gender: 'feminino',
        dateOfBirth: '1990-04-12',
      });
      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({ id: createdPrimary.id, ownership: 'own', accessLevel: 'OWNER' });
    });

    it('reuses the primary created by a concurrent request instead of failing', async () => {
      const racedPrimary = profileRow({ id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee' });
      const { tx } = createTx({
        select: [
          [],
          [{ name: 'Ana Souza', gender: 'feminino', dateOfBirth: '1990-04-12' }],
          [racedPrimary],
          [],
        ],
        insert: [[]],
      });
      runWith(tx);

      const result = await service.getProfilesForUser(USER_ID);

      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({ id: racedPrimary.id, ownership: 'own' });
    });
  });

  describe('getProfilesForUser legal basis (Phase 11.1, PREM-06)', () => {
    it('returns relationship and basis of the open guardianship and flags adults still under Art. 14', async () => {
      const primary = profileRow();
      const curated = profileRow({ id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', profileType: 'dependent_adult', dateOfBirth: '1960-01-01' });
      const supported = profileRow({ id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', profileType: 'dependent_adult', dateOfBirth: '1970-01-01' });
      const minor = profileRow({ id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', profileType: 'dependent_minor', dateOfBirth: '2018-01-01' });
      const { tx } = createTx({
        select: [
          [primary, curated, supported, minor],
          [],
          [
            { dependentProfileId: curated.id, relationshipType: 'curator', lgpdLegalBasis: 'lgpd_art_14' },
            { dependentProfileId: supported.id, relationshipType: 'supported_decision', lgpdLegalBasis: 'lgpd_art_11_i' },
            { dependentProfileId: minor.id, relationshipType: 'parent', lgpdLegalBasis: 'lgpd_art_14' },
          ],
        ],
      });
      runWith(tx);

      const result = await service.getProfilesForUser(USER_ID);
      const byId = new Map(result.map((p) => [p.id, p]));

      expect(byId.get(primary.id)).toMatchObject({ relationshipType: null, lgpdLegalBasis: null, legalBasisNeedsConfirmation: false });
      expect(byId.get(curated.id)).toMatchObject({ relationshipType: 'curator', lgpdLegalBasis: 'lgpd_art_14', legalBasisNeedsConfirmation: true });
      expect(byId.get(supported.id)).toMatchObject({ relationshipType: 'supported_decision', lgpdLegalBasis: 'lgpd_art_11_i', legalBasisNeedsConfirmation: false });
      expect(byId.get(minor.id)).toMatchObject({ relationshipType: 'parent', lgpdLegalBasis: 'lgpd_art_14', legalBasisNeedsConfirmation: false });
    });
  });

  describe('getProfilesForUser hand-over status (D3)', () => {
    const primary = profileRow();
    const agedOut = profileRow({
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      profileType: 'dependent_minor',
      name: 'Lucas Souza',
      dateOfBirth: bornYearsAgo(19),
    });
    const withCode = profileRow({ id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', profileType: 'dependent_minor', name: 'Bia', dateOfBirth: bornYearsAgo(18) });
    const minor = profileRow({ id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', profileType: 'dependent_minor', name: 'Teo', dateOfBirth: bornYearsAgo(10) });
    const curated = profileRow({ id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', profileType: 'dependent_adult', name: 'Rui', dateOfBirth: bornYearsAgo(70) });
    const sharedAgedOut = profileRow({ id: '99999999-9999-4999-8999-999999999999', accountOwnerId: OTHER_USER_ID, profileType: 'dependent_minor', dateOfBirth: bornYearsAgo(19) });
    const future = new Date(Date.now() + 60 * 60 * 1000);
    const past = new Date(Date.now() - 60 * 1000);
    const guardianships = (agedOutNotified: Date | null) => [
      { id: 'g1', dependentProfileId: agedOut.id, relationshipType: 'parent', lgpdLegalBasis: 'lgpd_art_14', handoverCodeExpiresAt: past, handoverNotifiedAt: agedOutNotified },
      { id: 'g2', dependentProfileId: withCode.id, relationshipType: 'legal_guardian', lgpdLegalBasis: 'lgpd_art_14', handoverCodeExpiresAt: future, handoverNotifiedAt: new Date() },
      { id: 'g3', dependentProfileId: minor.id, relationshipType: 'parent', lgpdLegalBasis: 'lgpd_art_14', handoverCodeExpiresAt: null, handoverNotifiedAt: null },
      { id: 'g4', dependentProfileId: curated.id, relationshipType: 'curator', lgpdLegalBasis: 'lgpd_art_11_i', handoverCodeExpiresAt: null, handoverNotifiedAt: null },
    ];

    it('reports due, code_active with its expiry, and none for minors, adult curator dependents and shared profiles', async () => {
      const { tx } = createTx({
        select: [
          [primary, agedOut, withCode, minor, curated],
          [{ profile: sharedAgedOut, accessLevel: 'VIEW_ONLY', categories: ['habits'] }],
          guardianships(new Date()),
        ],
      });
      runWith(tx);

      const byId = new Map((await service.getProfilesForUser(USER_ID)).map((p) => [p.id, p]));

      expect(byId.get(agedOut.id)).toMatchObject({ handoverStatus: 'due', handoverCodeExpiresAt: null });
      expect(byId.get(withCode.id)).toMatchObject({ handoverStatus: 'code_active', handoverCodeExpiresAt: future.toISOString() });
      for (const id of [primary.id, minor.id, curated.id, sharedAgedOut.id]) {
        expect(byId.get(id)).toMatchObject({ handoverStatus: 'none', handoverCodeExpiresAt: null });
      }
      // Already notified: no update, no email.
      expect(tx.update).not.toHaveBeenCalled();
      expect(mockEmailService.sendHandoverDueEmail).not.toHaveBeenCalled();
    });

    it('marks a newly due guardianship as notified and emails the guardian once', async () => {
      const first = createTx({
        select: [[primary, agedOut, withCode, minor, curated], [], guardianships(null), [{ email: 'ana@example.com', name: 'Ana Souza' }]],
        update: [[{ dependentProfileId: agedOut.id }]],
      });
      runWith(first.tx);

      await service.getProfilesForUser(USER_ID);

      expect(first.tx.update).toHaveBeenCalledTimes(1);
      expect(first.tx.update).toHaveBeenCalledWith(legalGuardianships);
      expect(first.calls.updateSets[0]).toEqual({ handoverNotifiedAt: expect.any(Date) });
      expect(mockEmailService.sendHandoverDueEmail).toHaveBeenCalledTimes(1);
      expect(mockEmailService.sendHandoverDueEmail).toHaveBeenCalledWith('ana@example.com', 'Ana Souza', 'Lucas');

      // A concurrent or later list finds the row already marked: the UPDATE returns nothing.
      const second = createTx({
        select: [[primary, agedOut, withCode, minor, curated], [], guardianships(null)],
        update: [[]],
      });
      runWith(second.tx);

      await service.getProfilesForUser(USER_ID);

      expect(mockEmailService.sendHandoverDueEmail).toHaveBeenCalledTimes(1);
    });

    it('sends nothing when the transaction fails after marking', async () => {
      const { tx } = createTx({
        select: [[primary, agedOut], [], guardianships(null), [{ email: 'ana@example.com', name: 'Ana Souza' }]],
        update: [[{ dependentProfileId: agedOut.id }]],
      });
      mockDatabaseService.withRls.mockImplementation(async (_userId: string, cb: any) => {
        await cb(tx);
        throw new Error('commit failed');
      });

      await expect(service.getProfilesForUser(USER_ID)).rejects.toThrow('commit failed');
      expect(mockEmailService.sendHandoverDueEmail).not.toHaveBeenCalled();
    });
  });

  describe('getProfilesForUser categories (Phase 11.1, PREM-07)', () => {
    const ALL = [...SHARE_CATEGORIES];
    const sharedProfile = profileRow({
      id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      accountOwnerId: OTHER_USER_ID,
      name: 'Mariana',
    });

    it('gives owned profiles (primary and dependents) every category in both arrays', async () => {
      const primary = profileRow();
      const dependent = profileRow({ id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', profileType: 'dependent_minor' });
      const { tx } = createTx({ select: [[primary, dependent], []] });
      runWith(tx);

      const result = await service.getProfilesForUser(USER_ID);

      expect(result).toHaveLength(2);
      for (const profile of result) {
        expect(profile.readableCategories).toEqual(ALL);
        expect(profile.writableCategories).toEqual(ALL);
      }
    });

    it('unions readable categories across grants and writable only across CO_MANAGE grants', async () => {
      const { tx } = createTx({
        select: [
          [profileRow()],
          [
            { profile: sharedProfile, accessLevel: 'VIEW_ONLY', categories: ['emotional_journal'] },
            { profile: sharedProfile, accessLevel: 'CO_MANAGE', categories: ['habits'] },
          ],
        ],
      });
      runWith(tx);

      const [, shared] = await service.getProfilesForUser(USER_ID);

      expect(shared).toMatchObject({
        id: sharedProfile.id,
        accessLevel: 'CO_MANAGE',
        readableCategories: ['habits', 'emotional_journal'],
        writableCategories: ['habits'],
      });
    });

    it('orders the arrays as SHARE_CATEGORIES and drops unknown values', async () => {
      const { tx } = createTx({
        select: [
          [profileRow()],
          [{ profile: sharedProfile, accessLevel: 'CO_MANAGE', categories: ['care', 'unknown', 'habits', 'conditions'] }],
        ],
      });
      runWith(tx);

      const [, shared] = await service.getProfilesForUser(USER_ID);

      expect(shared.readableCategories).toEqual(['habits', 'conditions', 'care']);
      expect(shared.writableCategories).toEqual(['habits', 'conditions', 'care']);
    });

    it('gives a VIEW_ONLY-only grantee nothing to write', async () => {
      const { tx } = createTx({
        select: [[profileRow()], [{ profile: sharedProfile, accessLevel: 'VIEW_ONLY', categories: ['habits', 'care'] }]],
      });
      runWith(tx);

      const [, shared] = await service.getProfilesForUser(USER_ID);

      expect(shared).toMatchObject({ accessLevel: 'VIEW_ONLY', readableCategories: ['habits', 'care'], writableCategories: [] });
    });

    it('returns the co-manager\'s categories after updateProfile', async () => {
      const updated = { ...sharedProfile, name: 'Novo nome' };
      const { tx } = createTx({
        select: [[sharedProfile], [
          { accessLevel: 'CO_MANAGE', categories: ['habits'] },
          { accessLevel: 'VIEW_ONLY', categories: ['care'] },
        ]],
        update: [[updated]],
      });
      runWith(tx);

      const result = await service.updateProfile(USER_ID, sharedProfile.id, { name: 'Novo nome' });

      expect(result).toMatchObject({
        accessLevel: 'CO_MANAGE',
        readableCategories: ['habits', 'care'],
        writableCategories: ['habits'],
      });
    });
  });

  describe('updateProfile', () => {
    const shared = profileRow({
      id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      accountOwnerId: OTHER_USER_ID,
      profileType: 'dependent_minor',
    });

    it('rejects a picture link with 400 at the validation layer', async () => {
      // Any https link used to be stored and then loaded by every phone showing the profile.
      const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });

      await expect(
        pipe.transform({ avatarUrl: 'https://tracker.example/pixel.png' }, { type: 'body', metatype: UpdateProfileDto }),
      ).rejects.toBeInstanceOf(BadRequestException);
      await expect(
        pipe.transform({ name: 'Novo nome' }, { type: 'body', metatype: UpdateProfileDto }),
      ).resolves.toMatchObject({ name: 'Novo nome' });
    });

    it('returns 403 for a VIEW_ONLY grantee', async () => {
      const { tx } = createTx({ select: [[shared], [{ accessLevel: 'VIEW_ONLY' }]] });
      runWith(tx);

      await expect(
        service.updateProfile(USER_ID, shared.id, { name: 'Novo nome' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(tx.update).not.toHaveBeenCalled();
    });

    it('returns 403 when the user has no grant on someone else\'s profile', async () => {
      const { tx } = createTx({ select: [[shared], []] });
      runWith(tx);

      await expect(
        service.updateProfile(USER_ID, shared.id, { name: 'Novo nome' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('allows a CO_MANAGE grantee to update', async () => {
      const updated = { ...shared, name: 'Novo nome' };
      const { tx, calls } = createTx({
        select: [[shared], [{ accessLevel: 'CO_MANAGE' }]],
        update: [[updated]],
      });
      runWith(tx);

      const result = await service.updateProfile(USER_ID, shared.id, { name: 'Novo nome' });

      expect((calls.updateSets[0] as any).name).toBe('Novo nome');
      expect((calls.updateSets[0] as any).updatedAt).toBeInstanceOf(Date);
      expect(result).toMatchObject({ name: 'Novo nome', ownership: 'shared', accessLevel: 'CO_MANAGE' });
    });

    it('allows the owner to update', async () => {
      const own = profileRow({ profileType: 'dependent_adult' });
      const { tx } = createTx({ select: [[own]], update: [[{ ...own, gender: 'outro' }]] });
      runWith(tx);

      const result = await service.updateProfile(USER_ID, own.id, { gender: 'outro' });
      expect(result).toMatchObject({ gender: 'outro', ownership: 'dependent', accessLevel: 'OWNER' });
    });
  });

  describe('age × relationship rule (Phase 11.1, PREM-06)', () => {
    it('refuses parent for a 40-year-old with 400 and opens no transaction', async () => {
      const promise = service.createDependent(
        USER_ID,
        validDependent({ dateOfBirth: bornYearsAgo(40), relationshipType: 'parent' }),
      );
      await expect(promise).rejects.toBeInstanceOf(BadRequestException);
      await expect(promise).rejects.toThrow(ADULT_MESSAGE);
      expect(mockDatabaseService.withRls).not.toHaveBeenCalled();
    });

    it('refuses curator for a 10-year-old with 400', async () => {
      await expect(
        service.createDependent(USER_ID, validDependent({ dateOfBirth: bornYearsAgo(10), relationshipType: 'curator' })),
      ).rejects.toThrow(MINOR_MESSAGE);
      expect(mockDatabaseService.withRls).not.toHaveBeenCalled();
    });

    it('refuses a DOB change that makes a parent-dependent an adult', async () => {
      const dependent = profileRow({ profileType: 'dependent_minor', dateOfBirth: bornYearsAgo(10) });
      const { tx } = createTx({ select: [[dependent], [{ relationshipType: 'parent' }]] });
      runWith(tx);

      await expect(
        service.updateProfile(USER_ID, dependent.id, { dateOfBirth: bornYearsAgo(30) }),
      ).rejects.toThrow(ADULT_MESSAGE);
      expect(tx.update).not.toHaveBeenCalled();
    });

    it('refuses a DOB change that makes a curator-dependent a minor', async () => {
      const dependent = profileRow({ profileType: 'dependent_adult', dateOfBirth: bornYearsAgo(50) });
      const { tx } = createTx({ select: [[dependent], [{ relationshipType: 'curator' }]] });
      runWith(tx);

      await expect(
        service.updateProfile(USER_ID, dependent.id, { dateOfBirth: bornYearsAgo(5) }),
      ).rejects.toThrow(MINOR_MESSAGE);
      expect(tx.update).not.toHaveBeenCalled();
    });

    it('refuses a DOB change by a CO_MANAGE grantee on a dependent with 403 (A8)', async () => {
      const dependent = profileRow({
        accountOwnerId: OTHER_USER_ID,
        profileType: 'dependent_minor',
        dateOfBirth: bornYearsAgo(17),
      });
      const { tx } = createTx({ select: [[dependent], [{ accessLevel: 'CO_MANAGE', categories: ['habits'] }]] });
      runWith(tx);

      const promise = service.updateProfile(USER_ID, dependent.id, { dateOfBirth: bornYearsAgo(19) });
      await expect(promise).rejects.toBeInstanceOf(ForbiddenException);
      await expect(promise).rejects.toThrow('Apenas quem cadastrou o perfil pode alterar a data de nascimento.');
      expect(tx.update).not.toHaveBeenCalled();
    });

    it('stores the profileType recomputed from a valid new DOB', async () => {
      const dependent = profileRow({ profileType: 'dependent_minor', dateOfBirth: bornYearsAgo(60) });
      const updated = { ...dependent, profileType: 'dependent_adult', dateOfBirth: bornYearsAgo(55) };
      const { tx, calls } = createTx({
        select: [[dependent], [{ relationshipType: 'curator' }]],
        update: [[updated]],
      });
      runWith(tx);

      const result = await service.updateProfile(USER_ID, dependent.id, { dateOfBirth: bornYearsAgo(55) });

      expect((calls.updateSets[0] as any).profileType).toBe('dependent_adult');
      expect((calls.updateSets[0] as any).dateOfBirth).toBe(bornYearsAgo(55));
      expect(result.profileType).toBe('dependent_adult');
    });

    it('never changes the profileType of a primary profile', async () => {
      const primary = profileRow({ dateOfBirth: '1990-04-12' });
      const { tx, calls } = createTx({ select: [[primary]], update: [[{ ...primary, dateOfBirth: '1991-04-12' }]] });
      runWith(tx);

      const result = await service.updateProfile(USER_ID, primary.id, { dateOfBirth: '1991-04-12' });

      expect((calls.updateSets[0] as any).profileType).toBeUndefined();
      expect(result.profileType).toBe('primary');
    });
  });

  describe('derived profileType (D3)', () => {
    it('derives profileType from the DOB for dependents even when the stored value is stale', async () => {
      const primary = profileRow();
      const stale = profileRow({
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        profileType: 'dependent_minor',
        dateOfBirth: bornYearsAgo(19),
      });
      const shared = profileRow({
        id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        accountOwnerId: OTHER_USER_ID,
        profileType: 'dependent_adult',
        dateOfBirth: bornYearsAgo(8),
      });
      const { tx } = createTx({
        select: [[primary, stale], [{ profile: shared, accessLevel: 'VIEW_ONLY', categories: ['habits'] }], []],
      });
      runWith(tx);

      const result = await service.getProfilesForUser(USER_ID);

      expect(result.map((p) => p.profileType)).toEqual(['primary', 'dependent_adult', 'dependent_minor']);
    });
  });

  describe('confirmLegalBasis (A3)', () => {
    const adult = profileRow({
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      profileType: 'dependent_adult',
      dateOfBirth: bornYearsAgo(45),
    });
    const guardianship = {
      id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
      relationshipType: 'curator',
      lgpdLegalBasis: 'lgpd_art_14',
    };

    it('moves the guardian\'s adult curator dependent to Art. 11, I with a new consent timestamp', async () => {
      const { tx, calls } = createTx({
        select: [[adult], [guardianship]],
        update: [[{ ...guardianship, lgpdLegalBasis: 'lgpd_art_11_i' }]],
      });
      runWith(tx);

      const before = Date.now();
      const result = await service.confirmLegalBasis(USER_ID, adult.id, true);

      const set = calls.updateSets[0] as any;
      expect(set.lgpdLegalBasis).toBe('lgpd_art_11_i');
      expect(set.lgpdConsentRecordedAt).toBeInstanceOf(Date);
      expect(set.lgpdConsentRecordedAt.getTime()).toBeGreaterThanOrEqual(before);
      expect(result).toMatchObject({
        id: adult.id,
        ownership: 'dependent',
        relationshipType: 'curator',
        lgpdLegalBasis: 'lgpd_art_11_i',
        legalBasisNeedsConfirmation: false,
      });
    });

    it('refuses anyone but the guardian with 403', async () => {
      const notMine = { ...adult, accountOwnerId: OTHER_USER_ID };
      const { tx } = createTx({ select: [[notMine], []] });
      runWith(tx);

      await expect(service.confirmLegalBasis(USER_ID, adult.id, true)).rejects.toBeInstanceOf(ForbiddenException);
      expect(tx.update).not.toHaveBeenCalled();
    });

    it('refuses the owner without an open guardianship with 403', async () => {
      const { tx } = createTx({ select: [[adult], []] });
      runWith(tx);

      await expect(service.confirmLegalBasis(USER_ID, adult.id, true)).rejects.toBeInstanceOf(ForbiddenException);
      expect(tx.update).not.toHaveBeenCalled();
    });

    it('refuses a minor with 409', async () => {
      const minor = { ...adult, profileType: 'dependent_minor', dateOfBirth: bornYearsAgo(12) };
      const { tx } = createTx({ select: [[minor], [{ ...guardianship, relationshipType: 'parent' }]] });
      runWith(tx);

      await expect(service.confirmLegalBasis(USER_ID, adult.id, true)).rejects.toBeInstanceOf(ConflictException);
      expect(tx.update).not.toHaveBeenCalled();
    });

    it('refuses without lgpdConsent true with 400 and opens no transaction', async () => {
      await expect(
        service.confirmLegalBasis(USER_ID, adult.id, false as unknown as true),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(mockDatabaseService.withRls).not.toHaveBeenCalled();

      const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
      await expect(pipe.transform({}, { type: 'body', metatype: ConfirmLegalBasisDto })).rejects.toBeInstanceOf(
        BadRequestException,
      );
      await expect(
        pipe.transform({ lgpdConsent: false }, { type: 'body', metatype: ConfirmLegalBasisDto }),
      ).rejects.toBeInstanceOf(BadRequestException);
      await expect(
        pipe.transform({ lgpdConsent: true }, { type: 'body', metatype: ConfirmLegalBasisDto }),
      ).resolves.toMatchObject({ lgpdConsent: true });
    });
  });

  describe('createHandoverCode (D3, A6)', () => {
    /** YYYY-MM-DD for someone who turned 18 yesterday (UTC). */
    const eighteenPlusOneDay = () => {
      const d = new Date();
      d.setUTCDate(d.getUTCDate() - 1);
      d.setUTCFullYear(d.getUTCFullYear() - 18);
      return d.toISOString().slice(0, 10);
    };
    const guardianship = { id: 'ffffffff-ffff-4fff-8fff-ffffffffffff', relationshipType: 'parent', lgpdLegalBasis: 'lgpd_art_14' };
    const agedOut = () =>
      profileRow({ id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', profileType: 'dependent_minor', dateOfBirth: eighteenPlusOneDay() });

    it('stores a 10-character invite-alphabet code valid for 72 h on the open guardianship', async () => {
      const { tx, calls } = createTx({ select: [[agedOut()], [guardianship]], update: [[{ id: guardianship.id }]] });
      runWith(tx);

      const before = Date.now();
      const result = await service.createHandoverCode(USER_ID, agedOut().id);

      expect(result.claimCode).toMatch(new RegExp(`^[${INVITE_CODE_CHARS}]{10}$`));
      const expectedExpiry = before + 72 * 60 * 60 * 1000;
      expect(result.expiresAt.getTime()).toBeGreaterThanOrEqual(expectedExpiry);
      expect(result.expiresAt.getTime()).toBeLessThan(expectedExpiry + 5_000);
      expect(calls.updateSets[0]).toEqual({ handoverCode: result.claimCode, handoverCodeExpiresAt: result.expiresAt });
      expect(tx.transaction).toHaveBeenCalledTimes(1);
    });

    it('retries with a new code on a unique violation', async () => {
      const { tx, calls } = createTx({ select: [[agedOut()], [guardianship]], update: [[{ id: guardianship.id }]] });
      const collision = Object.assign(new Error('duplicate key value'), { code: '23505' });
      tx.transaction.mockImplementationOnce(async () => {
        throw collision;
      });
      runWith(tx);

      const result = await service.createHandoverCode(USER_ID, agedOut().id);

      expect(tx.transaction).toHaveBeenCalledTimes(2);
      expect(calls.updateSets).toHaveLength(1);
      expect(result.claimCode).toHaveLength(10);
    });

    it('refuses a minor with 409 HANDOVER_NOT_DUE', async () => {
      const minor = profileRow({ id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', profileType: 'dependent_minor', dateOfBirth: bornYearsAgo(12) });
      const { tx } = createTx({ select: [[minor], [guardianship]] });
      runWith(tx);

      const err = await service.createHandoverCode(USER_ID, minor.id).catch((e) => e);
      expect(err).toBeInstanceOf(ConflictException);
      expect(err.getResponse()).toMatchObject({ code: 'HANDOVER_NOT_DUE' });
      expect(tx.update).not.toHaveBeenCalled();
    });

    it('refuses an adult curator dependent with 409 HANDOVER_NOT_DUE', async () => {
      const adult = profileRow({ id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', profileType: 'dependent_adult', dateOfBirth: bornYearsAgo(40) });
      const { tx } = createTx({ select: [[adult], [{ ...guardianship, relationshipType: 'curator' }]] });
      runWith(tx);

      const err = await service.createHandoverCode(USER_ID, adult.id).catch((e) => e);
      expect(err).toBeInstanceOf(ConflictException);
      expect(err.getResponse()).toMatchObject({ code: 'HANDOVER_NOT_DUE' });
    });

    it('refuses a profile the caller does not own with 409 and an invisible one with 403', async () => {
      const shared = { ...agedOut(), accountOwnerId: OTHER_USER_ID };
      const first = createTx({ select: [[shared]] });
      runWith(first.tx);
      const err = await service.createHandoverCode(USER_ID, shared.id).catch((e) => e);
      expect(err).toBeInstanceOf(ConflictException);
      expect(err.getResponse()).toMatchObject({ code: 'HANDOVER_NOT_DUE' });

      const second = createTx({ select: [[]] });
      runWith(second.tx);
      await expect(service.createHandoverCode(USER_ID, shared.id)).rejects.toBeInstanceOf(ForbiddenException);
      expect(second.tx.update).not.toHaveBeenCalled();
    });
  });

  describe('claimProfile (D3, A4, A5)', () => {
    const claimed = profileRow({ id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', profileType: 'primary', name: 'Lucas Souza' });
    const CODE = 'ABCDEFGH23';
    const refusal = (name: string) => Object.assign(new Error(name), { code: 'P0001' });

    it('claims through claim_dependent_profile and returns the profile as the caller\'s own primary', async () => {
      const { tx } = createTx({ execute: [{ rows: [{ profile_id: claimed.id }] }], select: [[claimed]] });
      runWith(tx);

      const result = await service.claimProfile(USER_ID, ` ${CODE.toLowerCase()} `);

      expect(tx.execute).toHaveBeenCalledTimes(1);
      const query = tx.execute.mock.calls[0][0];
      expect(JSON.stringify(query.queryChunks)).toContain('claim_dependent_profile');
      expect(query.queryChunks).toContain(CODE);
      expect(result).toMatchObject({ id: claimed.id, ownership: 'own', accessLevel: 'OWNER', profileType: 'primary' });
    });

    it('answers 404 CLAIM_INVALID_CODE when the function returns NULL, without the code in the message', async () => {
      const { tx } = createTx({ execute: [{ rows: [{ profile_id: null }] }] });
      runWith(tx);

      const err = await service.claimProfile(USER_ID, CODE).catch((e) => e);
      expect(err).toBeInstanceOf(NotFoundException);
      expect(err.getResponse()).toMatchObject({ code: 'CLAIM_INVALID_CODE' });
      expect(JSON.stringify(err.getResponse())).not.toContain(CODE);
    });

    it.each([
      ['CLAIM_BY_GUARDIAN', 403],
      ['CLAIM_NOT_ADULT', 409],
      ['CLAIM_ACCOUNT_HAS_DATA', 409],
    ])('maps %s to %i with the code', async (name, status) => {
      const { tx } = createTx({ execute: [refusal(name)] });
      runWith(tx);

      const err = await service.claimProfile(USER_ID, CODE).catch((e) => e);
      expect(err).toBeInstanceOf(HttpException);
      expect(err.getStatus()).toBe(status);
      expect(err.getResponse()).toMatchObject({ code: name });
    });

    it('refuses the sixth attempt in 15 minutes with 429 before reaching the database', async () => {
      const { tx } = createTx({ execute: Array.from({ length: 6 }, () => ({ rows: [{ profile_id: null }] })) });
      runWith(tx);

      for (let i = 0; i < 5; i++) {
        await expect(service.claimProfile(USER_ID, CODE)).rejects.toBeInstanceOf(NotFoundException);
      }
      const err = await service.claimProfile(USER_ID, CODE).catch((e) => e);
      expect(err).toBeInstanceOf(HttpException);
      expect(err.getStatus()).toBe(429);
      expect(tx.execute).toHaveBeenCalledTimes(5);

      // Another account keeps its own budget.
      await expect(service.claimProfile(OTHER_USER_ID, CODE)).rejects.toBeInstanceOf(NotFoundException);
    });

    it('validates the body: trimmed string of 10 to 12 characters', async () => {
      const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
      const run = (body: unknown) => pipe.transform(body, { type: 'body', metatype: ClaimProfileDto });

      await expect(run({})).rejects.toBeInstanceOf(BadRequestException);
      await expect(run({ claimCode: '' })).rejects.toBeInstanceOf(BadRequestException);
      await expect(run({ claimCode: 'ABC' })).rejects.toBeInstanceOf(BadRequestException);
      await expect(run({ claimCode: 12345678901 })).rejects.toBeInstanceOf(BadRequestException);
      await expect(run({ claimCode: ` ${CODE} ` })).resolves.toMatchObject({ claimCode: CODE });
    });
  });

  describe('deleteProfile', () => {
    it('refuses to delete the primary profile with 400', async () => {
      const { tx } = createTx({ select: [[profileRow()]] });
      runWith(tx);

      await expect(service.deleteProfile(USER_ID, profileRow().id)).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(tx.delete).not.toHaveBeenCalled();
    });

    it('refuses to delete a profile owned by someone else with 403', async () => {
      const { tx } = createTx({
        select: [[profileRow({ accountOwnerId: OTHER_USER_ID, profileType: 'dependent_minor' })]],
      });
      runWith(tx);

      await expect(service.deleteProfile(USER_ID, profileRow().id)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(tx.delete).not.toHaveBeenCalled();
    });

    it('deletes an owned dependent', async () => {
      const dependent = profileRow({ profileType: 'dependent_minor' });
      const { tx, calls } = createTx({ select: [[dependent]], delete: [[]] });
      runWith(tx);

      await expect(service.deleteProfile(USER_ID, dependent.id)).resolves.toBeUndefined();
      expect(calls.deleteTables).toEqual([profiles]);
    });
  });
});
