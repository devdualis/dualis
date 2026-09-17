import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Request,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CheckAntiburlaDto, AntiburlaCheckResponseDto } from './dto/antiburla.dto';
import { SubmitTriageDto, TriageOutcomeResponseDto } from './dto/triage-outcome.dto';
import {
  SubmitDailyCheckInDto,
  DailyCheckInResponseDto,
} from './dto/daily-checkin.dto';
import {
  GetTriageHistoryQueryDto,
  TriageHistoryResponseDto,
} from './dto/triage-history.dto';
import { TriageOutcomeService } from './services/triage-outcome.service';
import { AntiburlaService } from './services/antiburla.service';
import { TriageHistoryService } from './services/triage-history.service';

@Controller({ path: 'triage', version: '1' })
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class TriageController {
  constructor(
    @Inject(TriageOutcomeService)
    private readonly triageOutcomeService: TriageOutcomeService,
    @Inject(AntiburlaService)
    private readonly antiburlaService: AntiburlaService,
    @Inject(TriageHistoryService)
    private readonly triageHistoryService: TriageHistoryService,
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

  @Post('daily-checkin')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      expectedType: SubmitDailyCheckInDto,
    }),
  )
  async createDailyCheckIn(
    @Request() req: any,
    @Body() dto: SubmitDailyCheckInDto,
  ): Promise<DailyCheckInResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.triageOutcomeService.recordDailyCheckIn(userId, dto);
  }

  @Post('antiburla-check')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      expectedType: CheckAntiburlaDto,
    }),
  )
  async checkAntiburla(
    @Request() req: any,
    @Body() dto: CheckAntiburlaDto,
  ): Promise<AntiburlaCheckResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.antiburlaService.checkHistoricalConsistency(userId, dto);
  }

  @Get('history')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      expectedType: GetTriageHistoryQueryDto,
    }),
  )
  async getHistory(
    @Request() req: any,
    @Query() query: GetTriageHistoryQueryDto,
  ): Promise<TriageHistoryResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.triageHistoryService.getHistory(userId, query);
  }

  @Delete('history/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async deleteHistoryItem(
    @Request() req: any,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<{ success: boolean; id: string }> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.triageHistoryService.deleteHistoryItem(userId, id);
  }
}
