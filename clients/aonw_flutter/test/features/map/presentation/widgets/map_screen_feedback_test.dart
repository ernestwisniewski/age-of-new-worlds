import 'package:aonw_flutter/features/artifacts/application/artifact_session_port.dart';
import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  testWidgets(
    'presents accepted artifact feedback through the shared map screen',
    (tester) async {
      const artifact = WorldArtifactView(
        id: 'artifact',
        kind: WorldArtifactKindView.heroSword,
        location: MapArtifactLocationView((col: 0, row: 0)),
      );
      final scene = testMapScene(
        units: [testVisibleUnit()],
        artifacts: const [artifact],
      );
      final session = FakeGameSession.success(
        scene,
        reachableResult: testReachableView(),
        artifactResult: ArtifactCommandResultView.accepted(
          player: _afterExcavation(scene.player),
        ),
      );
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
      addTearDown(controller.dispose);
      final game = AonwFlameGame();
      final screen = Scaffold(
        body: MapScreen(controller: controller, flameGameFactory: () => game),
      );
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        LocalizedTestApp(home: screen, locale: const Locale('pl')),
      );
      await tester.pumpAndSettle();
      controller.select((col: 0, row: 0));
      await tester.pumpAndSettle();
      controller.executeArtifactAction(
        const StartArtifactExcavationActionView(unitId: 'preview-commander'),
      );
      await tester.pump();
      await tester.pump();
      expect(session.artifactCommandCalls, 1);
      final layer = game.world.eventFeedbackLayer;
      expect(layer.debugActiveBurstCount, 1);
      expect(layer.debugTextCount, 1);
      game.update(0.13);
      expect(layer.debugVisibleTextCount, 1);
      await tester.pumpWidget(LocalizedTestApp(home: screen));
      await tester.pump();
      expect(layer.debugTextCount, 1);
      game.skipEffects();
      expect(layer.debugTextImageCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

PlayerMapView _afterExcavation(PlayerMapView source) => PlayerMapView(
  actorPlayerId: source.actorPlayerId,
  stamp: testSessionStamp(revision: 1),
  turnMode: source.turnMode,
  participants: source.participants,
  fog: source.fog,
  economy: source.economy,
  research: source.research,
  victory: source.victory,
  turnView: source.turnView,
  diplomacy: source.diplomacy,
  units: [testVisibleUnit(excavatingArtifactId: 'artifact')],
  artifacts: const [
    WorldArtifactView(
      id: 'artifact',
      kind: WorldArtifactKindView.heroSword,
      location: ExcavationArtifactLocationView(
        unitId: 'preview-commander',
        coordinate: (col: 0, row: 0),
        remainingTurns: 2,
      ),
    ),
  ],
  recentFeedback: const [
    MapParticleCueView(
      identity: (revision: 1, eventIndex: 0),
      coordinate: (col: 0, row: 0),
      kind: MapParticleKindView.technologyResearched,
      colorValue: 0xffffd166,
    ),
    MapFloatingTextCueView(
      identity: (revision: 1, eventIndex: 0),
      coordinate: (col: 0, row: 0),
      content: MapMessageTextView(
        MapFeedbackMessageView.artifactExcavationStarted,
      ),
      colorValue: 0xffffd166,
      style: MapFloatingTextStyleView.bubble,
      anchor: MapUnitTextAnchorView('preview-commander'),
      delay: Duration(milliseconds: 120),
    ),
  ],
);
