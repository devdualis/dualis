import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  ParseUUIDPipe,
  Post,
  Request,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FamilySharingService } from './family-sharing.service';
import { CreateInviteDto } from './dto/create-invite.dto';
import { AcceptInviteDto } from './dto/accept-invite.dto';
import {
  AcceptedGrantResponseDto,
  InviteCreatedResponseDto,
  ListGrantsResponseDto,
  RevokeGrantResponseDto,
} from './dto/grant-response.dto';

@Controller({ path: 'family-sharing', version: '1' })
@UseGuards(JwtAuthGuard)
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class FamilySharingController {
  constructor(
    @Inject(FamilySharingService)
    private readonly familySharingService: FamilySharingService,
  ) {}

  @Post('invite')
  @HttpCode(HttpStatus.CREATED)
  async createInvite(
    @Request() req: any,
    @Body() dto: CreateInviteDto,
  ): Promise<InviteCreatedResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.familySharingService.createInvite(userId, dto.targetProfileId, dto.accessLevel);
  }

  @Post('accept')
  @HttpCode(HttpStatus.OK)
  async acceptInvite(
    @Request() req: any,
    @Body() dto: AcceptInviteDto,
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

  @Get('grants')
  @HttpCode(HttpStatus.OK)
  async listGrants(@Request() req: any): Promise<ListGrantsResponseDto> {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.familySharingService.listGrants(userId);
  }
}
