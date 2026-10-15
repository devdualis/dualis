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
import { TriageAuditService } from './triage-audit.service';
import { CreateEmergencyEventDto } from './dto/create-emergency-event.dto';
import { OptionalJwtAuthGuard } from './guards/optional-jwt-auth.guard';
import {
  ActiveProfile,
  ProfileAccess,
  ProfileContext,
  ProfileContextGuard,
} from '../profiles/profile-context';

@Controller({ path: 'triage', version: '1' })
export class TriageAuditController {
  constructor(
    @Inject(TriageAuditService)
    private readonly triageAuditService: TriageAuditService,
  ) {}

  @Post('emergency-event')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(OptionalJwtAuthGuard, ProfileContextGuard)
  // Read access only: an emergency must never be blocked by a permission level.
  @ProfileAccess('read', { allowAnonymous: true })
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      expectedType: CreateEmergencyEventDto,
    }),
  )
  async createEmergencyEvent(
    @Body() dto: CreateEmergencyEventDto,
    @Req() req: any,
    @ActiveProfile() profile?: ProfileContext,
  ) {
    const userId = req.user?.id || null;
    const event = await this.triageAuditService.recordEmergencyEvent(
      dto,
      userId,
      profile?.profileId ?? null,
    );
    return {
      success: true,
      data: event,
    };
  }
}
