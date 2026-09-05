import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/aonw_tokens.dart';
import '../../features/cities/read_model/city_view.dart';
import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/map_view_mode.dart';
import 'city_territory_geometry.dart';
import 'city_territory_style.dart';
import 'static_map_layers.dart';
import 'territory_glow_cache.dart';

part 'city_territory_rendering.dart';

final class MapCityTerritoryLayerComponent extends Component
    with HasVisibility {
  MapCityTerritoryLayerComponent() : super(priority: 22) {
    isVisible = false;
  }

  final _boundaryCache = <String, ui.Path>{};
  final _glows = MapTerritoryGlowCache();
  final _styleCache =
      <({int colorValue, bool strategic}), MapCityTerritoryStyle>{};
  List<_MapCityTerritory> _territories = const [];
  String? _renderSignature;
  String? _selectedCityId;
  String? _highlightedPlayerId;
  var _strategicView = false;
  var _zoomEmphasis = 0.0;
  var _geometryBuildCount = 0;
  var _syncCount = 0;
  var _renderedTerritoryCount = 0;

  @visibleForTesting
  int get debugRenderedTerritoryCount => _renderedTerritoryCount;

  @visibleForTesting
  MapTerritoryGlowCache get debugGlowCache => _glows;

  @visibleForTesting
  int get debugTerritoryCount => _territories.length;

  @visibleForTesting
  int get debugGeometryBuildCount => _geometryBuildCount;

  @visibleForTesting
  int get debugBoundaryCacheCount => _boundaryCache.length;

  @visibleForTesting
  int get debugSyncCount => _syncCount;

  @visibleForTesting
  bool get debugStrategicView => _strategicView;

  @visibleForTesting
  double get debugZoomEmphasis => _zoomEmphasis;

  @visibleForTesting
  String? get debugSelectedCityId => _selectedCityId;

  @visibleForTesting
  String? get debugHighlightedPlayerId => _highlightedPlayerId;

  @visibleForTesting
  int get debugHighlightedTerritoryCount =>
      _territories.where((territory) => territory.empireHighlighted).length;

  @visibleForTesting
  int get debugBoundaryMetricCount => _territories.fold(
    0,
    (count, territory) => count + territory.boundary.computeMetrics().length,
  );

  @visibleForTesting
  List<MapHexCoordinate> debugHexesForCity(String cityId) => List.unmodifiable(
    _territories
        .where((territory) => territory.city.id == cityId)
        .expand((territory) => territory.hexes),
  );

  void applySnapshot(MapRenderSnapshot snapshot, MapStaticRenderCache cache) {
    final selectedCityId = snapshot.interaction.city?.cityId;
    final highlightedPlayerId = _ownerForCity(
      snapshot.player.cities,
      selectedCityId,
    );
    final strategicView = snapshot.effectiveViewMode == MapViewMode.tile;
    final colors = {
      for (final participant in snapshot.player.participants)
        participant.id: participant.colorValue,
    };
    final signature = _signature(
      snapshot.player.cities,
      colors,
      selectedCityId: selectedCityId,
      strategicView: strategicView,
      cache: cache,
    );
    if (_renderSignature == signature) return;
    _glows.clear();

    final territories = <_MapCityTerritory>[];
    final liveBoundaries = <String>{};
    for (final city in snapshot.player.cities) {
      final hexes = _visibleTerritoryHexes(city, cache);
      if (hexes.isEmpty) continue;
      final hexesSignature = mapCityTerritoryHexesSignature(hexes);
      liveBoundaries.add(hexesSignature);
      final boundary = _boundaryCache.putIfAbsent(hexesSignature, () {
        _geometryBuildCount += 1;
        return buildMapCityTerritoryBoundaryPath(cache, hexes);
      });
      final colorValue =
          colors[city.ownerPlayerId] ?? AonwColorTokens.brand.toARGB32();
      territories.add(
        _MapCityTerritory(
          city: city,
          hexes: hexes,
          boundary: boundary,
          centerPath: buildMapCityTerritoryCenterPath(cache, city.center),
          playerColor: ui.Color(colorValue),
          selected: city.id == selectedCityId,
          empireHighlighted: city.ownerPlayerId == highlightedPlayerId,
        ),
      );
    }
    _boundaryCache.removeWhere((key, _) => !liveBoundaries.contains(key));
    _territories = List.unmodifiable(territories);
    _renderSignature = signature;
    _selectedCityId = selectedCityId;
    _highlightedPlayerId = highlightedPlayerId;
    _strategicView = strategicView;
    _syncCount += 1;
    isVisible = territories.isNotEmpty;
  }

  bool setZoom(double zoom) {
    final emphasis = _zoomEmphasisFor(zoom);
    if (_zoomEmphasis == emphasis) return false;
    _zoomEmphasis = emphasis;
    return true;
  }

  void clearLayer() {
    _glows.clear();
    _territories = const [];
    _boundaryCache.clear();
    _styleCache.clear();
    _renderSignature = null;
    _selectedCityId = null;
    _highlightedPlayerId = null;
    _strategicView = false;
    _zoomEmphasis = 0;
    isVisible = false;
  }

  @override
  void onRemove() {
    clearLayer();
    super.onRemove();
  }

  @override
  void render(ui.Canvas canvas) {
    _renderedTerritoryCount = 0;
    if (_territories.isEmpty) return;
    final clip = canvas.getLocalClipBounds();
    final visible = [
      for (final territory in _territories)
        if (territory.bounds.overlaps(clip)) territory,
    ];
    _renderedTerritoryCount = visible.length;
    for (final territory in visible) {
      final style = _styleFor(territory.playerColor);
      canvas.drawPath(
        territory.boundary,
        style.fillPaint(
          empireHighlighted: territory.empireHighlighted,
          zoomEmphasis: _zoomEmphasis,
        ),
      );
      if (!_strategicView) {
        _drawInsetWash(canvas, territory, style);
      }
    }
    for (final territory in visible) {
      if (territory.selected) continue;
      _drawBorder(canvas, territory);
    }
    if (_strategicView) {
      for (final territory in visible) {
        _drawStrategicCenter(canvas, territory);
      }
    }
    final selected = _selectedTerritory;
    if (selected == null) return;
    _drawMapDimming(canvas);
    if (selected.bounds.overlaps(clip)) _drawSelectedBorder(canvas, selected);
  }

  _MapCityTerritory? get _selectedTerritory {
    for (final territory in _territories) {
      if (territory.selected) return territory;
    }
    return null;
  }

  static List<MapHexCoordinate> _visibleTerritoryHexes(
    CityView city,
    MapStaticRenderCache cache,
  ) => List.unmodifiable({
    if (cache.tilePaths.containsKey(city.center)) city.center,
    for (final coordinate in city.visibleControlledHexes)
      if (cache.tilePaths.containsKey(coordinate)) coordinate,
  });

  static String? _ownerForCity(List<CityView> cities, String? cityId) {
    if (cityId == null) return null;
    for (final city in cities) {
      if (city.id == cityId) return city.ownerPlayerId;
    }
    return null;
  }

  static String _signature(
    List<CityView> cities,
    Map<String, int> colors, {
    required String? selectedCityId,
    required bool strategicView,
    required MapStaticRenderCache cache,
  }) => [
    cache.identity.mapId,
    cache.identity.contentHash,
    strategicView,
    selectedCityId,
    for (final city in cities) ...[
      city.id,
      city.ownerPlayerId,
      colors[city.ownerPlayerId],
      city.center,
      mapCityTerritoryHexesSignature(city.visibleControlledHexes),
    ],
  ].join('|');

  static double _zoomEmphasisFor(double zoom) {
    if (zoom >= 0.95) return 0;
    if (zoom <= 0.35) return 1;
    return ((0.95 - zoom) / 0.6).clamp(0, 1).toDouble();
  }

  static void _drawCityGlyph(ui.Canvas canvas, ui.Offset center) {
    final stroke = territoryStroke(
      AonwColorTokens.brandLight,
      alpha: 245,
      width: 1.8,
    );
    final roof = ui.Path()
      ..moveTo(center.dx - 5, center.dy - 0.8)
      ..lineTo(center.dx, center.dy - 5.4)
      ..lineTo(center.dx + 5, center.dy - 0.8);
    final base = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(center.dx - 3.9, center.dy - 0.7, 7.8, 5.5),
      const ui.Radius.circular(1.2),
    );
    canvas
      ..drawPath(roof, stroke)
      ..drawRRect(base, stroke)
      ..drawLine(
        ui.Offset(center.dx - 5, center.dy + 5.2),
        ui.Offset(center.dx + 5, center.dy + 5.2),
        stroke,
      );
  }
}

final class _MapCityTerritory {
  _MapCityTerritory({
    required this.city,
    required this.hexes,
    required this.boundary,
    required this.centerPath,
    required this.playerColor,
    required this.selected,
    required this.empireHighlighted,
  }) : bounds = boundary
           .getBounds()
           .expandToInclude(centerPath.getBounds())
           .inflate(32);

  final CityView city;
  final List<MapHexCoordinate> hexes;
  final ui.Path boundary;
  final ui.Path centerPath;
  final ui.Color playerColor;
  final bool selected;
  final bool empireHighlighted;
  final ui.Rect bounds;
}
