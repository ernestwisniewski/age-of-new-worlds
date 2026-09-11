import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'performance_environment.dart';

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
      'buildMode': performanceBuildMode,
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
      'eraTint': game.world.eraTintLayer.debugEra!.name,
      'eraTintRegions': game.world.eraTintLayer.debugRegionCount,
      'eraTintContours': game.world.eraTintLayer.debugRegionContourCount,
      'renderedEraTintRegions':
          game.world.eraTintLayer.debugRenderedRegionCount,
      'sharedUnitPaints': game.world.unitLayer.debugSharedPaintCount,
      'sharedCityPaints': game.world.cityLayer.debugSharedPaintCount,
      'sharedInfrastructurePaints':
          game.world.workerInfrastructureLayer.debugSharedPaintCount,
    },
    'metrics': {
      'startupMicros': startupMicros,
      'residentMemoryDeltaBytes': rssDelta,
      'memoryBaseline': 'localized app shell before constructing the scene',
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
Future<void> waitForPerformanceSprites(
  AonwFlameGame game,
  MapRenderSnapshot snapshot,
) async {
  final watch = Stopwatch()..start();
  while (!_spritesReady(game, snapshot)) {
    if (watch.elapsed > const Duration(seconds: 30)) {
      throw TestFailure(
        'Production scene sprites did not load within 30 seconds',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await game.ready();
  }
}

bool _spritesReady(AonwFlameGame game, MapRenderSnapshot snapshot) =>
    snapshot.player.units.every(
      (unit) =>
          game.world.unitLayer
              .debugComponentForUnit(unit.id)
              ?.debugSpriteFrame !=
          null,
    ) &&
    snapshot.player.cities.every((city) {
      final component = game.world.cityLayer.debugComponentForCity(city.id);
      return component != null &&
          (!component.debugSpriteVisible || component.debugSpriteFrame != null);
    }) &&
    snapshot.player.fieldImprovements.every((value) {
      final component = game.world.workerInfrastructureLayer.debugImprovementAt(
        value.coordinate,
      );
      return component != null &&
          (!component.debugSpriteVisible || component.debugSpriteFrame != null);
    });

/// Checks decoded frames after the bounded native startup wait.
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
    if (!game.world.cityLayer
        .debugComponentForCity(city.id)!
        .debugSpriteVisible) {
      continue;
    }
    expect(
      game.world.cityLayer.debugComponentForCity(city.id)!.debugSpriteFrame,
      isNotNull,
    );
  }
  for (final improvement in snapshot.player.fieldImprovements) {
    if (!game.world.workerInfrastructureLayer
        .debugImprovementAt(improvement.coordinate)!
        .debugSpriteVisible) {
      continue;
    }
    expect(
      game.world.workerInfrastructureLayer
          .debugImprovementAt(improvement.coordinate)!
          .debugSpriteFrame,
      isNotNull,
    );
  }
}
