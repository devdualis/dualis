import { Controller, Get, Headers, Inject, Query } from '@nestjs/common';
import { LegalService } from './legal.service';
import { MedicalDisclaimerResponseDto } from './dto/medical-disclaimer-response.dto';
import {
  LegalEntityDetailsDto,
  TermsOfServiceResponseDto,
  PrivacyPolicyResponseDto,
  SecurityPolicyResponseDto,
} from './dto/saas-legal-documents.dto';

@Controller('legal')
export class LegalController {
  constructor(@Inject(LegalService) private readonly legalService: LegalService) {}

  @Get('entity')
  getLegalEntity(): LegalEntityDetailsDto {
    return this.legalService.getLegalEntityDetails();
  }

  @Get('terms-of-service')
  getTermsOfService(
    @Query('lang') lang?: string,
    @Headers('accept-language') acceptLanguage?: string,
  ): TermsOfServiceResponseDto {
    return this.legalService.getTermsOfService(lang, acceptLanguage);
  }

  @Get('privacy-policy')
  getPrivacyPolicy(
    @Query('lang') lang?: string,
    @Headers('accept-language') acceptLanguage?: string,
  ): PrivacyPolicyResponseDto {
    return this.legalService.getPrivacyPolicy(lang, acceptLanguage);
  }

  @Get('security-policy')
  getSecurityPolicy(
    @Query('lang') lang?: string,
    @Headers('accept-language') acceptLanguage?: string,
  ): SecurityPolicyResponseDto {
    return this.legalService.getSecurityPolicy(lang, acceptLanguage);
  }

  @Get('disclaimer')
  getMedicalDisclaimer(
    @Query('lang') lang?: string,
    @Headers('accept-language') acceptLanguage?: string,
  ): MedicalDisclaimerResponseDto {
    return this.legalService.getMedicalDisclaimer(lang, acceptLanguage);
  }
}
