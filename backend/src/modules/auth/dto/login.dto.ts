import { IsEmail, IsNotEmpty, IsString } from 'class-validator';
import { Transform } from 'class-transformer';

export class LoginDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.toLowerCase().trim() : value))
  @IsEmail({}, { message: 'Informe um endereço de e-mail válido.' })
  email!: string;

  @IsString({ message: 'Senha é obrigatória.' })
  @IsNotEmpty({ message: 'Senha não pode ser vazia.' })
  password!: string;
}
