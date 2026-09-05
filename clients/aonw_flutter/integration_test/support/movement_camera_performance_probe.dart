import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:aonw_flutter/game/map/map_movement_camera.dart';
import 'package:aonw_flutter/game/map/map_unit_sprite_animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'active_frame_timings.dart';
import 'movement_camera_performance_fixture.dart';

Future<void> measureMovementCamera(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot source, {
  required int rssBefore,
  bool cinematic = false,
}) async {
  game.setCinematicCamera(cinematic);
  game.replaceScene(source);
  game.skipEffects();
  game.setMovementCameraOptions((
    focusOwn: true,
    followOwn: true,
    focusForeign: false,
    followForeign: false,
  ));
  game.setEffectPlaybackSpeed(2);
  game.mapCamera.centerOnHex((col: 30, row: 15));
  final cache = game.world.debugStaticRenderCache!;
  final cameraUpdates = game.mapCamera.debugTransformUpdateCount;
  game.replaceScene(movementCameraPerformanceSnapshot(source));
  final unit = game.world.unitLayer.componentForUnit(
    source.player.units.first.id,
  )!;
  final origin = unit.visualCenter;
  expect(game.mapCamera.hasMotion, isTrue);
  final spriteFrames = <String>{};
  final frameTimes = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
    beforeFrame: () {
      final frame = unit.debugSpriteFrame;
      if (frame != null) spriteFrames.add(frame.id.value);
    },
  );
  expect(game.mapCamera.isFollowing, isTrue);
  expect(unit.debugSpriteAction, MapUnitSpriteAction.walk);
  final walkFrames = spriteFrames.where((id) => id.contains('.walk.')).length;
  expect(walkFrames, 6);
  expect(unit.visualCenter.dx, greaterThan(origin.dx));
  expect(game.world.effectHost.debugActiveEffectCount, 1);
  expect(game.world.debugStaticRenderCache, same(cache));
  final culling = (
    terrain: game.world.terrainLayer.debugRenderedRegionCount,
    era: game.world.eraTintLayer.debugRenderedRegionCount,
  );
  expect(culling.terrain, inInclusiveRange(1, cache.terrainRegions.length - 1));
  expect(
    culling.era,
    inInclusiveRange(1, game.world.eraTintLayer.debugRegionCount - 1),
  );
  final updates = game.mapCamera.debugTransformUpdateCount - cameraUpdates;
  expect(updates, greaterThan(60));
  binding.reportData![cinematic
          ? 'flameCinematicCameraFrameTimes'
          : 'flameMovementCameraFrameTimes'] =
      frameTimes;
  final rssDelta = ProcessInfo.currentRss - rssBefore;
  game.skipEffects();
  await game.waitForCommandEffects();
  expect(game.paused, isTrue);
  final idleUpdates = game.mapCamera.debugTransformUpdateCount;
  await tester.pump(const Duration(milliseconds: 100));
  expect(game.mapCamera.debugTransformUpdateCount, idleUpdates);
  final record = _movementCameraRecord(
    game,
    frameTimes,
    rssDelta: rssDelta,
    updates: updates,
    idleUpdates: idleUpdates,
    cinematic: cinematic,
    culling: culling,
    walkFrames: walkFrames,
  );
  final label = cinematic ? 'CINEMATIC_CAMERA' : 'MOVEMENT_CAMERA';
  // ignore: avoid_print
  print('AONW_FLAME_${label}_BASELINE ${jsonEncode(record)}');
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
  game.setCinematicCamera(false);
  game.setEffectPlaybackSpeed(1);
  game.setMovementCameraOptions(defaultMapMovementCameraOptions);
  game.replaceScene(source);
}

Map<String, Object> _movementCameraRecord(
  AonwFlameGame game,
  Map<String, dynamic> frameTimes, {
  required int rssDelta,
  required int updates,
  required int idleUpdates,
  required bool cinematic,
  required int walkFrames,
  required ({int terrain, int era}) culling,
}) {
  return {
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
      'cinematicProjectionStrength': cinematic ? 0.26 : 0,
      'executedPathSteps': 39,
      'focusDurationSeconds': 0.28,
      'followHalfLifeSeconds': 0.1,
      'effectPlaybackSpeed': 2,
      'movementStepDurationSeconds': 0.6,
      'movementCurve': 'linear',
      'walkFrameDurationSeconds': 0.14,
      'observedWalkFrames': walkFrames,
      'cameraUpdates': updates,
      'evidenceScope':
          'synthetic observed movement with a public executed route',
      'warmupFrames': 12,
      'timedFrames': 60,
    },
    'metrics': {
      'residentMemoryDeltaBytes': rssDelta,
      'renderedTerrainRegions': culling.terrain,
      'terrainRegions':
          game.world.debugStaticRenderCache!.terrainRegions.length,
      'renderedEraTintRegions': culling.era,
      'eraTintRegions': game.world.eraTintLayer.debugRegionCount,
      'territoryGlowImages':
          game.world.cityTerritoryLayer.debugGlowCache.debugImageCount,
      'territoryGlowPixels':
          game.world.cityTerritoryLayer.debugGlowCache.debugPixelCount,
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
}
