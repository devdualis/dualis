import '../../../l10n/app_localizations.dart';

/// Wellness topics of the general library (strategy §9.3), in fixed order.
enum LibraryCategory {
  emocoes,
  estresse,
  sono,
  corpo,
  alimentacao,
  hidratacao,
  relacoes,
  ajuda;

  String label(AppLocalizations l10n) => switch (this) {
        LibraryCategory.emocoes => l10n.xv2LibCatEmocoes,
        LibraryCategory.estresse => l10n.xv2LibCatEstresse,
        LibraryCategory.sono => l10n.xv2LibCatSono,
        LibraryCategory.corpo => l10n.xv2LibCatCorpo,
        LibraryCategory.alimentacao => l10n.xv2LibCatAlimentacao,
        LibraryCategory.hidratacao => l10n.xv2LibCatHidratacao,
        LibraryCategory.relacoes => l10n.xv2LibCatRelacoes,
        LibraryCategory.ajuda => l10n.xv2LibCatAjuda,
      };
}

/// One curated text with its real public source (plan F0, rule R6).
class LibraryArticle {
  final String id;
  final LibraryCategory category;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) summary;

  /// Name of the institution that publishes the text.
  final String source;
  final String url;
  final int readTimeMinutes;

  const LibraryArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.readTimeMinutes,
  });
}

const _bvs = 'Biblioteca Virtual em Saúde do Ministério da Saúde (BVS)';
const _opas = 'Organização Pan-Americana da Saúde (OPAS)';
const _ms = 'Ministério da Saúde';

/// The same list, in the same order, for every person. Nothing here reads
/// or depends on what anyone recorded. Every link is a public institution's
/// page about everyday habits, one distinct page per article.
final List<LibraryArticle> kLibraryArticles = List.unmodifiable([
  LibraryArticle(
    id: 'art-emocoes-01',
    category: LibraryCategory.emocoes,
    title: (l) => l.xv2LibArtDesanimoTitle,
    summary: (l) => l.xv2LibArtDesanimoSummary,
    source: _bvs,
    url: 'https://bvsms.saude.gov.br/10-de-outubro-dia-mundial-da-saude-mental/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-emocoes-02',
    category: LibraryCategory.emocoes,
    title: (l) => l.xv2LibArtAgitacaoTitle,
    summary: (l) => l.xv2LibArtAgitacaoSummary,
    source: 'Ministério dos Direitos Humanos e da Cidadania',
    url:
        'https://www.gov.br/mdh/pt-br/assuntos/acolha-a-vida/cartilhas-fbtc-conteudos/2-enfrentando-o-estresse-e-protegendo-a-familia-marilda-lipp-corrigida.pdf',
    readTimeMinutes: 6,
  ),
  LibraryArticle(
    id: 'art-estresse-01',
    category: LibraryCategory.estresse,
    title: (l) => l.xv2LibArtTrabalhoTitle,
    summary: (l) => l.xv2LibArtTrabalhoSummary,
    source: _bvs,
    url: 'https://bvsms.saude.gov.br/estresse/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-estresse-02',
    category: LibraryCategory.estresse,
    title: (l) => l.xv2LibArtRespiracaoTitle,
    summary: (l) => l.xv2LibArtRespiracaoSummary,
    source: 'Secretaria da Saúde do Ceará',
    url:
        'https://www.ce.gov.br/saude/2021/05/28/respirar-corretamente-melhora-a-capacidade-funcional-dos-pulmoes-e-traz-beneficios-a-saude-confira-dicas/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-sono-01',
    category: LibraryCategory.sono,
    title: (l) => l.xv2LibArtSonoTitle,
    summary: (l) => l.xv2LibArtSonoSummary,
    source: _bvs,
    url:
        'https://bvsms.saude.gov.br/durma-bem-viva-melhor-13-3-dia-mundial-do-sono-2026/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-corpo-01',
    category: LibraryCategory.corpo,
    title: (l) => l.xv2LibArtBracosTitle,
    summary: (l) => l.xv2LibArtBracosSummary,
    source: 'Secretaria Municipal de Saúde de Belo Horizonte',
    url:
        'https://prefeitura.pbh.gov.br/sites/default/files/estrutura-de-governo/saude/2024/12-06-24-smsa-folder-ergonomia-trabalho.pdf',
    readTimeMinutes: 3,
  ),
  LibraryArticle(
    id: 'art-corpo-02',
    category: LibraryCategory.corpo,
    title: (l) => l.xv2LibArtMovimentoTitle,
    summary: (l) => l.xv2LibArtMovimentoSummary,
    source: _opas,
    url: 'https://www.paho.org/pt/topicos/atividade-fisica',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-alimentacao-01',
    category: LibraryCategory.alimentacao,
    title: (l) => l.xv2LibArtAlimentacaoTitle,
    summary: (l) => l.xv2LibArtAlimentacaoSummary,
    source: _ms,
    url:
        'https://bvsms.saude.gov.br/bvs/publicacoes/guia_alimentar_populacao_brasileira_2ed.pdf',
    readTimeMinutes: 10,
  ),
  LibraryArticle(
    id: 'art-hidratacao-01',
    category: LibraryCategory.hidratacao,
    title: (l) => l.xv2LibArtAguaTitle,
    summary: (l) => l.xv2LibArtAguaSummary,
    source: 'Secretaria da Saúde do Espírito Santo',
    url:
        'https://saude.es.gov.br/Noticia/no-dia-mundial-da-agua-saiba-a-importancia-da-ingestao-de-liquido-para-a-saude-2',
    readTimeMinutes: 3,
  ),
  LibraryArticle(
    id: 'art-relacoes-01',
    category: LibraryCategory.relacoes,
    title: (l) => l.xv2LibArtConvivioTitle,
    summary: (l) => l.xv2LibArtConvivioSummary,
    source: _ms,
    url:
        'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/saude-da-pessoa-idosa/saude-mental/saude-mental',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-ajuda-samu',
    category: LibraryCategory.ajuda,
    title: (l) => l.xv2LibArtSamuTitle,
    summary: (l) => l.xv2LibArtSamuSummary,
    source: _ms,
    url: 'https://www.gov.br/saude/pt-br/composicao/saes/samu-192',
    readTimeMinutes: 3,
  ),
  LibraryArticle(
    id: 'art-ajuda-cvv',
    category: LibraryCategory.ajuda,
    title: (l) => l.xv2LibArtCvvTitle,
    summary: (l) => l.xv2LibArtCvvSummary,
    source: _ms,
    url:
        'https://www.gov.br/saude/pt-br/assuntos/noticias/2017/marco/acordo-do-ministerio-da-saude-com-cvv-garantira-ligacoes-gratuitas-ao-servico',
    readTimeMinutes: 2,
  ),
]);

/// Articles by topic, topics in enum order, articles in list order.
Map<LibraryCategory, List<LibraryArticle>> libraryByCategory() {
  return {
    for (final category in LibraryCategory.values)
      category: kLibraryArticles.where((a) => a.category == category).toList(),
  };
}
