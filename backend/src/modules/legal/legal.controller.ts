import { Controller, Get, Headers, Inject, Query } from '@nestjs/common';
import { LegalService } from './legal.service';
import { MedicalDisclaimerResponseDto } from './dto/medical-disclaimer-response.dto';

@Controller('legal')
export class LegalController {
  constructor(@Inject(LegalService) private readonly legalService: LegalService) {}

  @Get('disclaimer')
  getMedicalDisclaimer(
    @Query('lang') lang?: string,
    @Headers('accept-language') acceptLanguage?: string,
  ): MedicalDisclaimerResponseDto {
    return this.legalService.getMedicalDisclaimer(lang, acceptLanguage);
  }
}
