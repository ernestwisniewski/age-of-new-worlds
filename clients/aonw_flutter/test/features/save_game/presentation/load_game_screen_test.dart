import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/replay/application/replay_state.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_presentation_controller.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_state.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_summary.dart';
import 'package:aonw_flutter/features/save_game/presentation/load_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('shows an honest empty state and unavailable transfer action', (
    tester,
  ) async {
    var startCalls = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: LoadGameScreen(
          listLocalSaves: () async => const [],
          resumeLocalGame: (_) async => const LocalResumeResultView.failed(
            LocalResumeFailureViewCode.missing,
          ),
          onResumed: () {},
          hasLocalReplay: (_) async => false,
          openReplay: (_) async =>
              const ReplayOpenResultView.failed(ReplayFailureViewCode.missing),
          onReplayOpened: () {},
          onStartSinglePlayer: () => startCalls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved games were found.'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('import-save')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('empty-start-single-player')));
    expect(startCalls, 1);
  });

  testWidgets('lists and resumes the selected authoritative save', (
    tester,
  ) async {
    var resumeCalls = 0;
    LocalGameScenarioView? resumedScenario;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: LoadGameScreen(
          listLocalSaves: () async => const [
            LocalSaveSummaryView.ready(
              scenario: LocalGameScenarioView.starterDuel,
              gameMode: LocalSaveGameModeView.singlePlayer,
              turnMode: MatchTurnModeView.simultaneous,
              turn: 7,
              recoveredFromBackup: false,
            ),
            LocalSaveSummaryView.ready(
              scenario: LocalGameScenarioView.dravonia,
              gameMode: LocalSaveGameModeView.hotseat,
              turnMode: MatchTurnModeView.sequential,
              turn: 12,
              recoveredFromBackup: true,
            ),
          ],
          resumeLocalGame: (scenario) async {
            resumeCalls += 1;
            resumedScenario = scenario;
            return const LocalResumeResultView.started();
          },
          onResumed: () {},
          hasLocalReplay: (scenario) async =>
              scenario == LocalGameScenarioView.dravonia,
          openReplay: (_) async => const ReplayOpenResultView.started(),
          onReplayOpened: () {},
          onStartSinglePlayer: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Single player · Starter'), findsOneWidget);
    expect(find.text('Hotseat · Dravonia'), findsOneWidget);
    expect(find.text('Turn 7 · Simultaneous'), findsOneWidget);
    expect(find.text('Turn 12 · Traditional'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('continue-game-dravonia')));
    await tester.pump();
    expect(resumeCalls, 1);
    expect(resumedScenario, LocalGameScenarioView.dravonia);
  });
}
