import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';

void recordGameplayPerformance(
  AonwFlameGame game,
  Map<String, dynamic> frameTimes, {
  required int startupMicros,
  required int rssDelta,
  required int idleUpdates,
}) {
  final record = <String, Object?>{
    'schemaVersion': 1,
    'environment': {
      'operatingSystem': Platform.operatingSystemVersion,
      'dart': Platform.version,
      'buildMode': 'flutter-test-device-debug',
      'flame': '1.38.0',
    },
    'workload': {
      'mapId': 'flame-performance-40x30',
      'dimensions': {'cols': 40, 'rows': 30},
      'visibleUnits': 120,
      'visibleCities': 40,
      'visibleFieldImprovements': 120,
      'visibleRoads': 120,
      'warmupFrames': 12,
      'timedFrames': 60,
      'timingCollector':
          'engine timestamps between consecutive warmup and measured frames',
      'worldComponents': game.world.children.length,
      'sharedUnitPaints': game.world.unitLayer.debugSharedPaintCount,
      'sharedCityPaints': game.world.cityLayer.debugSharedPaintCount,
      'sharedInfrastructurePaints':
          game.world.workerInfrastructureLayer.debugSharedPaintCount,
    },
    'metrics': {
      'startupMicros': startupMicros,
      'residentMemoryDeltaBytes': rssDelta,
      'idleEffectUpdates':
          game.world.effectHost.debugActiveUpdateCount - idleUpdates,
      'frameTimes': frameTimes,
    },
    'policy': {
      'classification': 'hard-flame-gameplay',
      'owner': 'Flutter client',
      'buildP99MillisMax': 16.667,
      'rasterP99MillisMax': 16.667,
      'missedFrameBudgetMax': 0,
      'residentMemoryDeltaBytesMax': 192 * 1024 * 1024,
    },
  };
  // Stable marker copied into the reviewed Flame performance record.
  // ignore: avoid_print
  print('AONW_FLAME_GAMEPLAY_BASELINE ${jsonEncode(record)}');
}

/// Prevents a device run from measuring asset-loading fallbacks as the scene.
void expectPerformanceSpritesReady(
  AonwFlameGame game,
  MapRenderSnapshot snapshot,
) {
  for (final unit in snapshot.player.units) {
    expect(
      game.world.unitLayer.debugComponentForUnit(unit.id)!.debugSpriteFrame,
      isNotNull,
    );
  }
  for (final city in snapshot.player.cities) {
    expect(
      game.world.cityLayer.debugComponentForCity(city.id)!.debugSpriteFrame,
      isNotNull,
    );
  }
  for (final improvement in snapshot.player.fieldImprovements) {
    expect(
      game.world.workerInfrastructureLayer
          .debugImprovementAt(improvement.coordinate)!
          .debugSpriteFrame,
      isNotNull,
    );
  }
}
