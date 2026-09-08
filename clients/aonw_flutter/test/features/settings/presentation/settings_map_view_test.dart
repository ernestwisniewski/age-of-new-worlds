import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
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
      '${locale.languageCode} default map view fits, persists and resets',
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
        final option = find.byKey(const ValueKey('preferred-map-view-setting'));
        final navigator = Navigator.of(tester.element(option));
        expect(_value(tester, option), MapViewMode.graphic);
        await _toggle(tester, option);
        expect(store.value.preferredMapViewMode, MapViewMode.tile);
        expect(_value(tester, option), MapViewMode.tile);
        expect(Navigator.of(tester.element(option)), same(navigator));
        expect(tester.takeException(), isNull);
        final reset = find.byKey(const ValueKey('reset-settings'));
        await Scrollable.ensureVisible(tester.element(reset), alignment: 0.5);
        await _frames(tester);
        await tester.tap(reset);
        await _frames(tester);
        expect(store.value.preferredMapViewMode, MapViewMode.graphic);
        expect(_value(tester, option), MapViewMode.graphic);
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

MapViewMode? _value(WidgetTester tester, Finder setting) =>
    tester.widget<DropdownButton<MapViewMode>>(setting).value;

Future<void> _toggle(WidgetTester tester, Finder setting) async {
  await Scrollable.ensureVisible(tester.element(setting), alignment: 0.5);
  await _frames(tester);
  await tester.tap(setting);
  await _frames(tester);
  final l10n = AonwLocalizations.of(tester.element(setting));
  await tester.tap(find.text(l10n.mapViewModeTiles).last);
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
