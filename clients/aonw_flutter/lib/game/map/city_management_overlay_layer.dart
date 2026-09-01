import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/aonw_tokens.dart';
import '../../features/cities/application/city_state.dart';
import '../../features/cities/read_model/city_view.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_interaction_geometry.dart';
import 'static_map_layers.dart';

part 'city_management_overlay_rendering.dart';

enum MapCityManagementHexKind {
  growthCandidate,
  growthRecommended,
  workedManual,
  workedAuto,
  workedIdle,
}

final class MapCityManagementOverlayLayerComponent extends Component
    with HasVisibility {
  MapCityManagementOverlayLayerComponent() : super(priority: 55) {
    isVisible = false;
  }

  List<_CityManagementHexGeometry> _hexes = const [];
  bool _dimmed = false;
  String? _signature;
  var _geometryBuildCount = 0;

  @visibleForTesting
  int get debugHexCount => _hexes.length;

  @visibleForTesting
  int get debugGeometryBuildCount => _geometryBuildCount;

  @visibleForTesting
  bool get debugDimmed => _dimmed;

  @visibleForTesting
  List<MapCityManagementHexKind> get debugKinds =>
      List.unmodifiable(_hexes.map((value) => value.kind));

  @visibleForTesting
  List<MapHexCoordinate> get debugCoordinates =>
      List.unmodifiable(_hexes.map((value) => value.coordinate));

  @visibleForTesting
  List<YieldValueView?> get debugTileYields =>
      List.unmodifiable(_hexes.map((value) => value.tileYield));

  void applyManagement(
    MapStaticRenderCache cache,
    CityState? city,
    PlayerMapView player,
  ) {
    final input = _cityManagementInput(city, player);
    if (input == null || input.hexes.isEmpty) {
      clearLayer();
      return;
    }
    final signature = _cityManagementSignature(cache, input);
    if (_signature == signature) return;
    _signature = signature;
    _dimmed = input.dimmed;
    _hexes = List.unmodifiable([
      for (final hex in input.hexes)
        _CityManagementHexGeometry(
          coordinate: hex.coordinate,
          path: mapProjectedTopFacePath(cache, hex.coordinate),
          center: mapProjectedTopFaceCenter(cache, hex.coordinate),
          kind: hex.kind,
          label: hex.label,
          tileYield: hex.tileYield,
          actionable: hex.actionable,
        ),
    ]);
    _geometryBuildCount += 1;
    isVisible = true;
  }

  void clearLayer() {
    _hexes = const [];
    _dimmed = false;
    _signature = null;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    if (!isVisible) return;
    _renderCityManagement(canvas);
  }
}

final class _CityManagementInput {
  const _CityManagementInput({required this.hexes, required this.dimmed});

  final List<_CityManagementHexInput> hexes;
  final bool dimmed;
}

final class _CityManagementHexInput {
  const _CityManagementHexInput({
    required this.coordinate,
    required this.kind,
    required this.label,
    required this.tileYield,
    required this.actionable,
  });

  final MapHexCoordinate coordinate;
  final MapCityManagementHexKind kind;
  final String label;
  final YieldValueView? tileYield;
  final bool actionable;
}

final class _CityManagementHexGeometry {
  const _CityManagementHexGeometry({
    required this.coordinate,
    required this.path,
    required this.center,
    required this.kind,
    required this.label,
    required this.tileYield,
    required this.actionable,
  });

  final MapHexCoordinate coordinate;
  final ui.Path path;
  final ui.Offset center;
  final MapCityManagementHexKind kind;
  final String label;
  final YieldValueView? tileYield;
  final bool actionable;
}

_CityManagementInput? _cityManagementInput(
  CityState? city,
  PlayerMapView player,
) {
  final mode = city?.managementMode;
  final inspection = city?.inspection;
  if (city == null || mode == null || inspection == null) return null;
  final selectedCity = player.controlledCityById(city.cityId ?? '');
  if (selectedCity == null ||
      selectedCity.center != inspection.workedHexes.center) {
    return null;
  }
  final hexes = switch (mode) {
    CityManagementMode.workedHexes => _workedHexInputs(inspection, player.fog),
    CityManagementMode.expansion => _expansionHexInputs(inspection, player.fog),
  };
  return _CityManagementInput(hexes: hexes, dimmed: city.commandPending);
}

List<_CityManagementHexInput> _workedHexInputs(
  CityInspectionView inspection,
  MapFogView fog,
) {
  final worked = inspection.workedHexes;
  return List.unmodifiable([
    for (final coordinate in worked.controlledHexes)
      if (fog.visibilityAt(coordinate) != MapFogVisibilityView.hidden)
        _CityManagementHexInput(
          coordinate: coordinate,
          kind: worked.selectedHexes.contains(coordinate)
              ? MapCityManagementHexKind.workedManual
              : worked.effectiveHexes.contains(coordinate)
              ? MapCityManagementHexKind.workedAuto
              : MapCityManagementHexKind.workedIdle,
          label: worked.selectedHexes.contains(coordinate)
              ? 'R'
              : worked.effectiveHexes.contains(coordinate)
              ? 'A'
              : '+',
          tileYield: null,
          actionable: worked.availableHexes.contains(coordinate),
        ),
  ]);
}

List<_CityManagementHexInput> _expansionHexInputs(
  CityInspectionView inspection,
  MapFogView fog,
) {
  final expansion = inspection.expansion;
  final recommended =
      expansion.preferredHex ??
      (expansion.candidates.isEmpty
          ? null
          : expansion.candidates.first.coordinate);
  return List.unmodifiable([
    for (final candidate in expansion.candidates)
      if (fog.visibilityAt(candidate.coordinate) != MapFogVisibilityView.hidden)
        _CityManagementHexInput(
          coordinate: candidate.coordinate,
          kind: candidate.coordinate == recommended
              ? MapCityManagementHexKind.growthRecommended
              : MapCityManagementHexKind.growthCandidate,
          label: candidate.coordinate == recommended ? 'N' : '+',
          tileYield: candidate.tileYield,
          actionable: true,
        ),
  ]);
}

String _cityManagementSignature(
  MapStaticRenderCache cache,
  _CityManagementInput input,
) {
  final buffer = StringBuffer()
    ..write(identityHashCode(cache))
    ..write('|')
    ..write(input.dimmed);
  for (final hex in input.hexes) {
    final value = hex.tileYield;
    buffer
      ..write('|')
      ..write(hex.coordinate.col)
      ..write(',')
      ..write(hex.coordinate.row)
      ..write(':')
      ..write(hex.kind.index)
      ..write(':')
      ..write(hex.actionable)
      ..write(':')
      ..write(value?.food)
      ..write(',')
      ..write(value?.production)
      ..write(',')
      ..write(value?.gold)
      ..write(',')
      ..write(value?.defense);
  }
  return buffer.toString();
}
