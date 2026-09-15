import { IsString, MinLength, Matches } from 'class-validator';

export class ChangePasswordDto {
  @IsString({ message: 'Senha atual é obrigatória.' })
  @MinLength(1, { message: 'Senha atual é obrigatória.' })
  currentPassword!: string;

  @IsString({ message: 'A nova senha deve ser um texto válido.' })
  @MinLength(8, { message: 'A nova senha deve ter pelo menos 8 caracteres.' })
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$/, {
    message:
      'A nova senha deve ter pelo menos 8 caracteres, incluindo letra maiúscula, minúscula, número e símbolo especial.',
  })
  newPassword!: string;
}
