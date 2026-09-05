import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/unit_map_layer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> verifyUnitWorkPresentation(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot source, {
  required int rssBefore,
}) async {
  game.setUnitIdleAnimations(false);
  game.replaceScene(_workingSnapshot(source));
  final layer = game.world.unitLayer;
  final units = [
    for (final unit in source.player.units.take(3))
      layer.componentForUnit(unit.id)!,
  ];
  for (final unit in units) {
    await unit.debugLoadSprite();
  }
  final cache = game.world.debugStaticRenderCache;
  final writes = game.world.debugSceneWriteCount;
  final effects = game.world.effectHost.debugActiveUpdateCount;
  final ticks = layer.debugAnimationTicks;
  final frames = {
    for (final unit in units) unit.debugUnit.kind.name: <String>{},
  };
  for (var sample = 0; sample < 14; sample++) {
    await tester.pump(const Duration(milliseconds: 110));
    expect(game.paused, isTrue);
    for (final unit in units) {
      frames[unit.debugUnit.kind.name]!.add(unit.debugSpriteFrame!.id.value);
    }
  }
  for (final observed in frames.values) {
    expect(observed, hasLength(6));
    expect(observed, everyElement(contains('.work.')));
  }
  expect(game.world.debugStaticRenderCache, same(cache));
  expect(game.world.debugSceneWriteCount, writes);
  expect(game.world.effectHost.debugActiveUpdateCount, effects);
  expect(layer.debugAnimationUnitCount, 3);
  await game.waitForCommandEffects();
  game.setReducedMotion(true);
  final stoppedTicks = layer.debugAnimationTicks;
  await tester.pump(const Duration(milliseconds: 300));
  expect(layer.debugAnimationScheduled, isFalse);
  expect(layer.debugAnimationTicks, stoppedTicks);
  expect(game.paused, isTrue);
  final rssDelta = ProcessInfo.currentRss - rssBefore;
  final record = {
    'schemaVersion': 1,
    'capturedAt': DateTime.now().toUtc().toIso8601String(),
    'observedWorkFrames': {
      for (final entry in frames.entries) entry.key: entry.value.length,
    },
    'samples': 14,
    'sampleIntervalMillis': 110,
    'frameDurationMillis': 220,
    'animationTimerTicks': stoppedTicks - ticks,
    'flamePausedThroughout': true,
    'idleAnimationsDisabled': true,
    'timerStoppedForReducedMotion': true,
    'residentMemoryDeltaBytes': rssDelta,
  };
  binding.reportData!['flameUnitWorkPresentation'] = record;
  // ignore: avoid_print
  print('AONW_FLAME_UNIT_WORK_PRESENTATION ${jsonEncode(record)}');
  expect(rssDelta, lessThanOrEqualTo(192 * 1024 * 1024));
  game.replaceScene(source);
  game.setReducedMotion(false);
  game.setUnitIdleAnimations(true);
}

MapRenderSnapshot _workingSnapshot(MapRenderSnapshot source) {
  const kinds = [
    VisibleUnitKind.worker,
    VisibleUnitKind.settler,
    VisibleUnitKind.merchant,
  ];
  final player = source.player;
  return MapRenderSnapshot(
    map: source.map,
    reference: source.reference,
    interaction: source.interaction,
    player: PlayerMapView(
      actorPlayerId: player.actorPlayerId,
      stamp: player.stamp,
      turnMode: player.turnMode,
      participants: player.participants,
      fog: player.fog,
      economy: player.economy,
      research: player.research,
      victory: player.victory,
      turnView: player.turnView,
      diplomacy: player.diplomacy,
      cities: player.cities,
      artifacts: player.artifacts,
      fieldImprovements: player.fieldImprovements,
      roads: player.roads,
      units: [
        for (var index = 0; index < player.units.length; index++)
          if (index >= kinds.length)
            player.units[index]
          else
            VisibleUnitView(
              id: player.units[index].id,
              ownerPlayerId: player.actorPlayerId,
              kind: kinds[index],
              name: 'Working unit $index',
              coordinate: player.units[index].coordinate,
              movementUnits: 0,
              posture: VisibleUnitPosture.active,
              workerAssignment: index == 0
                  ? player.units[index].coordinate
                  : null,
              cityFoundingRemainingTurns: index == 1 ? 2 : null,
              excavatingArtifactId: index == 2 ? 'performance-artifact' : null,
            ),
      ],
    ),
  );
}
