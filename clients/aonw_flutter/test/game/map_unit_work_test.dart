import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:aonw_flutter/game/map/map_unit_sprite_animation.dart';
import 'package:aonw_flutter/game/map/unit_map_layer.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWidgets('loops work without idle pauses or a continuous Flame loop', (
    tester,
  ) async {
    final game = await _mount(tester);
    final layer = game.world.unitLayer;
    final cache = game.world.debugStaticRenderCache;
    final writes = game.world.debugSceneWriteCount;
    final effects = game.world.effectHost.debugActiveUpdateCount;
    expect(layer.debugAnimationUnitCount, 4);
    expect(layer.idleAnimationsEnabled, isFalse);
    for (var index = 1; index <= 7; index++) {
      await tester.pump(const Duration(milliseconds: 220));
      for (final id in ['road', 'founding', 'excavation', 'assignment']) {
        final unit = layer.componentForUnit(id)!;
        expect(unit.debugSpriteAction, MapUnitSpriteAction.work);
        expect(unit.debugSpriteFrame!.id.value, endsWith('.work.${index % 6}'));
      }
      expect(game.paused, isTrue);
    }
    expect(
      layer.componentForUnit('far')!.debugSpriteFrame!.id.value,
      endsWith('.work.0'),
    );
    expect(
      layer.componentForUnit('military')!.debugSpriteAction,
      MapUnitSpriteAction.idle,
    );
    expect(layer.componentForUnit('assignment')!.debugWorkBadgeLabel, '+50%');
    expect(layer.componentForUnit('excavation')!.debugWorkBadgeLabel, '1t');
    expect(game.world.debugStaticRenderCache, same(cache));
    expect(game.world.debugSceneWriteCount, writes);
    expect(game.world.effectHost.debugActiveUpdateCount, effects);
    await game.waitForCommandEffects();
    await _unmount(tester);
  });

  testWidgets(
    'preserves work phase across updates and pauses outside the view',
    (tester) async {
      final game = await _mount(tester);
      final layer = game.world.unitLayer;
      final worker = layer.componentForUnit('road')!;
      await tester.pump(const Duration(milliseconds: 100));
      game.replaceScene(_snapshot(turns: 1));
      expect(layer.componentForUnit('road'), same(worker));
      expect(worker.debugWorkBadgeLabel, '1t');
      await tester.pump(const Duration(milliseconds: 120));
      expect(worker.debugSpriteFrame!.id.value, 'unit.worker.work.1');
      game.mapCamera.applyIntent(
        MapZoomIntent(focalPoint: game.mapCamera.viewportCenter!, factor: 0.4),
      );
      await tester.pump(const Duration(milliseconds: 220));
      expect(
        worker.debugSpriteFrame!.id.value,
        'unit.worker.work.2',
        reason: 'work remains animated below the idle zoom threshold',
      );
      for (final mode in ['hidden', 'reduced', 'offscreen']) {
        _stop(game, mode);
        final frame = worker.debugSpriteFrame;
        final ticks = layer.debugAnimationTicks;
        expect(layer.debugAnimationScheduled, isFalse);
        await tester.pump(const Duration(seconds: 2));
        expect(worker.debugSpriteFrame, same(frame));
        expect(layer.debugAnimationTicks, ticks);
        _resume(game, mode);
        expect(layer.debugAnimationScheduled, isTrue);
      }
      await _unmount(tester);
    },
  );

  testWidgets(
    'movement suspends work and completion restores the current job pose',
    (tester) async {
      final game = await _mount(tester);
      final layer = game.world.unitLayer;
      final worker = layer.componentForUnit('road')!;
      final center = worker.debugVisualCenter;
      worker.beginMovement();
      worker.advanceWalk(center, center + const ui.Offset(-10, 0), 0.14);
      final walk = worker.debugSpriteFrame;
      expect(layer.debugAnimationUnitCount, 3);
      await tester.pump(const Duration(milliseconds: 500));
      expect(worker.debugSpriteFrame, same(walk));
      worker.finishMovement(worker.debugUnit.coordinate, center);
      expect(worker.debugSpriteFrame!.id.value, 'unit.worker.work.0');
      expect(worker.debugSpriteMirrored, isTrue);
      expect(layer.debugAnimationUnitCount, 4);
      await tester.pump(const Duration(milliseconds: 220));
      expect(worker.debugSpriteFrame!.id.value, 'unit.worker.work.1');
      final compactSize = worker.debugSpriteSize;
      game.replaceScene(_snapshot(working: false));
      expect(worker.debugSpriteFrame!.id.value, 'unit.worker.idle.0');
      expect(worker.debugSpriteSize.width, greaterThan(compactSize.width));
      expect(layer.debugAnimationScheduled, isFalse);
      expect(game.paused, isTrue);
      game.setUnitIdleAnimations(true);
      expect(layer.debugAnimationScheduled, isTrue);
      game.clearScene();
      expect(layer.debugAnimationScheduled, isFalse);
      await _unmount(tester);
    },
  );
}

