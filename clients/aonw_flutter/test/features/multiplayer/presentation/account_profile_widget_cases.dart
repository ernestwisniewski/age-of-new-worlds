part of 'multiplayer_screen_test.dart';

void accountProfileWidgetCases() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Cinzel')..addFont(
          rootBundle.load('assets/fonts/Cinzel-VariableFont_wght.ttf'),
        ))
        .load();
    await (FontLoader(
      'Lato',
    )..addFont(rootBundle.load('assets/fonts/Lato-Regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final locale in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    testWidgets('$locale profile loads lazily and preserves a rejected draft', (
      tester,
    ) async {
      final width = switch (locale) {
        'en' => 1200.0,
        'de' => 800.0,
        _ => 360.0,
      };
      await tester.binding.setSurfaceSize(Size(width, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = _Session();
      final controller = MultiplayerController(
        MultiplayerCoordinator(session: session, documents: _Documents()),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: Locale(locale),
          theme: AonwTheme.dark,
          home: RepaintBoundary(
            key: const ValueKey('profile-golden'),
            child: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      children: [AccountProfileSettings(account: controller)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(session.profileReads, 0);
      await tester.tap(find.byKey(const ValueKey('account-profile-settings')));
      await tester.pumpAndSettle();
      expect(session.profileReads, 1);
      if (['en', 'de', 'pl'].contains(locale)) {
        await expectLater(
          find.byKey(const ValueKey('profile-golden')),
          matchesGoldenFile('goldens/account_profile_$locale.png'),
        );
      }
      final field = find.byKey(const ValueKey('profile-display-name'));
      expect(tester.widget<TextField>(field).controller!.text, 'Original');
      await tester.enterText(field, 'Taken');
      session.profileFailure = const MultiplayerSessionException(
        code: 'display_name_taken',
        message: 'Taken',
      );
      await tester.tap(find.byKey(const ValueKey('save-profile')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, 'Taken');
      expect(session.profileName, 'Original');
      session.profileFailure = null;
      await tester.enterText(field, ' New name ');
      await tester.tap(find.byKey(const ValueKey('save-profile')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, 'New name');
      expect(session.profileName, 'New name');
      expect(session.kickCount, 0);
      expect(session.resignCount, 0);
      await controller.signOut();
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(find.text('New name'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
