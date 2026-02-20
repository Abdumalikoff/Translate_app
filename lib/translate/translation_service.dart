abstract class TranslationService {
  Future<String> translate({
    required String text,
    required String from,
    required String to,
  });

  void dispose();
}
