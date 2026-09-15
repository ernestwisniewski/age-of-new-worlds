import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/map/read_model/player_victory_view.dart';
import 'package:aonw_flutter/features/objectives/presentation/match_outcome_overlay.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

part 'match_outcome_golden_tests.dart';

void main() {
  outcomeGoldenTests();
  for (final language in ['pl', 'en', 'fr', 'de', 'es', 'nl']) {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets('$language outcome fits $size at 200%', (tester) async {
        _size(tester, size);
        var exits = 0;
        await tester.pumpWidget(
          _app(
            _overlay(onExit: () => exits++),
            language: language,
            size: size,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final action = find.byKey(const ValueKey('outcome-return-menu'));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        expect(exits, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final (winner, actor, title) in [
    ('player-1', 'player-1', 'Victory'),
    ('player-2', 'player-1', 'Defeat'),
    (null, 'player-1', 'Draw'),
    ('player-2', null, 'Match finished'),
  ]) {
    testWidgets('presents $title from authoritative winner', (tester) async {
      var exits = 0;
      await tester.pumpWidget(
        _app(_overlay(winner: winner, actor: actor, onExit: () => exits++)),
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining('player-'), findsNothing);
      expect(find.text('Aleksandra'), findsOneWidget);
      expect(find.text('Tomasz'), findsOneWidget);
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey(('outcome-score', 'player-2'))),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey(('outcome-score', 'player-1'))),
              )
              .dy,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(exits, 1);
    });
  }

  testWidgets('never presents own cultural counts as a rival victory', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_overlay(condition: GameOutcomeConditionView.cultural)),
    );
    expect(find.text('5/6'), findsNothing);
    expect(find.text('4/5'), findsNothing);
    await tester.pumpWidget(
      _app(
        _overlay(
          condition: GameOutcomeConditionView.cultural,
          winner: 'player-1',
        ),
      ),
    );
    expect(find.text('5/6'), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
  });

  testWidgets('shows public domination counts without evaluating victory', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_overlay(condition: GameOutcomeConditionView.domination)),
    );
    expect(find.text('Defeat'), findsOneWidget);
    expect(find.text('57/100'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('60.0%'), findsOneWidget);
  });
}

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  Widget child, {
  String language = 'en',
  Size size = const Size(800, 600),
  double scale = 1,
}) => LocalizedTestApp(
  locale: Locale(language),
  theme: AonwTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: child),
  ),
);

Widget _overlay({
  String? winner = 'player-2',
  String? actor = 'player-1',
  GameOutcomeConditionView condition = GameOutcomeConditionView.score,
  VoidCallback? onExit,
  Map<String, int> scores = const {'player-1': 120, 'player-2': 420},
}) => MatchOutcomeOverlay(
  outcome: GameOutcomeView(
    condition: condition,
    winnerPlayerId: winner,
    scoreByPlayerId: scores,
  ),
  actorPlayerId: actor,
  playerNames: const {'player-1': 'Aleksandra', 'player-2': 'Tomasz'},
  progress: _progress,
  onReturnToMenu: onExit ?? () {},
);

final _progress = PlayerVictoryView(
  status: VictoryStatusView.empty,
  conquestEnabled: true,
  dominationEnabled: true,
  dominationRequiredControlPercent: 60,
  dominationRequiredHoldTurns: 5,
  culturalEnabled: true,
  culturalRequiredArtifacts: 6,
  culturalRequiredHoldTurns: 5,
  scoreFallbackEnabled: true,
  turnLimit: 100,
  remainingTurns: 0,
  scoreByPlayerId: const {},
  domination: const [
    DominationVictoryProgressView(
      playerId: 'player-2',
      controlledPassableHexes: 57,
      totalPassableHexes: 100,
      holdTurns: 3,
    ),
  ],
  ownCultural: const CulturalVictoryProgressView(
    uniqueStoredArtifacts: 5,
    holdTurns: 4,
  ),
  mapObjectives: const [],
);
