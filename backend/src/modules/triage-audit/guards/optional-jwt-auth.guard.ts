import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  override handleRequest<TUser = any>(err: any, user: any): TUser {
    // If error or unauthenticated, return null instead of throwing UnauthorizedException
    if (err || !user) {
      return null as TUser;
    }
    return user;
  }
}
