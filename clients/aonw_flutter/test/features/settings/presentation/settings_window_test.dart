import 'dart:async';

import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/application/window_settings.dart';
import 'package:aonw_flutter/features/settings/application/window_settings_coordinator.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/window_settings_controller.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  for (final locale in AonwLocalizations.supportedLocales) {
    testWidgets(
      '$locale changes and resets window mode without replacing the route',
      (tester) async {
        final h = await _Harness.mount(tester, locale: locale);
        final l10n = lookupAonwLocalizations(locale);
        final navigator = Navigator.of(tester.element(h.field));
        await h.open(tester);
        await tester.tap(find.text(l10n.windowModeWindowed).last);
        await tester.pumpAndSettle();
        expect(h.window.mode, WindowMode.windowed);
        expect(h.store.saved, [WindowMode.windowed]);
        expect(Navigator.of(tester.element(h.field)), same(navigator));
        expect(tester.takeException(), isNull);
        final reset = find.byKey(const ValueKey('reset-settings'));
        await Scrollable.ensureVisible(tester.element(reset), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(reset);
        await tester.pumpAndSettle();
        expect(h.window.mode, WindowMode.fullscreen);
        expect(h.store.saved.last, WindowMode.fullscreen);
        expect(h.value(tester), WindowMode.fullscreen);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'startup restores a saved windowed preference without writing it',
    (tester) async {
      final h = await _Harness.mount(tester, initial: WindowMode.windowed);
      expect(h.value(tester), WindowMode.windowed);
      expect(h.window.mode, WindowMode.windowed);
      expect(h.store.loads, 1);
      expect(h.store.saved, isEmpty);
    },
  );

  testWidgets('load failure is visible and retry restores the saved choice', (
    tester,
  ) async {
    final h = await _Harness.mount(
      tester,
      initial: WindowMode.windowed,
      failLoad: true,
    );
    expect(h.window.mode, WindowMode.fullscreen);
    expect(find.textContaining('could not be loaded'), findsOneWidget);
    h.store.failLoad = false;
    final retry = find.text('Retry');
    await Scrollable.ensureVisible(tester.element(retry), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(h.window.mode, WindowMode.windowed);
    expect(h.value(tester), WindowMode.windowed);
    expect(h.store.loads, 2);
    expect(h.store.saved, isEmpty);
    expect(find.textContaining('could not be loaded'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending transition disables the picker and saves after confirmation',
    (tester) async {
      final h = await _Harness.mount(tester);
      final pending = Completer<void>();
      h.window.transition = pending.future;
      await h.open(tester);
      await tester.tap(find.text('Windowed').last);
      await tester.pumpAndSettle();
      expect(h.store.saved, isEmpty);
      expect(
        tester.widget<DropdownButton<WindowMode>>(h.field).onChanged,
        isNull,
      );
      expect(find.text('Changing window mode…'), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
      expect(h.store.saved, [WindowMode.windowed]);
      expect(h.value(tester), WindowMode.windowed);
    },
  );

  testWidgets('failed save restores the visible value and exposes an error', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    h.store.failSave = true;
    await h.open(tester);
    await tester.tap(find.text('Windowed').last);
    await tester.pumpAndSettle();
    expect(h.window.mode, WindowMode.fullscreen);
    expect(h.value(tester), WindowMode.fullscreen);
    expect(find.textContaining('could not be saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard escape keeps the confirmed mode and settings route', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    await h.open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(h.store.saved, isEmpty);
    expect(h.value(tester), WindowMode.fullscreen);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets(
    'unsupported windows hide the section and reset performs no window I/O',
    (tester) async {
      final h = await _Harness.mount(tester, supported: false);
      expect(h.field, findsNothing);
      expect(find.text('Window'), findsNothing);
      final reset = find.byKey(const ValueKey('reset-settings'));
      await Scrollable.ensureVisible(tester.element(reset), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(h.store.loads, 0);
      expect(h.window.calls, 0);
      expect(h.store.saved, isEmpty);
    },
  );
}

final class _Harness {
  final window = _Window();
  final store = _Store();
  final field = find.byKey(const ValueKey('window-mode-setting'));

  static Future<_Harness> mount(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool supported = true,
    WindowMode initial = WindowMode.fullscreen,
    bool failLoad = false,
  }) async {
    final h = _Harness();
    h.window.isSupported = supported;
    h.store.mode = initial;
    h.store.failLoad = failLoad;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      AonwApp(
        mapController: MapPresentationController(
          capabilities: testGameSessionCapabilities(
            FakeGameSession.success(testMapScene()),
          ),
        ),
        settingsController: ClientSettingsController.ephemeral(),
        windowSettingsController: WindowSettingsController(
          WindowSettingsCoordinator(window: h.window, store: h.store),
        ),
        locale: locale,
        initialRoute: AonwRoute.settings,
      ),
    );
    await tester.pumpAndSettle();
    expect(h.store.saved, isEmpty);
    return h;
  }

  WindowMode? value(WidgetTester tester) =>
      tester.widget<DropdownButton<WindowMode>>(field).value;

  Future<void> open(WidgetTester tester) async {
    await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
  }
}

final class _Window implements GameWindowPort {
  @override
  bool isSupported = true;
  var mode = WindowMode.windowed;
  var calls = 0;
  Future<void>? transition;

  @override
  Future<WindowMode> readMode() async {
    calls += 1;
    return mode;
  }

  @override
  Future<void> setMode(WindowMode value) async {
    calls += 1;
    await transition;
    mode = value;
  }
}

final class _Store implements WindowSettingsStore {
  var loads = 0;
  var failSave = false;
  var failLoad = false;
  var mode = WindowMode.fullscreen;
  final saved = <WindowMode>[];

  @override
  Future<WindowMode> load() async {
    loads += 1;
    if (failLoad) throw StateError('load failure');
    return mode;
  }

  @override
  Future<void> save(WindowMode mode) async {
    if (failSave) throw StateError('write failure');
    saved.add(mode);
  }
}
