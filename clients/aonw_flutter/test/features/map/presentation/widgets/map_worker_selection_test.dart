import 'package:aonw_flutter/features/audio/presentation/game_audio_host.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/flame_map_viewport.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/recording_game_audio.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets(
    'worker selection closes HUD panels and cancels through keyboard and gamepad',
    (tester) async {
      final audio = RecordingGameAudio();
      final settings = ClientSettingsController.ephemeral();
      final input = TestMapInputSource();
      final game = AonwFlameGame();
      final session = _session();
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
      addTearDown(settings.dispose);
      addTearDown(controller.dispose);
      addTearDown(input.close);
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        GameAudioHost(
          settings: settings,
          settingsReady: Future<void>.value(),
          audio: audio,
          child: LocalizedTestApp(
            home: MapScreen(
              controller: controller,
              inputSource: input,
              flameGameFactory: () => game,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectUnit('preview-commander');
      await tester.pumpAndSettle();
      expect(audio.cues, isEmpty);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(game.world.actionPaletteLayer.debugView, isNull);
      await tester.tap(find.byKey(const ValueKey('open-objectives')));
      await tester.pump();
      expect(find.byKey(const ValueKey('close-objectives')), findsOneWidget);
      controller.setWorkerActionsOpen(true);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('close-objectives')), findsNothing);
      expect(audio.cues, [
        GameSoundCue.uiPanelOpen,
        GameSoundCue.uiPanelClose,
        GameSoundCue.uiPanelOpen,
      ]);
      final option =
          game.world.actionPaletteLayer.debugOptionRects.single.center;
      await _tapWorld(tester, game, option);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('worker-improvement-confirm')),
        findsOneWidget,
      );
      final viewport = tester.widget<FlameMapViewport>(
        find.byType(FlameMapViewport),
      );
      viewport.focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNothing);
      expect(
        (controller.state as GameSessionReady).interaction.selectedUnitId,
        'preview-commander',
      );
      await tester.tap(find.byKey(const ValueKey('worker-actions-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ChoiceChip));
      await tester.pumpAndSettle();
      input.add(MapInputCommand.cancel);
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNothing);
      expect(session.workerCommandCalls, 0);
      expect(audio.cues, [
        GameSoundCue.uiPanelOpen,
        GameSoundCue.uiPanelClose,
        GameSoundCue.uiPanelOpen,
        GameSoundCue.uiPanelOpen,
      ]);
      await tester.tap(find.byKey(const ValueKey('worker-actions-toggle')));
      await tester.pumpAndSettle();
      final bounds = game.world.actionPaletteLayer.debugBounds!;
      await _tapWorld(tester, game, bounds.center + const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNothing);
      expect(game.world.actionPaletteLayer.debugView, isNull);
      await tester.tap(find.byKey(const ValueKey('worker-actions-toggle')));
      await tester.pumpAndSettle();
      expect(game.world.actionPaletteLayer.debugBounds, isNotNull);
      input.add(MapInputCommand.cancel);
      await tester.pumpAndSettle();
      input.add(MapInputCommand.cancel);
      await tester.pumpAndSettle();
      expect(
        (controller.state as GameSessionReady).interaction.selectedUnitId,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

FakeGameSession _session() {
  final worker = testVisibleUnit(kind: VisibleUnitKind.worker);
  return FakeGameSession.success(
    testMapScene(units: [worker]),
    reachableResult: testReachableView(unitId: worker.id),
    workerOptionsResult: WorkerOptionsView(
      stamp: testSessionStamp(),
      unitId: worker.id,
      coordinate: worker.coordinate,
      improvements: const [
        WorkerImprovementOptionView(
          improvement: FieldImprovementKind.farm,
          buildTurns: 3,
        ),
      ],
      canAssign: false,
      canBuildRoad: false,
      automation: null,
    ),
  );
}

Future<void> _tapWorld(
  WidgetTester tester,
  AonwFlameGame game,
  Offset point,
) async {
  final flat = game.mapCamera.debugTransform!.worldToScreen((
    x: point.dx,
    y: point.dy,
  ));
  final projected = game.mapCamera.projectScreenPoint(flat);
  final origin = tester.getTopLeft(find.byKey(const ValueKey('map-viewport')));
  await tester.tapAt(origin + Offset(projected.x, projected.y));
}
