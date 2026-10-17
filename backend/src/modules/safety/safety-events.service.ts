import { randomUUID } from 'node:crypto';
import { Injectable, Logger, Inject } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import {
  safetyResourceEvents,
  SafetyResourceAction,
} from '../../database/schema/safety-resource-events.schema';
import { CreateSafetyEventDto } from './dto/create-safety-event.dto';
import { LegacyEmergencyEventDto } from './dto/legacy-emergency-event.dto';

export interface SafetyEventRecord {
  id: string;
  action: SafetyResourceAction;
  channel: string | null;
  profileId: string | null;
  clientTimestamp: Date;
  createdAt: Date;
}

@Injectable()
export class SafetyEventsService {
  private readonly logger = new Logger(SafetyEventsService.name);

  constructor(
    @Inject(DatabaseService)
    private readonly databaseService: DatabaseService,
  ) {}

  /** Old app versions: same event, severity/category/vertical discarded. */
  recordLegacyEmergencyEvent(
    dto: LegacyEmergencyEventDto,
    userId?: string | null,
    profileId?: string | null,
  ): Promise<SafetyEventRecord> {
    return this.recordSafetyEvent(
      { action: 'opened_resources', channel: dto.actionTaken, clientTimestamp: dto.clientTimestamp },
      userId,
      profileId,
    );
  }

  async recordSafetyEvent(
    dto: CreateSafetyEventDto,
    userId?: string | null,
    profileId?: string | null,
  ): Promise<SafetyEventRecord> {
    // Anonymous events (no session) have no profile; authenticated ones are filed
    // under the active profile resolved by ProfileContextGuard.
    const eventValues = {
      userId: userId ?? null,
      profileId: userId ? (profileId ?? null) : null,
      action: dto.action,
      channel: dto.channel ?? null,
      clientTimestamp: new Date(dto.clientTimestamp),
    };

    let insertedRecord;

    if (userId) {
      insertedRecord = await this.databaseService.withRls(userId, async (tx) => {
        const [result] = await tx.insert(safetyResourceEvents).values(eventValues).returning();
        return result;
      });
    } else {
      // No RETURNING here: Postgres checks RETURNING rows against the SELECT policy,
      // which an anonymous session never passes. The id is generated here instead,
      // so the insert cannot fail on RLS.
      const anonymousRecord = { ...eventValues, id: randomUUID(), createdAt: new Date() };
      await this.databaseService.db.insert(safetyResourceEvents).values(anonymousRecord);
      insertedRecord = anonymousRecord;
    }

    this.logger.log(
      `Recorded safety resource event: action=${eventValues.action}, channel=${eventValues.channel ?? 'NONE'}, userId=${userId ?? 'ANONYMOUS'}, profileId=${eventValues.profileId ?? 'NONE'}`,
    );

    return {
      id: insertedRecord.id,
      action: insertedRecord.action,
      channel: insertedRecord.channel ?? null,
      profileId: insertedRecord.profileId ?? null,
      clientTimestamp: insertedRecord.clientTimestamp,
      createdAt: insertedRecord.createdAt,
    };
  }
}
