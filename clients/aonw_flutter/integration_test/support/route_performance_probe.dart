import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'active_frame_timings.dart';

Future<void> measurePlannedRoute(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot source, {
  required int rssBefore,
}) async {
  final center = game.mapCamera.debugTransform!.worldCenter;
  final cache = game.world.debugStaticRenderCache;
  game.replaceScene(_routeSnapshot(source));
  await game.world.routeLayer.debugLoadGhost();
  game.mapCamera.centerOnHex((col: 4, row: 0));
  final route = game.world.routeLayer;
  final builds = route.debugPathBuildCount;
  final writes = game.world.debugSceneWriteCount;
  final effects = game.world.effectHost.debugActiveUpdateCount;
  final updates = route.debugActiveUpdateCount;
  final frames = <String>{};
  expect(route.debugSegmentCount, 39);
  expect(game.paused, isFalse);
  final frameTimes = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
    beforeFrame: () => frames.add(route.debugGhostFrameId!),
  );
  final activeUpdates = route.debugActiveUpdateCount - updates;
  expect(frames, hasLength(6));
  expect(frames, everyElement(contains('.walk.')));
  expect(activeUpdates, greaterThanOrEqualTo(71));
  expect(route.debugPathBuildCount, builds);
  expect(game.world.debugSceneWriteCount, writes);
  expect(game.world.debugStaticRenderCache, same(cache));
  expect(game.world.effectHost.debugActiveUpdateCount, effects);
  await game.waitForCommandEffects();
  game.setRouteAnimations(false);
  final stoppedUpdates = route.debugActiveUpdateCount;
  await tester.pump(const Duration(milliseconds: 100));
  expect(game.paused, isTrue);
  expect(route.debugActiveUpdateCount, stoppedUpdates);
  expect(route.debugFlowPhase, 0);
  expect(route.debugGhostFrameId, 'unit.commander.walk.0');
  final rssDelta = ProcessInfo.currentRss - rssBefore;
  binding.reportData!['flameRouteFrameTimes'] = frameTimes;
  final record = {
    'schemaVersion': 1,
    'capturedAt': DateTime.now().toUtc().toIso8601String(),
    'environment': {
      'operatingSystem': Platform.operatingSystemVersion,
      'dart': Platform.version,
      'buildMode': 'flutter-test-device-debug',
      'flame': '1.38.0',
    },
    'workload': {
      'mapDimensions': {'cols': 40, 'rows': 30},
      'units': 120,
      'cities': 40,
      'improvements': 120,
      'roads': 120,
      'routeSegments': 39,
      'observedWalkFrames': frames.length,
      'flowUnitsPerSecond': 24,
      'ghostSpeedFactor': 0.82,
      'activeUpdates': activeUpdates,
      'warmupFrames': 12,
      'timedFrames': 60,
    },
    'metrics': {
      'residentMemoryDeltaBytes': rssDelta,
      'frameTimes': frameTimes,
      'geometryRebuildsDuringAnimation': route.debugPathBuildCount - builds,
      'updatesAfterDisable': route.debugActiveUpdateCount - stoppedUpdates,
    },
    'policy': {
      'buildP99MillisMax': 16.667,
      'rasterP99MillisMax': 16.667,
      'missedFrameBudgetMax': 0,
      'residentMemoryDeltaBytesMax': 192 * 1024 * 1024,
    },
  };
  // ignore: avoid_print
  print('AONW_FLAME_ROUTE_BASELINE ${jsonEncode(record)}');
  expect(
    frameTimes['99th_percentile_frame_build_time_millis'],
    lessThanOrEqualTo(16.667),
  );
  expect(
    frameTimes['99th_percentile_frame_rasterizer_time_millis'],
    lessThanOrEqualTo(16.667),
  );
  expect(frameTimes['missed_frame_build_budget_count'], 0);
  expect(frameTimes['missed_frame_rasterizer_budget_count'], 0);
  expect(rssDelta, lessThanOrEqualTo(192 * 1024 * 1024));
  game.replaceScene(source);
  game.setRouteAnimations(true);
  game.mapCamera.centerOnWorld(center);
  expect(game.paused, isTrue);
}

MapRenderSnapshot _routeSnapshot(MapRenderSnapshot source) => MapRenderSnapshot(
  map: source.map,
  reference: source.reference,
  player: source.player,
  interaction: MapInteractionState(
    viewMode: source.interaction.viewMode,
    route: RoutePlanView(
      stamp: source.player.stamp,
      unitId: source.player.units.first.id,
      target: (col: 39, row: 0),
      destination: (col: 39, row: 0),
      totalCostUnits: 312,
      availableMovementUnits: 12,
      remainingMovementUnits: 0,
      estimatedTurns: 39,
      steps: [
        for (var col = 0; col < 40; col++)
          MovementStepView(
            coordinate: (col: col, row: 0),
            enterCostUnits: col == 0 ? 0 : 8,
            cumulativeCostUnits: col * 8,
          ),
      ],
    ),
  ),
);
