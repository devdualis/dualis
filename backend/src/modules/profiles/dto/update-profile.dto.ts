import { IsIn, IsISO8601, IsOptional, IsString, IsUrl, MaxLength, MinLength } from 'class-validator';
import { PROFILE_GENDERS } from './create-dependent.dto';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  name?: string;

  @IsOptional()
  @IsISO8601(
    { strict: true },
    { message: 'Data de nascimento deve ser uma data válida no formato YYYY-MM-DD.' },
  )
  dateOfBirth?: string;

  @IsOptional()
  @IsIn(PROFILE_GENDERS, {
    message: 'Sexo biológico deve ser masculino, feminino ou outro.',
  })
  gender?: string;

  @IsOptional()
  @IsUrl({ protocols: ['https'], require_protocol: true })
  @MaxLength(2048)
  avatarUrl?: string;
}
