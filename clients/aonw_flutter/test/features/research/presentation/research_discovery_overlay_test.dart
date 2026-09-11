import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/research/presentation/research_discovery_overlay.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../discovery_fixture.dart';

void main() {
  final frames = SpriteFrames.createScope();
  tearDownAll(frames.dispose);
  setUpAll(() async {
    await frames.preload([
      const SpriteFrameId("technology.mining"),
      const SpriteFrameId("technology.agriculture"),
    ]);
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
  for (final (language, size) in [
    ('pl', const Size(390, 844)),
    ('de', const Size(1024, 768)),
    ('en', const Size(1440, 900)),
  ]) {
    testWidgets('$language discovery is responsive with no idle frames', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final settings = ClientSettingsController.ephemeral();
      addTearDown(settings.dispose);
      final session = Object();
      await tester.pumpWidget(
        _app(discoveryPlayer(), session, settings, language: language),
      );
      await tester.pumpWidget(
        _app(
          discoveryPlayer(revision: 1, discoveries: [firstDiscovery]),
          session,
          settings,
          language: language,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('research-discovery-panel')),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(const ValueKey('discovery-golden')),
        matchesGoldenFile('goldens/research_discovery_$language.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.tap(find.byIcon(Icons.minimize));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('research-discovery-panel')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('restore-research-discovery')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('research-discovery-panel')),
        findsNothing,
      );
    });
  }
  testWidgets('six languages fit a landscape phone at 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final settings = ClientSettingsController.ephemeral();
    addTearDown(settings.dispose);
    for (final language in ['pl', 'en', 'de', 'fr', 'es', 'nl']) {
      final session = Object();
      await tester.pumpWidget(
        _app(
          discoveryPlayer(),
          session,
          settings,
          language: language,
          scale: 2,
        ),
      );
      await tester.pumpWidget(
        _app(
          discoveryPlayer(revision: 1, discoveries: [firstDiscovery]),
          session,
          settings,
          language: language,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byIcon(Icons.minimize));
      await tester.tap(find.byIcon(Icons.minimize));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'gamepad owns popup and suppress persists without a research command',
    (tester) async {
      final settings = ClientSettingsController.ephemeral();
      addTearDown(settings.dispose);
      final navigation = MapGamepadNavigation(
        onOwnerChanged: () {},
        returnToMap: () {},
      );
      addTearDown(navigation.dispose);
      final session = Object();
      Widget app(PlayerMapView player) => MapGamepadNavigationScope(
        navigation: navigation,
        child: _app(player, session, settings),
      );
      await tester.pumpWidget(app(discoveryPlayer()));
      await tester.pumpWidget(
        app(discoveryPlayer(revision: 1, discoveries: [firstDiscovery])),
      );
      await tester.pumpAndSettle();
      expect(navigation.hasOpenPanel, isTrue);
      expect(find.text('resourceVisibility: Iron'), findsNothing);
      expect(find.textContaining('Iron'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(navigation.handleCommand(MapInputCommand.cancel), isTrue);
      await tester.pumpAndSettle();
      expect(settings.settings.showResearchDiscoveries, isFalse);
      expect(
        find.byKey(const ValueKey('research-discovery-panel')),
        findsNothing,
      );
      expect(navigation.hasOpenPanel, isFalse);
    },
  );
}

Widget _app(
  PlayerMapView player,
  Object session,
  ClientSettingsController settings, {
  String language = 'en',
  double scale = 1.3,
}) => ClientSettingsScope(
  controller: settings,
  child: MaterialApp(
    theme: AonwTheme.dark,
    locale: Locale(language),
    localizationsDelegates: AonwLocalizations.localizationsDelegates,
    supportedLocales: AonwLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: RepaintBoundary(
        key: const ValueKey('discovery-golden'),
        child: Scaffold(
          body: Stack(
            children: [
              ResearchDiscoveryOverlay(
                player: player,
                session: session,
                options: discoveryOptions(player),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
