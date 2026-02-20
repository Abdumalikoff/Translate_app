class TranslationException implements Exception {
  final String message;
  const TranslationException(this.message);

  @override
  String toString() => message;
}
