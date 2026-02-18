import 'package:flutter/material.dart';

class Lang {
  final String code;
  final String label;
  const Lang(this.code, this.label);
}

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextStyle languageStyle = const TextStyle(
    color: Color(0xFF888888),
    fontSize: 14,
  );

  final langs = const [
    Lang('en', 'English'),
    Lang('ru', 'Russian'),
    Lang('uz', "O‘zbek"),
    Lang('tr', 'Turkish'),
    Lang('en', 'English'),
    Lang('ru', 'Russian'),
    Lang('uz', "O‘zbek"),
    Lang('tr', 'Turkish'),
    Lang('en', 'English'),
    Lang('ru', 'Russian'),
    Lang('uz', "O‘zbek"),
    Lang('tr', 'Turkish'),
    Lang('en', 'English'),
    Lang('ru', 'Russian'),
    Lang('uz', "O‘zbek"),
    Lang('tr', 'Turkish'),
    Lang('en', 'English'),
    Lang('ru', 'Russian'),
    Lang('uz', "O‘zbek"),
    Lang('tr', 'Turkish'),
  ];

  Lang fromLang = const Lang('en', 'English');
  Lang toLang = const Lang('ru', 'Russian');

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
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          final tmp = fromLang;
                          fromLang = toLang;
                          toLang = tmp;
                        });
                      },
                      icon: const Icon(Icons.swap_horiz),
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
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TranslateFieldWidget(languageStyle: languageStyle),
            const SizedBox(height: 10),
            TranslateResultWidget(languageStyle: languageStyle),
            const SizedBox(height: 10),
            Text(
              'Recent Translation',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            RecentTranslationWidget(languageStyle: languageStyle),
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 1) Радиус кнопки меняется, когда меню открыто (низ прямой)
          final BorderRadiusGeometry cardRadius = isOpen
              ? const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                )
              : BorderRadius.circular(14);

          // 2) Радиус меню: сверху прямое, снизу круглое
          final ShapeBorder menuShape = const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            side: BorderSide(color: Color(0xFFE5E7EB)),
          );

          return PopupMenuButton<Lang>(
            // важно: только один onSelected
            onSelected: (v) {
              widget.onSelected(v);
              setState(() => isOpen = false);
            },
            onOpened: () => setState(() => isOpen = true),
            onCanceled: () => setState(() => isOpen = false),

            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 2,

            constraints: BoxConstraints(
              minWidth: constraints.minWidth,
              maxWidth: constraints.maxWidth,
              maxHeight: 400,
            ),

            shape: menuShape,

            // чуть меньше, чем высота кнопки, чтобы "приклеилось"
            offset: const Offset(0, 56),

            itemBuilder: (context) => widget.items
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

            child: CardContainerWidget(
              hight: 58,
              borderRadius: cardRadius, // <-- вот почему "круглость" ушла
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
          );
        },
      ),
    );
  }
}

class TranslateFieldWidget extends StatelessWidget {
  const TranslateFieldWidget({super.key, required this.languageStyle});
  final TextStyle languageStyle;

  @override
  Widget build(BuildContext context) {
    return const CardContainerWidget(
      hight: 180,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('English'),
            Expanded(
              child: TextField(
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Enter your text...',
                  border: InputBorder.none,
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
  const TranslateResultWidget({super.key, required this.languageStyle});
  final TextStyle languageStyle;

  @override
  Widget build(BuildContext context) {
    return const CardContainerWidget(
      hight: 180,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Russian'), SizedBox(height: 10), Text('Result')],
        ),
      ),
    );
  }
}

class CardContainerWidget extends StatelessWidget {
  const CardContainerWidget({
    super.key,
    required this.child,
    required this.hight,
    this.borderRadius,
  });

  final Widget child;
  final double? hight;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: hight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class RecentTranslationWidget extends StatelessWidget {
  RecentTranslationWidget({super.key, required this.languageStyle});
  final TextStyle languageStyle;
  @override
  Widget build(BuildContext context) {
    return CardContainerWidget(
      hight: null,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('English - Russian', style: languageStyle),
                Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.star_border_purple500_outlined, size: 28),
                ),
              ],
            ),

            Text(
              'Hello',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Привет',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF0024A5),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('English - Russian', style: languageStyle),
                    Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.star_border_purple500_outlined,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                Text(
                  'Hello',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Привет',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0024A5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Divider(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
