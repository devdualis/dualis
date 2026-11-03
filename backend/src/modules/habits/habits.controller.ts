import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Inject, Param, Put, Query, Request, UseGuards, ValidationPipe } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ActiveProfile, ProfileAccess, ProfileContext, ProfileContextGuard } from '../profiles/profile-context';
import { HabitDayDto, HabitDaysQueryDto, PutHabitDayDto } from './dto/habits.dto';
import { HabitsService } from './habits.service';

const userIdOf = (req: any): string => req.user?.id || req.user?.userId || req.user?.sub;
const validate = (expectedType: new () => object) =>
  new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true, expectedType });

@Controller({ path: 'habits', version: '1' })
@UseGuards(JwtAuthGuard, ProfileContextGuard)
export class HabitsController {
  constructor(@Inject(HabitsService) private readonly habits: HabitsService) {}

  @Get()
  @ProfileAccess('read', { category: 'habits' })
  listDays(@Request() req: any, @ActiveProfile() profile: ProfileContext,
    @Query(validate(HabitDaysQueryDto)) query: HabitDaysQueryDto): Promise<{ days: HabitDayDto[] }> {
    return this.habits.listDays(userIdOf(req), profile.profileId, query.days);
  }

  @Put(':day')
  @HttpCode(HttpStatus.OK)
  @ProfileAccess('write', { category: 'habits' })
  putDay(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Param('day') day: string,
    @Body(validate(PutHabitDayDto)) dto: PutHabitDayDto): Promise<HabitDayDto> {
    return this.habits.putDay(userIdOf(req), profile.profileId, day, dto);
  }

  @Delete(':day')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ProfileAccess('write', { category: 'habits' })
  deleteDay(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Param('day') day: string): Promise<void> {
    return this.habits.deleteDay(userIdOf(req), profile.profileId, day);
  }
}
