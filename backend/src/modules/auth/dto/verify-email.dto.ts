import { IsEmail, IsString, Matches } from 'class-validator';
import { Transform } from 'class-transformer';

export class VerifyEmailDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.toLowerCase().trim() : value))
  @IsEmail({}, { message: 'Informe um endereço de e-mail válido.' })
  email!: string;

  @IsString({ message: 'O código de verificação deve ser uma string.' })
  @Matches(/^\d{6}$/, { message: 'O código de verificação deve conter exatamente 6 dígitos numéricos.' })
  code!: string;
}
