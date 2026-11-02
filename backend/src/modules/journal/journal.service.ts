import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { and, asc, desc, eq, gte, inArray, isNull, sql } from 'drizzle-orm';
import { DatabaseService, DrizzleTransaction } from '../../database/database.service';
import { conditionReadings, journalEntries, journalItems, symptomLogs, userConditions } from '../../database/schema';
import { EncryptionService } from '../../common/encryption/encryption.service';
import { Lang, Localized, resolveLang } from '../../common/i18n/lang';
import { GlucoseMoment, JOURNAL_LIMITS, READING_INPUT_LIMITS, TrackingKind } from './constants/journal-keys.constant';
import {
  ConditionReadingDto,
  ConditionReadingInputDto,
  ConditionReadingsQueryDto,
  CreateJournalEntryDto,
  journalEntryShapeError,
  journalItemShapeError,
  JournalDaysQueryDto,
  JournalEntriesResponseDto,
  JournalEntryDto,
  JournalItemDto,
  JournalSummaryDto,
  LegacyJournalEntryDto,
  LegacyJournalItemDto,
  UpdateConditionDto,
  UserConditionDto,
  UserConditionsResponseDto,
} from './dto/journal.dto';
import { buildJournalSummary } from './journal-summary';

type EntryRow = typeof journalEntries.$inferSelect;
type ItemRow = typeof journalItems.$inferSelect;
type LegacyRow = typeof symptomLogs.$inferSelect;
type ReadingRow = typeof conditionReadings.$inferSelect;

/** Only the value fields of a reading, in a fixed order. Kind and time stay in their columns. */
function readingValues(r: ConditionReadingInputDto): Record<string, unknown> {
  switch (r.kind) {
    case 'blood_pressure':
      return { systolic: r.systolic, diastolic: r.diastolic, pulse: r.pulse ?? null };
    case 'glucose':
      return { mgdl: r.mgdl, moment: r.moment };
    case 'weight':
      return { kg: r.kg };
  }
}

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Plain-language names for the values old app versions stored in symptom_logs, keyed
 * by those stored values. Only used to show old rows as "registro anterior".
 */
const OLD_BODY_LABELS: Record<string, Localized> = {
  cabeca_pescoco: { pt: 'Cabeça e pescoço', en: 'Head and neck', es: 'Cabeza y cuello' },
  cardiovascular_torax: { pt: 'Peito', en: 'Chest', es: 'Pecho' },
  respiratorio: { pt: 'Respiração', en: 'Breathing', es: 'Respiración' },
  gastrointestinal_abdomen: { pt: 'Barriga e estômago', en: 'Stomach and belly', es: 'Estómago y vientre' },
  coluna_dor_dorsal: { pt: 'Costas', en: 'Back', es: 'Espalda' },
  membros_superiores: { pt: 'Braços e mãos', en: 'Arms and hands', es: 'Brazos y manos' },
  membros_inferiores: { pt: 'Pernas e pés', en: 'Legs and feet', es: 'Piernas y pies' },
  neurologico: { pt: 'Tontura e equilíbrio', en: 'Dizziness and balance', es: 'Mareo y equilibrio' },
  geniturinario_pelvico: { pt: 'Baixo ventre e urina', en: 'Lower belly and urination', es: 'Bajo vientre y orina' },
  dermatologico: { pt: 'Pele', en: 'Skin', es: 'Piel' },
  muscular_geral_sistemico: { pt: 'Corpo todo', en: 'Whole body', es: 'Todo el cuerpo' },
  endocrino_metabolico: { pt: 'Energia e apetite', en: 'Energy and appetite', es: 'Energía y apetito' },
};

const OLD_MOOD_LABELS: Record<string, Localized> = {
  ansiosa_agitacao: { pt: 'Ansiedade e agitação', en: 'Anxious and restless', es: 'Ansiedad e inquietud' },
  depressiva_desanimo: { pt: 'Pra baixo', en: 'Feeling down', es: 'Decaído(a)' },
  estresse_burnout: { pt: 'Estressado(a) ou esgotado(a)', en: 'Stressed or worn out', es: 'Estresado(a) o agotado(a)' },
  somatica: { pt: 'Emoções sentidas no corpo', en: 'Emotions felt in the body', es: 'Emociones sentidas en el cuerpo' },
  sono: { pt: 'Sono ruim', en: 'Poor sleep', es: 'Dormir mal' },
  cognitiva_foco: { pt: 'Cansaço mental e foco', en: 'Mental tiredness and focus', es: 'Cansancio mental y concentración' },
  autoestima: { pt: 'Autoestima', en: 'Self-esteem', es: 'Autoestima' },
};

