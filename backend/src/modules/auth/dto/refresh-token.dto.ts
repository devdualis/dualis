import { IsNotEmpty, IsString } from 'class-validator';

export class RefreshTokenDto {
  @IsString({ message: 'Token de atualização é obrigatório.' })
  @IsNotEmpty({ message: 'Token de atualização não pode ser vazio.' })
  refreshToken!: string;
}
