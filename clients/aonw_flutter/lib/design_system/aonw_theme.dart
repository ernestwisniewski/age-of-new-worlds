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
      snackBarTheme: _snackBarTheme(),
      tooltipTheme: _tooltipTheme(),
      cardTheme: _cardTheme(),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: minimumInteractiveSize),
      ),
      filledButtonTheme: _filledButtonTheme(minimumInteractiveSize),
      outlinedButtonTheme: _outlinedButtonTheme(minimumInteractiveSize),
    );
  }

  static SnackBarThemeData _snackBarTheme() => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AonwColorTokens.surfaceDeep.withAlpha(242),
    contentTextStyle: AonwTextStyles.bodyStrong.copyWith(
      color: AonwColorTokens.textPrimary,
      fontSize: 13,
    ),
    actionTextColor: AonwColorTokens.brandLight,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: AonwColorTokens.brand.withAlpha(130)),
    ),
  );

  static TooltipThemeData _tooltipTheme() => TooltipThemeData(
    triggerMode: TooltipTriggerMode.longPress,
    waitDuration: const Duration(milliseconds: 450),
    showDuration: const Duration(seconds: 5),
    preferBelow: false,
    verticalOffset: 16,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AonwColorTokens.background.withAlpha(242),
      borderRadius: BorderRadius.circular(AonwRadii.panel),
      border: Border.all(color: AonwColorTokens.brand.withAlpha(120)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    textStyle: AonwTextStyles.bodySmall.copyWith(
      color: AonwColorTokens.textPrimary,
      fontWeight: FontWeight.w700,
    ),
  );

  static CardThemeData _cardTheme() => CardThemeData(
    color: AonwColorTokens.card.withValues(alpha: 0.94),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: AonwColorTokens.brand.withValues(alpha: 0.48)),
      borderRadius: const BorderRadius.all(Radius.circular(AonwRadii.panel)),
    ),
  );

  static FilledButtonThemeData _filledButtonTheme(
    WidgetStateProperty<Size?> minimumSize,
  ) => FilledButtonThemeData(
    style: ButtonStyle(
      minimumSize: minimumSize,
      textStyle: const WidgetStatePropertyAll(AonwTextStyles.menuButton),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AonwRadii.panel)),
        ),
      ),
    ),
  );

  static OutlinedButtonThemeData _outlinedButtonTheme(
    WidgetStateProperty<Size?> minimumSize,
  ) => OutlinedButtonThemeData(
    style: ButtonStyle(
      minimumSize: minimumSize,
      foregroundColor: const WidgetStatePropertyAll(
        AonwColorTokens.textPrimary,
      ),
      textStyle: const WidgetStatePropertyAll(AonwTextStyles.actionLabel),
      side: WidgetStatePropertyAll(
        BorderSide(color: AonwColorTokens.brand.withValues(alpha: 0.72)),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AonwRadii.panel)),
        ),
      ),
    ),
  );

  static TextTheme _textTheme() =>
      Typography.material2021(platform: defaultTargetPlatform).white
          .apply(
            bodyColor: AonwColorTokens.textPrimary,
            displayColor: AonwColorTokens.brandLight,
            fontFamily: AonwTypography.bodyFamily,
          )
          .copyWith(
            displayLarge: AonwTextStyles.brandTitle,
            displayMedium: AonwTextStyles.brandTitle,
            displaySmall: AonwTextStyles.brandTitle,
            headlineLarge: AonwTextStyles.screenTitle,
            headlineMedium: AonwTextStyles.screenTitle,
            headlineSmall: AonwTextStyles.cardTitle,
            titleLarge: AonwTextStyles.screenTitle,
            titleMedium: AonwTextStyles.cardTitle,
            titleSmall: AonwTextStyles.sectionHeader,
            bodyLarge: AonwTextStyles.body,
            bodyMedium: AonwTextStyles.body,
            bodySmall: AonwTextStyles.bodySmall,
            labelLarge: AonwTextStyles.actionLabel,
            labelMedium: AonwTextStyles.chipLabel,
            labelSmall: AonwTextStyles.labelSmall,
          );
}
