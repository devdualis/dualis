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

  /// AI tagging flagged a mention of self-harm: the wizard shows crisis
  /// resources as soon as it opens.
  final bool mentionsSelfHarm;

  const TriageNavigationArgs({
    required this.initialVertical,
    this.isDual = false,
    this.naturalLanguageText,
    this.preselectedCategoryKey,
    this.isOffTopic = false,
    this.mentionsSelfHarm = false,
  });
}
