import 'dart:async';

import 'package:aonw_flutter/features/multiplayer/application/match_history_port.dart';
import 'package:aonw_flutter/features/replay/application/replay_state.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_presentation_controller.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_state.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_summary.dart';
import 'package:aonw_flutter/features/save_game/presentation/load_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../multiplayer/presentation/match_history_fixture.dart';

void main() {
  for (final changeAccount in [false, true]) {
    testWidgets(
      'history replay opens once and guards account change=$changeAccount',
      (tester) async {
        final account = ValueNotifier('account');
        addTearDown(account.dispose);
        final history = HistoryPort()..replayAvailable = true;
        final pending = Completer<ReplayOpenResultView>();
        var requests = 0;
        var navigated = 0;
        MatchHistoryEntryView? selected;
        String? selectedAccount;
        await tester.pumpWidget(
          LocalizedTestApp(
            home: LoadGameScreen(
              listLocalSaves: () async => [],
              resumeLocalGame: (_) async => const LocalResumeResultView.failed(
                LocalResumeFailureViewCode.missing,
              ),
              onResumed: () {},
              hasLocalReplay: (_) async => false,
              openReplay: (_) async => const ReplayOpenResultView.failed(
                ReplayFailureViewCode.missing,
              ),
              onReplayOpened: () => navigated++,
              onStartSinglePlayer: () {},
              matchHistory: history,
              onlineChanges: account,
              onlineIndex: () => OnlineSaveIndexView(
                phase: OnlineSaveIndexPhaseView.ready,
                userId: account.value,
              ),
              openOnlineReplay: (entry, userId) {
                requests++;
                selected = entry;
                selectedAccount = userId;
                return pending.future;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final section = find.byKey(const ValueKey('match-history-section'));
        await tester.ensureVisible(section);
        await tester.tap(section);
        await tester.pumpAndSettle();
        final button = find.byKey(
          const ValueKey(('history-replay', 'match-first')),
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
        expect(requests, 1);
        expect(selected!.match.matchId, 'match-first');
        expect(selectedAccount, 'account');
        expect(navigated, 0);
        if (changeAccount) {
          history.userId = 'other';
          account.value = 'other';
          await tester.pump();
        }
        pending.complete(const ReplayOpenResultView.started());
        await tester.pumpAndSettle();
        expect(navigated, changeAccount ? 0 : 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
