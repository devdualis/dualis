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

/** What the JWT strategy puts on `req.user`: only what requests need. */
export interface AuthenticatedUser {
  id: string;
  email: string;
}

export class AuthResponseDto {
  accessToken!: string;
  refreshToken!: string;
  user!: SanitizedUser;
}

/** Same for a new or an already registered address. */
export class RegisterResponseDto {
  requiresVerification!: boolean;
  email!: string;
  message!: string;
}
