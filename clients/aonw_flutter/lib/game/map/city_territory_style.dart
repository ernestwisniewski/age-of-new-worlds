import 'dart:ui' as ui;

import '../../design_system/aonw_tokens.dart';

final class MapCityTerritoryStyle {
  MapCityTerritoryStyle(this.playerColor, {required this.strategicView});

  final ui.Color playerColor;
  final bool strategicView;

  late final ui.Color fillColor = strategicView
      ? ui.Color.lerp(playerColor, AonwColorTokens.brandLight, 0.18)!
      : playerColor;
  late final ui.Color insetWashColor = ui.Color.lerp(
    fillColor,
    AonwColorTokens.brandLight,
    0.12,
  )!;
  late final ui.Color edgeBandColor = ui.Color.lerp(
    playerColor,
    AonwColorTokens.copper,
    0.18,
  )!;
  late final ui.Color strategicCenterColor = ui.Color.lerp(
    playerColor,
    AonwColorTokens.brandLight,
    0.22,
  )!;
  late final ui.Color _borderShadowColor = ui.Color.lerp(
    playerColor,
    AonwColorTokens.background,
    0.72,
  )!;
  late final ui.Color _solidBorderColor = ui.Color.lerp(
    playerColor,
    AonwColorTokens.background,
    strategicView ? 0.12 : 0.48,
  )!;
  late final ui.Color _atlasInkBorderColor = ui.Color.lerp(
    AonwColorTokens.background,
    playerColor,
    0.1,
  )!;
  late final ui.Color _borderGlowColor = ui.Color.lerp(
    playerColor,
    AonwColorTokens.brandLight,
    0.34,
  )!;
  late final ui.Color _innerBorderHighlightColor = ui.Color.lerp(
    playerColor,
    AonwColorTokens.textBright,
    0.26,
  )!;
  late final ui.Color _selectedBorderGlowColor = ui.Color.lerp(
    playerColor,
    AonwColorTokens.brandLight,
    0.18,
  )!;

  late final ui.Paint outerBorderPaint = territoryStroke(
    _borderShadowColor,
    alpha: strategicView ? 180 : 220,
    width: strategicView ? 4.6 : 5.2,
  );
  late final ui.Paint solidBorderPaint = territoryStroke(
    _solidBorderColor,
    alpha: strategicView ? 245 : 255,
    width: strategicView ? 3.5 : 3.2,
  );
  late final ui.Paint atlasInkBorderPaint = territoryStroke(
    _atlasInkBorderColor,
    alpha: strategicView ? 130 : 190,
    width: strategicView ? 1 : 1.25,
  );
  late final ui.Paint borderGlowPaint = territoryStroke(
    _borderGlowColor,
    alpha: 130,
    width: 5,
  )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
  late final ui.Paint strategicCenterGlowPaint = territoryStroke(
    strategicCenterColor,
    alpha: 180,
    width: 5,
  )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
  late final ui.Paint strategicCenterInnerPaint = territoryStroke(
    strategicCenterColor,
    alpha: 220,
    width: 1,
  );
  late final ui.Paint insetWashPaint = territoryStroke(
    insetWashColor,
    alpha: 36,
    width: 27,
  )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.4);
  late final ui.Paint selectedInsetWashPaint = territoryStroke(
    insetWashColor,
    alpha: 48,
    width: 31,
  )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.4);
  late final ui.Paint selectedBorderBackingPaint = territoryStroke(
    AonwColorTokens.background,
    alpha: 220,
    width: 3.8,
  );

  ui.Paint fillPaint({
    required bool empireHighlighted,
    required double zoomEmphasis,
  }) => territoryFill(
    fillColor,
    alpha: strategicView
        ? 230
        : territoryEmphasizedAlpha(
            empireHighlighted ? 56 : 42,
            empireHighlighted ? 176 : 150,
            zoomEmphasis,
          ),
  );

  ui.Paint innerBorderHighlightPaint(double zoomEmphasis) => territoryStroke(
    _innerBorderHighlightColor,
    alpha: strategicView
        ? 130
        : territoryEmphasizedAlpha(118, 150, zoomEmphasis),
    width: strategicView ? 1.2 : 1.1,
  );

  ui.Paint edgeGlowPaint({
    required bool empireHighlighted,
    required double zoomEmphasis,
  }) => territoryStroke(
    edgeBandColor,
    alpha: territoryEmphasizedAlpha(
      empireHighlighted ? 106 : 88,
      empireHighlighted ? 148 : 126,
      zoomEmphasis,
    ),
    width: empireHighlighted ? 19 : 17,
  )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5.2);

  ui.Paint edgeBandPaint({
    required bool empireHighlighted,
    required double zoomEmphasis,
  }) => territoryStroke(
    edgeBandColor,
    alpha: territoryEmphasizedAlpha(
      empireHighlighted ? 78 : 60,
      empireHighlighted ? 112 : 92,
      zoomEmphasis,
    ),
    width: empireHighlighted ? 10.8 : 9.2,
  );

  ui.Paint selectedBorderGlowPaint(double zoomEmphasis) => territoryStroke(
    _selectedBorderGlowColor,
    alpha: territoryEmphasizedAlpha(132, 164, zoomEmphasis),
    width: 8.8,
  )..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.6);

  ui.Paint selectedPlayerBorderPaint(double zoomEmphasis) => territoryStroke(
    playerColor,
    alpha: territoryEmphasizedAlpha(168, 196, zoomEmphasis),
    width: 1.6,
  );
}

int territoryEmphasizedAlpha(int base, int zoomedOut, double emphasis) =>
    ui.lerpDouble(base.toDouble(), zoomedOut.toDouble(), emphasis)!.round();

ui.Paint territoryFill(ui.Color color, {required int alpha}) => ui.Paint()
  ..style = ui.PaintingStyle.fill
  ..color = color.withAlpha(alpha)
  ..isAntiAlias = true;

ui.Paint territoryStroke(
  ui.Color color, {
  required int alpha,
  required double width,
}) => ui.Paint()
  ..style = ui.PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = ui.StrokeCap.round
  ..strokeJoin = ui.StrokeJoin.round
  ..color = color.withAlpha(alpha)
  ..isAntiAlias = true;

final mapCityTerritoryCenterFillPaint = territoryFill(
  AonwColorTokens.background,
  alpha: 130,
);
final mapCityTerritoryCenterBorderPaint = territoryStroke(
  AonwColorTokens.brandLight,
  alpha: 245,
  width: 2,
);
final mapCityTerritoryDimmingPaint = territoryFill(
  AonwColorTokens.background,
  alpha: 130,
);
