import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { and, desc, eq, gte, lte } from 'drizzle-orm';
import { DatabaseService } from '../../database/database.service';
import { dailyHabits } from '../../database/schema';
import { HabitDayDto, PutHabitDayDto } from './dto/habits.dto';

const DAY_MS = 86_400_000;

/** The device supplies a local calendar date; the accepted window is bounded in UTC. */
export function assertHabitDay(day: string, now = new Date()): void {
  const parsed = new Date(`${day}T00:00:00.000Z`);
  const today = Date.parse(`${now.toISOString().slice(0, 10)}T00:00:00.000Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day) || Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== day ||
      parsed.getTime() < today - 365 * DAY_MS || parsed.getTime() > today + DAY_MS) {
    throw new BadRequestException('day deve ser YYYY-MM-DD, de 365 dias atrás até amanhã em UTC.');
  }
}

@Injectable()
export class HabitsService {
  constructor(@Inject(DatabaseService) private readonly databaseService: DatabaseService) {}

  async listDays(userId: string, profileId: string, days = 30): Promise<{ days: HabitDayDto[] }> {
    this.assertIds(userId, profileId);
    const today = Date.parse(`${new Date().toISOString().slice(0, 10)}T00:00:00.000Z`);
    const cutoff = new Date(today - (days - 1) * DAY_MS).toISOString().slice(0, 10);
    const tomorrow = new Date(today + DAY_MS).toISOString().slice(0, 10);
    return this.databaseService.withRls(userId, async (tx) => {
      const rows = await tx.select().from(dailyHabits)
        .where(and(eq(dailyHabits.profileId, profileId), gte(dailyHabits.day, cutoff), lte(dailyHabits.day, tomorrow)))
        .orderBy(desc(dailyHabits.day));
      return { days: rows.map(toHabitDayDto) };
    });
  }

  async putDay(userId: string, profileId: string, day: string, dto: PutHabitDayDto): Promise<HabitDayDto> {
    this.assertIds(userId, profileId);
    assertHabitDay(day);
    if (dto.movementMinutes != null && dto.moved !== true) throw new BadRequestException('movementMinutes exige moved = true.');
    const answers = {
      sleepQuality: dto.sleepQuality ?? null,
      sleepHours: dto.sleepHours ?? null,
      moved: dto.moved ?? null,
      movementMinutes: dto.movementMinutes ?? null,
      period: dto.period ?? null,
      updatedAt: new Date(),
    };
    return this.databaseService.withRls(userId, async (tx) => {
      const [row] = await tx.insert(dailyHabits).values({ userId, profileId, day, ...answers })
        .onConflictDoUpdate({ target: [dailyHabits.profileId, dailyHabits.day], set: answers }).returning();
      return toHabitDayDto(row);
    });
  }

  async deleteDay(userId: string, profileId: string, day: string): Promise<void> {
    this.assertIds(userId, profileId);
    assertHabitDay(day);
    await this.databaseService.withRls(userId, async (tx) => {
      const rows = await tx.delete(dailyHabits)
        .where(and(eq(dailyHabits.profileId, profileId), eq(dailyHabits.day, day))).returning({ id: dailyHabits.id });
      if (!rows.length) throw new NotFoundException('Registro não encontrado.');
    });
  }

  private assertIds(userId: string, profileId: string): void {
    if (!userId) throw new BadRequestException('ID do usuário ausente.');
    if (!profileId) throw new BadRequestException('ID do perfil ausente.');
  }
}

export function toHabitDayDto(row: typeof dailyHabits.$inferSelect): HabitDayDto {
  return {
    day: row.day, sleepQuality: row.sleepQuality, sleepHours: row.sleepHours,
    moved: row.moved, movementMinutes: row.movementMinutes, period: row.period,
    updatedAt: row.updatedAt.toISOString(),
  };
}
