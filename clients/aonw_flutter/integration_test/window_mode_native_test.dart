import 'dart:convert';

import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/application/window_settings.dart';
import 'package:aonw_flutter/features/settings/application/window_settings_coordinator.dart';
import 'package:aonw_flutter/features/settings/infrastructure/platform_game_window.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/window_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';

import '../test/support/map_test_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'changes the native window and resets without replacing the route',
    (tester) async {
      final window = PlatformGameWindow();
      expect(window.isSupported, isTrue);
      final original = await window.readMode();
      final store = _Store();
      final controller = WindowSettingsController(
        WindowSettingsCoordinator(window: window, store: store),
      );
      try {
        await windowManager.show();
        await windowManager.focus();
        await tester.pumpWidget(
          AonwApp(
            mapController: MapPresentationController(
              capabilities: testGameSessionCapabilities(
                FakeGameSession.success(testMapScene()),
              ),
            ),
            settingsController: ClientSettingsController.ephemeral(),
            windowSettingsController: controller,
            locale: const Locale('en'),
            initialRoute: AonwRoute.settings,
          ),
        );
        await _settle(tester, controller, WindowMode.fullscreen);
        expect(await window.readMode(), WindowMode.fullscreen);
        expect(store.saved, isEmpty);
        final field = find.byKey(const ValueKey('window-mode-setting'));
        final navigator = Navigator.of(tester.element(field));
        await _reveal(tester, field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Windowed').last);
        await _settle(tester, controller, WindowMode.windowed);
        expect(await window.readMode(), WindowMode.windowed);
        expect(store.saved, [WindowMode.windowed]);
        expect(Navigator.of(tester.element(field)), same(navigator));
        final reset = find.byKey(const ValueKey('reset-settings'));
        await _reveal(tester, reset);
        await tester.tap(reset);
        await _settle(tester, controller, WindowMode.fullscreen);
        expect(await window.readMode(), WindowMode.fullscreen);
        expect(store.saved, [WindowMode.windowed, WindowMode.fullscreen]);
        expect(Navigator.of(tester.element(field)), same(navigator));
        expect(tester.takeException(), isNull);
        final report = {
          'modes': ['fullscreen', 'windowed', 'fullscreen'],
          'routePreserved': true,
        };
        binding.reportData = report;
        debugPrint(jsonEncode(report));
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await window.setMode(original);
      }
    },
  );
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> _settle(
  WidgetTester tester,
  WindowSettingsController controller,
  WindowMode mode,
) async {
  final timer = Stopwatch()..start();
  do {
    await tester.pump(const Duration(milliseconds: 100));
    if (timer.elapsed > const Duration(seconds: 20)) {
      fail('Window transition did not finish: ${controller.settings.failure}');
    }
  } while (controller.settings.isBusy || controller.settings.mode != mode);
  expect(controller.settings.failure, isNull);
  await tester.pumpAndSettle();
}

final class _Store implements WindowSettingsStore {
  final saved = <WindowMode>[];

  @override
  Future<WindowMode> load() async => WindowMode.fullscreen;

  @override
  Future<void> save(WindowMode mode) async => saved.add(mode);
}
