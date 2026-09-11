import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_hud_panels.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_strip.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/active_frame_timings.dart';
import 'support/combat_performance_probe.dart';
import 'support/full_hud_hover_probe.dart';
import 'support/full_hud_performance_host.dart';
import 'support/gameplay_performance_record.dart';
import 'support/performance_shell.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  testWidgets(
    '40x30 production MapScreen with fog and HUD stays within budget',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await warmPerformanceShell(tester);
      final rssBefore = ProcessInfo.currentRss;
      final host = FullHudPerformanceHost();
      addTearDown(host.dispose);
      await host.prepare();
      await tester.pumpWidget(host.build());
      await tester.runAsync(() async {
        await host.game.loaded.timeout(const Duration(seconds: 30));
        await host.game.ready().timeout(const Duration(seconds: 30));
      });
      await tester.pumpAndSettle();
      expect(find.byType(MapHudPanels), findsOneWidget);
      expect(find.byType(ResourceStrip), findsOneWidget);
      expect(host.scene.player.fog.enabled, isTrue);
      expect(host.game.world.unitLayer.debugUnitCount, 120);
      expect(host.game.world.cityLayer.debugCityCount, 40);
      expect(host.game.world.children, hasLength(24));
      await tester.runAsync(
        () => waitForPerformanceSprites(host.game, host.snapshot),
      );
      expectPerformanceSpritesReady(host.game, host.snapshot);
      final idleUpdates = host.game.world.effectHost.debugActiveUpdateCount;
      await tester.pump(const Duration(seconds: 2));
      expect(host.game.paused, isTrue);
      expect(host.game.world.effectHost.debugActiveUpdateCount, idleUpdates);
      host.game.setContinuousRendering(true);
      final timings = await measureActiveFrameTimings(
        tester,
        warmupFrames: 12,
        timedFrames: 60,
      );
      host.game.setContinuousRendering(false);
      _expectBudget(timings);
      final hoverTimings = await measureFullHudHover(tester, host);
      _expectBudget(hoverTimings);
      final rssDelta = ProcessInfo.currentRss - rssBefore;
      expect(rssDelta, lessThanOrEqualTo(192 * 1024 * 1024));
      final report = <String, Object?>{
        'scene': 'production-MapScreen-40x30',
        'buildMode': const bool.fromEnvironment('dart.vm.profile')
            ? 'profile'
            : 'debug',
        'fog': true,
        'hud': true,
        'units': 120,
        'cities': 40,
        'fieldImprovements': 120,
        'roads': 120,
        'frameTimes': timings,
        'hoverFrameTimes': hoverTimings,
        'residentMemoryDeltaBytes': rssDelta,
        'memoryBaseline': 'localized app shell before constructing the scene',
        'idleEffectUpdates':
            host.game.world.effectHost.debugActiveUpdateCount - idleUpdates,
        'operatingSystem': Platform.operatingSystemVersion,
      };
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['fullHudPerformance'] = report;
      debugPrint('AONW_FULL_HUD_PERFORMANCE ${jsonEncode(report)}');
      await measureCombatFeedback(
        binding,
        tester,
        host.game,
        host.snapshot,
        rssBefore: rssBefore,
      );
      expect(find.byType(MapHudPanels), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpAndSettle();
      expect(SpriteFrames.debugAtlasBytes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

void _expectBudget(Map<String, dynamic> timings) {
  for (final field in [
    '99th_percentile_frame_build_time_millis',
    '99th_percentile_frame_rasterizer_time_millis',
  ]) {
    expect(timings[field] as num, lessThanOrEqualTo(16.667), reason: field);
  }
  for (final field in [
    'missed_frame_build_budget_count',
    'missed_frame_rasterizer_budget_count',
  ]) {
    expect(timings[field], 0, reason: field);
  }
}
