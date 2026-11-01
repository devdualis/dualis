import { Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsOptional, Max, Min, Validate, ValidationArguments, ValidatorConstraint, ValidatorConstraintInterface } from 'class-validator';

export const SLEEP_QUALITY_KEYS = ['bem', 'regular', 'mal'] as const;
export const SLEEP_HOURS_KEYS = ['menos_5', '5_6', '7_8', '9_mais'] as const;
export const MOVEMENT_MINUTES_KEYS = ['ate_15', '15_30', '30_60', 'mais_60'] as const;

@ValidatorConstraint({ name: 'habitMovement', async: false })
class HabitMovementConstraint implements ValidatorConstraintInterface {
  validate(_value: unknown, args: ValidationArguments): boolean {
    const dto = args.object as PutHabitDayDto;
    return dto.movementMinutes == null || dto.moved === true;
  }
  defaultMessage(): string { return 'movementMinutes exige moved = true.'; }
}

export class PutHabitDayDto {
  @IsOptional()
  @IsIn(SLEEP_QUALITY_KEYS)
  sleepQuality?: (typeof SLEEP_QUALITY_KEYS)[number] | null;

  @IsOptional()
  @IsIn(SLEEP_HOURS_KEYS)
  sleepHours?: (typeof SLEEP_HOURS_KEYS)[number] | null;

  @IsOptional()
  @IsBoolean()
  moved?: boolean | null;

  @IsOptional()
  @IsIn(MOVEMENT_MINUTES_KEYS)
  @Validate(HabitMovementConstraint)
  movementMinutes?: (typeof MOVEMENT_MINUTES_KEYS)[number] | null;

  @IsOptional()
  @IsBoolean()
  period?: boolean | null;
}

export class HabitDaysQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  days?: number;
}

export interface HabitDayDto {
  day: string;
  sleepQuality: string | null;
  sleepHours: string | null;
  moved: boolean | null;
  movementMinutes: string | null;
  period: boolean | null;
  updatedAt: string;
}
