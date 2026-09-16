import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ArticleEmbeddingService } from '../../src/modules/triage/services/article-embedding.service';
import { ArticlesVectorService } from '../../src/modules/triage/services/articles-vector.service';

describe('ArticlesVectorService & ArticleEmbeddingService Unit Tests', () => {
  let embeddingService: ArticleEmbeddingService;
  let vectorService: ArticlesVectorService;
  let mockDb: any;

  beforeEach(() => {
    embeddingService = new ArticleEmbeddingService();

    mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          limit: vi.fn().mockResolvedValue([{ id: 'art-coluna-01' }]),
        }),
      }),
      execute: vi.fn().mockImplementation(async () => {
        return {
          rows: [
            {
              id: 'art-coluna-01',
              title: 'Ergonomia no Trabalho e Prevenção de Dores Lombares e Cervicais',
              category: 'coluna_dor_dorsal',
              author: 'Dr. Marcelo Mendes',
              authorRole: 'Ortopedista e Traumatologista (HCFMUSP / CRM-SP 128.450)',
              readTimeMinutes: 5,
              summary: 'Posturas preventivas e exercícios de descompressão da coluna lombar.',
              url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
              similarity: 0.88,
            },
          ],
        };
      }),
    };

    vectorService = new ArticlesVectorService(mockDb, embeddingService);
  });

  it('1. ArticleEmbeddingService produces 768-dimensional normalized vectors', async () => {
    const vector = await embeddingService.embed('dor lombar intensa na coluna');
    expect(vector).toHaveLength(768);

    let norm = 0;
    for (const v of vector) {
      norm += v * v;
    }
    expect(Math.sqrt(norm)).toBeCloseTo(1.0, 2);
  });

  it('2. Similar clinical texts produce higher cosine similarity than unrelated texts', async () => {
    const v1 = await embeddingService.embed('dor lombar e coluna travada');
    const v2 = await embeddingService.embed('desconforto na coluna lombar e costas');
    const v3 = await embeddingService.embed('manchas vermelhas na pele e coceira');

    let dot12 = 0;
    let dot13 = 0;
    for (let i = 0; i < 768; i++) {
      dot12 += v1[i] * v2[i];
      dot13 += v1[i] * v3[i];
    }

    expect(dot12).toBeGreaterThan(dot13);
  });

  it('3. ArticlesVectorService returns orthopedic article for back pain query', async () => {
    const articles = await vectorService.searchArticles({
      queryText: 'dor nas costas e coluna lombar',
      category: 'coluna_dor_dorsal',
      vertical: 'physical',
    });

    expect(articles).toHaveLength(1);
    expect(articles[0].id).toBe('art-coluna-01');
    expect(articles[0].author).toContain('Dr. Marcelo Mendes');
    expect(articles[0].authorRole).toContain('Ortopedista');
  });

  it('4. Second query with identical symptom hits semantic cache without executing DB query again', async () => {
    mockDb.execute.mockClear();

    const firstResult = await vectorService.searchArticles({
      queryText: 'dor nas costas e coluna lombar',
      category: 'coluna_dor_dorsal',
      vertical: 'physical',
    });

    expect(mockDb.execute).toHaveBeenCalledTimes(1);

    const cachedResult = await vectorService.searchArticles({
      queryText: 'dor nas costas e coluna lombar',
      category: 'coluna_dor_dorsal',
      vertical: 'physical',
    });

    expect(mockDb.execute).toHaveBeenCalledTimes(1);
    expect(cachedResult).toEqual(firstResult);
  });

  it('5. Fallback without narrative matches by category directly', async () => {
    mockDb.execute.mockImplementation(async () => {
      return {
        rows: [
          {
            id: 'art-ansiedade-01',
            title: 'Manejo da Ansiedade Aguda com Respiração Diafragmática',
            category: 'ansiosa_agitacao',
            author: 'Dra. Camila Prado',
            authorRole: 'Psiquiatra Clínica (ABP / CRM-SP 165.340)',
            readTimeMinutes: 4,
            summary: 'Exercício guiado 4-7-8 para desaceleração do sistema simpático.',
            url: 'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
          },
        ],
      };
    });

    const articles = await vectorService.searchArticles({
      category: 'ansiosa_agitacao',
      vertical: 'emotional',
    });

    expect(articles).toHaveLength(1);
    expect(articles[0].id).toBe('art-ansiedade-01');
    expect(articles[0].author).toContain('Dra. Camila Prado');
  });

  it('6. Seed catalog comprehensively covers all 7 emotional dimensions and 12 physical systems', () => {
    expect(vectorService.seedArticles).toHaveLength(39);

    const emotionalCategories = [
      'ansiosa_agitacao',
      'depressiva_desanimo',
      'estresse_burnout',
      'somatica',
      'sono',
      'cognitiva_foco',
      'autoestima',
    ];

    const physicalCategories = [
      'cabeca_pescoco',
      'cardiovascular_torax',
      'respiratorio',
      'gastrointestinal_abdomen',
      'coluna_dor_dorsal',
      'membros_superiores',
      'membros_inferiores',
      'neurologico',
      'geniturinario_pelvico',
      'dermatologico',
      'muscular_geral_sistemico',
      'endocrino_metabolico',
    ];

    for (const cat of [...emotionalCategories, ...physicalCategories]) {
      const matching = vectorService.seedArticles.filter((a) => a.category === cat);
      expect(matching.length).toBeGreaterThanOrEqual(2);
    }

    const general = vectorService.seedArticles.filter((a) => a.category === 'geral');
    expect(general).toHaveLength(1);

    for (const article of vectorService.seedArticles) {
      expect(article.title.length).toBeGreaterThan(5);
      expect(article.summary.length).toBeGreaterThan(10);
      expect(article.contentMarkdown.length).toBeGreaterThan(20);
      expect(article.keywords.length).toBeGreaterThanOrEqual(4);
      expect(article.url.startsWith('https://')).toBe(true);
      expect(article.url).not.toContain('dualis.health');
    }
  });

  describe('ensureSeedArticles re-seeding behavior', () => {
    function buildSeedRow(overrides: Record<string, unknown> = {}) {
      const seed = vectorService.seedArticles[0];
      return {
        id: seed.id,
        title: seed.title,
        category: seed.category,
        somaticSystem: seed.somaticSystem ?? null,
        author: seed.author,
        authorRole: seed.authorRole,
        readTimeMinutes: seed.readTimeMinutes,
        summary: seed.summary,
        contentMarkdown: seed.contentMarkdown,
        keywords: seed.keywords,
        url: seed.url,
        ...overrides,
      };
    }

    it('7. skips rows whose stored content already matches the seed source', async () => {
      const upToDateRow = buildSeedRow();
      const otherIds = new Set(vectorService.seedArticles.slice(1).map((a) => a.id));

      mockDb.select = vi.fn().mockReturnValue({
        from: vi.fn().mockResolvedValue([
          upToDateRow,
          ...vectorService.seedArticles
            .filter((a) => otherIds.has(a.id))
            .map((a) => buildSeedRowFor(a)),
        ]),
      });
      mockDb.insert = vi.fn();
      mockDb.update = vi.fn();

      function buildSeedRowFor(seed: (typeof vectorService.seedArticles)[number]) {
        return {
          id: seed.id,
          title: seed.title,
          category: seed.category,
          somaticSystem: seed.somaticSystem ?? null,
          author: seed.author,
          authorRole: seed.authorRole,
          readTimeMinutes: seed.readTimeMinutes,
          summary: seed.summary,
          contentMarkdown: seed.contentMarkdown,
          keywords: seed.keywords,
          url: seed.url,
        };
      }

      await vectorService.ensureSeedArticles();

      expect(mockDb.insert).not.toHaveBeenCalled();
      expect(mockDb.update).not.toHaveBeenCalled();
    });

    it('8. re-embeds and updates a row whose stored URL/content drifted from the seed source (stale seed regression)', async () => {
      const staleRow = buildSeedRow({ url: 'https://old-outdated-url.example.com/moved' });
      const restRows = vectorService.seedArticles.slice(1).map((seed) => ({
        id: seed.id,
        title: seed.title,
        category: seed.category,
        somaticSystem: seed.somaticSystem ?? null,
        author: seed.author,
        authorRole: seed.authorRole,
        readTimeMinutes: seed.readTimeMinutes,
        summary: seed.summary,
        contentMarkdown: seed.contentMarkdown,
        keywords: seed.keywords,
        url: seed.url,
      }));

      mockDb.select = vi.fn().mockReturnValue({
        from: vi.fn().mockResolvedValue([staleRow, ...restRows]),
      });

      const setMock = vi.fn().mockReturnValue({ where: vi.fn().mockResolvedValue(undefined) });
      mockDb.update = vi.fn().mockReturnValue({ set: setMock });
      mockDb.insert = vi.fn();

      await vectorService.ensureSeedArticles();

      expect(mockDb.update).toHaveBeenCalledTimes(1);
      expect(setMock).toHaveBeenCalledWith(
        expect.objectContaining({ id: vectorService.seedArticles[0].id, url: vectorService.seedArticles[0].url }),
      );
      expect(mockDb.insert).not.toHaveBeenCalled();
    });

    it('9. inserts rows for seed articles missing from the database', async () => {
      mockDb.select = vi.fn().mockReturnValue({ from: vi.fn().mockResolvedValue([]) });
      const valuesMock = vi.fn().mockReturnValue({ onConflictDoNothing: vi.fn().mockResolvedValue(undefined) });
      mockDb.insert = vi.fn().mockReturnValue({ values: valuesMock });
      mockDb.update = vi.fn();

      await vectorService.ensureSeedArticles();

      expect(mockDb.insert).toHaveBeenCalledTimes(vectorService.seedArticles.length);
      expect(mockDb.update).not.toHaveBeenCalled();
    });
  });
});
