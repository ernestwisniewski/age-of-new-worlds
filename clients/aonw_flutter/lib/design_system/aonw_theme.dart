import 'package:flutter/material.dart';

import 'aonw_tokens.dart';

abstract final class AonwTheme {
  static ThemeData get dark => darkFor();

  static ThemeData darkFor({bool highContrast = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AonwColorTokens.brand,
      brightness: Brightness.dark,
      contrastLevel: highContrast ? 1 : 0,
    );
    const minimumInteractiveSize = WidgetStatePropertyAll(
      Size.square(AonwSizes.minimumInteractive),
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AonwRadii.panel)),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: minimumInteractiveSize),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(minimumSize: minimumInteractiveSize),
      ),
    );
  }
}
