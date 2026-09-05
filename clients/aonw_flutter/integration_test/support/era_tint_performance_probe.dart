import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'active_frame_timings.dart';

Future<void> measureEraTintTransition(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot snapshot, {
  required int rssBefore,
}) async {
  game.setEffectPlaybackSpeed(0.05);
  game.replaceScene(_industrySnapshot(snapshot));
  final layer = game.world.eraTintLayer;
  expect(layer.debugActive, isTrue);
  expect(game.paused, isFalse);
  final frameTimes = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
  );
  expect(layer.debugActive, isTrue);
  binding.reportData!['flameEraTintFrameTimes'] = frameTimes;
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
      'fromEra': 'foundation',
      'toEra': 'industry',
      'eraTintRegions': layer.debugRegionCount,
      'eraTintContours': layer.debugRegionContourCount,
      'renderedEraTintRegions': layer.debugRenderedRegionCount,
      'effectPlaybackSpeed': 0.05,
      'continuousTransitionAcrossWarmup': true,
      'hudIncluded': false,
      'fogShadingIncluded': false,
      'warmupFrames': 12,
      'timedFrames': 60,
    },
    'metrics': {
      'residentMemoryDeltaBytes': rssDelta,
      'frameTimes': frameTimes,
      'idleEraUpdatesAfterSkip': layer.debugActiveUpdateCount - updates,
    },
    'policy': {
      'buildP99MillisMax': 16.667,
      'rasterP99MillisMax': 16.667,
      'missedFrameBudgetMax': 0,
      'residentMemoryDeltaBytesMax': 192 * 1024 * 1024,
    },
  };
  // ignore: avoid_print
  print('AONW_FLAME_ERA_TINT_BASELINE ${jsonEncode(record)}');
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

MapRenderSnapshot _industrySnapshot(MapRenderSnapshot source) {
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
      research: PlayerResearchSummaryView(
        dominantEra: PlayerTechnologyEraView.industry,
        activeTechnologyId: null,
        activeProgress: null,
        activeEffectiveCost: null,
        scienceOverflow: 0,
        sciencePerTurn: 0,
        scienceByCityId: const {},
        scienceSources: const [],
      ),
      victory: player.victory,
      turnView: player.turnView,
      diplomacy: player.diplomacy,
      units: player.units,
      cities: player.cities,
      artifacts: player.artifacts,
      fieldImprovements: player.fieldImprovements,
      roads: player.roads,
      cityFoundingDraft: player.cityFoundingDraft,
    ),
  );
}
