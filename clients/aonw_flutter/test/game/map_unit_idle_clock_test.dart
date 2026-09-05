import 'package:aonw_flutter/game/map/map_unit_idle_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('coalesces unit deadlines into bounded shared frame requests', (
    tester,
  ) async {
    var redraws = 0;
    final clock = MapUnitIdleClock(
      now: tester.binding.clock.now,
      onFrame: () => redraws++,
    );
    addTearDown(clock.clear);
    final units = List.generate(120, (_) => _DueIdleUnit());
    clock.synchronize(units);
    await tester.pump(const Duration(seconds: 1));
    expect(redraws, inInclusiveRange(59, 60));
    expect(clock.ticks, redraws);
    expect(units.map((unit) => unit.advances), everyElement(redraws));
    final ticks = clock.ticks;
    clock.clear();
    await tester.pump(const Duration(seconds: 1));
    expect(clock.ticks, ticks);
    expect(clock.scheduled, isFalse);
  });
}

final class _DueIdleUnit implements MapUnitIdleParticipant {
  var advances = 0;

  @override
  double get idleFrameDelay => 0.001;

  @override
  bool advanceIdle(double dt) {
    advances++;
    return true;
  }
}
