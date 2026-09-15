import { Injectable } from '@nestjs/common';
import { RecommendedArticleDto } from '../dto/triage-outcome.dto';
import { MEDICAL_ARTICLES_SEED } from '../data/medical-articles.seed';

@Injectable()
export class ArticlesCatalogService {
  private readonly articles: RecommendedArticleDto[] = MEDICAL_ARTICLES_SEED.map((a) => ({
    id: a.id,
    title: a.title,
    category: a.category,
    author: a.author,
    authorRole: a.authorRole,
    readTimeMinutes: a.readTimeMinutes,
    summary: a.summary,
    url: a.url,
  }));

  getArticlesForCategory(category: string): RecommendedArticleDto[] {
    const matched = this.articles.filter((a) => a.category === category);
    if (matched.length > 0) {
      const general = this.articles.find((a) => a.category === 'geral');
      return general && !matched.includes(general) ? [...matched, general] : matched;
    }

    return this.articles.slice(0, 2);
  }
}
