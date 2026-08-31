import 'package:flutter/material.dart';

abstract final class AonwColorTokens {
  static const background = Color(0xFF0A0A0E);
  static const surface = Color(0xFF101620);
  static const surfaceDeep = Color(0xFF1A2030);
  static const card = Color(0xFF131B26);
  static const brand = Color(0xFFD2A856);
  static const brandLight = Color(0xFFF0DCAE);
  static const brandDark = Color(0xFF8C6926);
  static const textPrimary = Color(0xFFF0EDE6);
  static const textSecondary = Color(0xFFA0A5B2);
}

abstract final class AonwTypography {
  static const headingFamily = 'Cinzel';
  static const bodyFamily = 'Lato';
}

abstract final class AonwSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

abstract final class AonwRadii {
  static const panel = 10.0;
}

abstract final class AonwSizes {
  static const minimumInteractive = 48.0;
  static const compactProgress = 18.0;
}
