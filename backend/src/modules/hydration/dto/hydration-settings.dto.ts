import { ArrayMaxSize, IsArray, IsBoolean, IsIn, IsInt, Max, Min } from 'class-validator';

export const REMINDER_SOUND_STYLES = ['whatsapp_chime', 'phone_alarm'] as const;

/** The person's water goal and reminder choices (`users.hydration_settings`). */
export class HydrationSettingsDto {
  @IsBoolean()
  reminderEnabled!: boolean;

  @IsBoolean()
  trackingEnabled!: boolean;

  @IsIn(REMINDER_SOUND_STYLES)
  reminderSoundStyle!: (typeof REMINDER_SOUND_STYLES)[number];

  @IsInt()
  @Min(250)
  @Max(10000)
  dailyTargetMl!: number;

  @IsArray()
  @ArrayMaxSize(24)
  @IsInt({ each: true })
  @Min(0, { each: true })
  @Max(23, { each: true })
  scheduledHours!: number[];
}

export class HydrationSettingsResponseDto {
  /** Null until the app saves settings once. */
  settings!: HydrationSettingsDto | null;
}