@Injectable()
export class JournalService {
  constructor(
    @Inject(DatabaseService) private readonly databaseService: DatabaseService,
    @Inject(EncryptionService) private readonly encryptionService: EncryptionService,
  ) {}

  // Entries

  async createEntry(userId: string, profileId: string, dto: CreateJournalEntryDto): Promise<JournalEntryDto> {
    this.assertIds(userId, profileId);
    const shapeError = journalEntryShapeError(dto) ?? dto.items.map(journalItemShapeError).find(Boolean);
    if (shapeError) throw new BadRequestException(shapeError);
    const recordedAt = new Date(dto.recordedAt);
    if (isNaN(recordedAt.getTime())) throw new BadRequestException('recordedAt inválido.');

    return this.databaseService.withRls(userId, async (tx) => {
      const existing = await this.findByClientId(tx, profileId, dto.clientId);
      if (existing) return this.replay(tx, existing, profileId);

      const conditionIds = [...new Set(dto.items.filter((i) => i.kind === 'condition').map((i) => i.conditionId!))];
      const conditionLabels = await this.conditionLabels(tx, profileId, conditionIds);
      if (conditionLabels.size !== conditionIds.length) {
        throw new BadRequestException('Condição não encontrada para este perfil.');
      }

      const [entry] = await tx
        .insert(journalEntries)
        .values({
          userId,
          profileId,
          recordedAt,
          mood: dto.mood,
          area: dto.area ?? null,
          triggers: [...new Set(dto.triggers)],
          coping: dto.coping ?? null,
          helpers: dto.helpers ?? [],
          triggerNote: this.encryptOptional(dto.triggerNote),
          note: this.encryptOptional(dto.note),
          transitionVariantIds: dto.transitionVariantIds,
          clientId: dto.clientId,
        })
        .onConflictDoNothing({ target: [journalEntries.profileId, journalEntries.clientId] })
        .returning();

      if (!entry) {
        // Concurrent retry of the same outbox record on this profile: replay it. The
        // clientId is unique per profile, so another profile's entry never collides.
        const raced = await this.findByClientId(tx, profileId, dto.clientId);
        if (raced) return this.replay(tx, raced, profileId);
        throw new ConflictException('clientId em conflito.');
      }

      const items = dto.items.length
        ? await tx
            .insert(journalItems)
            .values(
              dto.items.map((item) => ({
                entryId: entry.id,
                kind: item.kind,
                optionKey: item.kind === 'condition' ? null : item.optionKey!,
                customLabel: item.kind === 'condition' ? null : this.encryptOptional(item.customLabel?.trim()),
                conditionId: item.kind === 'condition' ? item.conditionId! : null,
                bodySide: item.kind === 'physical' ? (item.bodySide ?? null) : null,
                sensation: item.kind === 'physical' ? (item.sensation ?? null) : null,
                persistence: item.persistence ?? null,
                intensity: item.intensity ?? null,
              })),
            )
            .returning()
        : [];

      // Readings ride on their condition item, in the same transaction as the entry, so a
      // replayed clientId never stores them twice. Values are encrypted; only this module and
      // the LGPD export read them.
      const readingRows = dto.items.flatMap((item) =>
        item.kind === 'condition' && item.readings?.length
          ? item.readings.map((r) => ({
              userId,
              profileId,
              entryId: entry.id,
              conditionId: item.conditionId!,
              kind: r.kind,
              measuredAt: new Date(r.measuredAt),
              data: this.encryptionService.encrypt(JSON.stringify(readingValues(r))),
            }))
          : [],
      );
      const readings = readingRows.length ? await tx.insert(conditionReadings).values(readingRows).returning() : [];

      return this.toEntryDto(entry, items, conditionLabels, readings);
    });
  }

