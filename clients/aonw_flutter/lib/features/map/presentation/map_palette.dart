import 'package:flutter/material.dart';

import '../read_model/map_view.dart';

abstract final class MapPalette {
  static const grid = Color(0xA61A242C);
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
  static const objectiveRuins = Color(0xFFB8A58A);
  static const objectiveStrategicPass = Color(0xFFE76F51);
  static const objectiveHolySite = Color(0xFFE8D272);
  static const objectiveLegendaryResource = Color(0xFF7FDBB6);
  static const objectiveOutline = Color(0xFF17242D);

  static const _terrain = {
    MapTerrain.ocean: Color(0xFF245B91),
    MapTerrain.coast: Color(0xFF4F9DC4),
    MapTerrain.lake: Color(0xFF3F87B3),
    MapTerrain.plains: Color(0xFFB7A66A),
    MapTerrain.grassland: Color(0xFF6E9C54),
    MapTerrain.desert: Color(0xFFC5A15F),
    MapTerrain.tundra: Color(0xFF89938A),
    MapTerrain.snow: Color(0xFFD9E2E3),
    MapTerrain.mountain: Color(0xFF666B6F),
    MapTerrain.hills: Color(0xFF8A7957),
    MapTerrain.wetlands: Color(0xFF537A68),
    MapTerrain.jungle: Color(0xFF356A43),
    MapTerrain.forest: Color(0xFF3E7148),
    MapTerrain.river: Color(0xFF3E83AD),
  };

  static Color terrain(MapTerrain terrain) => _terrain[terrain]!;
}
