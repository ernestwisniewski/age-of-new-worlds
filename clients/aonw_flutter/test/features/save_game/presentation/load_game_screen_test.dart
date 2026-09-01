import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/replay/application/replay_state.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_presentation_controller.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_state.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_summary.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_transfer.dart';
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

  testWidgets(
    'lists an active online match and keeps transfer actions honest',
    (tester) async {
      String? resumedMatchId;
      await tester.pumpWidget(
        LocalizedTestApp(
          home: LoadGameScreen(
            listLocalSaves: () async => const [],
            resumeLocalGame: (_) async => const LocalResumeResultView.failed(
              LocalResumeFailureViewCode.missing,
            ),
            onResumed: () {},
            hasLocalReplay: (_) async => false,
            openReplay: (_) async => const ReplayOpenResultView.failed(
              ReplayFailureViewCode.missing,
            ),
            onReplayOpened: () {},
            onStartSinglePlayer: () {},
            onlineIndex: () => const OnlineSaveIndexView(
              phase: OnlineSaveIndexPhaseView.ready,
              saves: [
                OnlineSaveSummaryView(
                  matchId: 'online-1',
                  mapId: 'dravonia',
                  phase: OnlineSavePhaseView.running,
                ),
              ],
            ),
            resumeOnlineGame: (matchId) async {
              resumedMatchId = matchId;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Multiplayer · Dravonia'), findsOneWidget);
      expect(find.text('Match: online-1'), findsOneWidget);
      expect(find.text('Status: in progress'), findsOneWidget);
      final disabledActions = tester.widgetList<OutlinedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('online-save-online-1')),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(disabledActions, hasLength(2));
      expect(
        disabledActions.every((action) => action.onPressed == null),
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('continue-online-online-1')));
      await tester.pump();
      expect(resumedMatchId, 'online-1');
    },
  );

  testWidgets('imports, refreshes, and exports the selected local slot', (
    tester,
  ) async {
    var imported = false;
    LocalGameScenarioView? exportedScenario;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: LoadGameScreen(
          listLocalSaves: () async => imported
              ? const [
                  LocalSaveSummaryView.ready(
                    scenario: LocalGameScenarioView.dravonia,
                    gameMode: LocalSaveGameModeView.singlePlayer,
                    turnMode: MatchTurnModeView.simultaneous,
                    turn: 5,
                    recoveredFromBackup: false,
                  ),
                ]
              : const [],
          resumeLocalGame: (_) async => const LocalResumeResultView.failed(
            LocalResumeFailureViewCode.missing,
          ),
          onResumed: () {},
          hasLocalReplay: (_) async => false,
          openReplay: (_) async =>
              const ReplayOpenResultView.failed(ReplayFailureViewCode.missing),
          onReplayOpened: () {},
          onStartSinglePlayer: () {},
          onImportSave: () async {
            imported = true;
            return const LocalSaveTransferResultView.completed(
              scenario: LocalGameScenarioView.dravonia,
            );
          },
          onExportSave: (scenario) async {
            exportedScenario = scenario;
            return LocalSaveTransferResultView.completed(scenario: scenario);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('import-save')));
    await tester.pumpAndSettle();
    expect(find.text('Single player · Dravonia'), findsOneWidget);
    expect(
      find.text(
        'Imported Dravonia. The previous save for this map was preserved as a backup.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('export-save-dravonia')));
    await tester.pumpAndSettle();
    expect(exportedScenario, LocalGameScenarioView.dravonia);
    expect(find.text('Exported Dravonia.'), findsOneWidget);
  });

  testWidgets('offers multiplayer sign-in without showing an empty-save CTA', (
    tester,
  ) async {
    var openCalls = 0;
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
          onStartSinglePlayer: () {},
          onlineIndex: () => const OnlineSaveIndexView(
            phase: OnlineSaveIndexPhaseView.signedOut,
          ),
          onOpenMultiplayer: () => openCalls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved games were found.'), findsNothing);
    expect(
      find.byKey(const ValueKey('online-saves-signed-out')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('open-online-sign-in')));
    expect(openCalls, 1);
  });
}
