import { Controller, Get, HttpCode, HttpStatus, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface AppConfigResponseDto {
  minSupportedVersion: string;
}

const DEFAULT_MIN_SUPPORTED_VERSION = '1.0.0';
const SEMVER_PATTERN = /^\d+\.\d+\.\d+$/;

/** Public (no auth): the app checks it at startup and asks for an update below the minimum. */
@Controller({ path: 'app', version: '1' })
export class AppConfigController {
  constructor(@Inject(ConfigService) private readonly configService: ConfigService) {}

  @Get('config')
  @HttpCode(HttpStatus.OK)
  getConfig(): AppConfigResponseDto {
    const configured = this.configService.get<string>('MIN_SUPPORTED_APP_VERSION')?.trim();
    return {
      minSupportedVersion:
        configured && SEMVER_PATTERN.test(configured) ? configured : DEFAULT_MIN_SUPPORTED_VERSION,
    };
  }
}
