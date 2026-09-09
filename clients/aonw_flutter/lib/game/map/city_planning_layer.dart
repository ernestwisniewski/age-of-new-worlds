import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/aonw_tokens.dart';
import '../../features/map/read_model/city_planning_view.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_canvas_clip.dart';
import 'map_interaction_geometry.dart';
import 'static_map_layers.dart';

part 'city_planning_rendering.dart';

final class MapCityPlanningLayerComponent extends Component with HasVisibility {
  MapCityPlanningLayerComponent() : super(priority: 54) {
    isVisible = false;
  }

  MapStaticRenderCache? _cache;
  Object? _input;
  Set<MapHexCoordinate> _sites = const {};
  Set<MapHexCoordinate> _growth = const {};
  List<ui.Offset> _siteCenters = const [];
  List<ui.Offset> _growthCenters = const [];
  var _geometryBuildCount = 0;
  var _renderedMarkerCount = 0;

  @visibleForTesting
  int get debugGeometryBuildCount => _geometryBuildCount;
  @visibleForTesting
  int get debugRenderedMarkerCount => _renderedMarkerCount;
  @visibleForTesting
  List<ui.Offset> get debugSiteCenters => List.unmodifiable(_siteCenters);
  @visibleForTesting
  List<ui.Offset> get debugGrowthCenters => List.unmodifiable(_growthCenters);

  bool applyPlanning(
    MapStaticRenderCache cache,
    CityPlanningView? planning,
    PlayerMapView player, {
    required bool showCitySites,
    required bool showCityGrowth,
  }) {
    final input = (cache, planning, player, showCitySites, showCityGrowth);
    if (_input == input) return false;
    _input = input;
    final matching = _matchesPlanning(planning, player);
    final sites = matching && showCitySites
        ? _disclosedPlanning(planning!.citySites, cache, player)
        : <MapHexCoordinate>{};
    final growth = matching && showCityGrowth
        ? _disclosedPlanning(planning!.growthTiles, cache, player)
        : <MapHexCoordinate>{};
    if (identical(cache, _cache) &&
        setEquals(sites, _sites) &&
        setEquals(growth, _growth)) {
      return false;
    }
    _cache = cache;
    _sites = sites;
    _growth = growth;
    _siteCenters = [
      for (final hex in sites) _planningAnchor(cache, hex, site: true),
    ];
    _growthCenters = [
      for (final hex in growth) _planningAnchor(cache, hex, site: false),
    ];
    _geometryBuildCount += 1;
    isVisible = sites.isNotEmpty || growth.isNotEmpty;
    return true;
  }

  void clearLayer() {
    _cache = null;
    _input = null;
    _sites = const {};
    _growth = const {};
    _siteCenters = const [];
    _growthCenters = const [];
    _renderedMarkerCount = 0;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    _renderedMarkerCount = 0;
    if (!isVisible) return;
    final clip = mapCanvasClipBounds(canvas).inflate(8);
    for (final center in _siteCenters) {
      if (clip.contains(center)) {
        _drawPlanningMarker(canvas, center, site: true);
        _renderedMarkerCount += 1;
      }
    }
    for (final center in _growthCenters) {
      if (clip.contains(center)) {
        _drawPlanningMarker(canvas, center, site: false);
        _renderedMarkerCount += 1;
      }
    }
  }
}

ui.Offset _planningAnchor(
  MapStaticRenderCache cache,
  MapHexCoordinate hex, {
  required bool site,
}) {
  final corners = mapProjectedTopFaceCorners(cache, hex);
  final center = mapProjectedTopFaceCenter(cache, hex);
  return site
      ? ui.Offset(
          center.dx,
          corners.map((point) => point.dy).reduce(math.min) + 18.5,
        )
      : ui.Offset(
          corners.map((point) => point.dx).reduce(math.max) - 18.5,
          center.dy,
        );
}

bool _samePlanningStamp(SessionStampView first, SessionStampView second) =>
    (first.revision, first.stateDigest, first.mapHash, first.rulesetHash) ==
    (second.revision, second.stateDigest, second.mapHash, second.rulesetHash);

bool _matchesPlanning(CityPlanningView? planning, PlayerMapView player) =>
    planning != null &&
    planning.actorPlayerId == player.actorPlayerId &&
    _samePlanningStamp(planning.stamp, player.stamp);

Set<MapHexCoordinate> _disclosedPlanning(
  Iterable<MapHexCoordinate> coordinates,
  MapStaticRenderCache cache,
  PlayerMapView player,
) => {
  for (final hex in coordinates)
    if (cache.tilePaths.containsKey(hex) &&
        player.fog.visibilityAt(hex) != MapFogVisibilityView.hidden)
      hex,
};
