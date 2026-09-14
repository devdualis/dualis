import {
  Injectable,
  Inject,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { eq, sql } from 'drizzle-orm';
import * as crypto from 'crypto';
import { DRIZZLE_DB } from '../../database/database.service';
import * as schema from '../../database/schema';
import { users, userDisclaimerConsents } from '../../database/schema';
import { hashPassword, verifyPassword } from './utils/password.util';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto, SanitizedUser } from './dto/auth-response.dto';

@Injectable()
export class AuthService {
  constructor(
    @Inject(DRIZZLE_DB) private readonly db: NodePgDatabase<typeof schema>,
    private readonly jwtService: JwtService,
  ) {}

  async register(
    dto: RegisterDto,
    clientIp: string = '127.0.0.1',
    userAgent: string = 'Unknown',
  ): Promise<AuthResponseDto> {
    if (dto.lgpdConsent !== true) {
      throw new BadRequestException('Consentimento LGPD Art. 11 é obrigatório.');
    }

    const email = dto.email.toLowerCase().trim();

    // Check email uniqueness within transaction with auth service setting
    const existing = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.email, email))
        .limit(1);
      return record;
    });

    if (existing) {
      throw new ConflictException('E-mail já cadastrado.');
    }

    const newUserId = crypto.randomUUID();
    const passwordHash = await hashPassword(dto.password);
    const ipAddressHash = crypto.createHash('sha256').update(clientIp || '127.0.0.1').digest('hex');

    const created = await this.db.transaction(async (tx) => {
      // 1. Set current user ID to satisfy users & userDisclaimerConsents RLS
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${newUserId}, true)`,
      );

      // 2. Insert into users
      const [insertedUser] = await tx
        .insert(users)
        .values({
          id: newUserId,
          name: dto.name,
          email,
          passwordHash,
          gender: dto.gender,
          dateOfBirth: dto.dateOfBirth,
        })
        .returning();

      // 3. Atomically record consent into user_disclaimer_consents
      await tx.insert(userDisclaimerConsents).values({
        userId: newUserId,
        disclaimerVersion: dto.disclaimerVersion || '2026.1',
        ipAddressHash,
        userAgent: userAgent || 'Unknown',
      });

      return insertedUser;
    });

    const sanitizedUser: SanitizedUser = {
      id: created.id,
      name: created.name,
      email: created.email,
      gender: created.gender,
      dateOfBirth: created.dateOfBirth,
      createdAt: created.createdAt,
      updatedAt: created.updatedAt,
    };

    const tokens = this.generateTokens(created.id, created.email);

    return {
      ...tokens,
      user: sanitizedUser,
    };
  }

  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const email = dto.email.toLowerCase().trim();

    const user = await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT set_config('app.is_auth_service', 'true', true)`);
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.email, email))
        .limit(1);
      return record;
    });

    if (!user) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    const isMatch = await verifyPassword(user.passwordHash, dto.password);
    if (!isMatch) {
      throw new UnauthorizedException('Credenciais inválidas.');
    }

    const sanitizedUser: SanitizedUser = {
      id: user.id,
      name: user.name,
      email: user.email,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };

    const tokens = this.generateTokens(user.id, user.email);

    return {
      ...tokens,
      user: sanitizedUser,
    };
  }

  async validateUserById(id: string): Promise<SanitizedUser | null> {
    const user = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${id}, true)`,
      );
      const [record] = await tx
        .select()
        .from(users)
        .where(eq(users.id, id))
        .limit(1);
      return record;
    });

    if (!user) return null;

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });
    return { accessToken, refreshToken };
  }
}
