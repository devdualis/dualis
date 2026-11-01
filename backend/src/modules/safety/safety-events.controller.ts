import {
  Controller,
  Post,
  Body,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
  Inject,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { MINUTE_MS, RateLimiter } from '../../common/http/rate-limiter';
import { SafetyEventsService } from './safety-events.service';
import { CreateSafetyEventDto } from './dto/create-safety-event.dto';
import { LegacyEmergencyEventDto } from './dto/legacy-emergency-event.dto';
import { OptionalJwtAuthGuard } from './guards/optional-jwt-auth.guard';
import {
  ActiveProfile,
  ProfileAccess,
  ProfileContext,
  ProfileContextGuard,
} from '../profiles/profile-context';

/**
 * Audit of the static help resources. Session and X-Profile-Id are optional, and read
 * access is enough: reaching help must never be blocked by a login or a permission level.
 * Every call stores a row, so calls are capped (429): per account when signed in, per IP and
 * in total when anonymous. The app sends these events fire-and-forget, so a 429 never delays
 * the help screen or the call.
 */
@Controller({ version: '1' })
@UseGuards(OptionalJwtAuthGuard, ProfileContextGuard)
@ProfileAccess('read', { allowAnonymous: true })
export class SafetyEventsController {
  constructor(
    @Inject(SafetyEventsService)
    private readonly safetyEventsService: SafetyEventsService,
    @Inject(RateLimiter) private readonly rateLimiter: RateLimiter,
  ) {}

  private limit(req: any): void {
    if (req.user?.id) {
      this.rateLimiter.hit(`safety-event:user:${req.user.id}`, 30, MINUTE_MS);
      return;
    }
    this.rateLimiter.hit(`safety-event:ip:${req.ip}`, 10, MINUTE_MS);
    this.rateLimiter.hit('safety-event:anonymous', 30, MINUTE_MS);
  }

  @Post('journal/safety-event')
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      expectedType: CreateSafetyEventDto,
    }),
  )
  async createSafetyEvent(
    @Body() dto: CreateSafetyEventDto,
    @Req() req: any,
    @ActiveProfile() profile?: ProfileContext,
  ) {
    this.limit(req);
    const event = await this.safetyEventsService.recordSafetyEvent(
      dto,
      req.user?.id || null,
      profile?.profileId ?? null,
    );
    return { success: true, data: event };
  }

  /** Legacy alias used by published app versions. */
  @Post('triage/emergency-event')
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      expectedType: LegacyEmergencyEventDto,
    }),
  )
  async createLegacyEmergencyEvent(
    @Body() dto: LegacyEmergencyEventDto,
    @Req() req: any,
    @ActiveProfile() profile?: ProfileContext,
  ) {
    this.limit(req);
    const event = await this.safetyEventsService.recordLegacyEmergencyEvent(
      dto,
      req.user?.id || null,
      profile?.profileId ?? null,
    );
    return { success: true, data: event };
  }
}
