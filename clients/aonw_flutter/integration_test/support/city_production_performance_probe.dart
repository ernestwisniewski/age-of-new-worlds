import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'active_frame_timings.dart';
import 'city_production_performance_fixture.dart';

Future<void> measureCityProductionHints(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot snapshot, {
  required int rssBefore,
}) async {
  game.replaceScene(cityProductionPerformanceSnapshot(snapshot));
  final layer = game.world.cityProductionLayer;
  final visibleHints = layer.debugHintCount;
  expect(visibleHints, inInclusiveRange(1, 19));
  expect(game.paused, isTrue);
  for (var frame = 0; frame < 180 && layer.debugActiveHintCount == 0; frame++) {
    await tester.pump(const Duration(microseconds: 16667));
  }
  expect(layer.debugActiveHintCount, visibleHints);
  game.setEffectPlaybackSpeed(0.05);
  final frameTimes = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
  );
  expect(layer.debugActiveHintCount, visibleHints);
  expect(layer.debugRenderedHintCount, visibleHints);
  binding.reportData!['flameCityProductionFrameTimes'] = frameTimes;
  final rssDelta = ProcessInfo.currentRss - rssBefore;
  game.skipEffects();
  expect(game.paused, isTrue);
  final updates = layer.debugActiveUpdateCount;
  await tester.pump(const Duration(milliseconds: 100));
  expect(layer.debugActiveUpdateCount, updates);
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
      'producingOwnedCities': 20,
      'visibleHints': visibleHints,
      'renderedHints': visibleHints,
      'worldComponents': 23,
      'hintPaints': 1,
      'hintComponents': 0,
      'evidenceScope': 'synthetic recipient-owned city production queues',
      'effectPlaybackSpeed': 0.05,
      'continuousHintsAcrossWarmup': true,
      'hudIncluded': false,
      'fogShadingIncluded': false,
      'warmupFrames': 12,
      'timedFrames': 60,
    },
    'metrics': {
      'residentMemoryDeltaBytes': rssDelta,
      'frameTimes': frameTimes,
      'idleProductionUpdatesAfterSkip': layer.debugActiveUpdateCount - updates,
    },
    'policy': {
      'buildP99MillisMax': 16.667,
      'rasterP99MillisMax': 16.667,
      'missedFrameBudgetMax': 0,
      'residentMemoryDeltaBytesMax': 192 * 1024 * 1024,
    },
  };
  // ignore: avoid_print
  print('AONW_FLAME_CITY_PRODUCTION_BASELINE ${jsonEncode(record)}');
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
  game.skipEffects();
  game.setEffectPlaybackSpeed(1);
}
