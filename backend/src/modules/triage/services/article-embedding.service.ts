import { Inject, Injectable, Optional } from '@nestjs/common';
import { GeminiService } from '../../../common/ai/gemini.service';

@Injectable()
export class ArticleEmbeddingService {
  constructor(@Optional() @Inject(GeminiService) private readonly gemini?: GeminiService) {}

  async embed(text: string): Promise<number[]> {
    const values = await this.gemini?.embed(text);
    return values ?? this.generateDeterministicEmbedding(text);
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
