import 'package:ezzy/translate/widgets/card_container_widget.dart';
import 'package:flutter/material.dart';

class RecentTranslationWidget extends StatelessWidget {
  const RecentTranslationWidget({
    super.key,
    required this.languageStyle,
    required this.title,
    required this.sourceText,
    required this.translatedText,
    this.isStarred = false,
    this.onStarTap,
    this.onTap,
  });

  final TextStyle languageStyle;
  final String title;
  final String sourceText;
  final String translatedText;

  final bool isStarred;
  final VoidCallback? onStarTap;
  final VoidCallback? onTap;

  // 1) Функция: “этот текст НЕ помещается в 2 строки при данной ширине?”
  // Почему внутри виджета: чтобы логика была рядом с UI.
  bool _exceedsTwoLines(
    BuildContext context,
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 2,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);

    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    // Стили вынесли в переменные, чтобы:
    // 1) измерять тем же стилем (TextPainter)
    // 2) не дублировать код
    const sourceStyle = TextStyle(
      fontSize: 18,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    const translatedStyle = TextStyle(
      fontSize: 18,
      color: Color(0xFF0024A5),
      fontWeight: FontWeight.bold,
    );

    // 2) LayoutBuilder даёт нам constraints (реальную доступную ширину)
    return LayoutBuilder(
      builder: (context, constraints) {
        // учитываем Padding left/right = 10 + 10
        final textWidth = (constraints.maxWidth - 20)
            .clamp(0, double.infinity)
            .toDouble();

        // 3) Проверяем, длинный ли текст
        final sourceLong = _exceedsTwoLines(
          context,
          sourceText,
          sourceStyle,
          textWidth,
        );
        final translatedLong = _exceedsTwoLines(
          context,
          translatedText,
          translatedStyle,
          textWidth,
        );

        // если хоть один из текстов длинный — тогда есть смысл открывать bottom sheet
        final canExpand = sourceLong || translatedLong;

        return InkWell(
          // 4) Если коротко — onTap = null (карточка “просто висит”)
          onTap: canExpand ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 10,
              bottom: 10,
              top: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: languageStyle),
                    const Spacer(),
                    IconButton(
                      onPressed: onStarTap,
                      icon: Icon(
                        isStarred ? Icons.star : Icons.star_border,
                        size: 28,
                        color: isStarred
                            ? const Color(0xFFFFC107)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),

                // 5) Короткий — показываем полностью (maxLines: null)
                // Длинный — 2 строки и ...
                Text(
                  sourceText,
                  maxLines: sourceLong ? 2 : null,
                  overflow: sourceLong
                      ? TextOverflow.ellipsis
                      : TextOverflow.visible,
                  style: sourceStyle,
                ),

                const SizedBox(height: 5),

                Text(
                  translatedText,
                  maxLines: translatedLong ? 2 : null,
                  overflow: translatedLong
                      ? TextOverflow.ellipsis
                      : TextOverflow.visible,
                  style: translatedStyle,
                ),

                const SizedBox(height: 5),
                const Divider(),
              ],
            ),
          ),
        );
      },
    );
  }
}
