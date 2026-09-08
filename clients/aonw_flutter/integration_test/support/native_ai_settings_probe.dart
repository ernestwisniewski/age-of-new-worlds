import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'native_turn_automation_probe.dart';

extension NativeAiSettingsProbe on NativeTurnAutomationProbe {
  Future<void> toggleAiBatterySaver(bool enabled) async {
    final revision = ready.recipient.stamp.revision;
    final aiCalls = count('advanceAiTurn');
    await tap(const ValueKey('open-settings'));
    final option = find.byKey(const ValueKey('ai-battery-saver-setting'));
    await until(() => option.evaluate().isNotEmpty, 'AI settings route');
    await Scrollable.ensureVisible(tester.element(option), alignment: 0.5);
    await pumpFrame();
    await tester.tap(option);
    await until(
      () => settings.settings.ai.batterySaver == enabled,
      'AI setting applied',
    );
    Navigator.of(tester.element(option)).pop();
    await until(
      () => find
          .byKey(const ValueKey('open-settings'))
          .hitTestable()
          .evaluate()
          .isNotEmpty,
      'map route restored',
    );
    await idle();
    expect(ready.recipient.stamp.revision, revision);
    expect(count('advanceAiTurn'), aiCalls);
  }

  void expectAiProfiles() {
    final calls = requests.where(
      (request) => request['type'] == 'advanceAiTurn',
    );
    expect(calls.map((request) => request['runtimeProfile']), [
      'batterySaver',
      'standard',
    ]);
    expect(calls.map((request) => request['commandBudget']), everyElement(256));
  }
}
