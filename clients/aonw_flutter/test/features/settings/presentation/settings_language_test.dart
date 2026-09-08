import 'dart:async';

import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/flame_map_viewport.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/settings_screen.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets('French menu opens the local game wizard on a narrow screen', (
    tester,
  ) async {
    await _Harness.mount(
      tester,
      initial: ClientLanguage.french,
      route: AonwRoute.menu,
    );
    expect(find.text('SOLO'), findsOneWidget);
    expect(find.text('CHARGER UNE PARTIE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('SOLO'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir une civilisation'), findsOneWidget);
    final country = find.text('Pologne').first;
    await Scrollable.ensureVisible(tester.element(country), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(country);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Arabie saoudite'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arabie saoudite').last);
    await tester.pumpAndSettle();
    expect(find.text('Arabie saoudite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selects French, persists it and resolves French regional locales',
    (tester) async {
      final h = await _Harness.mount(tester);
      await h.choose(tester, 'Français');
      expect(find.text('Paramètres'), findsOneWidget);
      expect(h.store.value.language, ClientLanguage.french);
      await h.choose(tester, 'Langue du système');
      tester.platformDispatcher.localesTestValue = const [Locale('fr', 'CA')];
      await tester.pumpAndSettle();
      expect(find.text('Paramètres'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('changes language live and reset restores system selection', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    final field = find.byKey(const ValueKey('language-setting'));
    final navigator = Navigator.of(tester.element(field));
    expect(find.text('Settings'), findsOneWidget);
    await h.choose(tester, 'Polski');
    expect(find.text('Ustawienia'), findsOneWidget);
    expect(h.store.value.language, ClientLanguage.polish);
    expect(Navigator.of(tester.element(field)), same(navigator));
    expect(Localizations.localeOf(tester.element(field)), const Locale('pl'));
    await h.choose(tester, 'English');
    expect(find.text('Settings'), findsOneWidget);
    expect(h.store.value.language, ClientLanguage.english);
    tester.platformDispatcher.localesTestValue = const [Locale('pl', 'PL')];
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    final reset = find.byKey(const ValueKey('reset-settings'));
    await Scrollable.ensureVisible(tester.element(reset), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(h.store.value.language, ClientLanguage.system);
    expect(find.text('Ustawienia'), findsOneWidget);
    expect(
      tester.widget<DropdownButton<ClientLanguage>>(field).value,
      ClientLanguage.system,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'system mode follows later locale changes and skips unsupported ones',
    (tester) async {
      final h = await _Harness.mount(
        tester,
        locales: const [Locale('ja'), Locale('pl', 'PL')],
      );
      expect(find.text('Ustawienia'), findsOneWidget);
      expect(h.settings.settings.language, ClientLanguage.system);
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      await h.choose(tester, 'Polski');
      tester.platformDispatcher.localesTestValue = const [Locale('ja')];
      await tester.pumpAndSettle();
      expect(find.text('Ustawienia'), findsOneWidget);
      await h.choose(tester, 'Język systemowy');
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets('a delayed startup load cannot overwrite a language selection', (
    tester,
  ) async {
    final pending = Completer<ClientSettings>();
    final h = await _Harness.mount(tester, delayedLoad: pending.future);
    await h.choose(tester, 'Polski');
    pending.complete(
      ClientSettings.defaults.copyWith(language: ClientLanguage.english),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ustawienia'), findsOneWidget);
    expect(h.store.value.language, ClientLanguage.polish);
  });

  testWidgets('restores a saved language and updates an already open dialog', (
    tester,
  ) async {
    final h = await _Harness.mount(tester, initial: ClientLanguage.polish);
    expect(find.text('Ustawienia'), findsOneWidget);
    final context = tester.element(find.byType(SettingsScreen));
    final dialog = showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(content: Text(context.aonwL10n.languageSettings)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Język'),
      ),
      findsOneWidget,
    );
    await h.settings.update(
      h.settings.settings.copyWith(language: ClientLanguage.english),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Language'),
      ),
      findsOneWidget,
    );
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    await dialog;
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('language change preserves the running map and selection', (
    tester,
  ) async {
    final h = await _Harness.mount(tester, route: AonwRoute.map);
    h.map.selectUnit('preview-commander');
    await tester.pumpAndSettle();
    final before = h.map.state as GameSessionReady;
    final game = tester
        .widget<FlameMapViewport>(find.byType(FlameMapViewport))
        .game;
    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    await h.choose(tester, 'Polski');
    Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
    await tester.pumpAndSettle();
    final after = h.map.state as GameSessionReady;
    expect(after.scene, same(before.scene));
    expect(after.interaction.selectedUnitId, before.interaction.selectedUnitId);
    expect(after.interaction.selected, before.interaction.selected);
    expect(after.interaction.moveTargeting, before.interaction.moveTargeting);
    expect(
      tester.widget<FlameMapViewport>(find.byType(FlameMapViewport)).game,
      same(game),
    );
    expect(find.byTooltip('Otwórz ustawienia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keyboard can select a language and Escape keeps the current value',
    (tester) async {
      final h = await _Harness.mount(tester);
      final field = find.byKey(const ValueKey('language-setting'));
      await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(h.store.value.language, ClientLanguage.system);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(h.store.value.language, ClientLanguage.polish);
      expect(find.text('Ustawienia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _Harness {
  _Harness(ClientLanguage initial, Future<ClientSettings>? delayedLoad) {
    store.value = ClientSettings.defaults.copyWith(language: initial);
    store.delayedLoad = delayedLoad;
    settings = ClientSettingsController(store: store);
  }

  final store = _SettingsStore();
  late final ClientSettingsController settings;
  late final MapPresentationController map;
  final game = AonwFlameGame();

  Future<void> choose(WidgetTester tester, String label) async {
    final field = find.byKey(const ValueKey('language-setting'));
    await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  static Future<_Harness> mount(
    WidgetTester tester, {
    ClientLanguage initial = ClientLanguage.system,
    List<Locale> locales = const [Locale('en', 'US')],
    Future<ClientSettings>? delayedLoad,
    AonwRoute route = AonwRoute.settings,
  }) async {
    final h = _Harness(initial, delayedLoad);
    await tester.binding.setSurfaceSize(
      route == AonwRoute.map ? const Size(1000, 800) : const Size(390, 844),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    h.map = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(
          testMapScene(units: [testVisibleUnit()]),
          reachableResult: testReachableView(),
        ),
      ),
    );
    await tester.pumpWidget(
      AonwApp(
        mapController: h.map,
        settingsController: h.settings,
        initialRoute: route,
        flameGameFactory: () => h.game,
      ),
    );
    await tester.pumpAndSettle();
    return h;
  }
}

final class _SettingsStore implements ClientSettingsStore {
  ClientSettings value = ClientSettings.defaults;
  Future<ClientSettings>? delayedLoad;

  @override
  Future<ClientSettings> load() async => delayedLoad ?? value;

  @override
  Future<void> save(ClientSettings settings) async {
    value = settings;
  }
}
