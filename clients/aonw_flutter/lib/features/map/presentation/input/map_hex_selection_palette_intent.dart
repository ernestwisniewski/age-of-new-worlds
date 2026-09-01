import '../../read_model/map_view.dart';
import '../map_hex_selection_palette_view.dart';

sealed class MapHexSelectionPaletteIntent {
  const MapHexSelectionPaletteIntent(this.coordinate);

  final MapHexCoordinate coordinate;
}

final class SelectTerrainHexPaletteIntent extends MapHexSelectionPaletteIntent {
  const SelectTerrainHexPaletteIntent(super.coordinate);
}

final class SelectUnitHexPaletteIntent extends MapHexSelectionPaletteIntent {
  const SelectUnitHexPaletteIntent({
    required MapHexCoordinate coordinate,
    required this.unitId,
  }) : super(coordinate);

  final String unitId;
}

final class SelectCityHexPaletteIntent extends MapHexSelectionPaletteIntent {
  const SelectCityHexPaletteIntent({
    required MapHexCoordinate coordinate,
    required this.cityId,
  }) : super(coordinate);

  final String cityId;
}

final class InspectFieldImprovementHexPaletteIntent
    extends MapHexSelectionPaletteIntent {
  const InspectFieldImprovementHexPaletteIntent(super.coordinate);
}

final class InspectArtifactHexPaletteIntent
    extends MapHexSelectionPaletteIntent {
  const InspectArtifactHexPaletteIntent({
    required MapHexCoordinate coordinate,
    required this.artifactId,
  }) : super(coordinate);

  final String artifactId;
}

final class InspectObjectiveHexPaletteIntent
    extends MapHexSelectionPaletteIntent {
  const InspectObjectiveHexPaletteIntent({
    required MapHexCoordinate coordinate,
    required this.objectiveId,
  }) : super(coordinate);

  final String objectiveId;
}

MapHexSelectionPaletteIntent mapHexSelectionIntentFor(
  MapHexSelectionTargetView target,
) => switch (target) {
  TerrainHexSelectionTargetView(:final coordinate) =>
    SelectTerrainHexPaletteIntent(coordinate),
  UnitHexSelectionTargetView(:final coordinate, :final unitId) =>
    SelectUnitHexPaletteIntent(coordinate: coordinate, unitId: unitId),
  CityHexSelectionTargetView(:final coordinate, :final cityId) =>
    SelectCityHexPaletteIntent(coordinate: coordinate, cityId: cityId),
  FieldImprovementHexSelectionTargetView(:final coordinate) =>
    InspectFieldImprovementHexPaletteIntent(coordinate),
  ArtifactHexSelectionTargetView(:final coordinate, :final artifactId) =>
    InspectArtifactHexPaletteIntent(
      coordinate: coordinate,
      artifactId: artifactId,
    ),
  ObjectiveHexSelectionTargetView(:final coordinate, :final objectiveId) =>
    InspectObjectiveHexPaletteIntent(
      coordinate: coordinate,
      objectiveId: objectiveId,
    ),
};

typedef MapHexSelectionPaletteIntentSink =
    void Function(MapHexSelectionPaletteIntent intent);
