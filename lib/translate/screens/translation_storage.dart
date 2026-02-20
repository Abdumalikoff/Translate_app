import 'package:hive/hive.dart';
import '../models/translation_history_item.dart';

class TranslationStorage {
  TranslationStorage(this._box);

  final Box _box;

  static const String kRecent = 'recent_translations_v1';
  static const String kFavorites = 'favorites_translations_v1';

  Map<String, dynamic> _itemToMap(TranslationHistoryItem i) => {
    'fromLabel': i.fromLabel,
    'toLabel': i.toLabel,
    'sourceText': i.sourceText,
    'translatedText': i.translatedText,
    'isStarred': i.isStarred,
  };

  TranslationHistoryItem _itemFromMap(Map m) => TranslationHistoryItem(
    fromLabel: (m['fromLabel'] ?? '') as String,
    toLabel: (m['toLabel'] ?? '') as String,
    sourceText: (m['sourceText'] ?? '') as String,
    translatedText: (m['translatedText'] ?? '') as String,
    isStarred: (m['isStarred'] ?? false) as bool,
  );

  String makeKey({
    required String fromLabel,
    required String toLabel,
    required String sourceText,
  }) {
    return '$fromLabel|$toLabel|$sourceText';
  }

  // ---------- Favorites ----------
  Map<String, TranslationHistoryItem> loadFavorites() {
    final raw = _box.get(kFavorites);
    if (raw is Map) {
      final out = <String, TranslationHistoryItem>{};
      raw.forEach((key, value) {
        if (value is Map) out[key.toString()] = _itemFromMap(value);
      });
      return out;
    }
    return {};
  }

  Future<void> saveFavorites(Map<String, TranslationHistoryItem> fav) async {
    final raw = <String, dynamic>{};
    fav.forEach((k, v) => raw[k] = _itemToMap(v));
    await _box.put(kFavorites, raw);
  }
}
