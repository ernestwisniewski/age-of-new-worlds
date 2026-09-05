import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_cloud_layer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'active_frame_timings.dart';

MapCloudLayerComponent performanceCloudLayer() => MapCloudLayerComponent(
  random: _CloudWorkloadRandom(),
  initialDelaySeconds: 0,
  durationSeconds: (min: 40, max: 40),
);

Future<void> measureCloudDrift(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot snapshot, {
  required int rssBefore,
}) async {
  final rssBeforeClouds = ProcessInfo.currentRss;
  final cloud = game.world.cloudLayer;
  cloud.applyFog(
    game.world.debugStaticRenderCache!,
    MapFogView(
      enabled: true,
      discoveredHexes: [for (final tile in snapshot.map.tiles) tile.coordinate],
      visibleHexes: const [],
    ),
    actorPlayerId: snapshot.player.actorPlayerId,
  );
  await tester.pump(const Duration(milliseconds: 1));
  cloud.update(6);
  // Keep the drifting group in the viewport instead of timing off-screen puffs.
  game.mapCamera.centerOnHex((col: 4, row: 0));
  expect(cloud.debugActiveCloudCount, 3);
  expect(cloud.debugActivePuffCount, 33);
  expect(game.paused, isFalse);
  final frameTimes = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
  );
  expect(cloud.debugActiveCloudCount, 3);
  binding.reportData!['flameCloudFrameTimes'] = frameTimes;
  final rssAfterClouds = ProcessInfo.currentRss;
  final rssDelta = rssAfterClouds - rssBefore;
  game.setReducedMotion(true);
  expect(cloud.debugActiveCloudCount, 0);
  expect(cloud.debugSpawnScheduled, isFalse);
  expect(game.paused, isTrue);
  final updates = cloud.debugActiveUpdateCount;
  await tester.pump(const Duration(milliseconds: 100));
  expect(cloud.debugActiveUpdateCount, updates);
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
      'clouds': 3,
      'puffs': 33,
      'cloudStartingAgeSeconds': 6,
      'cameraFocus': {'col': 4, 'row': 0},
      'discoveredClipHexes': 1200,
      'fogShadingIncluded': false,
      'hudIncluded': false,
      'warmupFrames': 12,
      'timedFrames': 60,
    },
    'metrics': {
      'residentMemoryDeltaBytes': rssDelta,
      'cloudAndCameraResidentMemoryDeltaBytes':
          rssAfterClouds - rssBeforeClouds,
      'frameTimes': frameTimes,
      'idleCloudUpdatesAfterReducedMotion':
          cloud.debugActiveUpdateCount - updates,
    },
    'policy': {
      'buildP99MillisMax': 16.667,
      'rasterP99MillisMax': 16.667,
      'missedFrameBudgetMax': 0,
      'residentMemoryDeltaBytesMax': 192 * 1024 * 1024,
    },
  };
  // ignore: avoid_print
  print('AONW_FLAME_CLOUD_BASELINE ${jsonEncode(record)}');
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
}

/// The third sample places the group near the cities; the group roll makes
/// three cloudlets and every optional puff is present.
final class _CloudWorkloadRandom implements math.Random {
  var _samples = 0;
  @override
  double nextDouble() => _samples++ == 2 ? 0.06 : 0;
  @override
  bool nextBool() => true;
  @override
  int nextInt(int max) => 0;
}
