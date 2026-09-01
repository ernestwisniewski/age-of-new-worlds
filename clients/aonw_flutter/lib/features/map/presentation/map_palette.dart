import 'package:flutter/material.dart';

import '../read_model/map_view.dart';

abstract final class MapPalette {
  static const grid = Color(0x00000000);
  static const hover = Color(0xFFE7F1F6);
  static const selection = Color(0xFFFFC857);
  static const reachable = Color(0x5534D6C7);
  static const route = Color(0xFFFFD166);
  static const controlledUnit = Color(0xFF38BDF8);
  static const foreignUnit = Color(0xFFE76F51);
  static const unitOutline = Color(0xFF102A3A);
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
