import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'active_frame_timings.dart';

Future<void> measureCameraFocus(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot snapshot, {
  required int rssBefore,
}) async {
  game.replaceScene(snapshot);
  game.skipEffects();
  game.setReducedMotion(false);
  final cache = game.world.debugStaticRenderCache;
  final territories = game.world.cityTerritoryLayer;
  final territorySyncs = territories.debugSyncCount;
  final glowBuilds = territories.debugGlowCache.debugBuildCount;
  final updatesBefore = game.mapCamera.debugTransformUpdateCount;
  var focusCount = 0;
  final frameTimes = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
    beforeFrame: () {
      if (game.mapCamera.hasMotion) return;
      final unit = focusCount.isEven
          ? snapshot.player.units.last
          : snapshot.player.units.first;
      focusCount++;
      game.replaceScene(
        MapRenderSnapshot(
          map: snapshot.map,
          reference: snapshot.reference,
          player: snapshot.player,
          interaction: MapInteractionState(
            viewMode: snapshot.interaction.viewMode,
            selectedUnitId: unit.id,
          ),
        ),
      );
      expect(game.mapCamera.hasMotion, isTrue);
    },
  );
  final motionUpdates =
      game.mapCamera.debugTransformUpdateCount - updatesBefore;
  expect(focusCount, greaterThan(1));
  // Flame may resume a stopped loop with dt == 0 on the first frame of a
  // selection. Every subsequent frame must advance the camera transform.
  expect(motionUpdates, greaterThanOrEqualTo(72 - focusCount));
  expect(game.world.debugStaticRenderCache, same(cache));
  expect(territories.isVisible, isTrue);
  expect(territories.debugSyncCount, territorySyncs);
  final newGlowImages = territories.debugGlowCache.debugBuildCount - glowBuilds;
  expect(newGlowImages, lessThanOrEqualTo(snapshot.player.cities.length * 2));
  expect(
    territories.debugGlowCache.debugPixelCount,
    lessThanOrEqualTo(2097152),
  );
  binding.reportData!['flameCameraFocusFrameTimes'] = frameTimes;
  final rssDelta = ProcessInfo.currentRss - rssBefore;
  game.skipEffects();
  expect(game.paused, isTrue);
  final idleUpdates = game.mapCamera.debugTransformUpdateCount;
  await tester.pump(const Duration(milliseconds: 100));
  expect(game.mapCamera.debugTransformUpdateCount, idleUpdates);
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
      'selectionTransitionSeconds': 0.42,
      'selectionTransitions': focusCount,
      'cameraUpdates': motionUpdates,
      'evidenceScope': 'repeated selection between public units across the map',
      'warmupFrames': 12,
      'timedFrames': 60,
    },
    'metrics': {
      'residentMemoryDeltaBytes': rssDelta,
      'newTerritoryGlowImages': newGlowImages,
      'territoryGlowPixelCount': territories.debugGlowCache.debugPixelCount,
      'frameTimes': frameTimes,
      'idleCameraUpdatesAfterSkip':
          game.mapCamera.debugTransformUpdateCount - idleUpdates,
    },
    'policy': {
      'buildP99MillisMax': 16.667,
      'rasterP99MillisMax': 16.667,
      'missedFrameBudgetMax': 0,
      'residentMemoryDeltaBytesMax': 192 * 1024 * 1024,
    },
  };
  // ignore: avoid_print
  print('AONW_FLAME_CAMERA_FOCUS_BASELINE ${jsonEncode(record)}');
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
  game.replaceScene(snapshot);
}