  async listEntries(
    userId: string,
    profileId: string,
    query: JournalDaysQueryDto,
    acceptLanguage?: string,
  ): Promise<JournalEntriesResponseDto> {
    this.assertIds(userId, profileId);
    const cutoff = this.cutoff(query.days);
    const lang = resolveLang(acceptLanguage);

    return this.databaseService.withRls(userId, async (tx) => {
      const { entries, itemsByEntry, conditionLabels, readings } = await this.loadEntries(tx, profileId, cutoff);
      const legacyRows = await tx
        .select()
        .from(symptomLogs)
        .where(and(eq(symptomLogs.profileId, profileId), gte(symptomLogs.recordedAt, cutoff)))
        .orderBy(desc(symptomLogs.recordedAt));

      const merged: Array<JournalEntryDto | LegacyJournalEntryDto> = [
        ...entries.map((e) => this.toEntryDto(e, itemsByEntry.get(e.id) ?? [], conditionLabels, readings)),
        ...legacyRows.map((row) => this.toLegacyDto(row, lang)),
      ];
      merged.sort((a, b) => b.recordedAt.localeCompare(a.recordedAt));
      return { entries: merged };
    });
  }

  /** Deletes a v2 entry (items cascade) or, for old app data, a legacy symptom_logs row. */
  async deleteEntry(userId: string, profileId: string, id: string): Promise<void> {
    this.assertIds(userId, profileId);
    await this.databaseService.withRls(userId, async (tx) => {
      const deleted = await tx
        .delete(journalEntries)
        .where(and(eq(journalEntries.id, id), eq(journalEntries.profileId, profileId)))
        .returning({ id: journalEntries.id });
      if (deleted.length) return;

      const legacy = await tx
        .delete(symptomLogs)
        .where(and(eq(symptomLogs.id, id), eq(symptomLogs.profileId, profileId)))
        .returning({ id: symptomLogs.id });
      if (!legacy.length) throw new NotFoundException('Registro não encontrado.');
    });
  }

  async summary(userId: string, profileId: string, query: JournalDaysQueryDto): Promise<JournalSummaryDto> {
    this.assertIds(userId, profileId);
    const days = query.days ?? JOURNAL_LIMITS.defaultDays;
    const cutoff = this.cutoff(days);

    return this.databaseService.withRls(userId, async (tx) => {
      // Only keys are read: no free text and no condition labels reach the summary.
      const entries = await tx
        .select({ id: journalEntries.id, recordedAt: journalEntries.recordedAt, triggers: journalEntries.triggers, coping: journalEntries.coping, helpers: journalEntries.helpers })
        .from(journalEntries)
        .where(and(eq(journalEntries.profileId, profileId), gte(journalEntries.recordedAt, cutoff)));
      const items = entries.length
        ? await tx
            .select({ entryId: journalItems.entryId, kind: journalItems.kind, optionKey: journalItems.optionKey })
            .from(journalItems)
            .where(inArray(journalItems.entryId, entries.map((e) => e.id)))
        : [];

      const byEntry = new Map<string, Array<{ kind: string; optionKey: string | null }>>();
      for (const item of items) {
        const list = byEntry.get(item.entryId) ?? [];
        list.push(item);
        byEntry.set(item.entryId, list);
      }
      return buildJournalSummary(
        entries.map((e) => ({ recordedAt: e.recordedAt, triggers: e.triggers, coping: e.coping, helpers: e.helpers, items: byEntry.get(e.id) ?? [] })),
        days,
        query.tzOffset ?? 0,
      );
    });
  }

  // Conditions ("Minhas condições", named by the person)

  async listConditions(userId: string, profileId: string): Promise<UserConditionsResponseDto> {
    this.assertIds(userId, profileId);
    return this.databaseService.withRls(userId, async (tx) => {
      const rows = await tx
        .select()
        .from(userConditions)
        .where(and(eq(userConditions.profileId, profileId), isNull(userConditions.archivedAt)))
        .orderBy(asc(userConditions.createdAt));
      return { conditions: rows.map((row) => this.toConditionDto(row)) };
    });
  }

