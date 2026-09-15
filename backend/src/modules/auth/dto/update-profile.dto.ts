import {
  IsString,
  MinLength,
  IsIn,
  IsISO8601,
  IsOptional,
} from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString({ message: 'Nome deve ser um texto válido.' })
  @MinLength(2, { message: 'Nome deve ter pelo menos 2 caracteres.' })
  name?: string;

  @IsOptional()
  @IsISO8601(
    { strict: true },
    { message: 'Data de nascimento deve ser uma data válida no formato YYYY-MM-DD.' },
  )
  dateOfBirth?: string;

  @IsOptional()
  @IsString({ message: 'Avatar deve ser uma string válida.' })
  picture?: string;

  @IsOptional()
  @IsIn(['masculino', 'feminino', 'outro'], {
    message: 'Sexo biológico deve ser masculino, feminino ou outro.',
  })
  gender?: string;
}
