import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TranslationDetailSheet {
  static void show({
    required BuildContext context,
    required String title,
    required String sourceText,
    required String translatedText,
    required bool isStarred,
    required VoidCallback onToggleStar,
  }) {
    bool starred = isStarred; // состояние шита живёт тут

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      clipBehavior: Clip.antiAlias, // ✅ важно
      builder: (ctx) {
        return Container(
          color: Colors.white,
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              void toggle() {
                onToggleStar(); // обновляет Hive/списки снаружи
                setSheetState(
                  () => starred = !starred,
                ); // обновляет иконку в шите
              }

              return SafeArea(
                child: FractionallySizedBox(
                  heightFactor: 0.8,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                            IconButton(
                              onPressed: toggle,
                              icon: Icon(
                                starred ? Icons.star : Icons.star_border,
                                size: 28,
                                color: starred
                                    ? const Color(0xFFFFC107)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Оригинал',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: sourceText),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Оригинал скопирован',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy),
                                    ),
                                  ],
                                ),
                                Text(
                                  sourceText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 24, thickness: 1),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Перевод',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: translatedText),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Перевод скопирован'),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy),
                                    ),
                                  ],
                                ),
                                Text(
                                  translatedText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
