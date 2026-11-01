import { IsIn, IsISO8601, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { PROFILE_GENDERS } from './create-dependent.dto';

/**
 * No picture link: every phone that shows the profile would load it, telling whoever runs
 * that server its IP address and when the app is open. Unknown fields are a 400.
 */
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
}
