import 'package:aonw_flutter/features/replay/application/replay_state.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_presentation_controller.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_state.dart';
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
          hasLocalSave: () async => false,
          resumeLocalGame: () async => const LocalResumeResultView.failed(
            LocalResumeFailureViewCode.missing,
          ),
          onResumed: () {},
          hasLocalReplay: () async => false,
          openReplay: () async =>
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

  testWidgets('resumes the available authoritative save', (tester) async {
    var resumeCalls = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: LoadGameScreen(
          hasLocalSave: () async => true,
          resumeLocalGame: () async {
            resumeCalls += 1;
            return const LocalResumeResultView.started();
          },
          onResumed: () {},
          hasLocalReplay: () async => true,
          openReplay: () async => const ReplayOpenResultView.started(),
          onReplayOpened: () {},
          onStartSinglePlayer: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Single player · Starter'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('continue-game')));
    await tester.pump();
    expect(resumeCalls, 1);
  });
}
