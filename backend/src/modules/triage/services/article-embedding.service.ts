import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';

@Injectable()
export class ArticleEmbeddingService {
  private readonly logger = new Logger(ArticleEmbeddingService.name);
  private readonly client: GoogleGenAI | null = null;

  constructor(
    @Optional() @Inject(ConfigService) private readonly configService?: ConfigService,
  ) {
    const apiKey =
      this.configService?.get<string>('GEMINI_API') ||
      this.configService?.get<string>('GEMINI_API_KEY') ||
      process.env.GEMINI_API ||
      process.env.GEMINI_API_KEY;

    if (apiKey && apiKey !== 'mock-gemini-key') {
      try {
        this.client = new GoogleGenAI({ apiKey });
      } catch (err) {
        this.logger.warn(`Failed to initialize GoogleGenAI for embeddings: ${(err as Error).message}`);
      }
    }
  }

  async embed(text: string): Promise<number[]> {
    if (this.client) {
      try {
        const response = await this.client.models.embedContent({
          model: 'text-embedding-004',
          contents: text,
        });
        const values = (response as any)?.embedding?.values || (response as any)?.embeddings?.[0]?.values;
        if (Array.isArray(values) && values.length > 0) {
          return values;
        }
      } catch (err) {
        this.logger.warn(`Gemini embedding failed, falling back to clinical vector projection: ${(err as Error).message}`);
      }
    }
    return this.generateDeterministicEmbedding(text);
  }

  generateDeterministicEmbedding(text: string): number[] {
    const vector = new Array(768).fill(0);
    const normalized = text.toLowerCase().trim();
    for (let i = 0; i < normalized.length; i++) {
      const code = normalized.charCodeAt(i);
      const idx = (code * 31 + i * 17) % 768;
      vector[idx] += 0.5;
    }
    const words = normalized.split(/[\s,.;:!?/\\-]+/).filter((w) => w.length > 1);
    for (let w = 0; w < words.length; w++) {
      const word = words[w];
      let hash = 0;
      for (let c = 0; c < word.length; c++) {
        hash = (hash << 5) - hash + word.charCodeAt(c);
        hash |= 0;
      }
      const idx = Math.abs(hash) % 768;
      vector[idx] += 3.0;
    }
    let sumSquares = 0;
    for (let i = 0; i < 768; i++) {
      sumSquares += vector[i] * vector[i];
    }
    const magnitude = Math.sqrt(sumSquares) || 1;
    return vector.map((val) => Number((val / magnitude).toFixed(6)));
  }
}
