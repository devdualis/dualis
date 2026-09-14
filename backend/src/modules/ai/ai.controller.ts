import { BadRequestException, Body, Controller, HttpCode, HttpStatus, Inject, Post, UseGuards, UsePipes, ValidationPipe } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ClassifySymptomDto, TriageClassificationResult } from './dto/classify-symptom.dto';
import { GeminiTriageService } from './services/gemini-triage.service';

@Controller('v1/ai')
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class AiController {
  constructor(
    @Inject(GeminiTriageService)
    private readonly geminiTriageService: GeminiTriageService,
  ) {}

  @Post('classify-symptom')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async classifySymptom(
    @Body(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
    dto: ClassifySymptomDto,
  ): Promise<TriageClassificationResult> {
    if (!dto || !dto.text || typeof dto.text !== 'string' || dto.text.trim().length < 2) {
      throw new BadRequestException('O texto do sintoma deve ter pelo menos 2 caracteres.');
    }
    return this.geminiTriageService.classify(dto);
  }
}
