import 'dart:async';

import 'package:aonw_flutter/features/audio/presentation/game_audio_host.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/delayed_movement_session.dart';
import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';
import '../../../../support/recording_game_audio.dart';
import '../../../../support/test_map_input_source.dart';

void main() {
  testWidgets(
    'pointer keyboard and gamepad share audio and covering the map cancels pending audio',
    (tester) async {
      final audio = RecordingGameAudio();
      final settings = ClientSettingsController.ephemeral();
      final input = TestMapInputSource();
      final movement = DelayedMovementSession();
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(
          FakeGameSession.success(testMapScene(units: [testVisibleUnit()])),
          movement: movement,
        ),
      );
      final observer = RouteObserver<ModalRoute<void>>();
      final game = AonwFlameGame();
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
            navigatorObservers: [observer],
            home: MapScreen(
              controller: controller,
              inputSource: input,
              routeObserver: observer,
              flameGameFactory: () => game,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hex = game.debugScreenForHex((col: 2, row: 1))!;
      final viewport = find.byKey(const ValueKey('map-viewport'));
      await tester.tapAt(tester.getTopLeft(viewport) + Offset(hex.x, hex.y));
      await tester.pump();
      expect(audio.cues, [GameSoundCue.mapTileSelect]);
      controller.hover((col: 2, row: 0));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      input.add(MapInputCommand.activate);
      await tester.pump();
      expect(audio.cues, List.filled(3, GameSoundCue.mapTileSelect));
      controller.selectUnit('preview-commander');
      await tester.pumpAndSettle();
      controller.select((col: 1, row: 0));
      await tester.pump();
      final context = tester.element(find.byType(MapScreen));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('Covered map')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(game.debugViewportActive, isFalse);
      Navigator.of(context).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(game.debugViewportActive, isTrue);
      movement.requests.single.complete(testRoutePlanView());
      await tester.pump();
      await tester.pump();
      expect(audio.cues, hasLength(3));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'accepted movement reaches application audio once through Flame',
    (tester) async {
      final audio = RecordingGameAudio();
      final settings = ClientSettingsController.ephemeral();
      final scene = testMapScene(units: [testVisibleUnit()]);
      final session = FakeGameSession.success(
        scene,
        reachableResult: testReachableView(),
        routeResult: testRoutePlanView(),
        moveResult: MoveUnitResultView.accepted(
          player: _moved(scene.player),
          execution: testMoveUnitExecutionView(),
        ),
      );
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
      final game = AonwFlameGame();
      addTearDown(settings.dispose);
      addTearDown(controller.dispose);
      final settingsReady = Future<void>.value();
      final screen = MapScreen(
        controller: controller,
        flameGameFactory: () => game,
      );
      Widget app(Locale locale) => GameAudioHost(
        settings: settings,
        settingsReady: settingsReady,
        audio: audio,
        child: LocalizedTestApp(home: screen, locale: locale),
      );
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      expect(audio.cues, isEmpty);
      controller.select((col: 0, row: 0));
      await tester.pumpAndSettle();
      controller.select((col: 1, row: 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      audio.cues.clear();
      controller.confirmMove();
      await tester.pump();
      await tester.pump();
      expect(audio.cues, [GameSoundCue.walk]);
      await tester.pumpWidget(app(const Locale('pl')));
      await tester.pump();
      expect(audio.cues, [GameSoundCue.walk]);
      game.skipEffects();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(game.debugDisposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}

PlayerMapView _moved(PlayerMapView source) => PlayerMapView(
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
  units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
  recentFeedback: const [
    MapSoundCueView(
      identity: (revision: 1, eventIndex: 0),
      coordinate: (col: 1, row: 0),
      sound: MapSoundKindView.movement,
    ),
  ],
);
