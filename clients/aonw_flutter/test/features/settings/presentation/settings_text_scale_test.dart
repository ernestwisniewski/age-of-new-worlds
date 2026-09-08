import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  for (final (locale, largeLabel) in const [
    ('en', 'Extra large (130%)'),
    ('pl', 'Bardzo duży (130%)'),
    ('fr', 'Très grand (130%)'),
    ('de', 'Sehr groß (130%)'),
    ('es', 'Muy grande (130%)'),
  ]) {
    testWidgets('changes text size live, retains route and resets in $locale', (
      tester,
    ) async {
      final h = await _Harness.mount(tester, locale: locale);
      final field = find.byKey(const ValueKey('text-scale-setting'));
      final navigator = Navigator.of(tester.element(field));
      await _reveal(tester, field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(largeLabel).last);
      await tester.pumpAndSettle();
      expect(h.store.value.textScale, ClientTextScale.extraLarge);
      expect(_scale(tester, field), closeTo(31.2, 1e-9));
      expect(Navigator.of(tester.element(field)), same(navigator));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        tester.widget<DropdownButton<ClientTextScale>>(field).value,
        ClientTextScale.extraLarge,
      );
      expect(tester.takeException(), isNull);

      final reset = find.byKey(const ValueKey('reset-settings'));
      await _reveal(tester, reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(h.store.value.textScale, ClientTextScale.standard);
      expect(_scale(tester, field), 24);
      expect(
        tester.widget<DropdownButton<ClientTextScale>>(field).value,
        ClientTextScale.standard,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loads stored size and shares it with dialogs and new routes', (
    tester,
  ) async {
    final h = await _Harness.mount(tester, initial: ClientTextScale.large);
    final field = find.byKey(const ValueKey('text-scale-setting'));
    expect(_scale(tester, field), closeTo(27.6, 1e-9));
    final context = tester.element(field);
    final dialog = showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('Dialog scale probe')),
    );
    await tester.pumpAndSettle();
    expect(
      _scale(tester, find.text('Dialog scale probe')),
      closeTo(27.6, 1e-9),
    );
    await h.settings.update(
      h.settings.settings.copyWith(textScale: ClientTextScale.extraLarge),
    );
    await tester.pumpAndSettle();
    expect(
      _scale(tester, find.text('Dialog scale probe')),
      closeTo(31.2, 1e-9),
    );
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    await dialog;
    final route = Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Route scale probe')),
      ),
    );
    await tester.pumpAndSettle();
    expect(_scale(tester, find.text('Route scale probe')), closeTo(31.2, 1e-9));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(_scale(tester, find.text('Route scale probe')), closeTo(41.6, 1e-9));
    Navigator.of(tester.element(find.text('Route scale probe'))).pop();
    await tester.pumpAndSettle();
    await route;
    expect(_scale(tester, field), closeTo(41.6, 1e-9));
  });

  testWidgets(
    'keyboard cancels the picker and then opens and changes text size',
    (tester) async {
      final h = await _Harness.mount(tester);
      final field = find.byKey(const ValueKey('text-scale-setting'));
      await _reveal(tester, field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(h.store.value.textScale, ClientTextScale.standard);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

double _scale(WidgetTester tester, Finder finder) =>
    MediaQuery.textScalerOf(tester.element(finder)).scale(16);

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

final class _Harness {
  _Harness(ClientTextScale initial) {
    store.value = ClientSettings.defaults.copyWith(textScale: initial);
    settings = ClientSettingsController(store: store);
  }

  final store = _SettingsStore();
  late final ClientSettingsController settings;

  static Future<_Harness> mount(
    WidgetTester tester, {
    String locale = 'en',
    ClientTextScale initial = ClientTextScale.standard,
  }) async {
    final h = _Harness(initial);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final map = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(testMapScene()),
      ),
    );
    await tester.pumpWidget(
      AonwApp(
        mapController: map,
        settingsController: h.settings,
        initialRoute: AonwRoute.settings,
        locale: Locale(locale),
      ),
    );
    await tester.pumpAndSettle();
    return h;
  }
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
