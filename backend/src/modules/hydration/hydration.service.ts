import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { and, desc, eq, gte, lt, lte } from 'drizzle-orm';
import { DatabaseService } from '../../database/database.service';
import { waterIntakeLogs } from '../../database/schema/water-intake-logs.schema';
import { localDay } from '../../common/time/local-day';
import { LogWaterDto } from './dto/log-water.dto';
import {
  HydrationHistoryResponseDto,
  HydrationTodayResponseDto,
  WaterIntakeLogItemDto,
} from './dto/hydration-response.dto';

/**
 * Last local day of the history window. A wall-clock value without a zone
 * (`2026-10-27` or `2026-10-27T22:00:00`) already is the device's local time; a value
 * with `Z` or an offset is converted with `tzOffsetMinutes`.
 */
function referenceLocalDay(value: string | undefined, tzOffsetMinutes: number): string {
  if (value) {
    if (/^\d{4}-\d{2}-\d{2}(T[^Zz+-]*)?$/.test(value)) return value.slice(0, 10);
    const parsed = new Date(value);
    if (!isNaN(parsed.getTime())) return localDay(parsed, tzOffsetMinutes);
  }
  return localDay(new Date(), tzOffsetMinutes);
}

@Injectable()
export class HydrationService {
  constructor(
    @Inject(DatabaseService)
    private readonly databaseService: DatabaseService,
  ) {}

  async logWater(
    userId: string,
    profileId: string,
    dto: LogWaterDto,
  ): Promise<WaterIntakeLogItemDto> {
    this.assertIds(userId, profileId);

    const recordedAt = dto.recordedAt ? new Date(dto.recordedAt) : new Date();

    return this.databaseService.withRls(userId, async (tx) => {
      const [inserted] = await tx
        .insert(waterIntakeLogs)
        .values({
          userId,
          profileId,
          amountMl: dto.amountMl,
          source: dto.source || 'manual',
          recordedAt,
        })
        .returning();

      return {
        id: inserted.id,
        userId: inserted.userId,
        profileId: inserted.profileId,
        amountMl: inserted.amountMl,
        source: inserted.source,
        recordedAt: inserted.recordedAt.toISOString(),
        createdAt: inserted.createdAt.toISOString(),
      };
    });
  }

  async getTodayLogs(
    userId: string,
    profileId: string,
    dateStr?: string,
  ): Promise<HydrationTodayResponseDto> {
    this.assertIds(userId, profileId);

    let targetDate = new Date();
    if (dateStr) {
      const parsed = new Date(dateStr);
      if (!isNaN(parsed.getTime())) {
        targetDate = parsed;
      }
    }

    // Define day window
    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    return this.databaseService.withRls(userId, async (tx) => {
      const records = await tx
        .select()
        .from(waterIntakeLogs)
        .where(
          and(
            eq(waterIntakeLogs.profileId, profileId),
            gte(waterIntakeLogs.recordedAt, startOfDay),
            lte(waterIntakeLogs.recordedAt, endOfDay),
          ),
        )
        .orderBy(waterIntakeLogs.recordedAt);

      const logs: WaterIntakeLogItemDto[] = records.map((r) => ({
        id: r.id,
        userId: r.userId,
        profileId: r.profileId,
        amountMl: r.amountMl,
        source: r.source,
        recordedAt: r.recordedAt.toISOString(),
        createdAt: r.createdAt.toISOString(),
      }));

      const todayTotalMl = logs.reduce((sum, item) => sum + item.amountMl, 0);

      return {
        todayTotalMl,
        logs,
      };
    });
  }

  /**
   * Daily totals for the [days] local days ending on the reference day. Days are the
   * device's calendar days (`tzOffsetMinutes` east of UTC, default 0), so water logged
   * at 22:00 in Brasília counts on that Brasília day.
   */
  async getHistory(
    userId: string,
    profileId: string,
    days = 7,
    referenceDateStr?: string,
    tzOffsetMinutes = 0,
  ): Promise<HydrationHistoryResponseDto> {
    this.assertIds(userId, profileId);

    const lastDay = referenceLocalDay(referenceDateStr, tzOffsetMinutes);
    const [y, m, d] = lastDay.split('-').map(Number);
    const offsetMs = tzOffsetMinutes * 60_000;
    // Instants where the first local day starts and the day after the last one starts.
    const start = new Date(Date.UTC(y, m - 1, d - (days - 1)) - offsetMs);
    const end = new Date(Date.UTC(y, m - 1, d + 1) - offsetMs);

    return this.databaseService.withRls(userId, async (tx) => {
      const records = await tx
        .select()
        .from(waterIntakeLogs)
        .where(
          and(
            eq(waterIntakeLogs.profileId, profileId),
            gte(waterIntakeLogs.recordedAt, start),
            lt(waterIntakeLogs.recordedAt, end),
          ),
        )
        .orderBy(desc(waterIntakeLogs.recordedAt));

      const totals: Record<string, number> = {};
      for (let i = days - 1; i >= 0; i--) {
        totals[new Date(Date.UTC(y, m - 1, d - i)).toISOString().slice(0, 10)] = 0;
      }
      for (const rec of records) {
        const key = localDay(new Date(rec.recordedAt), tzOffsetMinutes);
        if (totals[key] !== undefined) totals[key] += rec.amountMl;
      }

      return {
        totals,
        days: Object.entries(totals).map(([date, totalMl]) => ({ date, totalMl })),
      };
    });
  }

  async deleteLog(
    userId: string,
    profileId: string,
    id: string,
  ): Promise<{ success: boolean; id: string }> {
    this.assertIds(userId, profileId);

    return this.databaseService.withRls(userId, async (tx) => {
      const deleted = await tx
        .delete(waterIntakeLogs)
        .where(and(eq(waterIntakeLogs.id, id), eq(waterIntakeLogs.profileId, profileId)))
        .returning();

      if (deleted.length === 0) {
        throw new NotFoundException(`Water intake log with id ${id} not found.`);
      }

      return { success: true, id };
    });
  }

  private assertIds(userId: string, profileId: string): void {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }
    if (!profileId) {
      throw new BadRequestException('Profile ID is required');
    }
  }
}
