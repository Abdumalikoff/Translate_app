import 'package:ezzy/translate/screens/translation_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/translation_history_item.dart';
import '../widgets/card_container_widget.dart';
import '../widgets/recent_translation_card.dart';
import '../widgets/translation_detail_sheet.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextStyle languageStyle = const TextStyle(
    color: Color(0xFF888888),
    fontSize: 16,
  );

  final Box _box = Hive.box('settings');
  late final TranslationStorage _storage = TranslationStorage(_box);

  Future<void> _removeFromFavorites(
    String key,
    Map<String, TranslationHistoryItem> fav,
  ) async {
    fav.remove(key);
    await _storage.saveFavorites(fav);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.black, fontSize: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder(
          valueListenable: _box.listenable(
            keys: const [TranslationStorage.kFavorites],
          ),
          builder: (context, box, _) {
            final fav = _storage.loadFavorites();
            final entries = fav.entries.toList();

            if (entries.isEmpty) {
              return Center(
                child: const Text(
                  'Пока нет избранных',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView(
              children: [
                CardContainerWidget(
                  hight: null,
                  child: Column(
                    children: List.generate(entries.length, (i) {
                      final key = entries[i].key;
                      final item = entries[i].value;

                      return Column(
                        children: [
                          RecentTranslationWidget(
                            languageStyle: languageStyle,
                            title: '${item.fromLabel} - ${item.toLabel}',
                            sourceText: item.sourceText,
                            translatedText: item.translatedText,
                            isStarred: true,
                            onStarTap: () => _removeFromFavorites(key, fav),
                            onTap: () {
                              TranslationDetailSheet.show(
                                context: context,
                                title: '${item.fromLabel} - ${item.toLabel}',
                                sourceText: item.sourceText,
                                translatedText: item.translatedText,
                                isStarred: true,
                                onToggleStar: () =>
                                    _removeFromFavorites(key, fav),
                              );
                            },
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
