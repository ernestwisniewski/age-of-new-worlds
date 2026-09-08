import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_activity_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';
import '../../../support/test_map_input_source.dart';

void main() {
  for (final inputMode in ['pointer', 'keyboard', 'gamepad']) {
    testWidgets('ends a turn from reduced-motion HUD using $inputMode', (
      tester,
    ) async {
      final nextPlayer = PlayerMapView.preview(
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
        turn: 2,
        pendingAction: null,
        units: const [],
      );
      final session = FakeGameSession.success(
        testMapScene(),
        turnResult: TurnCommandResultView.accepted(
          player: nextPlayer,
          activities: const [
            TurnActivityView(
              identity: TurnActivityIdentityView(revision: 1, eventIndex: 0),
              kind: TurnActivityKindView.turnEnded,
            ),
          ],
          evidence: TurnKernelEvidenceView(
            processors: const ['movement'],
            foundedCityIds: const [],
            combatExecutionCount: 0,
            resetUnitIds: const [],
            movementExecutionCount: 0,
            invalidatedOrderUnitIds: const [],
            finishedAutoExploreUnitIds: const [],
          ),
        ),
      );
      final input = TestMapInputSource();
      addTearDown(input.close);
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(const Size(420, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        LocalizedTestApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.6),
            ),
            child: MapScreen(controller: controller, inputSource: input),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final endTurn = find.byKey(const ValueKey('end-turn'));
      expect(endTurn, findsOneWidget);
      await tester.ensureVisible(endTurn);
      switch (inputMode) {
        case 'keyboard':
          Focus.of(tester.element(endTurn)).requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        case 'gamepad':
          input.addContinuous(const MapGamepadInput(hudFocusNext: true));
          await tester.pump();
          input.addContinuous(MapGamepadInput.idle);
          await tester.pump();
          input.addContinuous(const MapGamepadInput(activate: true));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          input.addContinuous(MapGamepadInput.idle);
        default:
          await tester.tap(endTurn);
      }
      await tester.pumpAndSettle();

      expect(session.endTurnCalls, 1);
      expect(find.text('Turn updated'), findsWidgets);
      expect(find.text('TURN 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
