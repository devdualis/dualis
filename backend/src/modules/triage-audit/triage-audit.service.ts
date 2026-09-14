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
  ) {
    const eventValues = {
      userId: userId ?? null,
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
      const [result] = await this.databaseService.db
        .insert(triageEmergencyEvents)
        .values(eventValues)
        .returning();
      insertedRecord = result;
    }

    this.logger.log(
      `Recorded emergency event: category=${dto.triggerCategory}, severity=${dto.severityLevel}, vertical=${dto.sourceVertical}, userId=${userId ?? 'ANONYMOUS'}`,
    );

    return {
      id: insertedRecord.id,
      triggerCategory: insertedRecord.triggerCategory,
      severityLevel: insertedRecord.severityLevel,
      sourceVertical: insertedRecord.sourceVertical,
      actionTaken: insertedRecord.actionTaken,
      reportedAt: insertedRecord.reportedAt,
      createdAt: insertedRecord.createdAt,
    };
  }
}
