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
  Patch,
  Post,
  Put,
  Query,
  Request,
  Res,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import type { FastifyReply } from 'fastify';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ActiveProfile, ProfileAccess, ProfileContext, ProfileContextGuard } from '../profiles/profile-context';
import {
  CreateCareRecordDto,
  CreateIntakeDto,
  ListCareRecordsQueryDto,
  ListDocumentsQueryDto,
  ReviewDocumentDto,
  UpdateCareRecordDto,
  UploadDocumentDto,
} from './care.dto';
import { CareService } from './care.service';

const userIdOf = (req: any): string => req.user?.id || req.user?.userId || req.user?.sub;

/**
 * Premium "Meus cuidados": vaccine doses, allergies, medications and intakes,
 * appointments, and exam/prescription documents of the active profile (X-Profile-Id).
 */
@Controller({ path: 'care', version: '1' })
@UseGuards(JwtAuthGuard, ProfileContextGuard)
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class CareController {
  constructor(@Inject(CareService) private readonly care: CareService) {}

  @Get('records')
  @ProfileAccess('read')
  list(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Query() query: ListCareRecordsQueryDto) {
    return this.care.listRecords(userIdOf(req), profile.profileId, query);
  }

  @Post('records')
  @HttpCode(HttpStatus.CREATED)
  @ProfileAccess('write')
  create(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Body() dto: CreateCareRecordDto) {
    return this.care.createRecord(userIdOf(req), profile.profileId, dto);
  }

  @Patch('records/:id')
  @ProfileAccess('write')
  update(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: UpdateCareRecordDto,
  ) {
    return this.care.updateRecord(userIdOf(req), profile.profileId, id, dto.data);
  }

  @Delete('records/:id')
  @ProfileAccess('write')
  remove(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.care.deleteRecord(userIdOf(req), profile.profileId, id);
  }

  @Post('medications/:id/intakes')
  @HttpCode(HttpStatus.CREATED)
  @ProfileAccess('write')
  logIntake(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: CreateIntakeDto,
  ) {
    return this.care.logIntake(userIdOf(req), profile.profileId, id, dto);
  }

  @Get('documents')
  @ProfileAccess('read')
  listDocuments(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Query() query: ListDocumentsQueryDto) {
    return this.care.listDocuments(userIdOf(req), profile.profileId, query.kind);
  }

  @Post('documents')
  @HttpCode(HttpStatus.CREATED)
  @ProfileAccess('write')
  upload(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Body() dto: UploadDocumentDto) {
    return this.care.uploadDocument(userIdOf(req), profile.profileId, dto);
  }

  @Get('documents/:id')
  @ProfileAccess('read')
  getDocument(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.care.getDocument(userIdOf(req), profile.profileId, id);
  }

  @Get('documents/:id/file')
  @ProfileAccess('read')
  async getDocumentFile(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Res() reply: FastifyReply,
  ) {
    const { mime, file } = await this.care.getDocumentFile(userIdOf(req), profile.profileId, id);
    reply.header('Content-Type', mime).header('Cache-Control', 'private, no-store').send(file);
  }

  @Put('documents/:id/review')
  @ProfileAccess('write')
  review(
    @Request() req: any,
    @ActiveProfile() profile: ProfileContext,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: ReviewDocumentDto,
  ) {
    return this.care.reviewDocument(userIdOf(req), profile.profileId, id, dto);
  }

  @Post('documents/:id/reprocess')
  @HttpCode(HttpStatus.ACCEPTED)
  @ProfileAccess('write')
  reprocess(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.care.reprocessDocument(userIdOf(req), profile.profileId, id);
  }

  @Delete('documents/:id')
  @ProfileAccess('write')
  removeDocument(@Request() req: any, @ActiveProfile() profile: ProfileContext, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.care.deleteDocument(userIdOf(req), profile.profileId, id);
  }
}
