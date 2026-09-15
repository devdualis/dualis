export interface SanitizedUser {
  id: string;
  name: string;
  email: string;
  gender: string;
  dateOfBirth: string | null;
  picture?: string | null;
  isEmailVerified?: boolean;
  createdAt: Date;
  updatedAt?: Date;
}

export class AuthResponseDto {
  accessToken!: string;
  refreshToken!: string;
  user!: SanitizedUser;
}

export class RegisterResponseDto {
  requiresVerification!: boolean;
  email!: string;
  userId!: string;
  message!: string;
  user?: SanitizedUser;
}


