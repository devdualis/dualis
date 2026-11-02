import { describe, it, expect, beforeEach, vi } from 'vitest';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException, BadRequestException } from '@nestjs/common';
import { AuthService } from '../../src/modules/auth/auth.service';
import * as passwordUtil from '../../src/modules/auth/utils/password.util';

describe('AuthService - LGPD Data Sovereignty & Account Deletion (SEC-03)', () => {
  let authService: AuthService;
  let mockDb: any;
  let mockJwtService: any;
  let mockEncryptionService: any;
  let mockTxExecute: any;
  let mockTxSelect: any;
  let mockTxDelete: any;

  const mockUserId = '88888888-8888-8888-8888-888888888888';
  const mockUser = {
    id: mockUserId,
    name: 'Maria Santos',
    email: 'maria.santos@exemplo.com.br',
    passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$fakehash',
    gender: 'feminino',
    dateOfBirth: '1992-07-20',
    createdAt: new Date('2026-01-01T10:00:00Z'),
    updatedAt: new Date('2026-01-01T10:00:00Z'),
  };

  beforeEach(() => {
    mockTxExecute = vi.fn().mockResolvedValue(undefined);
    mockTxSelect = vi.fn();
    mockTxDelete = vi.fn().mockReturnValue({
      where: vi.fn().mockResolvedValue(undefined),
    });

    mockDb = {
      transaction: vi.fn().mockImplementation(async (callback) => {
        const mockTx = {
          execute: mockTxExecute,
          select: mockTxSelect,
          delete: mockTxDelete,
        };
        return callback(mockTx);
      }),
    };

    mockJwtService = {
      sign: vi.fn().mockReturnValue('mock-token'),
    };

    mockEncryptionService = {
      encrypt: vi.fn().mockReturnValue('encrypted-val'),
      decrypt: vi.fn().mockImplementation((val) => `decrypted:${val}`),
    };

    const mockEmailService = {
      generateVerificationCode: vi.fn().mockReturnValue('123456'),
      hashCode: vi.fn().mockReturnValue('mock-hash-123456'),
      verifyCodeHash: vi.fn().mockReturnValue(true),
      sendVerificationEmail: vi.fn().mockResolvedValue(undefined),
      getLastSentCode: vi.fn().mockReturnValue('123456'),
    };

    authService = new AuthService(
      mockDb,
      mockJwtService as unknown as JwtService,
      mockEncryptionService,
      mockEmailService as any,
    );
  });

  describe('exportUserData', () => {
    it('throws UnauthorizedException when user does not exist', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),
          }),
        }),
      });

      await expect(authService.exportUserData(mockUserId)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    const primaryProfileId = '11111111-1111-1111-1111-111111111111';
    const dependentProfileId = '22222222-2222-2222-2222-222222222222';

    const mockSelectSequence = (results: any[]) => {
      let callCount = 0;
      mockTxSelect.mockImplementation(() => {
        const rows = results[callCount++] ?? [];
        // First query (users) ends with .limit(); the rest resolve at .where().
        if (callCount === 1) {
          return {
            from: vi.fn().mockReturnValue({
              where: vi.fn().mockReturnValue({ limit: vi.fn().mockResolvedValue(rows) }),
            }),
          };
        }
        return {
          from: vi.fn().mockReturnValue({ where: vi.fn().mockResolvedValue(rows) }),
        };
      });
    };

    const consent = {
      id: 'consent-1',
      disclaimerVersion: '2026.1',
      acceptedAt: new Date('2026-01-01T10:00:00Z'),
      ipAddressHash: 'hash123',
      userAgent: 'Flutter/iOS',
    };

    const ownedProfiles = [
      {
        id: dependentProfileId,
        accountOwnerId: mockUserId,
        profileType: 'dependent_minor',
        name: 'Lucas Santos',
        dateOfBirth: '2018-03-10',
        gender: 'masculino',
        createdAt: new Date('2026-02-01T10:00:00Z'),
      },
      {
        id: primaryProfileId,
        accountOwnerId: mockUserId,
        profileType: 'primary',
        name: 'Maria Santos',
        dateOfBirth: '1992-07-20',
        gender: 'feminino',
        createdAt: new Date('2026-01-01T10:00:00Z'),
      },
    ];

    const symptomRow = (id: string, profileId: string) => ({
      id,
      userId: mockUserId,
      profileId,
      intensity: 3,
      anatomicalSystem: 'respiratorio',
      emotionalDimension: null,
      disposition: 'consulta_eletiva',
      organicPrimacyApplied: true,
      encryptedNarrative: 'narrativa_cifrada',
      stepAnswers: JSON.stringify({ question1: 'tosse leve' }),
      recordedAt: new Date('2026-01-05T14:00:00Z'),
    });

    it('exports complete user data package with decrypted narratives and parsed answers', async () => {
      mockSelectSequence([
        [mockUser],
        [consent],
        ownedProfiles,
        [symptomRow('log-1', primaryProfileId)],
        [
          {
            id: 'safety-1',
            userId: mockUserId,
            profileId: primaryProfileId,
            action: 'call_started',
            channel: 'tel:192',
            clientTimestamp: new Date('2026-01-08T09:30:00Z'),
            createdAt: new Date('2026-01-08T09:30:01Z'),
          },
        ],
        [],
      ]);

      const result = await authService.exportUserData(mockUserId);

      expect(result.metadata.legalBasis).toContain('LGPD Art. 18, V');
      expect(result.profile.id).toBe(mockUserId);
      expect(result.profile.email).toBe('maria.santos@exemplo.com.br');
      expect(result.consents).toHaveLength(1);
      expect(result.consents[0].disclaimerVersion).toBe('2026.1');
      expect(result.symptomLogs).toHaveLength(1);
      expect(result.symptomLogs[0].decryptedNarrative).toBe('decrypted:narrativa_cifrada');
      expect(result.symptomLogs[0].stepAnswers).toEqual({ question1: 'tosse leve' });
      // Former assessment fields are exported only inside the labelled legacy block.
      expect(result.symptomLogs[0].legacy).toEqual({ disposition: 'consulta_eletiva', organicPrimacyApplied: true });
      expect(result.symptomLogs[0]).not.toHaveProperty('disposition');
      expect(result.metadata.legacyFieldsNote).toContain('legacy');
      expect(result.safetyResourceEvents).toEqual([
        {
          id: 'safety-1',
          action: 'call_started',
          channel: 'tel:192',
          clientTimestamp: '2026-01-08T09:30:00.000Z',
          createdAt: '2026-01-08T09:30:01.000Z',
        },
      ]);
      expect(result.waterIntakeLogs).toEqual([]);
      expect(mockEncryptionService.decrypt).toHaveBeenCalledWith('narrativa_cifrada');
    });

    it('groups owned dependents clinical data per profile, apart from the primary profile', async () => {
      mockSelectSequence([
        [mockUser],
        [consent],
        ownedProfiles,
        [symptomRow('log-own', primaryProfileId), symptomRow('log-lucas', dependentProfileId)],
        [],
        [
          {
            id: 'water-lucas',
            profileId: dependentProfileId,
            amountMl: 200,
            source: 'manual',
            recordedAt: new Date('2026-02-02T08:00:00Z'),
          },
        ],
      ]);

      const result = await authService.exportUserData(mockUserId);

      expect(result.symptomLogs.map((l) => l.id)).toEqual(['log-own']);
      expect(result.waterIntakeLogs).toEqual([]);
      expect(result.dependentProfiles).toHaveLength(1);

      const lucas = result.dependentProfiles[0];
      expect(lucas.profile).toEqual({
        id: dependentProfileId,
        name: 'Lucas Santos',
        profileType: 'dependent_minor',
        dateOfBirth: '2018-03-10',
        gender: 'masculino',
        createdAt: '2026-02-01T10:00:00.000Z',
      });
      expect(lucas.symptomLogs.map((l) => l.id)).toEqual(['log-lucas']);
      expect(lucas.safetyResourceEvents).toEqual([]);
      expect(lucas.waterIntakeLogs).toEqual([
        { id: 'water-lucas', amountMl: 200, source: 'manual', recordedAt: '2026-02-02T08:00:00.000Z' },
      ]);
    });

    it('exports journal entries, their items and the person\'s conditions, decrypted, per profile', async () => {
      const entry = (id: string, profileId: string, recordedAt: string) => ({
        id,
        userId: mockUserId,
        profileId,
        clientId: `client-${id}`,
        recordedAt: new Date(recordedAt),
        mood: 'nao_tao_bem',
        triggers: ['sono'],
        triggerNote: 'v1:mudança',
        note: 'v1:dia corrido',
        transitionVariantIds: ['futuro.intro.1'],
        createdAt: new Date(recordedAt),
      });
      mockSelectSequence([
        [mockUser],
        [consent],
        ownedProfiles,
        [],
        [],
        [],
        [
          entry('entry-old', primaryProfileId, '2026-10-01T10:00:00Z'),
          entry('entry-new', primaryProfileId, '2026-10-20T10:00:00Z'),
          entry('entry-lucas', dependentProfileId, '2026-10-21T10:00:00Z'),
        ],
        [
          { id: 'item-1', entryId: 'entry-new', kind: 'physical', optionKey: 'costas.custom', customLabel: 'v1:nuca dura', conditionId: null, bodySide: 'back', persistence: 'hoje', intensity: 4 },
          { id: 'item-2', entryId: 'entry-new', kind: 'condition', optionKey: null, customLabel: null, conditionId: 'cond-1', bodySide: null, persistence: null, intensity: 3 },
          { id: 'item-3', entryId: 'entry-lucas', kind: 'emotional', optionKey: 'futuro.mente.antecipar', customLabel: null, conditionId: null, bodySide: null, persistence: 'hoje', intensity: 2 },
        ],
        [
          { id: 'cond-1', userId: mockUserId, profileId: primaryProfileId, label: 'v1:Enxaqueca', tracking: ['blood_pressure'], createdAt: new Date('2026-09-01T10:00:00Z'), archivedAt: new Date('2026-10-25T10:00:00Z') },
        ],
        [], // daily habits
        [
          { id: 'reading-1', userId: mockUserId, profileId: primaryProfileId, entryId: 'entry-new', conditionId: 'cond-1', kind: 'blood_pressure', measuredAt: new Date('2026-10-20T09:00:00Z'), data: 'v1:json', createdAt: new Date('2026-10-20T10:00:00Z') },
          { id: 'reading-2', userId: mockUserId, profileId: primaryProfileId, entryId: 'entry-new', conditionId: 'cond-1', kind: 'blood_pressure', measuredAt: new Date('2026-10-20T09:30:00Z'), data: 'v1:json', createdAt: new Date('2026-10-20T10:00:00Z') },
        ],
      ]);
      mockEncryptionService.decrypt.mockImplementation((val: string) =>
        val === 'v1:json' ? '{"systolic":130,"diastolic":85,"pulse":null}' : `decrypted:${val}`,
      );

      const result = await authService.exportUserData(mockUserId);

      expect(result.metadata.formatVersion).toBe('1.5');
      expect(result.journalEntries.map((e) => e.id)).toEqual(['entry-new', 'entry-old']);
      expect(result.journalEntries[0]).toEqual({
        coping: null,
        helpers: [],
        id: 'entry-new',
        clientId: 'client-entry-new',
        recordedAt: '2026-10-20T10:00:00.000Z',
        mood: 'nao_tao_bem',
        triggers: ['sono'],
        triggerNote: 'decrypted:v1:mudança',
        note: 'decrypted:v1:dia corrido',
        createdAt: '2026-10-20T10:00:00.000Z',
        items: [
          { id: 'item-1', kind: 'physical', optionKey: 'costas.custom', customLabel: 'decrypted:v1:nuca dura', conditionId: null, conditionLabel: null, bodySide: 'back', persistence: 'hoje', intensity: 4 },
          { id: 'item-2', kind: 'condition', optionKey: null, customLabel: null, conditionId: 'cond-1', conditionLabel: 'decrypted:v1:Enxaqueca', bodySide: null, persistence: null, intensity: 3 },
        ],
      });
      expect(result.journalEntries[1].items).toEqual([]);
      expect(result.userConditions).toEqual([
        { id: 'cond-1', label: 'decrypted:v1:Enxaqueca', tracking: ['blood_pressure'], createdAt: '2026-09-01T10:00:00.000Z', archivedAt: '2026-10-25T10:00:00.000Z' },
      ]);
      // Readings as typed, newest first, with the condition's name.
      expect(result.conditionReadings.map((r) => r.id)).toEqual(['reading-2', 'reading-1']);
      expect(result.conditionReadings[1]).toEqual({
        id: 'reading-1',
        entryId: 'entry-new',
        conditionId: 'cond-1',
        conditionLabel: 'decrypted:v1:Enxaqueca',
        kind: 'blood_pressure',
        measuredAt: '2026-10-20T09:00:00.000Z',
        values: { systolic: 130, diastolic: 85, pulse: null },
        createdAt: '2026-10-20T10:00:00.000Z',
      });
      const lucas = result.dependentProfiles[0];
      expect(lucas.journalEntries.map((e) => e.id)).toEqual(['entry-lucas']);
      expect(lucas.journalEntries[0].items.map((i) => i.optionKey)).toEqual(['futuro.mente.antecipar']);
      expect(lucas.userConditions).toEqual([]);
      expect(lucas.conditionReadings).toEqual([]);
      expect(JSON.stringify(result)).not.toMatch(/"v1:/);
    });

    it('exports "Meus cuidados" records and documents per profile, decrypted, without loading files', async () => {
      // Care data is encrypted JSON; 'v1:broken' stands for a value that no longer decrypts.
      mockEncryptionService.decrypt.mockImplementation((val: string) => {
        if (val === 'v1:broken') throw new Error('unsupported state or unable to authenticate data');
        return val.startsWith('v1:json:') ? val.slice('v1:json:'.length) : `decrypted:${val}`;
      });
      const careRecord = (
        id: string,
        profileId: string,
        kind: string,
        occursAt: string | null,
        data: string,
        parentId: string | null = null,
      ) => ({
        id,
        userId: mockUserId,
        profileId,
        kind,
        parentId,
        occursAt: occursAt ? new Date(occursAt) : null,
        data,
        createdAt: new Date('2026-10-01T10:00:00Z'),
        updatedAt: new Date('2026-10-02T10:00:00Z'),
      });
      mockSelectSequence([
        [mockUser],
        [consent],
        ownedProfiles,
        [], // symptom logs
        [], // safety events
        [], // water
        [], // journal entries (no items query)
        [], // conditions
        [], // daily habits
        [], // condition readings
        [
          careRecord('vac-1', primaryProfileId, 'vaccine_dose', '2026-03-10T00:00:00Z', 'v1:json:{"vaccine":"Influenza","doseLabel":"Anual"}'),
          careRecord('med-1', primaryProfileId, 'medication', null, 'v1:json:{"name":"Vitamina D","stockCount":20}'),
          careRecord('intake-1', primaryProfileId, 'medication_intake', '2026-10-20T08:00:00Z', 'v1:json:{"action":"taken"}', 'med-1'),
          careRecord('appt-lucas', dependentProfileId, 'appointment', '2026-11-05T14:00:00Z', 'v1:broken'),
        ],
        [
          {
            id: 'doc-1',
            profileId: primaryProfileId,
            kind: 'lab',
            mime: 'application/pdf',
            sizeBytes: 120000,
            status: 'ready',
            data: 'v1:json:{"title":"Exames de rotina","values":[{"item":"Glicose","value":"90","confirmed":true}]}',
            createdAt: new Date('2026-10-10T10:00:00Z'),
            updatedAt: new Date('2026-10-11T10:00:00Z'),
          },
        ],
      ]);

      const result = await authService.exportUserData(mockUserId);

      expect(result.metadata.formatVersion).toBe('1.5');
      expect(result.metadata.careDocumentsNote).toContain('arquivos originais');
      // Newest first by date of the record (dose, intake, appointment), else by creation.
      expect(result.careRecords.map((r) => r.id)).toEqual(['intake-1', 'med-1', 'vac-1']);
      expect(result.careRecords[0]).toEqual({
        id: 'intake-1',
        kind: 'medication_intake',
        parentId: 'med-1',
        occursAt: '2026-10-20T08:00:00.000Z',
        data: { action: 'taken' },
        createdAt: '2026-10-01T10:00:00.000Z',
        updatedAt: '2026-10-02T10:00:00.000Z',
      });
      expect(result.careRecords[1]).toMatchObject({ id: 'med-1', occursAt: null, data: { name: 'Vitamina D', stockCount: 20 } });
      expect(result.careDocuments).toEqual([
        {
          id: 'doc-1',
          kind: 'lab',
          mime: 'application/pdf',
          sizeBytes: 120000,
          status: 'ready',
          data: { title: 'Exames de rotina', values: [{ item: 'Glicose', value: '90', confirmed: true }] },
          createdAt: '2026-10-10T10:00:00.000Z',
          updatedAt: '2026-10-11T10:00:00.000Z',
        },
      ]);

      const lucas = result.dependentProfiles[0];
      expect(lucas.careRecords).toEqual([expect.objectContaining({ id: 'appt-lucas', kind: 'appointment', data: null })]);
      expect(lucas.careDocuments).toEqual([]);
      expect(JSON.stringify(result)).not.toMatch(/"v1:/);

      // The document query lists its columns and never asks for the file bytes.
      const documentColumns = Object.keys(mockTxSelect.mock.calls.at(-1)[0]);
      expect(documentColumns).toEqual(expect.arrayContaining(['id', 'profileId', 'kind', 'mime', 'sizeBytes', 'status', 'data']));
      expect(documentColumns).not.toContain('file');
      expect(documentColumns).not.toContain('fileHmac');
    });

    it('skips clinical queries when the account owns no profile yet', async () => {
      mockSelectSequence([[mockUser], [], []]);

      const result = await authService.exportUserData(mockUserId);

      expect(mockTxSelect).toHaveBeenCalledTimes(3);
      expect(result.symptomLogs).toEqual([]);
      expect(result.safetyResourceEvents).toEqual([]);
      expect(result.waterIntakeLogs).toEqual([]);
      expect(result.journalEntries).toEqual([]);
      expect(result.userConditions).toEqual([]);
      expect(result.careRecords).toEqual([]);
      expect(result.careDocuments).toEqual([]);
      expect(result.dependentProfiles).toEqual([]);
    });
  });

  describe('deleteUserAccount', () => {
    it('throws UnauthorizedException when user does not exist', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),
          }),
        }),
      });

      await expect(
        authService.deleteUserAccount(mockUserId, { password: 'Password123!' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws BadRequestException when password confirmation does not match', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([mockUser]),
          }),
        }),
      });

      vi.spyOn(passwordUtil, 'verifyPassword').mockResolvedValue(false);

      await expect(
        authService.deleteUserAccount(mockUserId, { password: 'WrongPassword!' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('deletes user record under RLS when password is valid', async () => {
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([mockUser]),
          }),
        }),
      });

      vi.spyOn(passwordUtil, 'verifyPassword').mockResolvedValue(true);

      const res = await authService.deleteUserAccount(mockUserId, {
        password: 'ValidPassword123!',
      });

      expect(res.success).toBe(true);
      expect(res.message).toContain('LGPD Art. 18, VI');
      expect(mockTxDelete).toHaveBeenCalled();
    });

    it('deletes the uploaded pictures after the account row, never on a wrong password', async () => {
      const storage = { removeAvatars: vi.fn().mockResolvedValue(undefined) };
      authService = new AuthService(
        mockDb,
        mockJwtService as unknown as JwtService,
        mockEncryptionService,
        {} as any,
        storage as any,
      );
      mockTxSelect.mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([mockUser]),
          }),
        }),
      });

      vi.spyOn(passwordUtil, 'verifyPassword').mockResolvedValue(false);
      await expect(
        authService.deleteUserAccount(mockUserId, { password: 'WrongPassword!' }),
      ).rejects.toThrow(BadRequestException);
      expect(storage.removeAvatars).not.toHaveBeenCalled();

      vi.spyOn(passwordUtil, 'verifyPassword').mockResolvedValue(true);
      await authService.deleteUserAccount(mockUserId, { password: 'ValidPassword123!' });

      expect(storage.removeAvatars).toHaveBeenCalledWith(mockUserId);
      expect(mockTxDelete.mock.invocationCallOrder[0]).toBeLessThan(
        storage.removeAvatars.mock.invocationCallOrder[0],
      );
    });
  });
});
