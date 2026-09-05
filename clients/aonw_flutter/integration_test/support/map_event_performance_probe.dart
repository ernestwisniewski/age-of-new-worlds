import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'active_frame_timings.dart';

Future<void> measureMapEventParticles(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot snapshot, {
  required int rssBefore,
}) async {
  game.setEffectPlaybackSpeed(0.05);
  game.replaceScene(_eventSnapshot(snapshot));
  final layer = game.world.eventFeedbackLayer;
  expect(layer.debugActiveBurstCount, 8);
  expect(layer.debugParticleCount, 288);
  expect(game.paused, isFalse);
  final frameTimes = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
  );
  expect(layer.debugActiveBurstCount, 8);
  expect(layer.debugParticleCount, 288);
  binding.reportData!['flameMapEventFrameTimes'] = frameTimes;
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
      'eventBursts': 8,
      'particles': 288,
      'eventKind': 'cityFounded',
      'evidenceScope': 'synthetic accepted event cues',
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
  print('AONW_FLAME_MAP_EVENT_BASELINE ${jsonEncode(record)}');
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

MapRenderSnapshot _eventSnapshot(MapRenderSnapshot source) {
  final player = source.player;
  return MapRenderSnapshot(
    map: source.map,
    reference: source.reference,
    interaction: source.interaction,
    player: PlayerMapView(
      actorPlayerId: player.actorPlayerId,
      stamp: SessionStampView(
        revision: player.stamp.revision + 1,
        stateDigest: 'e' * 64,
        mapHash: player.stamp.mapHash,
        rulesetHash: player.stamp.rulesetHash,
      ),
      turnMode: player.turnMode,
      participants: player.participants,
      fog: player.fog,
      economy: player.economy,
      research: player.research,
      victory: player.victory,
      turnView: player.turnView,
      diplomacy: player.diplomacy,
      units: player.units,
      recentFeedback: [
        for (var index = 0; index < 8; index++)
          MapParticleCueView(
            identity: (revision: player.stamp.revision + 1, eventIndex: index),
            coordinate: (col: index % 4, row: index ~/ 4),
            kind: MapParticleKindView.cityFounded,
            colorValue: 0xff68a7e8,
          ),
      ],
      cities: player.cities,
      artifacts: player.artifacts,
      fieldImprovements: player.fieldImprovements,
      roads: player.roads,
      cityFoundingDraft: player.cityFoundingDraft,
    ),
  );
}
