import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Request,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FamilySharingService } from './family-sharing.service';
import { CreateInviteDto } from './dto/create-invite.dto';
import { AcceptInviteDto } from './dto/accept-invite.dto';
import { UpdateGrantDto } from './dto/update-grant.dto';
import {
  AcceptedGrantResponseDto,
  InviteCreatedResponseDto,
  ListGrantsResponseDto,
  OutgoingGrantItemDto,
  RevokeGrantResponseDto,
} from './dto/grant-response.dto';

// expectedType: the test build does not emit decorator metadata (same as the habits and journal controllers),
// so a pipe without it would skip validation there.
const validate = (expectedType: new () => object) =>
  new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true, expectedType });

@Controller({ path: 'family-sharing', version: '1' })
@UseGuards(JwtAuthGuard)
export class FamilySharingController {
  constructor(
    @Inject(FamilySharingService)
    private readonly familySharingService: FamilySharingService,
  ) {}

  @Post('invite')
  @HttpCode(HttpStatus.CREATED)
  async createInvite(
    @Request() req: any,
    @Body(validate(CreateInviteDto)) dto: CreateInviteDto,
  ): Promise<InviteCreatedResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.familySharingService.createInvite(userId, dto.targetProfileId, dto.accessLevel, {
      relationship: dto.relationship,
      categories: dto.categories,
      dependentShareConfirmed: dto.dependentShareConfirmed,
    });
  }

  @Post('accept')
  @HttpCode(HttpStatus.OK)
  async acceptInvite(
    @Request() req: any,
    @Body(validate(AcceptInviteDto)) dto: AcceptInviteDto,
  ): Promise<AcceptedGrantResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.familySharingService.acceptInvite(userId, dto.inviteCode);
  }

  @Post('revoke/:id')
  @HttpCode(HttpStatus.OK)
  async revokeGrant(
    @Request() req: any,
    @Param('id', new ParseUUIDPipe()) id: string,
  ): Promise<RevokeGrantResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.familySharingService.revokeGrant(userId, id);
  }

  /** The granter edits a grant's categories and/or relationship (PREM-07). */
  @Patch('grants/:id')
  @HttpCode(HttpStatus.OK)
  async updateGrant(
    @Request() req: any,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body(validate(UpdateGrantDto)) dto: UpdateGrantDto,
  ): Promise<OutgoingGrantItemDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.familySharingService.updateGrant(userId, id, dto);
  }

  @Get('grants')
  @HttpCode(HttpStatus.OK)
  async listGrants(@Request() req: any): Promise<ListGrantsResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.familySharingService.listGrants(userId);
  }
}