  async createCondition(
    userId: string,
    profileId: string,
    label: string,
    tracking: TrackingKind[] = [],
  ): Promise<UserConditionDto> {
    this.assertIds(userId, profileId);
    const clean = label.trim();
    if (!clean) throw new BadRequestException('label não pode ser vazio.');

    return this.databaseService.withRls(userId, async (tx) => {
      // Serialises concurrent creates on the same profile so the limit holds.
      await tx.execute(sql`SELECT pg_advisory_xact_lock(hashtext(${`user_conditions:${profileId}`}))`);
      const [{ active }] = await tx
        .select({ active: sql<number>`count(*)::int` })
        .from(userConditions)
        .where(and(eq(userConditions.profileId, profileId), isNull(userConditions.archivedAt)));
      if (active >= JOURNAL_LIMITS.maxActiveConditions) {
        throw new ConflictException(`Limite de ${JOURNAL_LIMITS.maxActiveConditions} condições ativas atingido.`);
      }

      const [row] = await tx
        .insert(userConditions)
        .values({ userId, profileId, label: this.encryptionService.encrypt(clean), tracking: [...new Set(tracking)] })
        .returning();
      return this.toConditionDto(row);
    });
  }

  /** Soft archive: past items keep showing the label. */
  async archiveCondition(userId: string, profileId: string, id: string): Promise<void> {
    this.assertIds(userId, profileId);
    await this.databaseService.withRls(userId, async (tx) => {
      const updated = await tx
        .update(userConditions)
        .set({ archivedAt: new Date() })
        .where(
          and(eq(userConditions.id, id), eq(userConditions.profileId, profileId), isNull(userConditions.archivedAt)),
        )
        .returning({ id: userConditions.id });
      if (!updated.length) throw new NotFoundException('Condição não encontrada.');
    });
  }

  /**
   * Changes the label and/or which readings the person notes. Past readings stay as they
   * are. Archived conditions and other profiles' conditions answer 404.
   */
  async updateCondition(
    userId: string,
    profileId: string,
    id: string,
    dto: UpdateConditionDto,
  ): Promise<UserConditionDto> {
    this.assertIds(userId, profileId);
    const changes: Partial<typeof userConditions.$inferInsert> = {};
    if (dto.label !== undefined) {
      const clean = dto.label.trim();
      if (!clean) throw new BadRequestException('label não pode ser vazio.');
      changes.label = this.encryptionService.encrypt(clean);
    }
    if (dto.tracking !== undefined) changes.tracking = [...new Set(dto.tracking)];

    return this.databaseService.withRls(userId, async (tx) => {
      const where = and(eq(userConditions.id, id), eq(userConditions.profileId, profileId), isNull(userConditions.archivedAt));
      const [row] = Object.keys(changes).length
        ? await tx.update(userConditions).set(changes).where(where).returning()
        : await tx.select().from(userConditions).where(where).limit(1);
      if (!row) throw new NotFoundException('Condição não encontrada.');
      return this.toConditionDto(row);
    });
  }

  /**
   * Readings of one condition of the active profile, newest first, as typed. Archived
   * conditions keep their readings. Another profile's condition returns 404.
   */
  async listConditionReadings(
    userId: string,
    profileId: string,
    conditionId: string,
    query: ConditionReadingsQueryDto,
  ): Promise<ConditionReadingDto[]> {
    this.assertIds(userId, profileId);
    const days = Math.min(Math.max(query.days ?? READING_INPUT_LIMITS.defaultHistoryDays, 1), JOURNAL_LIMITS.maxDays);
    const cutoff = new Date(Date.now() - days * DAY_MS);

    return this.databaseService.withRls(userId, async (tx) => {
      const [condition] = await tx
        .select({ id: userConditions.id })
        .from(userConditions)
        .where(and(eq(userConditions.id, conditionId), eq(userConditions.profileId, profileId)))
        .limit(1);
      if (!condition) throw new NotFoundException('Condição não encontrada.');

      const rows = await tx
        .select()
        .from(conditionReadings)
        .where(
          and(
            eq(conditionReadings.profileId, profileId),
            eq(conditionReadings.conditionId, conditionId),
            gte(conditionReadings.measuredAt, cutoff),
          ),
        )
        .orderBy(desc(conditionReadings.measuredAt), desc(conditionReadings.createdAt));
      return rows.map((row) => this.toReadingDto(row)).filter((r): r is ConditionReadingDto => r !== null);
    });
  }

  // Helpers

  private async findByClientId(
    tx: DrizzleTransaction,
    profileId: string,
    clientId: string,
  ): Promise<EntryRow | undefined> {
    const [row] = await tx
      .select()
      .from(journalEntries)
      .where(and(eq(journalEntries.profileId, profileId), eq(journalEntries.clientId, clientId)))
      .limit(1);
    return row;
  }

