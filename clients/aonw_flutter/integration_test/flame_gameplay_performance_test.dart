import 'dart:io';

import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/active_frame_timings.dart';
import 'support/camera_focus_performance_probe.dart';
import 'support/city_production_performance_probe.dart';
import 'support/cloud_performance_probe.dart';
import 'support/combat_performance_probe.dart';
import 'support/era_tint_performance_probe.dart';
import 'support/gameplay_performance_record.dart';
import 'support/large_gameplay_snapshot.dart';
import 'support/map_event_performance_probe.dart';
import 'support/map_floating_text_performance_probe.dart';
import 'support/movement_camera_performance_probe.dart';
import 'support/performance_shell.dart';
import 'support/route_performance_probe.dart';
import 'support/unit_combat_presentation_probe.dart';
import 'support/unit_idle_presentation_probe.dart';
import 'support/unit_work_presentation_probe.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  testWidgets('keeps the production Flame workload within its budget', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await warmPerformanceShell(tester);
    final rssBefore = ProcessInfo.currentRss;
    final snapshot = largeGameplaySnapshot();
    final game = AonwFlameGame(
      world: AonwWorld(cloudLayer: performanceCloudLayer()),
    );
    final startup = Stopwatch()..start();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget<AonwFlameGame>(game: game, autofocus: false),
      ),
    );
    game.replaceScene(snapshot);
    await tester.runAsync(game.ready);
    game.setViewportActive(true);
    await tester.pump();
    await tester.runAsync(() => waitForPerformanceSprites(game, snapshot));
    startup.stop();

    expect(game.world.unitLayer.debugUnitCount, 120);
    expect(game.world.unitLayer.debugSharedPaintCount, 8);
    expect(game.world.cityLayer.debugCityCount, 40);
    expect(game.world.cityLayer.debugSharedPaintCount, 5);
    expect(game.world.workerInfrastructureLayer.debugImprovementCount, 120);
    expect(game.world.workerInfrastructureLayer.debugRoadCount, 120);
    expect(game.world.workerInfrastructureLayer.debugSharedPaintCount, 9);
    expect(game.world.children, hasLength(24));
    expect(game.paused, isTrue, reason: 'the turn-based world starts idle');
    final idleUpdates = game.world.effectHost.debugActiveUpdateCount;
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    expect(game.world.effectHost.debugActiveUpdateCount, idleUpdates);

    expectPerformanceSpritesReady(game, snapshot);
    game.setContinuousRendering(true);
    final frameTimes = await measureActiveFrameTimings(
      tester,
      warmupFrames: 12,
      timedFrames: 60,
    );
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['flameGameplayFrameTimes'] = frameTimes;
    game.setContinuousRendering(false);
    expect(game.paused, isTrue);
    expect(
      game.world.eraTintLayer.debugRenderedRegionCount,
      inInclusiveRange(1, game.world.eraTintLayer.debugRegionCount - 1),
      reason: 'the real camera must bound culling on the recording canvas',
    );

    final buildP99 =
        frameTimes['99th_percentile_frame_build_time_millis']! as num;
    final rasterP99 =
        frameTimes['99th_percentile_frame_rasterizer_time_millis']! as num;
    final missedBuild = frameTimes['missed_frame_build_budget_count']! as int;
    final missedRaster =
        frameTimes['missed_frame_rasterizer_budget_count']! as int;
    final rssDelta = ProcessInfo.currentRss - rssBefore;

    expect(buildP99, lessThanOrEqualTo(16.667));
    expect(rasterP99, lessThanOrEqualTo(16.667));
    expect(missedBuild, 0);
    expect(missedRaster, 0);
    expect(rssDelta, lessThanOrEqualTo(192 * 1024 * 1024));

    recordGameplayPerformance(
      game,
      frameTimes,
      startupMicros: startup.elapsedMicroseconds,
      rssDelta: rssDelta,
      idleUpdates: idleUpdates,
    );

    await verifyUnitIdlePresentation(
      binding,
      tester,
      game,
      snapshot,
      rssBefore: rssBefore,
    );
    await verifyUnitWorkPresentation(
      binding,
      tester,
      game,
      snapshot,
      rssBefore: rssBefore,
    );
    await verifyUnitCombatPresentation(
      binding,
      tester,
      game,
      snapshot,
      rssBefore: rssBefore,
    );
    await measurePlannedRoute(
      binding,
      tester,
      game,
      snapshot,
      rssBefore: rssBefore,
    );
    await _measureActiveEffects(binding, tester, game, snapshot, rssBefore);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(SpriteFrames.debugAtlasBytes, isEmpty);
    binding.reportData!['spriteAtlasesReleasedOnUnmount'] = true;
  });
}

Future<void> _measureActiveEffects(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  AonwFlameGame game,
  MapRenderSnapshot snapshot,
  int rssBefore,
) async {
  await measureCombatFeedback(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
  );

  await measureEraTintTransition(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
  );

  await measureMapEventParticles(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
  );

  await measureMapFloatingText(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
  );

  await measureCityProductionHints(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
  );

  await measureCloudDrift(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
  );

  await measureCameraFocus(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
  );
  await measureMovementCamera(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
  );
  await measureMovementCamera(
    binding,
    tester,
    game,
    snapshot,
    rssBefore: rssBefore,
    cinematic: true,
  );
}
