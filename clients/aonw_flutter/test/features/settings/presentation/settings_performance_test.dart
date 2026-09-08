import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/settings_screen.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  for (final locale in AonwLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} performance options fit, change independently and reset',
      (tester) async {
        final store = _SettingsStore();
        final settings = ClientSettingsController(store: store);
        final map = MapPresentationController(
          capabilities: testGameSessionCapabilities(
            FakeGameSession.success(testMapScene()),
          ),
        );
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          AonwApp(
            mapController: map,
            settingsController: settings,
            initialRoute: AonwRoute.settings,
            locale: locale,
          ),
        );
        await _frames(tester);
        final actions = find.byKey(const ValueKey('show-fps-setting'));
        final endTurn = find.byKey(const ValueKey('show-map-zoom-setting'));
        final navigator = Navigator.of(tester.element(actions));
        expect(find.byKey(const ValueKey('performance-counter')), findsNothing);
        expect(_value(tester, actions), isFalse);
        expect(_value(tester, endTurn), isFalse);
        await _toggle(tester, actions);
        expect(find.textContaining(RegExp(r'^\d+ FPS$')), findsOneWidget);
        expect(
          store.value.performance,
          const ClientPerformanceSettings(showFps: true),
        );
        await _toggle(tester, endTurn);
        expect(
          store.value.performance,
          const ClientPerformanceSettings(showFps: true, showMapZoom: true),
        );
        expect(_value(tester, actions), isTrue);
        expect(_value(tester, endTurn), isTrue);
        expect(Navigator.of(tester.element(actions)), same(navigator));
        expect(tester.takeException(), isNull);
        final reset = find.byKey(const ValueKey('reset-settings'));
        await Scrollable.ensureVisible(tester.element(reset), alignment: 0.5);
        await _frames(tester);
        await tester.tap(reset);
        await _frames(tester);
        expect(store.value.performance, const ClientPerformanceSettings());
        expect(find.byKey(const ValueKey('performance-counter')), findsNothing);
        expect(_value(tester, actions), isFalse);
        expect(_value(tester, endTurn), isFalse);
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

bool _value(WidgetTester tester, Finder setting) => tester
    .widget<SwitchListTile>(
      find.descendant(of: setting, matching: find.byType(SwitchListTile)),
    )
    .value;

Future<void> _toggle(WidgetTester tester, Finder setting) async {
  await Scrollable.ensureVisible(tester.element(setting), alignment: 0.5);
  await _frames(tester);
  await tester.tap(setting);
  await _frames(tester);
}

final class _SettingsStore implements ClientSettingsStore {
  ClientSettings value = ClientSettings.defaults;

  @override
  Future<ClientSettings> load() async => value;

  @override
  Future<void> save(ClientSettings settings) async {
    value = settings;
  }
}

Future<void> _frames(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
