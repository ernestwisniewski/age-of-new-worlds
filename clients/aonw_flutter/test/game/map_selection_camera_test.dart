import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:aonw_flutter/game/presentation/map_camera_selection.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'selection focuses the rendered unit, preserves picking and returns to idle',
    AonwFlameGame.new,
    (game) async {
      game.onGameResize(Vector2(900, 700));
      game.setViewportActive(true);
      game.replaceScene(_snapshot());
      final initial = game.mapCamera.debugTransform!.worldCenter;
      final cache = game.world.debugStaticRenderCache;
      final expected = game.world.unitLayer
          .componentForUnit('second')!
          .visualCenter;
      game.replaceScene(_snapshot(unit: 'second'));
      expect(game.paused, isFalse);
      final completion = game.waitForCommandEffects();
      game.update(0.21);
      final middle = game.mapCamera.debugTransform!.worldCenter;
      expect(middle.x, inExclusiveRange(initial.x, expected.dx));
      expect(game.mapCamera.hasMotion, isTrue);
      final screen = game.debugScreenForHex((col: 2, row: 2))!;
      expect(game.debugHexAtScreen(screen), (col: 2, row: 2));
      game.onGameResize(Vector2(1100, 800));
      expect(game.mapCamera.debugTransform!.worldCenter, middle);
      game.replaceScene(_snapshot(unit: 'second'));
      game.update(0.21);
      await completion;
      final target = game.mapCamera.debugTransform!.worldCenter;
      expect(target.x, closeTo(expected.dx, 0.0001));
      expect(target.y, closeTo(expected.dy, 0.0001));
      expect(game.world.debugStaticRenderCache, same(cache));
      expect(game.paused, isTrue);
      final updates = game.mapCamera.debugTransformUpdateCount;
      game.update(1);
      expect(game.mapCamera.debugTransformUpdateCount, updates);
    },
  );

  testWithGame<AonwFlameGame>(
    'manual camera input cancels focus while hover and empty frames preserve it',
    AonwFlameGame.new,
    (game) async {
      game.onGameResize(Vector2(900, 700));
      game.setViewportActive(true);
      game.replaceScene(_snapshot());
      game.replaceScene(_snapshot(unit: 'second'));
      game.update(0.1);
      game.mapCamera.applyIntent(
        const MapViewportFrameIntent(
          screenPanDelta: (x: 0, y: 0),
          zoomFocalPoint: null,
          zoomFactor: 1,
          hoverScreenPosition: (x: 30, y: 30),
        ),
      );
      expect(game.mapCamera.hasMotion, isTrue);
      game.mapCamera.applyIntent(const MapPanIntent((x: 40, y: 20)));
      final afterPan = game.mapCamera.debugTransform!.worldCenter;
      game.replaceScene(_snapshot(unit: 'second'));
      game.update(1);
      expect(game.mapCamera.debugTransform!.worldCenter, afterPan);
      expect(game.paused, isTrue);
      game.replaceScene(_snapshot(city: 'city'));
      expect(game.mapCamera.hasMotion, isTrue);
      game.mapCamera.applyIntent(
        const MapZoomIntent(focalPoint: (x: 450, y: 350), factor: 1.5),
      );
      expect(game.mapCamera.hasMotion, isFalse);
      expect(game.mapCamera.zoom, 1.5);
      game.replaceScene(_snapshot(unit: 'first'));
      game.setKeyboardPanDirection(x: 1, y: 0);
      game.update(0.1);
      expect(game.mapCamera.hasMotion, isFalse);
      game.setKeyboardPanDirection(x: 0, y: 0);
    },
  );

  testWithGame<AonwFlameGame>(
    'reduced motion and the camera preference apply independently',
    AonwFlameGame.new,
    (game) async {
      game.onGameResize(Vector2(900, 700));
      game.setViewportActive(true);
      game.replaceScene(_snapshot());
      game.setSmoothCameraMovement(false);
      game.replaceScene(_snapshot(unit: 'second'));
      expect(game.mapCamera.hasMotion, isFalse);
      game.setReducedMotion(true);
      game.setSmoothCameraMovement(true);
      game.replaceScene(_snapshot(city: 'city'));
      final center = game.world.debugStaticRenderCache!.projection
          .hexTopFaceCenter((col: 2, row: 2));
      expect(game.mapCamera.debugTransform!.worldCenter, center);
      expect(game.paused, isTrue);
      game.setReducedMotion(false);
      game.replaceScene(_snapshot(unit: 'first'));
      game.update(0.1);
      final partial = game.mapCamera.debugTransform!.worldCenter;
      final completion = game.waitForCommandEffects();
      game.setReducedMotion(true);
      await completion;
      game.update(1);
      expect(game.mapCamera.debugTransform!.worldCenter, partial);
      expect(game.mapCamera.hasMotion, isFalse);
    },
  );

  testWithGame<AonwFlameGame>(
    'a new target supersedes focus and replay resets or hidden routes cancel it',
    AonwFlameGame.new,
    (game) async {
      game.onGameResize(Vector2(900, 700));
      game.setViewportActive(true);
      game.replaceScene(_snapshot());
      game.replaceScene(_snapshot(unit: 'second'));
      game.update(0.1);
      game.replaceScene(_snapshot(city: 'city'));
      game.update(0.42);
      final cache = game.world.debugStaticRenderCache!;
      expect(
        game.mapCamera.debugTransform!.worldCenter,
        cache.projection.hexTopFaceCenter((col: 2, row: 2)),
      );
      game.replaceScene(_snapshot(unit: 'first'));
      game.update(0.1);
      final partial = game.mapCamera.debugTransform!.worldCenter;
      final completion = game.waitForCommandEffects();
      game.replaceScene(_snapshot(unit: 'first', epoch: 1));
      await completion;
      expect(game.mapCamera.debugTransform!.worldCenter, partial);
      expect(game.world.debugStaticRenderCache, same(cache));
      game.replaceScene(_snapshot(unit: 'second', epoch: 1));
      game.setViewportActive(false);
      game.setViewportActive(true);
      game.update(1);
      expect(game.mapCamera.hasMotion, isFalse);
      game.replaceScene(_snapshot(city: 'city', epoch: 1));
      game.clearScene();
      expect(game.mapCamera.hasMotion, isFalse);
      expect(game.mapCamera.debugTransform, isNull);
    },
  );

  test(
    'focus obeys visible units and discovered cities in the recipient view',
    () {
      final fog = MapFogView(
        enabled: true,
        discoveredHexes: [(col: 2, row: 2)],
        visibleHexes: [],
      );
      expect(
        mapCameraSelection(_snapshot(unit: 'second', fog: fog, foreign: true)),
        isNull,
      );
      expect(
        mapCameraSelection(
          _snapshot(city: 'city', fog: fog, foreign: true),
        )?.key,
        'city:city',
      );
      expect(
        mapCameraSelection(_snapshot(unit: 'second', fog: fog))?.key,
        'unit:second',
      );
      expect(mapCameraSelection(_snapshot(unit: 'missing')), isNull);
      expect(mapCameraSelection(_snapshot(fog: fog)), isNull);
      final hidden = MapFogView(
        enabled: true,
        discoveredHexes: [],
        visibleHexes: [],
      );
      expect(
        mapCameraSelection(_snapshot(city: 'city', fog: hidden, foreign: true)),
        isNull,
      );
    },
  );
}

