part of 'replay_presentation_controller_test.dart';

void replayAudioTests() {
  testWidgets(
    'replay sounds observed commands and pauses behind another route',
    (tester) async {
      final session = _ReplaySession(observed: true, audio: true);
      final controller = ReplayPresentationController(
        session: session,
        viewerCapabilities: testGameSessionCapabilities(
          FakeGameSession.success(testMapScene()),
          cityPlanning: session,
        ),
        store: _ReplayStore(primary: 'valid'),
      );
      final settings = ClientSettingsController.ephemeral();
      final audio = RecordingGameAudio();
      final observer = RouteObserver<ModalRoute<void>>();
      final game = AonwFlameGame();
      addTearDown(controller.dispose);
      addTearDown(settings.dispose);
      await controller.openLatest();
      await tester.pumpWidget(
        GameAudioHost(
          settings: settings,
          settingsReady: Future<void>.value(),
          audio: audio,
          child: LocalizedTestApp(
            navigatorObservers: [observer],
            home: ReplayScreen(
              controller: controller,
              routeObserver: observer,
              flameGameFactory: () => game,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(audio.cues, isEmpty);
      controller.play();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(audio.cues, [GameSoundCue.attack]);
      final context = tester.element(find.byType(ReplayScreen));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('Covered replay')),
        ),
      );
      await tester.pumpAndSettle();
      expect(game.debugViewportActive, isFalse);
      expect((controller.state as ReplayReady).isPlaying, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(session.positions, [1]);
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(game.debugViewportActive, isTrue);
      expect(audio.cues, [GameSoundCue.attack]);
      controller.play();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(audio.cues, [GameSoundCue.attack, GameSoundCue.attack]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(game.debugViewportActive, isFalse);
      expect((controller.state as ReplayReady).isPlaying, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      controller.seek(0);
      await tester.pump();
      expect(
        audio.cues,
        hasLength(2),
        reason: 'a backward seek drops retained audio',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(game.debugDisposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
