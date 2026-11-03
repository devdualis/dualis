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
  Put,
  Request,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ConfirmLegalBasisDto, CreateDependentDto } from './dto/create-dependent.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfileResponseDto } from './dto/profile-response.dto';
import { ProfilesService } from './profiles.service';

// expectedType: the test build does not emit decorator metadata (same as the family-sharing
// controller), so a pipe without it would skip body validation there.
const validate = (expectedType: new () => object) =>
  new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true, expectedType });

@Controller({ path: 'profiles', version: '1' })
@UseGuards(JwtAuthGuard)
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class ProfilesController {
  constructor(
    @Inject(ProfilesService)
    private readonly profilesService: ProfilesService,
  ) {}

  @Get()
  @HttpCode(HttpStatus.OK)
  async listProfiles(@Request() req: any): Promise<ProfileResponseDto[]> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.profilesService.getProfilesForUser(userId);
  }

  @Post('dependents')
  @HttpCode(HttpStatus.CREATED)
  async createDependent(
    @Request() req: any,
    @Body(validate(CreateDependentDto)) dto: CreateDependentDto,
  ): Promise<ProfileResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.profilesService.createDependent(userId, dto);
  }

  /** Guardian re-confirms an adult dependent's consent under LGPD Art. 11, I (A3). */
  @Post(':id/legal-basis-confirmation')
  @HttpCode(HttpStatus.OK)
  async confirmLegalBasis(
    @Request() req: any,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body(validate(ConfirmLegalBasisDto)) dto: ConfirmLegalBasisDto,
  ): Promise<ProfileResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.profilesService.confirmLegalBasis(userId, id, dto.lgpdConsent);
  }

  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async updateProfile(
    @Request() req: any,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body(validate(UpdateProfileDto)) dto: UpdateProfileDto,
  ): Promise<ProfileResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.profilesService.updateProfile(userId, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteProfile(
    @Request() req: any,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<void> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    await this.profilesService.deleteProfile(userId, id);
  }
}
