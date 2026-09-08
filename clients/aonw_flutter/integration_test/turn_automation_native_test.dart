import 'dart:convert';

import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/native_hotseat_automation_probe.dart';
import 'support/native_turn_automation_probe.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final mode in LocalTurnModeView.values) {
    testWidgets('automates native ${mode.name} turns with an AI opponent', (
      tester,
    ) async {
      final probe = NativeTurnAutomationProbe(tester);
      try {
        await probe.start(mode);
        await probe.skipAndDismissResearch();
        await probe.selectResearchAndEndTurn();
        await probe.skipNextTurn();
        final report = probe.report(mode);
        binding.reportData ??= <String, dynamic>{};
        binding.reportData![mode.name] = report;
        debugPrint(jsonEncode(report));
      } finally {
        await probe.close();
      }
    });
  }
  testWidgets('pauses native automation for private hotseat handoffs', (
    tester,
  ) async {
    final probe = NativeTurnAutomationProbe(tester);
    try {
      await probe.start(
        LocalTurnModeView.sequential,
        opponent: LocalPlayerControlView.human,
      );
      await probe.skipAndDismissResearch();
      await probe.selectResearch();
      await probe.enableAutomaticEnds();
      await probe.awaitPrivateHandoff('player-2', 1);
      expect(probe.ready.recipient.research.activeTechnologyId, isNull);
      await probe.confirmPrivateHandoff('player-2');
      await probe.skipAndChooseResearch();
      await probe.awaitPrivateHandoff('player-1', 2);
      expect(
        probe.ready.recipient.research.activeTechnologyId,
        probe.technology,
      );
      await probe.confirmPrivateHandoff('player-1');
      expect(probe.count('skipUnitTurn'), 2);
      expect(probe.count('selectTechnology'), 2);
      expect(probe.count('endTurn'), 2);
      expect(probe.count('advanceAiTurn'), 0);
      final report = probe.report(LocalTurnModeView.sequential);
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['hotseat'] = report;
      debugPrint(jsonEncode({'hotseat': report}));
    } finally {
      await probe.close();
    }
  });
}
