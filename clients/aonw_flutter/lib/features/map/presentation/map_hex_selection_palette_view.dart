import '../../../l10n/generated/aonw_localizations.dart';
import '../../artifacts/read_model/artifact_view.dart';
import '../read_model/map_view.dart';
import '../read_model/pending_action_view.dart';
import '../read_model/player_map_view.dart';

final class MapHexSelectionPaletteView {
  MapHexSelectionPaletteView({
    required this.coordinate,
    required List<MapHexSelectionTargetView> targets,
  }) : targets = List.unmodifiable(targets) {
    if (targets.isEmpty) {
      throw ArgumentError.value(targets, 'targets', 'must not be empty');
    }
  }

  final MapHexCoordinate coordinate;
  final List<MapHexSelectionTargetView> targets;
}

sealed class MapHexSelectionTargetView {
  const MapHexSelectionTargetView({
    required this.coordinate,
    required this.label,
  });

  final MapHexCoordinate coordinate;
  final String label;
  String get key;
}

final class TerrainHexSelectionTargetView extends MapHexSelectionTargetView {
  const TerrainHexSelectionTargetView({
    required super.coordinate,
    required super.label,
    required this.terrain,
  });

  final MapTerrain terrain;

  @override
  String get key => 'terrain:${coordinate.col}:${coordinate.row}';
}

final class UnitHexSelectionTargetView extends MapHexSelectionTargetView {
  const UnitHexSelectionTargetView({
    required super.coordinate,
    required super.label,
    required this.unitId,
    required this.kind,
  });

  final String unitId;
  final VisibleUnitKind kind;

  @override
  String get key => 'unit:$unitId';
}

final class CityHexSelectionTargetView extends MapHexSelectionTargetView {
  const CityHexSelectionTargetView({
    required super.coordinate,
    required super.label,
    required this.cityId,
  });

  final String cityId;

  @override
  String get key => 'city:$cityId';
}

final class FieldImprovementHexSelectionTargetView
    extends MapHexSelectionTargetView {
  const FieldImprovementHexSelectionTargetView({
    required super.coordinate,
    required super.label,
    required this.improvement,
  });

  final FieldImprovementKind improvement;

  @override
  String get key => 'improvement:${coordinate.col}:${coordinate.row}';
}

final class ArtifactHexSelectionTargetView extends MapHexSelectionTargetView {
  const ArtifactHexSelectionTargetView({
    required super.coordinate,
    required super.label,
    required this.artifactId,
    required this.kind,
  });

  final String artifactId;
  final WorldArtifactKindView kind;

  @override
  String get key => 'artifact:$artifactId';
}

final class ObjectiveHexSelectionTargetView extends MapHexSelectionTargetView {
  const ObjectiveHexSelectionTargetView({
    required super.coordinate,
    required super.label,
    required this.objectiveId,
    required this.type,
  });

  final String objectiveId;
  final MapObjectiveType type;

  @override
  String get key => 'objective:$objectiveId';
}

MapHexSelectionPaletteView? buildMapHexSelectionPaletteView({
  required MapHexCoordinate coordinate,
  required MapView map,
  required PlayerMapView player,
  required AonwLocalizations l10n,
}) {
  final tile = map.tileAt(coordinate);
  if (tile == null ||
      player.fog.visibilityAt(coordinate) == MapFogVisibilityView.hidden) {
    return null;
  }
  final unit = _firstUnitAt(player, coordinate);
  final city = player.cityAt(coordinate);
  final improvement = player.fieldImprovementAt(coordinate);
  final artifact = _firstVisibleArtifactAt(player, coordinate);
  final objective = _objectiveAt(map, coordinate);
  return MapHexSelectionPaletteView(
    coordinate: coordinate,
    targets: [
      TerrainHexSelectionTargetView(
        coordinate: coordinate,
        label: l10n.selectionTerrain,
        terrain: tile.displayTerrain,
      ),
      if (unit != null)
        UnitHexSelectionTargetView(
          coordinate: coordinate,
          label: l10n.presentationName(unit.kind.name),
          unitId: unit.id,
          kind: unit.kind,
        ),
      if (city != null)
        CityHexSelectionTargetView(
          coordinate: coordinate,
          label: city.name,
          cityId: city.id,
        ),
      if (improvement != null)
        FieldImprovementHexSelectionTargetView(
          coordinate: coordinate,
          label: l10n.presentationName(improvement.improvement.name),
          improvement: improvement.improvement,
        ),
      if (artifact != null)
        ArtifactHexSelectionTargetView(
          coordinate: coordinate,
          label: l10n.artifactName(artifact.kind.name),
          artifactId: artifact.id,
          kind: artifact.kind,
        ),
      if (objective != null)
        ObjectiveHexSelectionTargetView(
          coordinate: coordinate,
          label: l10n.objectiveType(objective.type.name),
          objectiveId: objective.id,
          type: objective.type,
        ),
    ],
  );
}

VisibleUnitView? _firstUnitAt(
  PlayerMapView player,
  MapHexCoordinate coordinate,
) {
  for (final unit in player.unitsAt(coordinate)) {
    return unit;
  }
  return null;
}

WorldArtifactView? _firstVisibleArtifactAt(
  PlayerMapView player,
  MapHexCoordinate coordinate,
) {
  for (final artifact in player.artifactsAt(coordinate)) {
    if (artifact.location is MapArtifactLocationView ||
        artifact.location is ExcavationArtifactLocationView) {
      return artifact;
    }
  }
  return null;
}

MapObjectiveView? _objectiveAt(MapView map, MapHexCoordinate coordinate) {
  for (final objective in map.objectives) {
    if (objective.coordinate == coordinate) return objective;
  }
  return null;
}
