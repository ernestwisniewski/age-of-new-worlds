import 'package:aonw_flutter/features/map/application/game_session_capabilities.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  for (final finished in [false, true]) {
    testWidgets(
      'viewer HUD keeps queries and disables writes (finished: $finished)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final scene = testMapScene(
          pendingAction: const PendingResearchSelectionView(),
          outcome: finished
              ? GameOutcomeView(
                  condition: GameOutcomeConditionView.score,
                  winnerPlayerId: 'preview-player',
                  scoreByPlayerId: const {'preview-player': 10},
                )
              : null,
        );
        final session = FakeGameSession.success(scene);
        final controller = MapPresentationController(
          capabilities: testGameSessionCapabilities(
            session,
          ).forViewer(map: session),
        );
        addTearDown(controller.dispose);
        await controller.load();
        await tester.pumpWidget(
          LocalizedTestApp(
            home: MapScreen(controller: controller, autoLoad: false),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('save-game')), findsNothing);
        expect(find.byKey(const ValueKey('turn-hud')), findsNothing);
        expect(
          find.byKey(const ValueKey('research-selection-required')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('close-research')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('open-research')));
        await tester.pumpAndSettle();
        final choices = find.byWidgetPredicate(
          (widget) =>
              widget is FilledButton &&
              widget.key is ValueKey &&
              widget.key.toString().contains('select-technology'),
        );
        expect(choices, findsWidgets);
        for (final choice in tester.widgetList<FilledButton>(choices)) {
          expect(choice.onPressed, isNull);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('close-research')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('resource-gold')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('resource-details-gold')),
          findsOneWidget,
        );
        expect(session.researchCommandCalls, 0);
        expect(session.researchCancellationCalls, 0);
        expect(session.endTurnCalls, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
