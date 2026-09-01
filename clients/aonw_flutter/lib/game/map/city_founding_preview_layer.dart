import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/aonw_tokens.dart';
import '../../features/cities/application/city_state.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_interaction_geometry.dart';
import 'static_map_layers.dart';

part 'city_founding_preview_rendering.dart';

final class MapCityFoundingPreviewLayerComponent extends Component
    with HasVisibility {
  MapCityFoundingPreviewLayerComponent() : super(priority: 55) {
    isVisible = false;
  }

  static const dashLength = 13.0;
  static const gapLength = 7.0;
  static const dashPattern = dashLength + gapLength;
  static const dashSpeed = 22.0;

  ui.Path? _centerPath;
  ui.Offset? _center;
  List<_FoundingHexGeometry> _selected = const [];
  List<_FoundingHexGeometry> _candidates = const [];
  ui.Color _cityColor = AonwColorTokens.brand;
  String _label = '';
  String? _signature;
  double _dashPhase = 0;
  var _geometryBuildCount = 0;

  @visibleForTesting
  int get debugSelectedCount => _selected.length;

  @visibleForTesting
  int get debugCandidateCount => _candidates.length;

  @visibleForTesting
  int get debugRecommendedCount =>
      _candidates.where((candidate) => candidate.recommended).length;

  @visibleForTesting
  List<MapHexCoordinate> get debugSelectedCoordinates =>
      List.unmodifiable(_selected.map((value) => value.coordinate));

  @visibleForTesting
  List<MapHexCoordinate> get debugCandidateCoordinates =>
      List.unmodifiable(_candidates.map((value) => value.coordinate));

  @visibleForTesting
  String get debugLabel => _label;

  @visibleForTesting
  int get debugGeometryBuildCount => _geometryBuildCount;

  @visibleForTesting
  double get debugDashPhase => _dashPhase;

  void applyFounding(
    MapStaticRenderCache cache,
    CityState? city,
    PlayerMapView player,
  ) {
    final input = _foundingPreviewInput(city, player);
    if (input == null) {
      clearLayer();
      return;
    }
    final signature = _foundingSignature(
      cache,
      input.center,
      input.selection,
      input.candidates,
      input.recommendedCount,
      input.colorValue,
    );
    if (_signature == signature) return;
    _signature = signature;
    _applyGeometry(cache, input);
  }

  void _applyGeometry(MapStaticRenderCache cache, _FoundingPreviewInput input) {
    _cityColor = ui.Color(input.colorValue ?? AonwColorTokens.brand.toARGB32());
    _centerPath = mapProjectedTopFacePath(cache, input.center, scale: 0.84);
    _center = mapProjectedTopFaceCenter(cache, input.center);
    _selected = List.unmodifiable([
      for (final coordinate in input.selection)
        _FoundingHexGeometry(
          coordinate: coordinate,
          path: mapProjectedTopFacePath(cache, coordinate, scale: 0.92),
          center: mapProjectedTopFaceCenter(cache, coordinate),
          recommended: false,
        ),
    ]);
    _candidates = List.unmodifiable([
      for (var index = 0; index < input.candidates.length; index += 1)
        _FoundingHexGeometry(
          coordinate: input.candidates[index],
          path: mapProjectedTopFacePath(
            cache,
            input.candidates[index],
            scale: 0.92,
          ),
          center: mapProjectedTopFaceCenter(cache, input.candidates[index]),
          recommended: index < input.recommendedCount,
        ),
    ]);
    _label = '${input.selection.length}/${input.requiredCount}';
    _geometryBuildCount += 1;
    isVisible = true;
  }

  void clearLayer() {
    _centerPath = null;
    _center = null;
    _selected = const [];
    _candidates = const [];
    _label = '';
    _signature = null;
    _dashPhase = 0;
    isVisible = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isVisible || !dt.isFinite || dt <= 0) return;
    _dashPhase = (_dashPhase + dt * dashSpeed) % dashPattern;
  }

  @override
  void render(ui.Canvas canvas) {
    if (!isVisible) return;
    _renderFoundingPreview(canvas);
  }
}

final class _FoundingPreviewInput {
  const _FoundingPreviewInput({
    required this.center,
    required this.selection,
    required this.candidates,
    required this.requiredCount,
    required this.recommendedCount,
    required this.colorValue,
  });

  final MapHexCoordinate center;
  final List<MapHexCoordinate> selection;
  final List<MapHexCoordinate> candidates;
  final int requiredCount;
  final int recommendedCount;
  final int? colorValue;
}

final class _FoundingHexGeometry {
  const _FoundingHexGeometry({
    required this.coordinate,
    required this.path,
    required this.center,
    required this.recommended,
  });

  final MapHexCoordinate coordinate;
  final ui.Path path;
  final ui.Offset center;
  final bool recommended;
}

_FoundingPreviewInput? _foundingPreviewInput(
  CityState? city,
  PlayerMapView player,
) {
  final options = city?.foundingOptions;
  if (city == null || options == null) return null;
  final founder = player.controlledUnitById(options.founderUnitId);
  if (founder == null || founder.coordinate != options.center) return null;
  final selection = city.foundingSelection;
  final candidates = _visibleFoundingCandidates(
    options.rankedAvailableControlledHexes,
    selection,
    player.fog,
  );
  return _FoundingPreviewInput(
    center: options.center,
    selection: selection,
    candidates: candidates,
    requiredCount: options.requiredControlledHexes,
    recommendedCount: (options.requiredControlledHexes - selection.length)
        .clamp(0, candidates.length),
    colorValue: _participantColor(player, founder.ownerPlayerId),
  );
}

List<MapHexCoordinate> _visibleFoundingCandidates(
  List<MapHexCoordinate> available,
  List<MapHexCoordinate> selection,
  MapFogView fog,
) => List.unmodifiable([
  for (final coordinate in available)
    if (!selection.contains(coordinate) &&
        fog.visibilityAt(coordinate) != MapFogVisibilityView.hidden)
      coordinate,
]);

int? _participantColor(PlayerMapView player, String playerId) {
  for (final participant in player.participants) {
    if (participant.id == playerId) return participant.colorValue;
  }
  return null;
}

String _foundingSignature(
  MapStaticRenderCache cache,
  MapHexCoordinate center,
  List<MapHexCoordinate> selected,
  List<MapHexCoordinate> candidates,
  int recommendedCount,
  int? colorValue,
) {
  final buffer = StringBuffer()
    ..write(identityHashCode(cache))
    ..write('|')
    ..write(center.col)
    ..write(',')
    ..write(center.row)
    ..write('|')
    ..write(colorValue)
    ..write('|')
    ..write(recommendedCount)
    ..write('|selected:');
  for (final coordinate in selected) {
    buffer
      ..write(coordinate.col)
      ..write(',')
      ..write(coordinate.row)
      ..write(';');
  }
  buffer.write('|candidates:');
  for (final coordinate in candidates) {
    buffer
      ..write(coordinate.col)
      ..write(',')
      ..write(coordinate.row)
      ..write(';');
  }
  return buffer.toString();
}
