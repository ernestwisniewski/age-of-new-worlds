import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'active_frame_timings.dart';
import 'map_event_performance_fixture.dart';

Future<void> measureMapFloatingText(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot snapshot, {
  required int rssBefore,
}) async {
  game.setEffectPlaybackSpeed(0.05);
  game.replaceScene(mapEventPerformanceSnapshot(snapshot, floatingText: true));
  final layer = game.world.eventFeedbackLayer;
  expect(layer.debugActiveBurstCount, 8);
  expect(layer.debugParticleCount, 256);
  expect(layer.debugVisibleTextCount, 8);
  expect(layer.debugTextImageCount, 8);
  expect(game.paused, isFalse);
  final frameTimes = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
  );
  expect(layer.debugActiveBurstCount, 8);
  expect(layer.debugParticleCount, 256);
  expect(layer.debugVisibleTextCount, 8);
  expect(layer.debugTextImageCount, 8);
  expect(layer.debugRenderedTextCount, 8);
  final renderedBubbles = layer.debugRenderedTextCount;
  binding.reportData!['flameMapFloatingTextFrameTimes'] = frameTimes;
  final rssDelta = ProcessInfo.currentRss - rssBefore;
  game.skipEffects();
  expect(layer.debugTextImageCount, 0);
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
      'eventBursts': 8,
      'particles': 256,
      'visibleBubbles': 8,
      'renderedBubbles': renderedBubbles,
      'textImages': 8,
      'textDelaySeconds': 0,
      'eventKind': 'artifactCarried',
      'evidenceScope':
          'synthetic artifact cues with immediate text for full visibility',
      'effectPlaybackSpeed': 0.05,
      'continuousBurstsAcrossWarmup': true,
      'hudIncluded': false,
      'fogShadingIncluded': false,
      'warmupFrames': 12,
      'timedFrames': 60,
    },
    'metrics': {
      'residentMemoryDeltaBytes': rssDelta,
      'frameTimes': frameTimes,
      'idleEventUpdatesAfterSkip': layer.debugActiveUpdateCount - updates,
    },
    'policy': {
      'buildP99MillisMax': 16.667,
      'rasterP99MillisMax': 16.667,
      'missedFrameBudgetMax': 0,
      'residentMemoryDeltaBytesMax': 192 * 1024 * 1024,
    },
  };
  // ignore: avoid_print
  print('AONW_FLAME_FLOATING_TEXT_BASELINE ${jsonEncode(record)}');
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
