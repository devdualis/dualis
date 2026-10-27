import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { and, asc, desc, eq, gte, inArray, isNull, sql } from 'drizzle-orm';
import { DatabaseService, DrizzleTransaction } from '../../database/database.service';
import { journalEntries, journalItems, symptomLogs, userConditions } from '../../database/schema';
import { EncryptionService } from '../../common/encryption/encryption.service';
import { Lang, resolveLang } from '../../common/i18n/lang';
import { EMOTIONAL_LABELS, PHYSICAL_LABELS } from '../triage/services/triage-outcome.service';
import { JOURNAL_LIMITS } from './constants/journal-keys.constant';
import {
  CreateJournalEntryDto,
  JournalDaysQueryDto,
  JournalEntriesResponseDto,
  JournalEntryDto,
  JournalItemDto,
  JournalSummaryDto,
  LegacyJournalEntryDto,
  LegacyJournalItemDto,
  UserConditionDto,
  UserConditionsResponseDto,
} from './dto/journal.dto';
import { buildJournalSummary } from './journal-summary';

type EntryRow = typeof journalEntries.$inferSelect;
type ItemRow = typeof journalItems.$inferSelect;
type LegacyRow = typeof symptomLogs.$inferSelect;

const DAY_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class JournalService {
  constructor(
    @Inject(DatabaseService) private readonly databaseService: DatabaseService,
    @Inject(EncryptionService) private readonly encryptionService: EncryptionService,
  ) {}

  // Entries

  async createEntry(userId: string, profileId: string, dto: CreateJournalEntryDto): Promise<JournalEntryDto> {
    this.assertIds(userId, profileId);
    const recordedAt = new Date(dto.recordedAt);
    if (isNaN(recordedAt.getTime())) throw new BadRequestException('recordedAt inválido.');

    return this.databaseService.withRls(userId, async (tx) => {
      const existing = await this.findByClientId(tx, dto.clientId);
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
          triggers: [...new Set(dto.triggers)],
          triggerNote: this.encryptOptional(dto.triggerNote),
          note: this.encryptOptional(dto.note),
          transitionVariantIds: dto.transitionVariantIds,
          clientId: dto.clientId,
        })
        .onConflictDoNothing({ target: journalEntries.clientId })
        .returning();

      if (!entry) {
        // Concurrent retry of the same outbox record, or a clientId used by someone else.
        const raced = await this.findByClientId(tx, dto.clientId);
        if (raced) return this.replay(tx, raced, profileId);
        throw new ConflictException('clientId já utilizado.');
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
                bodySide: item.kind === 'physical' ? item.bodySide! : null,
                persistence: item.persistence ?? null,
                intensity: item.intensity,
              })),
            )
            .returning()
        : [];

      return this.toEntryDto(entry, items, conditionLabels);
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
      const { entries, itemsByEntry, conditionLabels } = await this.loadEntries(tx, profileId, cutoff);
      const legacyRows = await tx
        .select()
        .from(symptomLogs)
        .where(and(eq(symptomLogs.profileId, profileId), gte(symptomLogs.recordedAt, cutoff)))
        .orderBy(desc(symptomLogs.recordedAt));

      const merged: Array<JournalEntryDto | LegacyJournalEntryDto> = [
        ...entries.map((e) => this.toEntryDto(e, itemsByEntry.get(e.id) ?? [], conditionLabels)),
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
        .select({ id: journalEntries.id, recordedAt: journalEntries.recordedAt, triggers: journalEntries.triggers })
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
        entries.map((e) => ({ recordedAt: e.recordedAt, triggers: e.triggers, items: byEntry.get(e.id) ?? [] })),
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

  async createCondition(userId: string, profileId: string, label: string): Promise<UserConditionDto> {
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
        .values({ userId, profileId, label: this.encryptionService.encrypt(clean) })
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

  // Helpers

  private async findByClientId(tx: DrizzleTransaction, clientId: string): Promise<EntryRow | undefined> {
    const [row] = await tx.select().from(journalEntries).where(eq(journalEntries.clientId, clientId)).limit(1);
    return row;
  }

  /** Idempotent replay of an outbox record already stored. */
  private async replay(tx: DrizzleTransaction, entry: EntryRow, profileId: string): Promise<JournalEntryDto> {
    if (entry.profileId !== profileId) throw new ConflictException('clientId já utilizado.');
    const items = await tx.select().from(journalItems).where(eq(journalItems.entryId, entry.id));
    const conditionIds = items.map((i) => i.conditionId).filter((id): id is string => !!id);
    return this.toEntryDto(entry, items, await this.conditionLabels(tx, profileId, conditionIds));
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
    return { entries, itemsByEntry, conditionLabels };
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

  private toEntryDto(entry: EntryRow, items: ItemRow[], conditionLabels: Map<string, string>): JournalEntryDto {
    return {
      id: entry.id,
      legacy: false,
      clientId: entry.clientId,
      recordedAt: entry.recordedAt.toISOString(),
      mood: entry.mood,
      triggers: entry.triggers,
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
          persistence: item.persistence,
          intensity: item.intensity,
        }),
      ),
      createdAt: entry.createdAt.toISOString(),
    };
  }

  /** Old entries keep their stored area or mood, shown with its plain-language name. */
  private toLegacyDto(row: LegacyRow, lang: Lang): LegacyJournalEntryDto {
    const intensity = row.intensity >= 1 && row.intensity <= 5 ? row.intensity : null;
    const items: LegacyJournalItemDto[] = [];
    if (row.emotionalDimension && row.emotionalDimension !== 'normal') {
      items.push({
        kind: 'emotional',
        legacyLabel: EMOTIONAL_LABELS[row.emotionalDimension]?.[lang] ?? row.emotionalDimension,
        intensity,
      });
    }
    if (row.anatomicalSystem && row.anatomicalSystem !== 'normal') {
      items.push({
        kind: 'physical',
        legacyLabel: PHYSICAL_LABELS[row.anatomicalSystem]?.[lang] ?? row.anatomicalSystem,
        intensity,
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

  private toConditionDto(row: typeof userConditions.$inferSelect): UserConditionDto {
    return { id: row.id, label: this.decryptOptional(row.label) ?? '', createdAt: row.createdAt.toISOString() };
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
