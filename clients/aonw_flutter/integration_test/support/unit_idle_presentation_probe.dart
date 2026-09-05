import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/unit_map_layer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> verifyUnitIdlePresentation(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot source, {
  required int rssBefore,
}) async {
  final layer = game.world.unitLayer;
  final unit = layer.componentForUnit(source.player.units.first.id)!;
  final cache = game.world.debugStaticRenderCache;
  final sceneWrites = game.world.debugSceneWriteCount;
  final effectUpdates = game.world.effectHost.debugActiveUpdateCount;
  final firstTick = layer.debugAnimationTicks;
  final paints = unit.debugPaintCount;
  final frames = <String>{};
  for (var sample = 0; sample < 32; sample++) {
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.paused, isTrue);
    frames.add(unit.debugSpriteFrame!.id.value);
  }
  expect(frames, hasLength(6));
  expect(frames, everyElement(contains('.idle.')));
  expect(unit.debugPaintCount, greaterThan(paints));
  expect(layer.debugAnimationTicks, greaterThan(firstTick));
  expect(game.world.debugStaticRenderCache, same(cache));
  expect(game.world.debugSceneWriteCount, sceneWrites);
  expect(game.world.effectHost.debugActiveUpdateCount, effectUpdates);
  await game.waitForCommandEffects();

  game.setUnitIdleAnimations(false);
  final stoppedTicks = layer.debugAnimationTicks;
  final frozen = unit.debugSpriteFrame;
  await tester.pump(const Duration(milliseconds: 400));
  expect(layer.debugAnimationScheduled, isFalse);
  expect(layer.debugAnimationTicks, stoppedTicks);
  expect(unit.debugSpriteFrame, same(frozen));
  expect(game.paused, isTrue);
  final rssDelta = ProcessInfo.currentRss - rssBefore;
  final record = {
    'schemaVersion': 1,
    'capturedAt': DateTime.now().toUtc().toIso8601String(),
    'observedIdleFrames': frames.length,
    'samples': 32,
    'sampleIntervalMillis': 100,
    'idleTimerTicks': stoppedTicks - firstTick,
    'idlePaints': unit.debugPaintCount - paints,
    'effectUpdates':
        game.world.effectHost.debugActiveUpdateCount - effectUpdates,
    'residentMemoryDeltaBytes': rssDelta,
    'flamePausedThroughout': true,
    'timerStoppedWhenDisabled': true,
  };
  binding.reportData!['flameUnitIdlePresentation'] = record;
  // ignore: avoid_print
  print('AONW_FLAME_UNIT_IDLE_PRESENTATION ${jsonEncode(record)}');
  expect(rssDelta, lessThanOrEqualTo(192 * 1024 * 1024));
  game.setUnitIdleAnimations(true);
}
