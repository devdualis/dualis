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

@Controller({ path: 'triage', version: '1' })
export class TriageAuditController {
  constructor(
    @Inject(TriageAuditService)
    private readonly triageAuditService: TriageAuditService,
  ) {}

  @Post('emergency-event')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(OptionalJwtAuthGuard)
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
  ) {
    const userId = req.user?.id || null;
    const event = await this.triageAuditService.recordEmergencyEvent(
      dto,
      userId,
    );
    return {
      success: true,
      data: event,
    };
  }
}