  /** Idempotent replay of an outbox record already stored on this profile. */
  private async replay(tx: DrizzleTransaction, entry: EntryRow, profileId: string): Promise<JournalEntryDto> {
    const items = await tx.select().from(journalItems).where(eq(journalItems.entryId, entry.id));
    const readings = await tx.select().from(conditionReadings).where(eq(conditionReadings.entryId, entry.id));
    const conditionIds = items.map((i) => i.conditionId).filter((id): id is string => !!id);
    return this.toEntryDto(entry, items, await this.conditionLabels(tx, profileId, conditionIds), readings);
  }

  private async loadEntries(tx: DrizzleTransaction, profileId: string, cutoff: Date) {
    const entries = await tx
      .select()
      .from(journalEntries)
      .where(and(eq(journalEntries.profileId, profileId), gte(journalEntries.recordedAt, cutoff)))
      .orderBy(desc(journalEntries.recordedAt));
    const items = entries.length
      ? await tx.select().from(journalItems).where(inArray(journalItems.entryId, entries.map((e) => e.id)))
      : [];

    const itemsByEntry = new Map<string, ItemRow[]>();
    for (const item of items) {
      const list = itemsByEntry.get(item.entryId) ?? [];
      list.push(item);
      itemsByEntry.set(item.entryId, list);
    }
    const conditionIds = items.map((i) => i.conditionId).filter((id): id is string => !!id);
    const conditionLabels = await this.conditionLabels(tx, profileId, conditionIds);
    const readings = conditionIds.length
      ? await tx.select().from(conditionReadings).where(inArray(conditionReadings.entryId, entries.map((e) => e.id)))
      : [];
    return { entries, itemsByEntry, conditionLabels, readings };
  }

  /** Decrypted labels of the profile's conditions with these ids (archived ones included). */
  private async conditionLabels(
    tx: DrizzleTransaction,
    profileId: string,
    ids: string[],
  ): Promise<Map<string, string>> {
    const unique = [...new Set(ids)];
    if (!unique.length) return new Map();
    const rows = await tx
      .select({ id: userConditions.id, label: userConditions.label })
      .from(userConditions)
      .where(and(eq(userConditions.profileId, profileId), inArray(userConditions.id, unique)));
    return new Map(rows.map((r) => [r.id, this.decryptOptional(r.label) ?? '']));
  }

  private toEntryDto(
    entry: EntryRow,
    items: ItemRow[],
    conditionLabels: Map<string, string>,
    readings: ReadingRow[] = [],
  ): JournalEntryDto {
    // A reading belongs to the entry and to the condition of one of its items.
    const readingsOf = (conditionId: string | null): ConditionReadingDto[] =>
      conditionId
        ? readings
            .filter((r) => r.entryId === entry.id && r.conditionId === conditionId)
            .sort((a, b) => a.measuredAt.getTime() - b.measuredAt.getTime())
            .map((r) => this.toReadingDto(r))
            .filter((r): r is ConditionReadingDto => r !== null)
        : [];
    return {
      id: entry.id,
      legacy: false,
      clientId: entry.clientId,
      recordedAt: entry.recordedAt.toISOString(),
      mood: entry.mood,
      area: entry.area ?? null,
      triggers: entry.triggers,
      coping: entry.coping ?? null,
      helpers: entry.helpers ?? [],
      triggerNote: this.decryptOptional(entry.triggerNote),
      note: this.decryptOptional(entry.note),
      transitionVariantIds: entry.transitionVariantIds,
      items: items.map(
        (item): JournalItemDto => ({
          id: item.id,
          kind: item.kind as JournalItemDto['kind'],
          optionKey: item.optionKey,
          customLabel: this.decryptOptional(item.customLabel),
          conditionId: item.conditionId,
          label: item.conditionId ? (conditionLabels.get(item.conditionId) ?? null) : null,
          bodySide: item.bodySide,
          sensation: item.sensation ?? null,
          persistence: item.persistence,
          intensity: item.intensity,
          readings: item.kind === 'condition' ? readingsOf(item.conditionId) : [],
        }),
      ),
      createdAt: entry.createdAt.toISOString(),
    };
  }

