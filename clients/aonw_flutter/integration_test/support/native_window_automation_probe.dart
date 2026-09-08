import 'package:aonw_flutter/features/map/presentation/widgets/flame_map_viewport.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

import 'native_turn_automation_probe.dart';

extension NativeWindowAutomationProbe on NativeTurnAutomationProbe {
  Future<void> pauseAiAndResume() async {
    final game = tester
        .widget<FlameMapViewport>(find.byType(FlameMapViewport))
        .game;
    await selectResearch();
    await enableAutomaticEnds();
    await until(
      () => ready.localAiTurn.inFlight && game.hasActiveUnitEffects,
      'AI movement before minimizing the native window',
    );
    await windowManager.minimize();
    final timer = Stopwatch()..start();
    while (game.debugViewportActive) {
      if (timer.elapsed > const Duration(seconds: 5)) {
        fail('Minimized native window did not suspend the viewport');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(tester.binding.lifecycleState, isNot(AppLifecycleState.resumed));
    expect(game.paused, isTrue);
    expect(ready.localAiTurn.inFlight, isTrue);
    final revision = ready.recipient.stamp.revision;
    final completed = game.world.effectHost.debugCompletedMovementCount;
    final positions = {
      for (final unit in ready.recipient.units)
        if (game.world.unitLayer.componentForUnit(unit.id) case final sprite?)
          unit.id: sprite.visualCenter,
    };
    final commands = requests.length;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(ready.recipient.stamp.revision, revision);
    expect(game.world.effectHost.debugCompletedMovementCount, completed);
    for (final entry in positions.entries) {
      expect(
        game.world.unitLayer.componentForUnit(entry.key)?.visualCenter,
        entry.value,
      );
    }
    expect(requests.length, commands);
    final restorations = foregroundRestorations;
    await pumpFrame();
    await nextHumanTurn(2);
    expect(tester.binding.lifecycleState, AppLifecycleState.resumed);
    expect(game.debugViewportActive, isTrue);
    expect(foregroundRestorations, greaterThan(restorations));
    expect(count('endTurn'), 1);
    expect(count('advanceAiTurn'), 1);
    await idle();
  }
}
