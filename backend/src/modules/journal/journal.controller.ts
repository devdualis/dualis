import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
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
import { resolveLang } from '../../common/i18n/lang';
import {
  CreateConditionDto,
  CreateJournalEntryDto,
  JournalDaysQueryDto,
  JournalEntriesResponseDto,
  JournalEntryDto,
  JournalSummaryDto,
  SuggestJournalOptionDto,
  SuggestJournalOptionResponseDto,
  UserConditionDto,
  UserConditionsResponseDto,
} from './dto/journal.dto';
import { HouseAdsResponseDto, houseAdsFor } from './house-ads';
import { JournalService } from './journal.service';
import { JournalSuggestService } from './journal-suggest.service';

const userIdOf = (req: any): string => req.user?.id || req.user?.userId || req.user?.sub;

// expectedType: the test build does not emit decorator metadata (same as the other controllers).
const validate = (expectedType: new () => object) =>
  UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true, expectedType }));

/** Journal v2 (docs/bienestar/CONTRATO-JOURNAL-V2.md). Legacy /journal routes live in TriageController. */
@Controller({ path: 'journal', version: '1' })
@UseGuards(JwtAuthGuard, ProfileContextGuard)
export class JournalController {
  constructor(
    @Inject(JournalService) private readonly journalService: JournalService,
    @Inject(JournalSuggestService) private readonly journalSuggest: JournalSuggestService,
  ) {}

  @Post('entries')
  @HttpCode(HttpStatus.CREATED)
  @ProfileAccess('write')
  @validate(CreateJournalEntryDto)
  createEntry(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Body() dto: CreateJournalEntryDto,
  ): Promise<JournalEntryDto> {
    return this.journalService.createEntry(userIdOf(req), profile.profileId, dto);
  }

  @Get('entries')
  @ProfileAccess('read')
  @validate(JournalDaysQueryDto)
  listEntries(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Query() query: JournalDaysQueryDto,
  ): Promise<JournalEntriesResponseDto> {
    const acceptLanguage = req.headers?.['accept-language'];
    return this.journalService.listEntries(userIdOf(req), profile.profileId, query, acceptLanguage);
  }

  @Delete('entries/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ProfileAccess('write')
  async deleteEntry(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<void> {
    await this.journalService.deleteEntry(userIdOf(req), profile.profileId, id);
  }

  @Post('suggest-option')
  @HttpCode(HttpStatus.OK)
  @ProfileAccess('write')
  @validate(SuggestJournalOptionDto)
  suggestOption(
    @Body() dto: SuggestJournalOptionDto,
  ): Promise<SuggestJournalOptionResponseDto> {
    return this.journalSuggest.suggest(dto.text, dto.kind, dto.branch);
  }

  @Get('summary')
  @ProfileAccess('read')
  @validate(JournalDaysQueryDto)
  summary(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Query() query: JournalDaysQueryDto,
  ): Promise<JournalSummaryDto> {
    return this.journalService.summary(userIdOf(req), profile.profileId, query);
  }

  @Get('conditions')
  @ProfileAccess('read')
  listConditions(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
  ): Promise<UserConditionsResponseDto> {
    return this.journalService.listConditions(userIdOf(req), profile.profileId);
  }

  @Post('conditions')
  @HttpCode(HttpStatus.CREATED)
  @ProfileAccess('write')
  @validate(CreateConditionDto)
  createCondition(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Body() dto: CreateConditionDto,
  ): Promise<UserConditionDto> {
    return this.journalService.createCondition(userIdOf(req), profile.profileId, dto.label);
  }

  @Delete('conditions/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ProfileAccess('write')
  async archiveCondition(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<void> {
    await this.journalService.archiveCondition(userIdOf(req), profile.profileId, id);
  }
}

/**
 * Own ads, the same for everyone. Public on purpose: it takes no user, profile or
 * entry data, so nothing recorded can reach it.
 */
@Controller({ path: 'house-ads', version: '1' })
export class HouseAdsController {
  @Get()
  list(@Headers('accept-language') acceptLanguage?: string): HouseAdsResponseDto {
    return houseAdsFor(resolveLang(acceptLanguage));
  }
}
