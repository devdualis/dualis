import { randomUUID } from 'node:crypto';
import { Injectable, Logger, Inject } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import { triageEmergencyEvents } from '../../database/schema/triage-emergency-events.schema';
import { CreateEmergencyEventDto } from './dto/create-emergency-event.dto';

@Injectable()
export class TriageAuditService {
  private readonly logger = new Logger(TriageAuditService.name);

  constructor(
    @Inject(DatabaseService)
    private readonly databaseService: DatabaseService,
  ) {}

  async recordEmergencyEvent(
    dto: CreateEmergencyEventDto,
    userId?: string | null,
    profileId?: string | null,
  ) {
    // Anonymous events (no session) have no profile; authenticated ones are filed
    // under the active profile resolved by ProfileContextGuard.
    const eventValues = {
      userId: userId ?? null,
      profileId: userId ? (profileId ?? null) : null,
      triggerCategory: dto.triggerCategory,
      severityLevel: dto.severityLevel,
      sourceVertical: dto.sourceVertical,
      actionTaken: dto.actionTaken ?? null,
      reportedAt: new Date(dto.clientTimestamp),
    };

    let insertedRecord;

    if (userId) {
      insertedRecord = await this.databaseService.withRls(userId, async (tx) => {
        const [result] = await tx
          .insert(triageEmergencyEvents)
          .values(eventValues)
          .returning();
        return result;
      });
    } else {
      // No RETURNING here: Postgres checks RETURNING rows against the SELECT policy,
      // which an anonymous session never passes. The id is generated here instead,
      // so the emergency audit insert cannot fail on RLS.
      const anonymousRecord = { ...eventValues, id: randomUUID(), createdAt: new Date() };
      await this.databaseService.db.insert(triageEmergencyEvents).values(anonymousRecord);
      insertedRecord = anonymousRecord;
    }

    this.logger.log(
      `Recorded emergency event: category=${dto.triggerCategory}, severity=${dto.severityLevel}, vertical=${dto.sourceVertical}, userId=${userId ?? 'ANONYMOUS'}, profileId=${eventValues.profileId ?? 'NONE'}`,
    );

    return {
      id: insertedRecord.id,
      triggerCategory: insertedRecord.triggerCategory,
      severityLevel: insertedRecord.severityLevel,
      sourceVertical: insertedRecord.sourceVertical,
      profileId: insertedRecord.profileId ?? null,
      actionTaken: insertedRecord.actionTaken,
      reportedAt: insertedRecord.reportedAt,
      createdAt: insertedRecord.createdAt,
    };
  }
}
