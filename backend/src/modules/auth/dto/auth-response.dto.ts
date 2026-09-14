export interface SanitizedUser {
  id: string;
  name: string;
  email: string;
  gender: string;
  dateOfBirth: string | null;
  createdAt: Date;
  updatedAt?: Date;
}

export class AuthResponseDto {
  accessToken!: string;
  refreshToken!: string;
  user!: SanitizedUser;
}
