import 'package:flutter/material.dart';

import '../aonw_tokens.dart';

const aonwMenuBackgroundAsset = 'assets/main_menu/background.jpg';
const aonwLogoAsset = 'assets/runtime/ui/logo.webp';

final class AonwMenuBackdrop extends StatelessWidget {
  const AonwMenuBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        aonwMenuBackgroundAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AonwColorTokens.background.withValues(alpha: 0.54),
              AonwColorTokens.background.withValues(alpha: 0.85),
            ],
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [
              Colors.transparent,
              AonwColorTokens.background.withValues(alpha: 0.62),
            ],
          ),
        ),
      ),
      child,
    ],
  );
}