  /**
   * Old entries keep their stored area or mood, shown with its plain-language name. The
   * reported intensity belongs to the side the person filled in; a second side the old
   * app added from the free text gets no intensity (null).
   */
  private toLegacyDto(row: LegacyRow, lang: Lang): LegacyJournalEntryDto {
    const intensity = row.intensity >= 1 && row.intensity <= 5 ? row.intensity : null;
    const mood = row.emotionalDimension && row.emotionalDimension !== 'normal' ? row.emotionalDimension : null;
    const body = row.anatomicalSystem && row.anatomicalSystem !== 'normal' ? row.anatomicalSystem : null;
    const main = this.legacyMainKind(row, !!mood, !!body);

    const items: LegacyJournalItemDto[] = [];
    if (mood) {
      items.push({
        kind: 'emotional',
        legacyLabel: OLD_MOOD_LABELS[mood]?.[lang] ?? mood,
        intensity: main === 'emotional' ? intensity : null,
      });
    }
    if (body) {
      items.push({
        kind: 'physical',
        legacyLabel: OLD_BODY_LABELS[body]?.[lang] ?? body,
        intensity: main === 'physical' ? intensity : null,
      });
    }
    return {
      id: row.id,
      legacy: true,
      recordedAt: row.recordedAt.toISOString(),
      note: this.decryptOptional(row.encryptedNarrative),
      items,
    };
  }

  /** Side the person filled in on an old row: stored `_entryVertical`, else the only side present. */
  private legacyMainKind(row: LegacyRow, hasMood: boolean, hasBody: boolean): 'emotional' | 'physical' | null {
    if (hasMood !== hasBody) return hasMood ? 'emotional' : 'physical';
    if (!hasMood) return null;
    const answers = this.decryptOptional(row.stepAnswers ?? null);
    if (answers) {
      try {
        const kind = JSON.parse(answers)?._entryVertical;
        if (kind === 'emotional' || kind === 'physical') return kind;
      } catch {
        // unreadable answers: fall through
      }
    }
    // Rows older than `_entryVertical`: the old app only added a second side to emotional entries.
    return row.organicPrimacyApplied ? 'emotional' : 'physical';
  }

  private toConditionDto(row: typeof userConditions.$inferSelect): UserConditionDto {
    return {
      id: row.id,
      label: this.decryptOptional(row.label) ?? '',
      tracking: (row.tracking ?? []) as TrackingKind[],
      createdAt: row.createdAt.toISOString(),
    };
  }

  /** Decrypted reading; null when its values cannot be read (never ciphertext). */
  private toReadingDto(row: ReadingRow): ConditionReadingDto | null {
    const text = this.decryptOptional(row.data);
    if (!text) return null;
    let values: Record<string, unknown>;
    try {
      values = JSON.parse(text);
    } catch {
      return null;
    }
    const base = { id: row.id, entryId: row.entryId, conditionId: row.conditionId, measuredAt: row.measuredAt.toISOString() };
    switch (row.kind) {
      case 'blood_pressure':
        return { ...base, kind: 'blood_pressure', systolic: values.systolic as number, diastolic: values.diastolic as number, pulse: (values.pulse as number | null) ?? null };
      case 'glucose':
        return { ...base, kind: 'glucose', mgdl: values.mgdl as number, moment: values.moment as GlucoseMoment };
      case 'weight':
        return { ...base, kind: 'weight', kg: values.kg as number };
      default:
        return null;
    }
  }

  private encryptOptional(value?: string | null): string | null {
    return value ? this.encryptionService.encrypt(value) : null;
  }

  private decryptOptional(value: string | null): string | null {
    if (!value) return null;
    if (!value.startsWith('v1:')) return value;
    try {
      return this.encryptionService.decrypt(value);
    } catch {
      return null; // never return ciphertext to the client
    }
  }

  private cutoff(days?: number): Date {
    const window = Math.min(Math.max(days ?? JOURNAL_LIMITS.defaultDays, 1), JOURNAL_LIMITS.maxDays);
    return new Date(Date.now() - window * DAY_MS);
  }

  private assertIds(userId: string, profileId: string): void {
    if (!userId) throw new BadRequestException('ID do usuário ausente.');
    if (!profileId) throw new BadRequestException('ID do perfil ausente.');
  }
}