Future<AonwFlameGame> _mount(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final kind in [
      VisibleUnitKind.worker,
      VisibleUnitKind.settler,
      VisibleUnitKind.merchant,
      VisibleUnitKind.commander,
    ]) {
      final sprite = MapUnitSpriteAnimation(kind: kind, onLoaded: () {});
      await sprite.load();
      addTearDown(sprite.dispose);
    }
  });
  final layer = MapUnitLayerComponent(
    now: tester.binding.clock.now,
    idlePauseDuration: () => 1,
  );
  final game = AonwFlameGame(world: AonwWorld(unitLayer: layer));
  game.setUnitIdleAnimations(false);
  await tester.pumpWidget(
    Directionality(
      textDirection: ui.TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  game.replaceScene(_snapshot());
  await tester.runAsync(game.ready);
  await tester.pump();
  for (final unit in game.world.debugScene!.player.units) {
    await tester.runAsync(layer.componentForUnit(unit.id)!.debugLoadSprite);
  }
  game.setViewportActive(true);
  await tester.pump();
  return game;
}

MapRenderSnapshot _snapshot({bool working = true, int turns = 2}) {
  final job = working
      ? RoadConstructionJobView(
          target: (col: 2, row: 2),
          remainingTurns: turns,
          totalTurns: 3,
        )
      : null;
  final scene = testMapScene(
    cols: 20,
    rows: 16,
    units: [
      testVisibleUnit(
        id: 'road',
        kind: VisibleUnitKind.worker,
        coordinate: (col: 2, row: 2),
        workerJob: job,
      ),
      testVisibleUnit(
        id: 'founding',
        kind: VisibleUnitKind.settler,
        coordinate: (col: 3, row: 2),
        cityFoundingRemainingTurns: working ? turns : null,
      ),
      testVisibleUnit(
        id: 'excavation',
        kind: VisibleUnitKind.merchant,
        coordinate: (col: 2, row: 3),
        excavatingArtifactId: working ? 'artifact' : null,
      ),
      testVisibleUnit(
        id: 'assignment',
        kind: VisibleUnitKind.worker,
        coordinate: (col: 3, row: 3),
        workerAssignment: working ? (col: 3, row: 3) : null,
      ),
      testVisibleUnit(
        id: 'military',
        coordinate: (col: 4, row: 3),
        workerAssignment: working ? (col: 4, row: 3) : null,
      ),
      testVisibleUnit(
        id: 'far',
        kind: VisibleUnitKind.worker,
        coordinate: (col: 19, row: 15),
        workerJob: job,
      ),
    ],
  );
  return MapRenderSnapshot(
    map: scene.map,
    reference: scene.reference,
    player: scene.player,
    interaction: const MapInteractionState(),
  );
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void _stop(AonwFlameGame game, String mode) {
  switch (mode) {
    case 'hidden':
      game.setViewportActive(false);
    case 'reduced':
      game.setReducedMotion(true);
    case 'offscreen':
      game.mapCamera.centerOnWorld((x: -10000, y: -10000));
  }
}

void _resume(AonwFlameGame game, String mode) {
  switch (mode) {
    case 'hidden':
      game.setViewportActive(true);
    case 'reduced':
      game.setReducedMotion(false);
    case 'offscreen':
      game.mapCamera.centerOnHex((col: 2, row: 2));
  }
}
