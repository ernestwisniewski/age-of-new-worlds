import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/city_planning_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/map/city_planning_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWidgets('city planning badges retain their reference silhouette', (
    tester,
  ) async {
    final scene = testMapScene();
    final layer = MapCityPlanningLayerComponent();
    layer.applyPlanning(
      MapStaticRenderCache.build(scene.map),
      _planning(scene.player),
      scene.player,
      showCitySites: true,
      showCityGrowth: true,
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xff24262b), ui.BlendMode.src);
    canvas.scale(3);
    layer.render(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(660, 330);
    picture.dispose();
    try {
      await expectLater(image, matchesGoldenFile('goldens/city_planning.png'));
    } finally {
      image.dispose();
    }
  });

  test('city markings are independent and reuse unchanged geometry', () {
    final scene = testMapScene();
    final cache = MapStaticRenderCache.build(scene.map);
    final layer = MapCityPlanningLayerComponent();
    final planning = _planning(scene.player);
    expect(
      layer.applyPlanning(
        cache,
        planning,
        scene.player,
        showCitySites: true,
        showCityGrowth: false,
      ),
      isTrue,
    );
    expect(layer.debugSiteCenters, hasLength(1));
    expect(layer.debugGrowthCenters, isEmpty);
    final builds = layer.debugGeometryBuildCount;
    expect(
      layer.applyPlanning(
        cache,
        _planning(scene.player),
        scene.player,
        showCitySites: true,
        showCityGrowth: false,
      ),
      isFalse,
    );
    expect(layer.debugGeometryBuildCount, builds);
    layer.applyPlanning(
      cache,
      planning,
      scene.player,
      showCitySites: false,
      showCityGrowth: true,
    );
    expect(layer.debugSiteCenters, isEmpty);
    expect(layer.debugGrowthCenters, hasLength(2));
    layer.applyPlanning(
      cache,
      planning,
      scene.player,
      showCitySites: false,
      showCityGrowth: false,
    );
    expect(layer.isVisible, isFalse);
    expect(layer.debugGrowthCenters, isEmpty);
  });

  test('stale stamps and recipients remove previously displayed markings', () {
    final scene = testMapScene();
    final cache = MapStaticRenderCache.build(scene.map);
    final layer = MapCityPlanningLayerComponent();
    final source = scene.player.stamp;
    for (final stamp in [
      SessionStampView(
        revision: 1,
        stateDigest: source.stateDigest,
        mapHash: source.mapHash,
        rulesetHash: source.rulesetHash,
      ),
      SessionStampView(
        revision: 0,
        stateDigest: 'd' * 64,
        mapHash: source.mapHash,
        rulesetHash: source.rulesetHash,
      ),
      SessionStampView(
        revision: 0,
        stateDigest: source.stateDigest,
        mapHash: 'd' * 64,
        rulesetHash: source.rulesetHash,
      ),
      SessionStampView(
        revision: 0,
        stateDigest: source.stateDigest,
        mapHash: source.mapHash,
        rulesetHash: 'd' * 64,
      ),
    ]) {
      layer.applyPlanning(
        cache,
        _planning(scene.player),
        scene.player,
        showCitySites: true,
        showCityGrowth: true,
      );
      expect(layer.isVisible, isTrue);
      layer.applyPlanning(
        cache,
        _planning(scene.player, stamp: stamp),
        scene.player,
        showCitySites: true,
        showCityGrowth: true,
      );
      expect(layer.isVisible, isFalse);
    }
    layer.applyPlanning(
      cache,
      _planning(scene.player, actor: 'other'),
      scene.player,
      showCitySites: true,
      showCityGrowth: true,
    );
    expect(layer.isVisible, isFalse);
  });

  test('disclosure and map bounds filter malformed marker coordinates', () {
    final scene = testMapScene();
    final source = scene.player;
    final player = PlayerMapView(
      actorPlayerId: source.actorPlayerId,
      stamp: source.stamp,
      turnMode: source.turnMode,
      participants: source.participants,
      fog: MapFogView(
        enabled: true,
        discoveredHexes: const [(col: 0, row: 0)],
        visibleHexes: const [],
      ),
      economy: source.economy,
      research: source.research,
      victory: source.victory,
      turnView: source.turnView,
      diplomacy: source.diplomacy,
      units: source.units,
      cities: source.cities,
      artifacts: source.artifacts,
      fieldImprovements: source.fieldImprovements,
      roads: source.roads,
    );
    final layer = MapCityPlanningLayerComponent();
    layer.applyPlanning(
      MapStaticRenderCache.build(scene.map),
      _planning(player),
      player,
      showCitySites: true,
      showCityGrowth: true,
    );
    expect(layer.debugSiteCenters, hasLength(1));
    expect(layer.debugGrowthCenters, hasLength(1));
  });

  test('clipping preserves edge markers and idle updates do not rebuild', () {
    final scene = testMapScene();
    final layer = MapCityPlanningLayerComponent();
    layer.applyPlanning(
      MapStaticRenderCache.build(scene.map),
      _planning(scene.player),
      scene.player,
      showCitySites: true,
      showCityGrowth: false,
    );
    final center = layer.debugSiteCenters.single;
    _paint(layer, ui.Rect.fromLTWH(center.dx + 6, center.dy, 1, 1));
    expect(layer.debugRenderedMarkerCount, 1);
    _paint(layer, const ui.Rect.fromLTWH(-1000, -1000, 1, 1));
    expect(layer.debugRenderedMarkerCount, 0);
    final builds = layer.debugGeometryBuildCount;
    for (var frame = 0; frame < 120; frame++) {
      layer.update(1 / 60);
    }
    expect(layer.debugGeometryBuildCount, builds);
    layer.clearLayer();
    expect(layer.debugSiteCenters, isEmpty);
    expect(layer.isVisible, isFalse);
  });
}

CityPlanningView _planning(
  PlayerMapView player, {
  SessionStampView? stamp,
  String? actor,
}) => CityPlanningView(
  stamp: stamp ?? player.stamp,
  actorPlayerId: actor ?? player.actorPlayerId,
  citySites: const [(col: 0, row: 0), (col: 99, row: 99)],
  growthTiles: const [(col: 0, row: 0), (col: 1, row: 0)],
);

void _paint(MapCityPlanningLayerComponent layer, ui.Rect clip) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..clipRect(clip);
  layer.render(canvas);
  recorder.endRecording().dispose();
}
