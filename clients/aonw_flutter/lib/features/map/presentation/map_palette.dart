import 'package:flutter/material.dart';

import '../read_model/map_view.dart';

abstract final class MapPalette {
  static const grid = Color(0xFF000000);
  static const selection = Color(0xFFF0DCAE);
  static const selectionGlow = Color(0x82F0DCAE);
  static const selectionBacking = Color(0xDC000000);
  static const route = Color(0xFFFFFFFF);
  static const routeTargetGlow = Color(0x5AFFFFFF);
  static const routeBoundaryHalo = Color(0x1EFFFFFF);
  static const routeBoundaryDot = Color(0xF5FFFFFF);
  static const routeBoundaryBorder = Color(0xB4000000);
  static const moveHoverGlow = Color(0x3CFFFFFF);
  static const moveHoverHalo = Color(0x1EFFFFFF);
  static const attackHoverFill = Color(0x3CC0392B);
  static const attackHoverGlow = Color(0x5AC0392B);
  static const attackHoverLine = Color(0xDCC0392B);
  static const attackBadgeGlow = Color(0x1EE1A884);
  static const intentBadgeShadow = Color(0x5C000000);
  static const intentBadgeFill = Color(0xFF2A2D31);
  static const intentBadgeBorder = Color(0xF5F0DCAE);
  static const intentBadgeHighlight = Color(0x3CF8F2E4);
  static const intentBadgeGlyph = Color(0xF5F0DCAE);
  static const controlledUnit = Color(0xFF38BDF8);
  static const foreignUnit = Color(0xFFE76F51);
  static const unitOutline = Color(0xFF102A3A);
  static const unitBackground = Color(0xFF0A0A0E);
  static const unitSurfaceDeep = Color(0xFF1A2030);
  static const unitGold = Color(0xFFD2A856);
  static const unitGoldLight = Color(0xFFF0DCAE);
  static const unitGoldBorder = Color(0xB4F0DCAE);
  static const unitSelectedGlow = Color(0x2AD2A856);
  static const unitShadow = Color(0x5A000000);
  static const unitHealthBackdrop = Color(0xB4000000);
  static const unitSuccess = Color(0xFF6CC07A);
  static const unitWarning = Color(0xFFF0C36A);
  static const unitDanger = Color(0xFFC0392B);
  static const unitInfo = Color(0xFF6FA8D6);
  static const unitTextSecondary = Color(0xFFA0A5B2);
  static const unitTextTertiary = Color(0xFF747787);
  static const unitTextBright = Color(0xFFF8F2E4);
  static const unitWorkBorder = Color(0x82F8F2E4);
  static const controlledCity = Color(0xFFF4C95D);
  static const foreignCity = Color(0xFFCE6A85);
  static const cityOutline = Color(0xFF402A23);
  static const artifact = Color(0xFFB388FF);
  static const artifactExcavation = Color(0xFFFFD166);
  static const artifactOutline = Color(0xFF291B3A);
  static const fogHidden = Color(0xFF000000);
  static const fogDiscovered = Color(0x80000000);
  static const elevationWallBottom = Color(0xFF111820);
  static const elevationWallHighlight = Color(0xFFF8F2E4);
  static const mapIconFallback = Color(0xB4F0DCAE);
  static const heightBadge = Color(0xFFFFFFFF);
  static const heightBadgeOutline = Color(0xFF000000);
  static const roadEdge = Color(0xFF000000);
  static const roadAsphalt = Color(0xFF24262A);
  static const roadMarking = Color(0xFFFFFFFF);
  static const improvementSurface = Color(0x1E101620);
  static const improvementRim = Color(0xDCC8CCD2);
  static const improvementSelectedRim = Color(0xDCF1F4F8);
  static const improvementSelectedShadowStrong = Color(0x829AA2AE);
  static const improvementSelectedShadowSoft = Color(0x5A9AA2AE);
  static final elevationWallRight = Color.lerp(
    elevationWallBottom,
    elevationWallHighlight,
    0.10,
  )!;
  static final elevationWallLeft = Color.lerp(
    elevationWallBottom,
    elevationWallHighlight,
    0.20,
  )!;
  static const objectiveRuins = Color(0xFFB8A58A);
  static const objectiveStrategicPass = Color(0xFFE76F51);
  static const objectiveHolySite = Color(0xFFE8D272);
  static const objectiveLegendaryResource = Color(0xFF7FDBB6);
  static const objectiveOutline = Color(0xFF17242D);

  static const _terrain = {
    MapTerrain.ocean: Color(0xFF1A6691),
    MapTerrain.coast: Color(0xFF4A9FC4),
    MapTerrain.lake: Color(0xFF2F86A8),
    MapTerrain.plains: Color(0xFFC8B560),
    MapTerrain.grassland: Color(0xFF5A8A3C),
    MapTerrain.desert: Color(0xFFD4A84B),
    MapTerrain.tundra: Color(0xFF8DA89A),
    MapTerrain.snow: Color(0xFFE8E8F0),
    MapTerrain.mountain: Color(0xFF7A7A7A),
    MapTerrain.hills: Color(0xFFA0956E),
    MapTerrain.wetlands: Color(0xFF4D6F45),
    MapTerrain.jungle: Color(0xFF2D6B2A),
    MapTerrain.forest: Color(0xFF3D7A40),
    MapTerrain.river: Color(0xFF3A8FBF),
  };

  static Color terrain(MapTerrain terrain) => _terrain[terrain]!;
}
