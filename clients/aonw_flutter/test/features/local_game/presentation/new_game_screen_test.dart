import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets('starts a capacity-bound hotseat after a review step', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );

    await tester.pumpWidget(AonwApp(mapController: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('hotseat')));
    await tester.tap(find.byKey(const ValueKey('hotseat')));
    await tester.pumpAndSettle();

    expect(find.text('Play in hotseat mode'), findsOneWidget);
    final control = tester.widget<SegmentedButton<LocalPlayerControlView>>(
      find.byKey(const ValueKey('opponent-control')),
    );
    expect(control.selected, {LocalPlayerControlView.human});
    expect(find.byKey(const ValueKey('turn-mode-selector')), findsNothing);
    expect(find.text('Opponent 3'), findsOneWidget);
    expect(find.text('Victory paths'), findsOneWidget);
    expect(find.text('From settlement to empire'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('continue-to-summary')),
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-summary')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-game-review')), findsOneWidget);
    expect(find.text('Hotseat'), findsWidgets);
    expect(find.textContaining('Player 2'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('start-game')));
    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pumpAndSettle();

    final setup = session.lastLocalMatchSetup!;
    expect(setup.participants.map((participant) => participant.control), [
      LocalPlayerControlView.human,
      LocalPlayerControlView.human,
      LocalPlayerControlView.ai,
      LocalPlayerControlView.ai,
    ]);
    expect(setup.participants[1].ai, isNull);
    expect(
      setup.participants.skip(2).map((participant) => participant.ai),
      everyElement(isNotNull),
    );
    expect(setup.turnMode, LocalTurnModeView.sequential);
    expect(find.byKey(const ValueKey('map-viewport')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('infers single player when the hotseat rival becomes AI', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(testMapScene()),
      ),
    );

    await tester.pumpWidget(AonwApp(mapController: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('hotseat')));
    await tester.tap(find.byKey(const ValueKey('hotseat')));
    await tester.pumpAndSettle();

    final firstOpponent = tester
        .widget<SegmentedButton<LocalPlayerControlView>>(
          find.byKey(const ValueKey('opponent-control')),
        );
    firstOpponent.onSelectionChanged!({LocalPlayerControlView.ai});
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('continue-to-summary')),
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-summary')));
    await tester.pumpAndSettle();

    expect(find.text('Single player'), findsOneWidget);
  });

  testWidgets('fills every Dravonia seat with a distinct single-player AI', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );

    await tester.pumpWidget(AonwApp(mapController: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('single-player')));
    await tester.pumpAndSettle();
    await _selectScenario(tester, LocalGameScenarioView.dravonia, 'Dravonia');

    expect(find.text('Opponent 3'), findsOneWidget);
    expect(find.textContaining('40 × 30 · 4 civilizations'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('continue-to-summary')),
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-summary')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('start-game')));
    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pumpAndSettle();

    final setup = session.lastLocalMatchSetup!;
    expect(setup.assets.scenarioDocument, endsWith('dravonia_local.json'));
    expect(setup.participants.map((participant) => participant.id), [
      'player-1',
      'player-2',
      'player-3',
      'player-4',
    ]);
    expect(
      setup.participants.skip(1).map((participant) => participant.control),
      everyElement(LocalPlayerControlView.ai),
    );
    expect(
      setup.participants.map((participant) => participant.country).toSet(),
      hasLength(4),
    );
    expect(setup.turnMode, LocalTurnModeView.sequential);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('lets hotseat configure every seat as human or computer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );

    await tester.pumpWidget(AonwApp(mapController: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('hotseat')));
    await tester.tap(find.byKey(const ValueKey('hotseat')));
    await tester.pumpAndSettle();
    final thirdSeat = tester.widget<SegmentedButton<LocalPlayerControlView>>(
      find.byKey(const ValueKey(('opponent-control', 1))),
    );
    expect(thirdSeat.selected, {LocalPlayerControlView.ai});
    thirdSeat.onSelectionChanged!({LocalPlayerControlView.human});
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('continue-to-summary')),
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-summary')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('start-game')));
    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pumpAndSettle();

    final setup = session.lastLocalMatchSetup!;
    expect(setup.participants.map((participant) => participant.control), [
      LocalPlayerControlView.human,
      LocalPlayerControlView.human,
      LocalPlayerControlView.human,
      LocalPlayerControlView.ai,
    ]);
    expect(setup.turnMode, LocalTurnModeView.sequential);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _selectScenario(
  WidgetTester tester,
  LocalGameScenarioView scenario,
  String label,
) async {
  await tester.ensureVisible(
    find.byKey(ValueKey(('scenario', LocalGameScenarioView.starterDuel))),
  );
  await tester.tap(
    find.byKey(ValueKey(('scenario', LocalGameScenarioView.starterDuel))),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
  expect(find.byKey(ValueKey(('scenario', scenario))), findsOneWidget);
}
