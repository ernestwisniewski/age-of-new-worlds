import 'package:flutter/material.dart';

abstract final class AonwColorTokens {
  static const background = Color(0xFF0A0A0E);
  static const surface = Color(0xFF101620);
  static const surfaceDeep = Color(0xFF1A2030);
  static const chipSurface = Color(0xFF1E2738);
  static const chipSurfaceDim = Color(0xFF27384C);
  static const card = Color(0xFF131B26);
  static const cardAccent = Color(0xFF1E2738);
  static const brand = Color(0xFFD2A856);
  static const brandLight = Color(0xFFF0DCAE);
  static const brandDark = Color(0xFF8C6926);
  static const copper = Color(0xFFB47A4E);
  static const copperDeep = Color(0xFF7A4A28);
  static const success = Color(0xFF6CC07A);
  static const successLight = Color(0xFFA8E0B0);
  static const successDim = Color(0xFF3E7D49);
  static const successSubtle = Color(0xFF1E3B25);
  static const warning = Color(0xFFF0C36A);
  static const danger = Color(0xFFC0392B);
  static const dangerSubtle = Color(0xFF481D1A);
  static const info = Color(0xFF6FA8D6);
  static const scienceAccent = Color(0xFF9FC7B5);
  static const resourcesAccent = Color(0xFFD6A56B);
  static const textPrimary = Color(0xFFF0EDE6);
  static const textSecondary = Color(0xFFA0A5B2);
  static const textTertiary = Color(0xFF747787);
  static const textBright = Color(0xFFF8F2E4);
  static const textMuted = Color(0xFFEBD9B0);
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
  static const frame = 2.0;
  static const chip = 14.0;
  static const panel = 10.0;
  static const button = 12.0;
  static const pill = 999.0;
}

abstract final class AonwSizes {
  static const minimumInteractive = 48.0;
  static const compactProgress = 18.0;
}

abstract final class AonwMotion {
  static const snap = Duration(milliseconds: 120);
  static const fade = Duration(milliseconds: 200);
  static const slide = Duration(milliseconds: 240);
  static const scene = Duration(milliseconds: 350);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const stateChange = Curves.easeInOutCubic;
}
