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
import { LogWaterDto } from './dto/log-water.dto';
import { HydrationHistoryQueryDto, HydrationTodayQueryDto } from './dto/hydration-query.dto';
import {
  HydrationHistoryResponseDto,
  HydrationTodayResponseDto,
  WaterIntakeLogItemDto,
} from './dto/hydration-response.dto';
import { HydrationService } from './hydration.service';

@Controller({ path: 'hydration', version: '1' })
@UseGuards(JwtAuthGuard)
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class HydrationController {
  constructor(
    @Inject(HydrationService)
    private readonly hydrationService: HydrationService,
  ) {}

  @Post('log')
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      expectedType: LogWaterDto,
    }),
  )
  async logWater(
    @Request() req: any,
    @Body() dto: LogWaterDto,
  ): Promise<WaterIntakeLogItemDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.hydrationService.logWater(userId, dto);
  }

  @Get('today')
  @HttpCode(HttpStatus.OK)
  async getToday(
    @Request() req: any,
    @Query() query: HydrationTodayQueryDto,
  ): Promise<HydrationTodayResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.hydrationService.getTodayLogs(userId, query.date);
  }

  @Get('history')
  @HttpCode(HttpStatus.OK)
  async getHistory(
    @Request() req: any,
    @Query() query: HydrationHistoryQueryDto,
  ): Promise<HydrationHistoryResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.hydrationService.getHistory(userId, query.days, query.referenceDate);
  }

  @Delete('log/:id')
  @HttpCode(HttpStatus.OK)
  async deleteLog(
    @Request() req: any,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<{ success: boolean; id: string }> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.hydrationService.deleteLog(userId, id);
  }
}
