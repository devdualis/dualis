enum TriageVertical {
  psicoEmocional,
  fisica,
}

class TriageNavigationArgs {
  final TriageVertical initialVertical;
  final bool isDual;
  final String? naturalLanguageText;
  final String? preselectedCategoryKey;
  final bool isOffTopic;

  const TriageNavigationArgs({
    required this.initialVertical,
    this.isDual = false,
    this.naturalLanguageText,
    this.preselectedCategoryKey,
    this.isOffTopic = false,
  });
}
