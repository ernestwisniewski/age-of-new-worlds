import 'dart:ui' as ui;

import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/camera/map_camera_transform.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_city_production_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_production_test_fixture.dart';

void main() {
  testWidgets('defers city particles until the real camera settles', (
    tester,
  ) async {
    final layer = MapCityProductionLayerComponent(
      now: tester.binding.clock.now,
    );
    final game = AonwFlameGame(world: AonwWorld(cityProductionLayer: layer));
    await tester.pumpWidget(
      Directionality(
        textDirection: ui.TextDirection.ltr,
        child: GameWidget(game: game),
      ),
    );
    game.replaceScene(productionSnapshot());
    await tester.runAsync(game.ready);
    game.setViewportActive(true);
    await tester.pump(const Duration(milliseconds: 120));
    final created = layer.debugCreatedCount;
    for (var move = 0; move < 10; move++) {
      game.mapCamera.centerOnHex((col: move.isEven ? 2 : 1, row: 1));
      await tester.pump(const Duration(milliseconds: 20));
      expect(layer.debugHintCount, 0);
      expect(layer.debugCreatedCount, created);
      expect(game.paused, isTrue);
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(layer.debugCreatedCount, created + 1);
    expect(layer.debugActiveHintCount, 0);
    await tester.pump(const Duration(seconds: 2));
    expect(layer.debugActiveHintCount, 1);
    expect(layer.debugRenderedHintCount, 1);
    game.replaceScene(
      productionSnapshot(cities: [producingCity('city', producing: false)]),
    );
    expect(layer.debugHintCount, 0);
    expect(layer.debugSpawnScheduled, isFalse);
    expect(game.paused, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'retains per-city cadence through snapshots and sleeps between hints',
    (tester) async {
      final layer = MapCityProductionLayerComponent(
        now: tester.binding.clock.now,
      );
      addTearDown(layer.clearLayer);
      final snapshot = productionSnapshot();
      final cache = MapStaticRenderCache.build(snapshot.map);
      layer.applySnapshot(snapshot, cache);
      layer.applyCamera(_camera());
      layer.setViewportActive(true);
      await tester.pump(const Duration(milliseconds: 120));
      expect(layer.debugSpawnScheduled, isTrue);
      await tester.pump(const Duration(milliseconds: 700));
      layer.applySnapshot(
        productionSnapshot(
          cities: [producingCity('city'), producingCity('second')],
        ),
        cache,
      );
      final created = layer.debugCreatedCount;
      await tester.pump(const Duration(milliseconds: 1299));
      expect(layer.debugActiveHintCount, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(layer.debugActiveHintCount, 1);
      layer.update(0.7);
      expect(layer.debugActiveHintCount, 2);
      layer.update(1.101);
      expect(layer.debugActiveHintCount, 0);
      expect(layer.debugCreatedCount, created);
      expect(layer.debugSpawnScheduled, isTrue);
      final updates = layer.debugActiveUpdateCount;
      layer.update(100);
      expect(layer.debugActiveUpdateCount, updates);
      await tester.pump(const Duration(milliseconds: 199));
      expect(layer.debugActiveHintCount, 1);
    },
  );

  testWidgets('filters production by owner fog camera and interaction', (
    tester,
  ) async {
    final layer = MapCityProductionLayerComponent(
      now: tester.binding.clock.now,
    );
    addTearDown(layer.clearLayer);
    final snapshot = productionSnapshot(
      cities: [
        producingCity('owned'),
        producingCity('foreign', owner: 'other'),
        producingCity('idle', producing: false),
        producingCity('offscreen', center: (col: 9, row: 7)),
      ],
    );
    final cache = MapStaticRenderCache.build(snapshot.map);
    layer.applySnapshot(snapshot, cache);
    layer.applyCamera(_camera());
    layer.setViewportActive(true);
    await tester.pump(const Duration(milliseconds: 120));
    expect(layer.debugHintCount, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(layer.debugActiveHintCount, 1);
    layer.applyCamera(_camera(zoom: 0.54));
    expect(layer.debugHintCount, 0);
    expect(layer.debugSpawnScheduled, isFalse);
    layer.applyCamera(_camera(zoom: 0.55));
    await tester.pump(const Duration(milliseconds: 120));
    expect(layer.debugHintCount, 1);
    layer.applyCamera(_camera(zoom: 0.64, portrait: true));
    expect(layer.debugHintCount, 0);
    layer.applyCamera(_camera(zoom: 0.65, portrait: true));
    await tester.pump(const Duration(milliseconds: 120));
    expect(layer.debugHintCount, 1);
    for (final pending in [
      const PendingCityWorkedHexSelectionView(cityId: 'city'),
      const PendingCityExpansionSelectionView(cityId: 'city'),
      const PendingWorkerActionSelectionView(
        unitId: 'worker',
        improvement: null,
      ),
      const PendingMerchantTradeRouteSelectionView(unitId: 'merchant'),
      const PendingMerchantMoveToCitySelectionView(unitId: 'merchant'),
      const PendingAttackTargetingView(unitId: 'attacker', defender: null),
    ]) {
      layer.applySnapshot(productionSnapshot(pendingAction: pending), cache);
      expect(layer.debugSpawnScheduled, isFalse);
    }
    layer.applySnapshot(
      productionSnapshot(
        interaction: const MapInteractionState(
          city: CityState.loadingFounding('settler'),
        ),
      ),
      cache,
    );
    expect(layer.debugHintCount, 0);
    layer.applySnapshot(
      productionSnapshot(
        fog: MapFogView(
          enabled: true,
          discoveredHexes: const [(col: 1, row: 1)],
          visibleHexes: const [],
        ),
      ),
      cache,
    );
    expect(layer.debugHintCount, 0);
  });

  testWidgets(
    'wakes the shared game and clears timers on accessibility and disposal',
    (tester) async {
      final layer = MapCityProductionLayerComponent(
        now: tester.binding.clock.now,
      );
      final game = AonwFlameGame(world: AonwWorld(cityProductionLayer: layer));
      await tester.pumpWidget(
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: GameWidget(game: game),
        ),
      );
      game.replaceScene(productionSnapshot());
      await tester.runAsync(game.ready);
      game.setViewportActive(true);
      await tester.pump(const Duration(milliseconds: 120));
      expect(game.paused, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(game.paused, isFalse);
      game.setEffectPlaybackSpeed(2);
      layer.update(0.551);
      expect(game.paused, isTrue);
      await tester.pump(const Duration(milliseconds: 450));
      expect(game.paused, isFalse);
      game.skipEffects();
      expect(layer.debugActiveHintCount, 0);
      expect(game.paused, isTrue);
      game.setReducedMotion(true);
      expect(layer.debugSpawnScheduled, isFalse);
      game.setReducedMotion(false);
      expect(layer.debugSpawnScheduled, isTrue);
      game.setViewportActive(false);
      expect(layer.debugSpawnScheduled, isFalse);
      game.setViewportActive(true);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(layer.debugSpawnScheduled, isFalse);
      expect(layer.debugHintCount, 0);
    },
  );

  testWidgets(
    'restarts private hints for recipients maps and backward revisions',
    (tester) async {
      final layer = MapCityProductionLayerComponent(
        now: tester.binding.clock.now,
      );
      addTearDown(layer.clearLayer);
      final snapshot = productionSnapshot(revision: 2);
      final cache = MapStaticRenderCache.build(snapshot.map);
      layer.applySnapshot(snapshot, cache);
      layer.applyCamera(_camera());
      layer.setViewportActive(true);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(seconds: 2));
      expect(layer.debugActiveHintCount, 1);
      layer.applySnapshot(productionSnapshot(revision: 1), cache);
      expect(layer.debugActiveHintCount, 0);
      await tester.pump(const Duration(seconds: 2));
      layer.applySnapshot(productionSnapshot(actor: 'other'), cache);
      expect(layer.debugHintCount, 0);
      layer.applySnapshot(productionSnapshot(), cache);
      await tester.pump(const Duration(seconds: 2));
      final next = productionSnapshot(contentHash: 'b' * 64);
      layer.applySnapshot(next, MapStaticRenderCache.build(next.map));
      expect(layer.debugActiveHintCount, 0);
      layer.applySnapshot(productionSnapshot(cities: []), cache);
      expect(layer.debugSpawnScheduled, isFalse);
    },
  );
}

MapCameraTransform _camera({double zoom = 1, bool portrait = false}) =>
    MapCameraTransform.initial(
      viewport: (width: portrait ? 400 : 600, height: portrait ? 600 : 400),
      content: (width: 1200, height: 800),
      authoredZoom: zoom,
      worldCenter: (x: 200, y: 150),
    );
