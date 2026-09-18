import { Injectable } from '@nestjs/common';
import { RecommendedArticleDto } from '../dto/triage-outcome.dto';
import { MEDICAL_ARTICLES_SEED } from '../data/medical-articles.seed';

@Injectable()
export class ArticlesCatalogService {
  private readonly articles: (RecommendedArticleDto & { language: string })[] = MEDICAL_ARTICLES_SEED.map((a) => ({
    id: a.id,
    language: a.language || 'pt',
    title: a.title,
    category: a.category,
    author: a.author,
    authorRole: a.authorRole,
    readTimeMinutes: a.readTimeMinutes,
    summary: a.summary,
    url: a.url,
  }));

  getArticlesForCategory(category: string, language: string = 'pt'): RecommendedArticleDto[] {
    const lang = (language || 'pt').toLowerCase();
    const matched = this.articles.filter((a) => a.category === category && a.language === lang);
    if (matched.length > 0) {
      const general = this.articles.find((a) => a.category === 'geral' && a.language === lang);
      return general && !matched.includes(general) ? [...matched, general] : matched;
    }

    const fallbackLang = this.articles.filter((a) => a.language === lang);
    if (fallbackLang.length > 0) {
      return fallbackLang.slice(0, 2);
    }

    return this.articles.slice(0, 2);
  }
}
