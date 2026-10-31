import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
  Req,
  Inject,
} from '@nestjs/common';
import { FastifyRequest } from 'fastify';
import { BodyLimit } from '../../common/http/body-limit';
import { HOUR_MS, MINUTE_MS, RateLimiter } from '../../common/http/rate-limiter';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import {
  AuthResponseDto,
  AuthenticatedUser,
  SanitizedUser,
  RegisterResponseDto,
} from './dto/auth-response.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ResendVerificationDto } from './dto/resend-verification.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { DeleteAccountDto } from './dto/delete-account.dto';
import { UserDataExportResponseDto } from './dto/export-data.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

interface AuthenticatedRequest extends FastifyRequest {
  user: AuthenticatedUser;
}

// Limits per client IP (`req.ip` is the address Cloud Run's front end saw, see main.ts) and
// per email or account. Codes also have database limits per account (AuthService.issueCode).
@Controller({ path: 'auth', version: '1' })
export class AuthController {
  constructor(
    @Inject(AuthService) private readonly authService: AuthService,
    @Inject(RateLimiter) private readonly rateLimiter: RateLimiter,
  ) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async register(
    @Body() dto: RegisterDto,
    @Req() req: FastifyRequest,
  ): Promise<RegisterResponseDto> {
    this.rateLimiter.hit(`register:ip:${req.ip}`, 10, HOUR_MS);
    const userAgent = (req.headers['user-agent'] as string) || 'Unknown';

    return this.authService.register(dto, req.ip, userAgent);
  }

  @Post('verify-email')
  @HttpCode(HttpStatus.OK)
  async verifyEmail(
    @Body() dto: VerifyEmailDto,
    @Req() req: FastifyRequest,
  ): Promise<AuthResponseDto> {
    this.rateLimiter.hit(`verify-email:ip:${req.ip}`, 30, 15 * MINUTE_MS);
    this.rateLimiter.hit(`verify-email:email:${dto.email}`, 10, 15 * MINUTE_MS);
    return this.authService.verifyEmail(dto);
  }

  @Post('resend-verification')
  @HttpCode(HttpStatus.OK)
  async resendVerification(
    @Body() dto: ResendVerificationDto,
    @Req() req: FastifyRequest,
  ): Promise<{ success: boolean; message: string }> {
    this.rateLimiter.hit(`resend-verification:ip:${req.ip}`, 10, HOUR_MS);
    this.rateLimiter.hit(`resend-verification:email:${dto.email}`, 5, HOUR_MS);
    return this.authService.resendVerification(dto);
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  async forgotPassword(
    @Body() dto: ForgotPasswordDto,
    @Req() req: FastifyRequest,
  ): Promise<{ success: boolean; message: string }> {
    this.rateLimiter.hit(`forgot-password:ip:${req.ip}`, 10, HOUR_MS);
    this.rateLimiter.hit(`forgot-password:email:${dto.email}`, 5, HOUR_MS);
    return this.authService.forgotPassword(dto);
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(
    @Body() dto: ResetPasswordDto,
    @Req() req: FastifyRequest,
  ): Promise<{ success: boolean; message: string }> {
    this.rateLimiter.hit(`reset-password:ip:${req.ip}`, 30, 15 * MINUTE_MS);
    this.rateLimiter.hit(`reset-password:email:${dto.email}`, 10, 15 * MINUTE_MS);
    return this.authService.resetPassword(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginDto, @Req() req: FastifyRequest): Promise<AuthResponseDto> {
    this.rateLimiter.hit(`login:ip:${req.ip}`, 30, 15 * MINUTE_MS);
    this.rateLimiter.hit(`login:email:${dto.email}`, 10, 15 * MINUTE_MS);
    return this.authService.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshTokenDto): Promise<AuthResponseDto> {
    return this.authService.refreshTokens(dto.refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  @HttpCode(HttpStatus.OK)
  async getProfile(@Req() req: AuthenticatedRequest): Promise<SanitizedUser> {
    return this.authService.getProfile(req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  @HttpCode(HttpStatus.OK)
  @BodyLimit(5 * 1024 * 1024) // the app re-sends the current picture, which older versions kept larger
  async updateProfile(
    @Req() req: AuthenticatedRequest,
    @Body() dto: UpdateProfileDto,
  ): Promise<SanitizedUser> {
    return this.authService.updateProfile(req.user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('change-password')
  @HttpCode(HttpStatus.OK)
  async changePassword(
    @Req() req: AuthenticatedRequest,
    @Body() dto: ChangePasswordDto,
  ): Promise<{ success: boolean; message: string; accessToken: string; refreshToken: string }> {
    this.rateLimiter.hit(`password-check:user:${req.user.id}`, 10, 15 * MINUTE_MS);
    return this.authService.changePassword(req.user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('export-data')
  @HttpCode(HttpStatus.OK)
  async exportData(
    @Req() req: AuthenticatedRequest,
  ): Promise<UserDataExportResponseDto> {
    return this.authService.exportUserData(req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('account')
  @HttpCode(HttpStatus.OK)
  async deleteAccount(
    @Req() req: AuthenticatedRequest,
    @Body() dto: DeleteAccountDto,
  ): Promise<{ success: boolean; message: string }> {
    this.rateLimiter.hit(`password-check:user:${req.user.id}`, 10, 15 * MINUTE_MS);
    return this.authService.deleteUserAccount(req.user.id, dto);
  }
}
