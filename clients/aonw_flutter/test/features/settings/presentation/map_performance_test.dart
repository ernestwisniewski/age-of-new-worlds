import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_performance_host.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/settings_screen.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets(
    'map zoom follows wheel input and route visibility without replacing the scene',
    (tester) async {
      final settings = ClientSettingsController.ephemeral();
      await settings.update(
        ClientSettings.defaults.copyWith(
          performance: const ClientPerformanceSettings(showMapZoom: true),
          automation: const ClientAutomationSettings(advanceActions: false),
        ),
      );
      final game = AonwFlameGame();
      final map = MapPresentationController(
        capabilities: testGameSessionCapabilities(
          FakeGameSession.success(testMapScene()),
        ),
      );
      await tester.pumpWidget(
        AonwApp(
          mapController: map,
          settingsController: settings,
          flameGameFactory: () => game,
          initialRoute: AonwRoute.map,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      final scene = game.world.debugScene;
      final before = game.zoom.value!;
      expect(find.text('${before.toStringAsFixed(2)}Z'), findsOneWidget);
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(
            find.byKey(const ValueKey('map-viewport')),
          ),
          scrollDelta: const Offset(0, -100),
        ),
      );
      await tester.pumpAndSettle();
      final after = game.zoom.value!;
      expect(after, greaterThan(before));
      expect(find.text('${after.toStringAsFixed(2)}Z'), findsOneWidget);
      expect(game.world.debugScene, same(scene));
      expect(game.paused, isTrue);
      await tester.tap(find.byKey(const ValueKey('open-settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('performance-counter')), findsNothing);
      Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.text('${after.toStringAsFixed(2)}Z'), findsOneWidget);
      expect(game.debugMountCount, 1);
      await settings.update(
        settings.settings.copyWith(
          performance: const ClientPerformanceSettings(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('performance-counter')), findsNothing);
      expect(game.paused, isTrue);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(game.debugDisposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('global indicators allow pointer input through their panel', (
    tester,
  ) async {
    final zoom = ValueNotifier<double?>(1.25);
    addTearDown(zoom.dispose);
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ClientPerformanceHost(
          settings: const ClientPerformanceSettings(showMapZoom: true),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: 160,
                  height: 100,
                  child: TextButton(
                    key: const ValueKey('under-counter'),
                    onPressed: () => presses++,
                    child: const Text('Underlying action'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final context = tester.element(find.byKey(const ValueKey('under-counter')));
    MapZoomScope.maybeOf(context)!.attach(Object(), zoom);
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('performance-counter'))),
    );
    await tester.pumpAndSettle();
    expect(presses, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
