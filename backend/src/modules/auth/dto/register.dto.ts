import {
  IsString,
  IsEmail,
  MinLength,
  Matches,
  IsIn,
  IsISO8601,
  Equals,
  IsOptional,
} from 'class-validator';
import { Transform } from 'class-transformer';

export class RegisterDto {
  @IsString({ message: 'Nome deve ser um texto válido.' })
  @MinLength(3, { message: 'Nome deve ter pelo menos 3 caracteres.' })
  @Matches(/^\S+\s+\S+.*$/, {
    message: 'Nome deve conter pelo menos duas palavras (nome e sobrenome).',
  })
  name!: string;

  @Transform(({ value }) => (typeof value === 'string' ? value.toLowerCase().trim() : value))
  @IsEmail({}, { message: 'Informe um endereço de e-mail válido.' })
  email!: string;

  @IsString()
  @MinLength(8, { message: 'A senha deve ter pelo menos 8 caracteres.' })
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$/, {
    message:
      'A senha deve ter pelo menos 8 caracteres, incluindo letra maiúscula, minúscula, número e símbolo especial.',
  })
  password!: string;

  @IsIn(['masculino', 'feminino', 'outro'], {
    message: 'Sexo biológico deve ser masculino, feminino ou outro.',
  })
  gender!: string;

  @IsISO8601(
    { strict: true },
    { message: 'Data de nascimento deve ser uma data válida no formato YYYY-MM-DD.' },
  )
  dateOfBirth!: string;

  @Equals(true, { message: 'Consentimento LGPD Art. 11 é obrigatório.' })
  lgpdConsent!: boolean;

  @IsOptional()
  @IsString()
  disclaimerVersion?: string;
}
