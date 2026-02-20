import 'package:flutter/material.dart';

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
    final radius = borderRadius ?? BorderRadius.circular(14);

    return Material(
      color: Colors.white,
      elevation: 3, // можешь 2-4 подобрать
      shadowColor: const Color(0x14000000),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias, // важно: режет divider/ink внутри
      child: SizedBox(width: double.infinity, height: hight, child: child),
    );
  }
}