MapRenderSnapshot _snapshot({
  String? unit,
  String? city,
  int epoch = 0,
  MapFogView? fog,
  bool foreign = false,
}) {
  final scene = testMapScene(
    cols: 4,
    rows: 4,
    units: [
      testVisibleUnit(id: 'first', coordinate: (col: 0, row: 0)),
      testVisibleUnit(
        id: 'second',
        coordinate: (col: 2, row: 2),
        ownerPlayerId: foreign ? 'opponent' : 'preview-player',
      ),
    ],
    cities: [
      testCityView(
        id: 'city',
        center: (col: 2, row: 2),
        ownerPlayerId: foreign ? 'opponent' : 'preview-player',
        owned: !foreign,
      ),
    ],
  );
  final source = scene.player;
  final player = PlayerMapView(
    actorPlayerId: source.actorPlayerId,
    stamp: source.stamp,
    turnMode: source.turnMode,
    participants: source.participants,
    fog: fog ?? source.fog,
    economy: source.economy,
    research: source.research,
    victory: source.victory,
    turnView: source.turnView,
    diplomacy: source.diplomacy,
    units: source.units,
    cities: source.cities,
  );
  return MapRenderSnapshot(
    map: scene.map,
    reference: scene.reference,
    player: player,
    effectEpoch: epoch,
    interaction: MapInteractionState(
      selectedUnitId: unit,
      city: city == null ? null : CityState.loadingCity(city),
    ),
  );
}
