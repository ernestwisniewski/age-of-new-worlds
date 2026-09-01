import 'package:flutter/foundation.dart';

@immutable
final class MapDisplayOptions {
  const MapDisplayOptions({
    this.showElevationWalls = false,
    this.showTerrainIcons = false,
    this.showResourceIcons = true,
    this.showHeightBadges = false,
  });

  final bool showElevationWalls;
  final bool showTerrainIcons;
  final bool showResourceIcons;
  final bool showHeightBadges;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapDisplayOptions &&
          other.showElevationWalls == showElevationWalls &&
          other.showTerrainIcons == showTerrainIcons &&
          other.showResourceIcons == showResourceIcons &&
          other.showHeightBadges == showHeightBadges;

  @override
  int get hashCode => Object.hash(
    showElevationWalls,
    showTerrainIcons,
    showResourceIcons,
    showHeightBadges,
  );
}
