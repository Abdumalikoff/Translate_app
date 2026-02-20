import 'package:dio/dio.dart';
import 'translation_models.dart';
import 'translation_service.dart';

class YandexTranslateService implements TranslationService {
  YandexTranslateService({
    required String apiKey,
    required String folderId,
    Dio? dio,
  }) : _apiKey = apiKey,
       _folderId = folderId,
       _dio = dio ?? Dio();

  final String _apiKey;
  final String _folderId;
  final Dio _dio;

  static const _url =
      'https://translate.api.cloud.yandex.net/translate/v2/translate';

  @override
  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    final input = text.trim();
    if (input.isEmpty) return '';
    if (from == to) return input;

    try {
      final body = <String, dynamic>{
        'folderId': _folderId,
        'targetLanguageCode': to,
        'texts': [input],
      };

      // Если хочешь авто-определение источника — используй from='auto'
      // и тогда НЕ отправляем sourceLanguageCode.
      if (from != 'auto') {
        body['sourceLanguageCode'] = from;
      }

      final resp = await _dio.post(
        _url,
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Api-Key $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = resp.data;
      final translations = (data is Map)
          ? (data['translations'] as List?)
          : null;
      final first = (translations != null && translations.isNotEmpty)
          ? translations.first as Map
          : null;

      final out = first?['text'] as String?;
      if (out == null) throw const TranslationException('Пустой ответ от API');
      return out;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data?.toString() ?? e.message ?? 'Dio error';
      throw TranslationException('Yandex error ($code): $msg');
    } catch (e) {
      throw TranslationException('Ошибка перевода: $e');
    }
  }

  @override
  void dispose() {
    _dio.close(force: true);
  }
}
