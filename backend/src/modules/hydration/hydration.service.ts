import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { and, desc, eq, gte, lte } from 'drizzle-orm';
import { DatabaseService } from '../../database/database.service';
import { waterIntakeLogs } from '../../database/schema/water-intake-logs.schema';
import { LogWaterDto } from './dto/log-water.dto';
import {
  HydrationHistoryResponseDto,
  HydrationTodayResponseDto,
  WaterIntakeLogItemDto,
} from './dto/hydration-response.dto';

@Injectable()
export class HydrationService {
  constructor(
    @Inject(DatabaseService)
    private readonly databaseService: DatabaseService,
  ) {}

  async logWater(userId: string, dto: LogWaterDto): Promise<WaterIntakeLogItemDto> {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }

    const recordedAt = dto.recordedAt ? new Date(dto.recordedAt) : new Date();

    return this.databaseService.withRls(userId, async (tx) => {
      const [inserted] = await tx
        .insert(waterIntakeLogs)
        .values({
          userId,
          amountMl: dto.amountMl,
          source: dto.source || 'manual',
          recordedAt,
        })
        .returning();

      return {
        id: inserted.id,
        userId: inserted.userId,
        amountMl: inserted.amountMl,
        source: inserted.source,
        recordedAt: inserted.recordedAt.toISOString(),
        createdAt: inserted.createdAt.toISOString(),
      };
    });
  }

  async getTodayLogs(userId: string, dateStr?: string): Promise<HydrationTodayResponseDto> {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }

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
            eq(waterIntakeLogs.userId, userId),
            gte(waterIntakeLogs.recordedAt, startOfDay),
            lte(waterIntakeLogs.recordedAt, endOfDay),
          ),
        )
        .orderBy(waterIntakeLogs.recordedAt);

      const logs: WaterIntakeLogItemDto[] = records.map((r) => ({
        id: r.id,
        userId: r.userId,
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

  async getHistory(
    userId: string,
    days = 7,
    referenceDateStr?: string,
  ): Promise<HydrationHistoryResponseDto> {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }

    let refDate = new Date();
    if (referenceDateStr) {
      const parsed = new Date(referenceDateStr);
      if (!isNaN(parsed.getTime())) {
        refDate = parsed;
      }
    }

    // Calculate start date: (days - 1) days ago at 00:00:00
    const startDate = new Date(refDate);
    startDate.setDate(startDate.getDate() - (days - 1));
    startDate.setHours(0, 0, 0, 0);

    const endDate = new Date(refDate);
    endDate.setHours(23, 59, 59, 999);

    return this.databaseService.withRls(userId, async (tx) => {
      const records = await tx
        .select()
        .from(waterIntakeLogs)
        .where(
          and(
            eq(waterIntakeLogs.userId, userId),
            gte(waterIntakeLogs.recordedAt, startDate),
            lte(waterIntakeLogs.recordedAt, endDate),
          ),
        )
        .orderBy(desc(waterIntakeLogs.recordedAt));

      // Build daily map for all requested days
      const totals: Record<string, number> = {};
      const dayList: { date: string; totalMl: number }[] = [];

      for (let i = days - 1; i >= 0; i--) {
        const d = new Date(refDate);
        d.setDate(d.getDate() - i);
        const yyyy = d.getFullYear();
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const dd = String(d.getDate()).padStart(2, '0');
        const dateKey = `${yyyy}-${mm}-${dd}`;
        totals[dateKey] = 0;
      }

      for (const rec of records) {
        const d = new Date(rec.recordedAt);
        const yyyy = d.getFullYear();
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const dd = String(d.getDate()).padStart(2, '0');
        const dateKey = `${yyyy}-${mm}-${dd}`;

        if (totals[dateKey] !== undefined) {
          totals[dateKey] += rec.amountMl;
        }
      }

      for (const [date, totalMl] of Object.entries(totals)) {
        dayList.push({ date, totalMl });
      }

      return {
        totals,
        days: dayList,
      };
    });
  }

  async deleteLog(userId: string, id: string): Promise<{ success: boolean; id: string }> {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }

    return this.databaseService.withRls(userId, async (tx) => {
      const deleted = await tx
        .delete(waterIntakeLogs)
        .where(and(eq(waterIntakeLogs.id, id), eq(waterIntakeLogs.userId, userId)))
        .returning();

      if (deleted.length === 0) {
        throw new NotFoundException(`Water intake log with id ${id} not found.`);
      }

      return { success: true, id };
    });
  }
}
