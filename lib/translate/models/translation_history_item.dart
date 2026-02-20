class TranslationHistoryItem {
  final String fromLabel;
  final String toLabel;
  final String sourceText;
  final String translatedText;
  final bool isStarred;

  const TranslationHistoryItem({
    required this.fromLabel,
    required this.toLabel,
    required this.sourceText,
    required this.translatedText,
    this.isStarred = false,
  });

  TranslationHistoryItem copyWith({bool? isStarred}) {
    return TranslationHistoryItem(
      fromLabel: fromLabel,
      toLabel: toLabel,
      sourceText: sourceText,
      translatedText: translatedText,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}
