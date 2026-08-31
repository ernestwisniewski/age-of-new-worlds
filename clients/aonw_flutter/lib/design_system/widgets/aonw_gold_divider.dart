import 'package:flutter/material.dart';

import '../aonw_tokens.dart';

final class AonwGoldDivider extends StatelessWidget {
  const AonwGoldDivider({this.width, this.alpha = 170, super.key});

  final double? width;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    final fadedGold = AonwColorTokens.brand.withAlpha(alpha);
    return SizedBox(
      key: const ValueKey('gold-divider-root'),
      width: width,
      height: 9,
      child: Row(
        children: [
          Expanded(
            child: _DividerLine(colors: [Colors.transparent, fadedGold]),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              key: const ValueKey('gold-divider-diamond'),
              width: 5,
              height: 5,
              color: AonwColorTokens.brand,
            ),
          ),
          Expanded(
            child: _DividerLine(colors: [fadedGold, Colors.transparent]),
          ),
        ],
      ),
    );
  }
}

final class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      gradient: LinearGradient(colors: colors),
      shape: const RoundedRectangleBorder(),
    ),
    child: const SizedBox(height: 1),
  );
}
