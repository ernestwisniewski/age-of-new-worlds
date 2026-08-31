import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/objectives/presentation/objective_overlay.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('shows only authored objective requirements from the map', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        _ObjectiveHarness(
          objectives: const [
            MapObjectiveView(
              id: 'holy-site-1',
              type: MapObjectiveType.holySite,
              coordinate: (col: 2, row: 3),
              requiredHoldTurns: 4,
              victoryPoints: 7,
              goldPerTurn: 2,
            ),
          ],
          outcome: _ongoing(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-objectives')));
    await tester.pump();

    expect(find.text('Strategic objectives'), findsOneWidget);
    expect(find.text('Holy site'), findsOneWidget);
    expect(
      find.text(
        'Hex 2, 3\nRequired hold turns: 4 · Victory points: 7 · Gold per turn: 2',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Current hold'), findsNothing);
    expect(find.textContaining('7 /'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('presents terminal outcome as a blocking localized live region', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        _ObjectiveHarness(
          objectives: const [],
          outcome: GameOutcomeView(
            condition: GameOutcomeConditionView.score,
            winnerPlayerId: 'player-2',
            scoreByPlayerId: const {'player-2': 13, 'player-1': 9},
          ),
        ),
        locale: const Locale('pl'),
      ),
    );

    expect(find.byKey(const ValueKey('terminal-outcome')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('terminal-outcome')),
        matching: find.byType(ModalBarrier),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Rozgrywka zakończona'), findsOneWidget);
    expect(find.text('Zwycięstwo punktowe'), findsOneWidget);
    expect(find.text('Zwycięzca: player-2'), findsOneWidget);
    expect(find.text('player-1: 9'), findsOneWidget);
    expect(find.text('player-2: 13'), findsOneWidget);
    expect(find.byKey(const ValueKey('open-objectives')), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

GameOutcomeView _ongoing() => GameOutcomeView(
  condition: GameOutcomeConditionView.ongoing,
  winnerPlayerId: null,
  scoreByPlayerId: const {},
);

Widget _app(Widget child, {Locale locale = const Locale('en')}) =>
    LocalizedTestApp(
      locale: locale,
      home: Scaffold(body: child),
    );

final class _ObjectiveHarness extends StatefulWidget {
  const _ObjectiveHarness({required this.objectives, required this.outcome});

  final List<MapObjectiveView> objectives;
  final GameOutcomeView outcome;

  @override
  State<_ObjectiveHarness> createState() => _ObjectiveHarnessState();
}

final class _ObjectiveHarnessState extends State<_ObjectiveHarness> {
  var _open = false;

  @override
  Widget build(BuildContext context) => ObjectiveOverlay(
    objectives: widget.objectives,
    outcome: widget.outcome,
    open: _open,
    onOpenChanged: (value) => setState(() => _open = value),
  );
}
