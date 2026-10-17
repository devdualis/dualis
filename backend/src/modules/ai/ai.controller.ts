import { BadRequestException, Body, Controller, HttpCode, HttpStatus, Inject, Post, UseGuards, UsePipes, ValidationPipe } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { EntryTagResponseDto, TagEntryDto } from './dto/classify-symptom.dto';
import { AiTaggingService } from './services/ai-tagging.service';

@Controller({ path: 'ai', version: '1' })
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class AiController {
  constructor(
    @Inject(AiTaggingService)
    private readonly aiTaggingService: AiTaggingService,
  ) {}

  /** `tag-entry` is the current path; `classify-symptom` stays as an alias for published app versions. */
  @Post(['tag-entry', 'classify-symptom'])
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async tagEntry(
    @Body(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
    dto: TagEntryDto,
  ): Promise<EntryTagResponseDto> {
    if (!dto || !dto.text || typeof dto.text !== 'string' || dto.text.trim().length < 2) {
      throw new BadRequestException('O texto deve ter pelo menos 2 caracteres.');
    }
    return this.aiTaggingService.tagEntry(dto);
  }
}
