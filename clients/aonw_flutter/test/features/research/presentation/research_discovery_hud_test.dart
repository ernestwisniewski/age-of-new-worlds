import 'package:aonw_flutter/features/diplomacy/application/diplomacy_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_hud_panels.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/research/application/research_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';
import '../discovery_fixture.dart';

void main() {
  testWidgets(
    'closing discovery preserves required research and sends no command',
    (tester) async {
      final scene = testMapScene();
      final session = FakeGameSession.success(scene);
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
      addTearDown(controller.dispose);
      Widget app(bool discovered) {
        final player = discoveryPlayer(
          revision: discovered ? 1 : 0,
          pendingAction: const PendingResearchSelectionView(),
          discoveries: discovered ? [firstDiscovery] : [],
        );
        return LocalizedTestApp(
          home: Scaffold(
            body: MapHudPanels(
              scene: scene.withPlayer(player),
              controller: controller,
              research: ResearchState(options: discoveryOptions(player)),
              diplomacy: const DiplomacyState(),
            ),
          ),
        );
      }

      await tester.pumpWidget(app(false));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('close-research')), findsOneWidget);
      await tester.pumpWidget(app(true));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('research-discovery-panel')),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('research-discovery-panel')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('close-research')), findsOneWidget);
      expect(session.researchCancellationCalls, 0);
      expect(session.researchCommandCalls, 0);
      expect(session.endTurnCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
