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
import {
  ActiveProfile,
  ProfileAccess,
  ProfileContext,
  ProfileContextGuard,
} from '../profiles/profile-context';
import { LogWaterDto } from './dto/log-water.dto';
import { HydrationHistoryQueryDto, HydrationTodayQueryDto } from './dto/hydration-query.dto';
import {
  HydrationHistoryResponseDto,
  HydrationTodayResponseDto,
  WaterIntakeLogItemDto,
} from './dto/hydration-response.dto';
import { HydrationService } from './hydration.service';

@Controller({ path: 'hydration', version: '1' })
@UseGuards(JwtAuthGuard, ProfileContextGuard)
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class HydrationController {
  constructor(
    @Inject(HydrationService)
    private readonly hydrationService: HydrationService,
  ) {}

  @Post('log')
  @HttpCode(HttpStatus.CREATED)
  @ProfileAccess('write')
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
    @ActiveProfile() profile: ProfileContext,
    @Body() dto: LogWaterDto,
  ): Promise<WaterIntakeLogItemDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.hydrationService.logWater(userId, profile.profileId, dto);
  }

  @Get('today')
  @HttpCode(HttpStatus.OK)
  @ProfileAccess('read')
  async getToday(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Query() query: HydrationTodayQueryDto,
  ): Promise<HydrationTodayResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.hydrationService.getTodayLogs(userId, profile.profileId, query.date);
  }

  @Get('history')
  @HttpCode(HttpStatus.OK)
  @ProfileAccess('read')
  async getHistory(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Query() query: HydrationHistoryQueryDto,
  ): Promise<HydrationHistoryResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.hydrationService.getHistory(userId, profile.profileId, query.days, query.referenceDate);
  }

  @Delete('log/:id')
  @HttpCode(HttpStatus.OK)
  @ProfileAccess('write')
  async deleteLog(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<{ success: boolean; id: string }> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.hydrationService.deleteLog(userId, profile.profileId, id);
  }
}
