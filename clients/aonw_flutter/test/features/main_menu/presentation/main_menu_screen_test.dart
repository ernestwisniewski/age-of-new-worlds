import 'package:aonw_flutter/features/main_menu/presentation/main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('renders the target menu without resume or replay shortcuts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(
        home: MainMenuScreen(
          onOpenSinglePlayer: () {},
          onOpenMultiplayer: () {},
          onOpenHotseat: null,
          onOpenLoadGame: () {},
          onOpenSettings: () {},
          onOpenInstructions: () {},
          onOpenCredits: () {},
          onOpenFeedback: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in [
      'single-player',
      'multiplayer',
      'hotseat',
      'load-game',
      'menu-settings',
      'exit-game',
      'menu-help',
      'menu-credits',
      'menu-feedback',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('continue-game')), findsNothing);
    expect(find.byKey(const ValueKey('open-replay')), findsNothing);

    final hotseat = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('hotseat')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(hotseat.onPressed, isNull);
  });

  testWidgets('localizes the shell and invokes available actions', (
    tester,
  ) async {
    var singlePlayerCalls = 0;
    var exitCalls = 0;
    await tester.binding.setSurfaceSize(const Size(430, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(
        locale: const Locale('pl'),
        home: MainMenuScreen(
          onOpenSinglePlayer: () => singlePlayerCalls += 1,
          onOpenMultiplayer: null,
          onOpenHotseat: null,
          onOpenLoadGame: () {},
          onOpenSettings: () {},
          onOpenInstructions: () {},
          onOpenCredits: () {},
          onOpenFeedback: () {},
          onExit: () async => exitCalls += 1,
          serverUpdateRequired: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gra jednoosobowa'), findsOneWidget);
    expect(find.text('Wczytaj grę'), findsOneWidget);
    expect(find.textContaining('Nowsza wersja gry'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('single-player')));
    await tester.tap(find.byKey(const ValueKey('single-player')));
    await tester.ensureVisible(find.byKey(const ValueKey('exit-game')));
    await tester.tap(find.byKey(const ValueKey('exit-game')));
    await tester.pump();

    expect(singlePlayerCalls, 1);
    expect(exitCalls, 1);
  });
}
