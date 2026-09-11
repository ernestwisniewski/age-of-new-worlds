import 'package:flutter_test/flutter_test.dart';

import 'active_frame_timings.dart';
import 'full_hud_performance_host.dart';

Future<Map<String, dynamic>> measureFullHudHover(
  WidgetTester tester,
  FullHudPerformanceHost host,
) async {
  final world = host.game.world;
  final sceneWrites = world.debugSceneWriteCount;
  final tileWrites = world.tileDetailsLayer.debugCacheUpdateCount;
  final firstUnit = world.unitLayer.debugComponentForUnit('performance-unit-0');
  var index = 0;
  final timings = await measureActiveFrameTimings(
    tester,
    warmupFrames: 12,
    timedFrames: 60,
    beforeFrame: () => host.controller.hover((col: index++ % 40, row: 5)),
  );
  expect(world.debugSceneWriteCount, sceneWrites);
  expect(world.tileDetailsLayer.debugCacheUpdateCount, tileWrites);
  expect(
    world.unitLayer.debugComponentForUnit('performance-unit-0'),
    same(firstUnit),
  );
  host.controller.hover(null);
  await tester.pump();
  return timings;
}
