import { IsEmail } from 'class-validator';
import { Transform } from 'class-transformer';

export class ResendVerificationDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.toLowerCase().trim() : value))
  @IsEmail({}, { message: 'Informe um endereço de e-mail válido.' })
  email!: string;
}
