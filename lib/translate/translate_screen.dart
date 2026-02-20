import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:hive/hive.dart';

import 'package:ezzy/secrets.dart';
import 'package:ezzy/settings/settings_service.dart';

import 'package:ezzy/translate/models/lang.dart';
import 'package:ezzy/translate/models/translation_history_item.dart';
import 'package:ezzy/translate/screens/translation_storage.dart';
import 'package:ezzy/translate/translation_service.dart';
import 'package:ezzy/translate/translation_models.dart'; // если тут TranslationException
import 'package:ezzy/translate/yandex_translate_service.dart';

import 'package:ezzy/translate/widgets/card_container_widget.dart';
import 'package:ezzy/translate/widgets/recent_translation_card.dart';
import 'package:ezzy/translate/widgets/translation_detail_sheet.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextStyle languageStyle = const TextStyle(
    color: Color(0xFF888888),
    fontSize: 16,
  );

  late final TranslationService _service;

  final _inputCtrl = TextEditingController();
  final _settings = SettingsService();
  static const String _kRecent = 'recent_translations_v1';
  Box get _box => Hive.box('settings'); // box уже открыт в main.dart

  // Состояние UI
  String result = '';
  bool _isLoading = false;
  String? _errorText;

  late final TranslationStorage _storage;
  Map<String, TranslationHistoryItem> _favorites = {};
  ValueListenable<Box>? _favListenable;
  // 1) Debounce для перевода (быстро)
  Timer? _debounce;

  // 2) Debounce для сохранения в recent (медленнее)
  Timer? _saveDebounce;

  // защита от "старых" ответов
  int _reqId = 0;

  // чтобы не переводить заново на пробел/enter
  String _lastMeaningKey = '';

  // чтобы не сохранять одно и то же дважды
  String _pendingSaveKey = '';
  String _lastSavedKey = '';

  final List<TranslationHistoryItem> _recent = [];

  final langs = const [
    Lang('en', 'English'),
    Lang('ru', 'Russian'),
    Lang('uz', "O‘zbek"),
    Lang('tr', 'Turkish'),
    Lang('zh', 'Chinese'),
    Lang('es', 'Spanish'),
    Lang('de', 'German'),
    Lang('fr', 'French'),
    Lang('ja', 'Japanese'),
    Lang('ko', 'Korean'),
    Lang('it', 'Italian'),
    Lang('pt', 'Portuguese'),
    Lang('pt-BR', 'Portuguese (BR)'),
    Lang('ar', 'Arabic'),
    Lang('hi', 'Hindi'),
    Lang('id', 'Indonesian'),
    Lang('vi', 'Vietnamese'),
    Lang('uk', 'Ukrainian'),
  ];

  Lang fromLang = const Lang('en', 'English');
  Lang toLang = const Lang('ru', 'Russian');

  Map<String, dynamic> _itemToMap(TranslationHistoryItem i) => {
    'fromLabel': i.fromLabel,
    'toLabel': i.toLabel,
    'sourceText': i.sourceText,
    'translatedText': i.translatedText,
    'isStarred': i.isStarred,
  };

  void _syncFavoritesFromHive() {
    final fav = _storage.loadFavorites();
    _favorites = fav;

    for (var i = 0; i < _recent.length; i++) {
      final item = _recent[i];
      final key = _storage.makeKey(
        fromLabel: item.fromLabel,
        toLabel: item.toLabel,
        sourceText: item.sourceText,
      );

      final shouldStar = fav.containsKey(key);
      if (item.isStarred != shouldStar) {
        _recent[i] = item.copyWith(isStarred: shouldStar);
      }
    }

    if (mounted) setState(() {});
  }

  TranslationHistoryItem _itemFromMap(Map m) => TranslationHistoryItem(
    fromLabel: (m['fromLabel'] ?? '') as String,
    toLabel: (m['toLabel'] ?? '') as String,
    sourceText: (m['sourceText'] ?? '') as String,
    translatedText: (m['translatedText'] ?? '') as String,
    isStarred: (m['isStarred'] ?? false) as bool,
  );

  void _loadRecentFromHive() {
    final raw = _box.get(_kRecent);

    if (raw is List) {
      final loaded = <TranslationHistoryItem>[];

      for (final e in raw) {
        if (e is Map) loaded.add(_itemFromMap(e));
      }

      setState(() {
        _recent
          ..clear()
          ..addAll(loaded);

        // держим ровно 3
        if (_recent.length > 3) _recent.removeRange(3, _recent.length);
      });
    }
  }

  Future<void> _saveRecentToHive() async {
    final data = _recent.map(_itemToMap).toList(growable: false);
    await _box.put(_kRecent, data);
  }

  // ====== 1) Слушатель ввода: только планируем перевод ======
  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _translate);
  }

  // ====== 2) Перевод: обновляет result, но НЕ сохраняет сразу ======
  Future<void> _translate() async {
    final rawText = _inputCtrl.text;
    final meaningfulText = rawText.trim(); // убрали хвостовые пробелы/энтеры

    final fromSnap = fromLang; // снимок языков
    final toSnap = toLang;

    if (meaningfulText.isEmpty) {
      setState(() {
        result = '';
        _errorText = null;
        _isLoading = false;
      });
      _lastMeaningKey = '';
      return;
    }

    final meaningKey = '${fromSnap.code}|${toSnap.code}|$meaningfulText';
    if (meaningKey == _lastMeaningKey) return;

    final myReq = ++_reqId;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final out = await _service.translate(
        text: meaningfulText,
        from: fromSnap.code,
        to: toSnap.code,
      );

      if (!mounted || myReq != _reqId) return;

      setState(() {
        result = out;
        _isLoading = false;
      });

      _lastMeaningKey = meaningKey;

      // Важно: сохраняем не сразу, а через отдельный таймер
      _scheduleSaveRecent(
        from: fromSnap,
        to: toSnap,
        sourceText: meaningfulText,
        translatedText: out,
      );
    } on TranslationException catch (e) {
      if (!mounted || myReq != _reqId) return;

      setState(() {
        _errorText = e.message;
        result = '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || myReq != _reqId) return;

      setState(() {
        _errorText = 'Ошибка перевода: $e';
        result = '';
        _isLoading = false;
      });
    }
  }

  // ====== 3) Сохранение в recent: ждём, пока пользователь "закончил" ======
  void _scheduleSaveRecent({
    required Lang from,
    required Lang to,
    required String sourceText,
    required String translatedText,
  }) {
    _pendingSaveKey = '${from.code}|${to.code}|$sourceText';

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;

      final currentText = _inputCtrl.text.trim();
      final currentKey = '${fromLang.code}|${toLang.code}|$currentText';

      // если за время ожидания человек продолжил печатать/сменил язык — не сохраняем
      if (currentKey != _pendingSaveKey) return;

      // если уже сохраняли это — не дублируем
      if (_pendingSaveKey == _lastSavedKey) return;
      _lastSavedKey = _pendingSaveKey;

      _addRecentSmart(
        fromLabel: from.label,
        toLabel: to.label,
        sourceText: sourceText,
        translatedText: translatedText,
      );
    });
  }

  // ====== 4) Умное добавление: не плодит dog c / dog ca / dog cat ======
  void _addRecentSmart({
    required String fromLabel,
    required String toLabel,
    required String sourceText,
    required String translatedText,
  }) {
    // ✅ ВСТАВИТЬ ВОТ СЮДА (самое начало)
    final key = _storage.makeKey(
      fromLabel: fromLabel,
      toLabel: toLabel,
      sourceText: sourceText,
    );
    final starred = _favorites.containsKey(key);

    setState(() {
      if (_recent.isNotEmpty &&
          _recent[0].fromLabel == fromLabel &&
          _recent[0].toLabel == toLabel) {
        final top = _recent[0];

        final sameSession =
            sourceText.startsWith(top.sourceText) ||
            top.sourceText.startsWith(sourceText);

        if (sameSession) {
          _recent[0] = TranslationHistoryItem(
            fromLabel: fromLabel,
            toLabel: toLabel,
            sourceText: sourceText,
            translatedText: translatedText,
            // ✅ тут: если в избранных — true, иначе сохраним старое состояние top
            isStarred: starred ? true : top.isStarred,
          );
        } else {
          _recent.insert(
            0,
            TranslationHistoryItem(
              fromLabel: fromLabel,
              toLabel: toLabel,
              sourceText: sourceText,
              translatedText: translatedText,
              // ✅ тут
              isStarred: starred,
            ),
          );
        }
      } else {
        _recent.insert(
          0,
          TranslationHistoryItem(
            fromLabel: fromLabel,
            toLabel: toLabel,
            sourceText: sourceText,
            translatedText: translatedText,
            // ✅ тут
            isStarred: starred,
          ),
        );
      }

      if (_recent.length > 3) _recent.removeRange(3, _recent.length);
    });

    _saveRecentToHive();
  }

  void _toggleStar(int index) async {
    setState(() {
      final item = _recent[index];
      final newStar = !item.isStarred;
      final updated = item.copyWith(isStarred: newStar);
      _recent[index] = updated;

      final key = _storage.makeKey(
        fromLabel: updated.fromLabel,
        toLabel: updated.toLabel,
        sourceText: updated.sourceText,
      );

      if (newStar) {
        _favorites[key] = updated.copyWith(isStarred: true);
      } else {
        _favorites.remove(key);
      }
    });

    await _saveRecentToHive();
    await _storage.saveFavorites(_favorites);
  }

  void _openHistorySheet(int index) {
    final item = _recent[index];

    TranslationDetailSheet.show(
      context: context,
      title: '${item.fromLabel} - ${item.toLabel}',
      sourceText: item.sourceText,
      translatedText: item.translatedText,
      isStarred: item.isStarred,
      onToggleStar: () => _toggleStar(index),
    );
  }

  Lang _findLang(String code, Lang fallback) {
    for (final l in langs) {
      if (l.code == code) return l;
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();

    _service = YandexTranslateService(
      apiKey: Secrets.yandexApiKey,
      folderId: Secrets.yandexFolderId,
    );

    final savedFrom = _settings.getFromCode(fallback: fromLang.code);
    final savedTo = _settings.getToCode(fallback: toLang.code);
    fromLang = _findLang(savedFrom, fromLang);
    toLang = _findLang(savedTo, toLang);

    _storage = TranslationStorage(_box);

    _loadRecentFromHive(); // загрузили recent (со старыми isStarred)
    _syncFavoritesFromHive(); // сразу пересчитали звёзды по избранным

    _inputCtrl.addListener(_onInputChanged);

    _favListenable = _box.listenable(
      keys: const [TranslationStorage.kFavorites],
    );
    _favListenable?.addListener(_syncFavoritesFromHive);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveDebounce?.cancel();
    _favListenable?.removeListener(_syncFavoritesFromHive);
    _inputCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        title: const Text(
          'Translate',
          style: TextStyle(color: Colors.black, fontSize: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectLanguageWidget(
                    language: fromLang.label,
                    items: langs,
                    onSelected: (Lang value) {
                      setState(() => fromLang = value);
                      _settings.setFromCode(value.code);
                      _onInputChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          offset: Offset(0, 6),
                          color: Color(0x14000000),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      elevation: 0, // тень сделаем через BoxDecoration ниже
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      clipBehavior: Clip.antiAlias, // важно для ripple
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            final tmp = fromLang;
                            fromLang = toLang;
                            toLang = tmp;
                          });
                          _settings.setFromCode(fromLang.code);
                          _settings.setToCode(toLang.code);
                          _onInputChanged();
                        },
                        child: Icon(Icons.swap_horiz),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectLanguageWidget(
                    language: toLang.label,
                    items: langs,
                    onSelected: (Lang value) {
                      setState(() => toLang = value);
                      _settings.setToCode(value.code);
                      _onInputChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TranslateFieldWidget(
              languageStyle: languageStyle,
              languageLabel: fromLang.label,
              controller: _inputCtrl,
            ),
            const SizedBox(height: 10),
            TranslateResultWidget(
              languageStyle: languageStyle,
              languageLabel: toLang.label,
              isLoading: _isLoading,
              errorText: _errorText,
              resultText: result,
            ),
            const SizedBox(height: 10),
            const Text(
              'Recent Translation',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_recent.isEmpty)
              const Text(
                'Пока нет переводов',
                style: TextStyle(color: Colors.grey),
              )
            else
              CardContainerWidget(
                hight: null,
                child: Column(
                  children: List.generate(_recent.length, (i) {
                    final item = _recent[i];
                    return Column(
                      children: [
                        RecentTranslationWidget(
                          languageStyle: languageStyle,
                          title: '${item.fromLabel} - ${item.toLabel}',
                          sourceText: item.sourceText,
                          translatedText: item.translatedText,
                          isStarred: item.isStarred,
                          onStarTap: () => _toggleStar(i),
                          onTap: () => _openHistorySheet(i),
                        ),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SelectLanguageWidget extends StatefulWidget {
  const SelectLanguageWidget({
    super.key,
    required this.language,
    required this.items,
    required this.onSelected,
  });

  final String language;
  final List<Lang> items;
  final ValueChanged<Lang> onSelected;

  @override
  State<SelectLanguageWidget> createState() => _SelectLanguageWidgetState();
}

class _SelectLanguageWidgetState extends State<SelectLanguageWidget> {
  bool isOpen = false;

  Future<void> _openMenu(
    BuildContext context,
    BoxConstraints constraints,
  ) async {
    setState(() => isOpen = true);

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // верхняя точка меню = низ кнопки
    final Offset topLeft = button.localToGlobal(
      Offset(0, button.size.height),
      ancestor: overlay,
    );

    // нижняя точка меню = тоже низ кнопки (высоту меню showMenu сам считает)
    final Offset bottomRight = button.localToGlobal(
      Offset(button.size.width, button.size.height),
      ancestor: overlay,
    );

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<Lang>(
      context: context,
      position: position, // как у тебя offset
      color: Colors.white,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        side: BorderSide(color: Color(0xFFE5E7EB)),
      ),
      constraints: BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
        maxHeight: 400,
      ),
      items: widget.items
          .map(
            (l) => PopupMenuItem<Lang>(
              value: l,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              child: Text(l.label),
            ),
          )
          .toList(),
    );

    if (!mounted) return;
    setState(() => isOpen = false);

    if (selected != null) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final BorderRadius radius = isOpen
            ? const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              )
            : BorderRadius.circular(14);

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 6),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openMenu(context, constraints),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.language,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TranslateFieldWidget extends StatelessWidget {
  TranslateFieldWidget({
    super.key,
    required this.languageStyle,
    required this.languageLabel,
    required this.controller,
  });

  final TextStyle languageStyle;
  final String languageLabel;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CardContainerWidget(
      hight: 180,
      child: Padding(
        padding: const EdgeInsets.only(right: 10, left: 10, bottom: 10, top: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  Text(languageLabel, style: languageStyle),
                  const Spacer(),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final hasText = value.text.isNotEmpty;

                      return SizedBox(
                        width: 32,
                        height: 32,
                        child: hasText
                            ? IconButton(
                                onPressed: controller.clear,
                                icon: const Icon(Icons.close, size: 26),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                                visualDensity: VisualDensity.compact,
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextField(
                style: TextStyle(fontSize: 20),
                controller: controller,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Enter your text...',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TranslateResultWidget extends StatelessWidget {
  const TranslateResultWidget({
    super.key,
    required this.languageStyle,
    required this.languageLabel,
    required this.isLoading,
    required this.errorText,
    required this.resultText,
  });

  final TextStyle languageStyle;
  final String languageLabel;
  final bool isLoading;
  final String? errorText;
  final String resultText;

  @override
  Widget build(BuildContext context) {
    return CardContainerWidget(
      hight: 180,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(languageLabel, style: languageStyle),
            const SizedBox(height: 10),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (errorText != null) {
                    return SingleChildScrollView(
                      child: Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  // if (isLoading) {
                  //   return const Center(child: CircularProgressIndicator());
                  // }

                  return SingleChildScrollView(
                    child: Text(
                      resultText,
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
