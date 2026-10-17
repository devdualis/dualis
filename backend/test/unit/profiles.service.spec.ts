import { describe, it, expect, beforeEach, vi } from 'vitest';
import { BadRequestException, ForbiddenException, ValidationPipe } from '@nestjs/common';
import { ProfilesService, ageInYears } from '../../src/modules/profiles/profiles.service';
import { CreateDependentDto } from '../../src/modules/profiles/dto/create-dependent.dto';
import { profiles } from '../../src/database/schema/profiles.schema';
import { legalGuardianships } from '../../src/database/schema/legal-guardianships.schema';

const USER_ID = '11111111-1111-4111-8111-111111111111';
const OTHER_USER_ID = '22222222-2222-4222-8222-222222222222';

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
function createTx(results: { select?: unknown[][]; insert?: unknown[][]; update?: unknown[][]; delete?: unknown[][] }) {
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

  const tx = {
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

  const runWith = (tx: unknown) =>
    mockDatabaseService.withRls.mockImplementation(async (_userId: string, cb: any) => cb(tx));

  beforeEach(() => {
    mockDatabaseService = { withRls: vi.fn() };
    service = new ProfilesService(mockDatabaseService);
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
        avatarUrl: null,
        ownership: 'dependent',
        accessLevel: 'OWNER',
      });
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

  describe('updateProfile', () => {
    const shared = profileRow({
      id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      accountOwnerId: OTHER_USER_ID,
      profileType: 'dependent_minor',
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
