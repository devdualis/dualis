import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  Post,
  Request,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { IsString, MaxLength } from 'class-validator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AiConsentService, AiConsentStatusDto } from './ai-consent.service';

export class GrantAiConsentDto {
  @IsString()
  @MaxLength(20)
  version!: string;
}

const userIdOf = (req: any): string => req.user?.id || req.user?.userId || req.user?.sub;

const userAgentOf = (req: any): string | undefined => {
  const value = req.headers?.['user-agent'];
  return typeof value === 'string' ? value : undefined;
};

// expectedType: the test build does not emit decorator metadata (same as the other controllers).
const validate = (expectedType: new () => object) =>
  UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true, expectedType }));

/**
 * Account-level permission to send journal text to the AI provider (LGPD Art. 11, I).
 * X-Profile-Id is ignored: the consent belongs to the signed-in person.
 */
@Controller({ path: 'consents', version: '1' })
@UseGuards(JwtAuthGuard)
export class AiConsentController {
  constructor(@Inject(AiConsentService) private readonly aiConsent: AiConsentService) {}

  @Get('ai-processing')
  status(@Request() req: any): Promise<AiConsentStatusDto> {
    return this.aiConsent.status(userIdOf(req));
  }

  @Post('ai-processing')
  @HttpCode(HttpStatus.OK)
  @validate(GrantAiConsentDto)
  grant(@Request() req: any, @Body() dto: GrantAiConsentDto): Promise<AiConsentStatusDto> {
    return this.aiConsent.grant(userIdOf(req), dto.version, req.ip, userAgentOf(req));
  }

  @Delete('ai-processing')
  @HttpCode(HttpStatus.OK)
  revoke(@Request() req: any): Promise<AiConsentStatusDto> {
    return this.aiConsent.revoke(userIdOf(req));
  }
}
