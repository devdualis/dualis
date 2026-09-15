enum TriageVertical {
  psicoEmocional,
  fisica,
}

class TriageNavigationArgs {
  final TriageVertical initialVertical;
  final bool isDual;
  final String? naturalLanguageText;
  final String? preselectedCategoryKey;

  const TriageNavigationArgs({
    required this.initialVertical,
    this.isDual = false,
    this.naturalLanguageText,
    this.preselectedCategoryKey,
  });
}
