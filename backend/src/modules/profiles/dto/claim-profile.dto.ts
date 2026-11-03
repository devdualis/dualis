import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString, Length } from 'class-validator';

/** Hand-over code the guardian generated for a dependent who turned 18 (D3). */
export class ClaimProfileDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @IsNotEmpty()
  @Length(10, 12)
  claimCode!: string;
}
