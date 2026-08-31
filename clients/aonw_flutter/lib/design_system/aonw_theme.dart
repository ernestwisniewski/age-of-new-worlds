import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import 'aonw_tokens.dart';

abstract final class AonwTheme {
  static ThemeData get dark => darkFor();

  static ThemeData darkFor({bool highContrast = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AonwColorTokens.brand,
      brightness: Brightness.dark,
      contrastLevel: highContrast ? 1 : 0,
      surface: AonwColorTokens.surface,
    );
    const minimumInteractiveSize = WidgetStatePropertyAll(
      Size.square(AonwSizes.minimumInteractive),
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AonwColorTokens.background,
      fontFamily: AonwTypography.bodyFamily,
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: _textTheme(),
      cardTheme: CardThemeData(
        color: AonwColorTokens.card.withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AonwColorTokens.brand.withValues(alpha: 0.48),
          ),
          borderRadius: BorderRadius.all(Radius.circular(AonwRadii.panel)),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: minimumInteractiveSize),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(minimumSize: minimumInteractiveSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: minimumInteractiveSize,
          foregroundColor: const WidgetStatePropertyAll(
            AonwColorTokens.textPrimary,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: AonwColorTokens.brand.withValues(alpha: 0.72)),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AonwRadii.panel)),
            ),
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme() =>
      Typography.material2021(platform: defaultTargetPlatform).white
          .apply(
            bodyColor: AonwColorTokens.textPrimary,
            displayColor: AonwColorTokens.brandLight,
            fontFamily: AonwTypography.bodyFamily,
          )
          .copyWith(
            displayLarge: _heading(57),
            displayMedium: _heading(45),
            displaySmall: _heading(36),
            headlineLarge: _heading(32),
            headlineMedium: _heading(28),
            headlineSmall: _heading(24),
            titleLarge: _heading(20),
            titleMedium: _heading(16),
            titleSmall: _heading(14),
          );

  static TextStyle _heading(double size) => const TextStyle(
    color: AonwColorTokens.brandLight,
    fontFamily: AonwTypography.headingFamily,
    fontWeight: FontWeight.w700,
  ).copyWith(fontSize: size);
}
