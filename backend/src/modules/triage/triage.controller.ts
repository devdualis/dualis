import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Inject,
  Post,
  Request,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SubmitTriageDto, TriageOutcomeResponseDto } from './dto/triage-outcome.dto';
import { TriageOutcomeService } from './services/triage-outcome.service';

@Controller({ path: 'triage', version: '1' })
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class TriageController {
  constructor(
    @Inject(TriageOutcomeService)
    private readonly triageOutcomeService: TriageOutcomeService,
  ) {}

  @Post('outcome')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      expectedType: SubmitTriageDto,
    }),
  )
  async createOutcome(
    @Request() req: any,
    @Body() dto: SubmitTriageDto,
  ): Promise<TriageOutcomeResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.triageOutcomeService.processOutcome(userId, dto);
  }
}
