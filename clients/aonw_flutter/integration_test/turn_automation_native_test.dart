import 'dart:convert';

import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
}
