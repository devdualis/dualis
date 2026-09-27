export class WaterIntakeLogItemDto {
  id!: string;
  userId!: string;
  amountMl!: number;
  source!: string;
  recordedAt!: string;
  createdAt!: string;
}

export class HydrationTodayResponseDto {
  todayTotalMl!: number;
  logs!: WaterIntakeLogItemDto[];
}

export class HydrationHistoryDayDto {
  date!: string; // YYYY-MM-DD
  totalMl!: number;
}

export class HydrationHistoryResponseDto {
  totals!: Record<string, number>;
  days!: HydrationHistoryDayDto[];
}
