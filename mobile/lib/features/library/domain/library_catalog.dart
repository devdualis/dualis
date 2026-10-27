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

const _drauzio = 'Portal Drauzio Varella';
const _opas = 'Organização Pan-Americana da Saúde (OPAS)';
const _ms = 'Ministério da Saúde';

/// The same list, in the same order, for every person. Nothing here reads
/// or depends on what anyone recorded.
final List<LibraryArticle> kLibraryArticles = List.unmodifiable([
  LibraryArticle(
    id: 'art-humor-01',
    category: LibraryCategory.emocoes,
    title: (l) => l.xv2LibArtDesanimoTitle,
    summary: (l) => l.xv2LibArtDesanimoSummary,
    source: _opas,
    url: 'https://www.paho.org/pt/topicos/depressao',
    readTimeMinutes: 5,
  ),
  LibraryArticle(
    id: 'art-ansiedade-01',
    category: LibraryCategory.emocoes,
    title: (l) => l.xv2LibArtAgitacaoTitle,
    summary: (l) => l.xv2LibArtAgitacaoSummary,
    source: _drauzio,
    url:
        'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-burnout-01',
    category: LibraryCategory.estresse,
    title: (l) => l.xv2LibArtTrabalhoTitle,
    summary: (l) => l.xv2LibArtTrabalhoSummary,
    source: _drauzio,
    url:
        'https://drauziovarella.uol.com.br/psiquiatria/sindrome-de-burnout-esgotamento-profissional/',
    readTimeMinutes: 5,
  ),
  LibraryArticle(
    id: 'art-wellness-3',
    category: LibraryCategory.estresse,
    title: (l) => l.xv2LibArtRespiracaoTitle,
    summary: (l) => l.xv2LibArtRespiracaoSummary,
    source: _drauzio,
    url:
        'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
    readTimeMinutes: 5,
  ),
  LibraryArticle(
    id: 'art-wellness-1',
    category: LibraryCategory.sono,
    title: (l) => l.xv2LibArtSonoTitle,
    summary: (l) => l.xv2LibArtSonoSummary,
    source: _drauzio,
    url:
        'https://drauziovarella.uol.com.br/neurologia/higiene-do-sono-conheca-11-dicas-para-dormir-melhor/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-coluna-01',
    category: LibraryCategory.corpo,
    title: (l) => l.xv2LibArtCostasTitle,
    summary: (l) => l.xv2LibArtCostasSummary,
    source: 'Sociedade Brasileira de Ortopedia e Traumatologia',
    url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-membros-sup-01',
    category: LibraryCategory.corpo,
    title: (l) => l.xv2LibArtBracosTitle,
    summary: (l) => l.xv2LibArtBracosSummary,
    source: _drauzio,
    url: 'https://drauziovarella.uol.com.br/podcasts/tendinite/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-cefaleia-01',
    category: LibraryCategory.corpo,
    title: (l) => l.xv2LibArtCabecaTitle,
    summary: (l) => l.xv2LibArtCabecaSummary,
    source: 'Sociedade Brasileira de Cefaleia',
    url: 'https://sbcefaleia.com.br/noticias.php?id=350',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-dermato-01',
    category: LibraryCategory.corpo,
    title: (l) => l.xv2LibArtPeleTitle,
    summary: (l) => l.xv2LibArtPeleSummary,
    source: 'Sociedade Brasileira de Dermatologia',
    url: 'https://www.sbd.org.br/doencas/urticaria/',
    readTimeMinutes: 4,
  ),
  LibraryArticle(
    id: 'art-movimento-01',
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
        'https://www.gov.br/saude/pt-br/assuntos/saude-brasil/publicacoes-para-promocao-a-saude/guia_alimentar_populacao_brasileira_2ed.pdf/view',
    readTimeMinutes: 10,
  ),
  LibraryArticle(
    id: 'art-wellness-2',
    category: LibraryCategory.hidratacao,
    title: (l) => l.xv2LibArtAguaTitle,
    summary: (l) => l.xv2LibArtAguaSummary,
    source: _opas,
    url: 'https://www.paho.org/pt/topicos/curso-vida-saudavel',
    readTimeMinutes: 3,
  ),
  LibraryArticle(
    id: 'art-convivio-01',
    category: LibraryCategory.relacoes,
    title: (l) => l.xv2LibArtConvivioTitle,
    summary: (l) => l.xv2LibArtConvivioSummary,
    source: _opas,
    url: 'https://www.paho.org/pt/topicos/saude-mental',
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
    source: 'Centro de Valorização da Vida (CVV)',
    url: 'https://cvv.org.br/',
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
