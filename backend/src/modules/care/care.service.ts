import { BadRequestException, Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { and, desc, eq, gte, lte } from 'drizzle-orm';
import { DatabaseService, DrizzleTransaction } from '../../database/database.service';
import { EncryptionService } from '../../common/encryption/encryption.service';
import { careDocuments, careRecords, CareDocumentStatus, CareRecordKind } from '../../database/schema/care.schema';
import {
  CARE_DATA_CLASSES,
  CareDocumentResponse,
  CareRecordResponse,
  CreateCareRecordDto,
  CreateIntakeDto,
  DocumentData,
  ListCareRecordsQueryDto,
  MAX_DOCUMENT_BYTES,
  MedicationData,
  ReviewDocumentDto,
  UploadDocumentDto,
} from './care.dto';
import { DocumentReaderService } from './document-reader.service';

type CareRecordRow = typeof careRecords.$inferSelect;

/** Columns of care_documents without the file bytes (lists never load files). */
const documentMeta = {
  id: careDocuments.id,
  userId: careDocuments.userId,
  profileId: careDocuments.profileId,
  kind: careDocuments.kind,
  mime: careDocuments.mime,
  sizeBytes: careDocuments.sizeBytes,
  status: careDocuments.status,
  data: careDocuments.data,
  error: careDocuments.error,
  createdAt: careDocuments.createdAt,
  updatedAt: careDocuments.updatedAt,
};
type DocumentMetaRow = Omit<typeof careDocuments.$inferSelect, 'file'>;

@Injectable()
export class CareService {
  private readonly logger = new Logger(CareService.name);

  constructor(
    @Inject(DatabaseService) private readonly databaseService: DatabaseService,
    @Inject(EncryptionService) private readonly encryption: EncryptionService,
    @Inject(DocumentReaderService) private readonly reader: DocumentReaderService,
  ) {}

  // ---------------------------------------------------------------- records

  async listRecords(userId: string, profileId: string, query: ListCareRecordsQueryDto): Promise<CareRecordResponse[]> {
    return this.databaseService.withRls(userId, async (tx) => {
      const filters = [eq(careRecords.profileId, profileId), eq(careRecords.kind, query.kind)];
      if (query.parentId) filters.push(eq(careRecords.parentId, query.parentId));
      if (query.from) filters.push(gte(careRecords.occursAt, new Date(query.from)));
      if (query.to) filters.push(lte(careRecords.occursAt, new Date(query.to)));
      const rows = await tx
        .select()
        .from(careRecords)
        .where(and(...filters))
        .orderBy(desc(careRecords.occursAt), desc(careRecords.createdAt));
      return rows.map((r) => this.toRecord(r));
    });
  }

  async createRecord(userId: string, profileId: string, dto: CreateCareRecordDto): Promise<CareRecordResponse> {
    const data = this.validateData(dto.kind, dto.data);
    return this.databaseService.withRls(userId, async (tx) => {
      const [row] = await tx
        .insert(careRecords)
        .values({
          userId,
          profileId,
          kind: dto.kind,
          occursAt: occursAtOf(dto.kind, data),
          data: this.encryption.encrypt(JSON.stringify(data)),
        })
        .returning();
      return this.toRecord(row);
    });
  }

  async updateRecord(userId: string, profileId: string, id: string, rawData: Record<string, unknown>): Promise<CareRecordResponse> {
    return this.databaseService.withRls(userId, async (tx) => {
      const existing = await this.findRecord(tx, profileId, id);
      if (existing.kind === 'medication_intake') throw new BadRequestException('Intakes cannot be edited.');
      const data = this.validateData(existing.kind, rawData);
      const [row] = await tx
        .update(careRecords)
        .set({ data: this.encryption.encrypt(JSON.stringify(data)), occursAt: occursAtOf(existing.kind, data), updatedAt: new Date() })
        .where(eq(careRecords.id, id))
        .returning();
      return this.toRecord(row);
    });
  }

  async deleteRecord(userId: string, profileId: string, id: string): Promise<{ success: true; id: string }> {
    return this.databaseService.withRls(userId, async (tx) => {
      await this.findRecord(tx, profileId, id);
      await tx.delete(careRecords).where(eq(careRecords.id, id));
      return { success: true, id };
    });
  }

  /**
   * Logs "Tomei / Adiar / Pulei" for a medication. "Tomei" lowers the stock by the
   * amount the person configured; nothing else about the medication changes.
   */
  async logIntake(
    userId: string,
    profileId: string,
    medicationId: string,
    dto: CreateIntakeDto,
  ): Promise<{ intake: CareRecordResponse; medication: CareRecordResponse }> {
    return this.databaseService.withRls(userId, async (tx) => {
      const medication = await this.findRecord(tx, profileId, medicationId);
      if (medication.kind !== 'medication') throw new NotFoundException('Medication not found.');
      const data = this.validateData('medication_intake', { scheduledFor: dto.scheduledFor, action: dto.action });
      const [intake] = await tx
        .insert(careRecords)
        .values({
          userId,
          profileId,
          kind: 'medication_intake',
          parentId: medicationId,
          occursAt: new Date(dto.scheduledFor),
          data: this.encryption.encrypt(JSON.stringify(data)),
        })
        .returning();

      let medRow = medication;
      const med = this.decryptData(medication) as unknown as MedicationData;
      if (dto.action === 'taken' && typeof med.stockCount === 'number') {
        const next = { ...med, stockCount: Math.max(0, med.stockCount - (med.stockPerIntake ?? 1)) };
        [medRow] = await tx
          .update(careRecords)
          .set({ data: this.encryption.encrypt(JSON.stringify(next)), updatedAt: new Date() })
          .where(eq(careRecords.id, medicationId))
          .returning();
      }
      return { intake: this.toRecord(intake), medication: this.toRecord(medRow) };
    });
  }

  // -------------------------------------------------------------- documents

  async uploadDocument(userId: string, profileId: string, dto: UploadDocumentDto): Promise<CareDocumentResponse> {
    const file = Buffer.from(dto.fileBase64, 'base64');
    if (file.length === 0) throw new BadRequestException('Empty file.');
    if (file.length > MAX_DOCUMENT_BYTES) throw new BadRequestException('File larger than 10 MB.');

    const willRead = dto.read && dto.kind !== 'other';
    const status: CareDocumentStatus = willRead ? 'processing' : 'archived';
    const data: DocumentData = dto.title ? { title: dto.title } : {};

    const row = await this.databaseService.withRls(userId, async (tx) => {
      const [inserted] = await tx
        .insert(careDocuments)
        .values({
          userId,
          profileId,
          kind: dto.kind,
          mime: dto.mime,
          sizeBytes: file.length,
          file: this.encryption.encryptBuffer(file),
          status,
          data: this.encryption.encrypt(JSON.stringify(data)),
        })
        .returning(documentMeta);
      return inserted;
    });

    if (willRead) {
      // Runs after the response (Cloud Run is deployed with --no-cpu-throttling).
      setImmediate(() => void this.readDocument(userId, row.id, dto.kind as 'lab' | 'prescription', dto.mime, file, data));
    }
    return this.toDocument(row);
  }

  /** OCR + transcription. The person confirms every value before the document is "ready". */
  async readDocument(
    userId: string,
    documentId: string,
    kind: 'lab' | 'prescription',
    mime: string,
    file: Buffer,
    base: DocumentData,
  ): Promise<void> {
    let status: CareDocumentStatus = 'review';
    let data: DocumentData = base;
    let error: string | null = null;
    try {
      const reading = await this.reader.read(kind, mime, file);
      data = {
        ...reading,
        ...base,
        title: base.title ?? reading.title,
        // Rows start unconfirmed: the person confirms each one in the app.
        values: reading.values?.map((v) => ({ ...v, confirmed: false })),
      };
    } catch (err) {
      status = 'failed';
      error = 'read_failed';
      this.logger.warn(`Document ${documentId} reading failed: ${(err as Error).message?.slice(0, 200)}`);
    }
    try {
      await this.databaseService.withRls(userId, (tx) =>
        tx
          .update(careDocuments)
          .set({ status, error, data: this.encryption.encrypt(JSON.stringify(data)), updatedAt: new Date() })
          .where(and(eq(careDocuments.id, documentId), eq(careDocuments.status, 'processing'))),
      );
    } catch (err) {
      this.logger.error(`Document ${documentId} status update failed: ${(err as Error).message}`);
    }
  }

  async listDocuments(userId: string, profileId: string, kind?: string): Promise<CareDocumentResponse[]> {
    return this.databaseService.withRls(userId, async (tx) => {
      const filters = [eq(careDocuments.profileId, profileId)];
      if (kind) filters.push(eq(careDocuments.kind, kind as any));
      const rows = await tx.select(documentMeta).from(careDocuments).where(and(...filters)).orderBy(desc(careDocuments.createdAt));
      return rows.map((r) => this.toDocument(r));
    });
  }

  async getDocument(userId: string, profileId: string, id: string): Promise<CareDocumentResponse> {
    return this.databaseService.withRls(userId, async (tx) => this.toDocument(await this.findDocument(tx, profileId, id)));
  }

  async getDocumentFile(userId: string, profileId: string, id: string): Promise<{ mime: string; file: Buffer }> {
    return this.databaseService.withRls(userId, async (tx) => {
      const [row] = await tx
        .select({ mime: careDocuments.mime, file: careDocuments.file })
        .from(careDocuments)
        .where(and(eq(careDocuments.id, id), eq(careDocuments.profileId, profileId)));
      if (!row) throw new NotFoundException('Document not found.');
      return { mime: row.mime, file: this.encryption.decryptBuffer(row.file) };
    });
  }

  /** Saves what the person confirmed. Every exam value must carry confirmed: true. */
  async reviewDocument(userId: string, profileId: string, id: string, dto: ReviewDocumentDto): Promise<CareDocumentResponse> {
    if (dto.values?.some((v) => v.confirmed !== true)) {
      throw new BadRequestException('Every value must be confirmed by the person before saving.');
    }
    return this.databaseService.withRls(userId, async (tx) => {
      const existing = await this.findDocument(tx, profileId, id);
      if (existing.status === 'processing') throw new BadRequestException('Document is still being read.');
      const current = this.decryptDocumentData(existing);
      const data: DocumentData = {
        ...current,
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.labName !== undefined && { labName: dto.labName }),
        ...(dto.collectedOn !== undefined && { collectedOn: dto.collectedOn }),
        ...(dto.values !== undefined && { values: dto.values }),
        ...(dto.medications !== undefined && { medications: dto.medications }),
        ...(dto.note !== undefined && { note: dto.note }),
      };
      const status: CareDocumentStatus = existing.status === 'archived' ? 'archived' : 'ready';
      const [row] = await tx
        .update(careDocuments)
        .set({ data: this.encryption.encrypt(JSON.stringify(data)), status, error: null, updatedAt: new Date() })
        .where(eq(careDocuments.id, id))
        .returning(documentMeta);
      return this.toDocument(row);
    });
  }

  /** Reads the stored file again. Confirmed (ready) documents are never overwritten. */
  async reprocessDocument(userId: string, profileId: string, id: string): Promise<CareDocumentResponse> {
    const { row, file, base } = await this.databaseService.withRls(userId, async (tx) => {
      const existing = await this.findDocument(tx, profileId, id);
      if (existing.kind === 'other' || !['failed', 'review'].includes(existing.status)) {
        throw new BadRequestException('Only unread or unconfirmed exams and prescriptions can be read again.');
      }
      const current = this.decryptDocumentData(existing);
      const [stored] = await tx.select({ file: careDocuments.file }).from(careDocuments).where(eq(careDocuments.id, id));
      const [updated] = await tx
        .update(careDocuments)
        .set({ status: 'processing', error: null, updatedAt: new Date() })
        .where(eq(careDocuments.id, id))
        .returning(documentMeta);
      const base: DocumentData = current.title ? { title: current.title } : {};
      return { row: updated, file: this.encryption.decryptBuffer(stored.file), base };
    });
    setImmediate(() => void this.readDocument(userId, id, row.kind as 'lab' | 'prescription', row.mime, file, base));
    return this.toDocument(row);
  }

  async deleteDocument(userId: string, profileId: string, id: string): Promise<{ success: true; id: string }> {
    return this.databaseService.withRls(userId, async (tx) => {
      await this.findDocument(tx, profileId, id);
      await tx.delete(careDocuments).where(eq(careDocuments.id, id));
      return { success: true, id };
    });
  }

  // ---------------------------------------------------------------- helpers

  private validateData(kind: CareRecordKind, raw: Record<string, unknown>): Record<string, unknown> {
    const instance = plainToInstance(CARE_DATA_CLASSES[kind] as new () => object, raw ?? {});
    const errors = validateSync(instance, { whitelist: true, forbidNonWhitelisted: true });
    if (errors.length > 0) {
      const messages = errors.flatMap((e) => Object.values(e.constraints ?? {}));
      throw new BadRequestException(messages.length ? messages : 'Invalid data.');
    }
    return JSON.parse(JSON.stringify(instance));
  }

  private async findRecord(tx: DrizzleTransaction, profileId: string, id: string): Promise<CareRecordRow> {
    const [row] = await tx.select().from(careRecords).where(and(eq(careRecords.id, id), eq(careRecords.profileId, profileId)));
    if (!row) throw new NotFoundException('Record not found.');
    return row;
  }

  private async findDocument(tx: DrizzleTransaction, profileId: string, id: string): Promise<DocumentMetaRow> {
    const [row] = await tx
      .select(documentMeta)
      .from(careDocuments)
      .where(and(eq(careDocuments.id, id), eq(careDocuments.profileId, profileId)));
    if (!row) throw new NotFoundException('Document not found.');
    return row;
  }

  private decryptData(row: CareRecordRow): Record<string, unknown> {
    return JSON.parse(this.encryption.decrypt(row.data));
  }

  private decryptDocumentData(row: DocumentMetaRow): DocumentData {
    return row.data ? JSON.parse(this.encryption.decrypt(row.data)) : {};
  }

  private toRecord(row: CareRecordRow): CareRecordResponse {
    return {
      id: row.id,
      kind: row.kind,
      profileId: row.profileId,
      parentId: row.parentId,
      occursAt: row.occursAt ? row.occursAt.toISOString() : null,
      data: this.decryptData(row),
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  private toDocument(row: DocumentMetaRow): CareDocumentResponse {
    return {
      id: row.id,
      kind: row.kind,
      profileId: row.profileId,
      mime: row.mime,
      sizeBytes: row.sizeBytes,
      status: row.status,
      data: this.decryptDocumentData(row),
      error: row.error,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }
}

/** The date a record is sorted by. Medications have none. */
export function occursAtOf(kind: CareRecordKind, data: Record<string, unknown>): Date | null {
  const value =
    kind === 'vaccine_dose' ? data.appliedOn
    : kind === 'allergy' ? data.informedOn
    : kind === 'appointment' ? data.startsAt
    : kind === 'medication_intake' ? data.scheduledFor
    : undefined;
  return typeof value === 'string' ? new Date(value) : null;
}

