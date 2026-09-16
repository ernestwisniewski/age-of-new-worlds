part of 'multiplayer_screen_test.dart';

void lobbyPresenceWidgetCases() {
  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    testWidgets('lobby connection states fit $language at 200%', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final session = _PresenceSession();
      final coordinator = MultiplayerCoordinator(
        session: session,
        documents: _Documents(),
      );
      final controller = MultiplayerController(coordinator);
      addTearDown(controller.dispose);
      await controller.initialize();
      await coordinator.createMatch();
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: Locale(language),
          theme: AonwTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: MultiplayerScreen(controller: controller),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final ready = find.byKey(const ValueKey('multiplayer-ready'));
      expect(tester.widget<OutlinedButton>(ready).onPressed, isNull);
      session.frames.addError(
        const MultiplayerSessionException(
          code: 'connection_interrupted',
          message: 'Offline',
          retryable: true,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.widget<OutlinedButton>(ready).onPressed, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(session.cancelled, isTrue);
    });
  }
}

final class _PresenceSession extends _Session
    implements MultiplayerLobbyWatchPort {
  var cancelled = false;
  late final frames = StreamController<MultiplayerMatchLobbyView>(
    onCancel: () => cancelled = true,
  );

  @override
  Stream<MultiplayerMatchLobbyView> watchLobby(String matchId) => frames.stream;
}
