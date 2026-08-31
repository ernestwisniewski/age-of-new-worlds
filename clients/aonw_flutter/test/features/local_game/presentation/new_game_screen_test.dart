import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets('starts hotseat with two humans after a review step', (
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
    ]);
    expect(setup.participants.last.ai, isNull);
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

    await tester.tap(find.text('Computer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('continue-to-summary')),
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-summary')));
    await tester.pumpAndSettle();

    expect(find.text('Single player'), findsOneWidget);
  });
}
