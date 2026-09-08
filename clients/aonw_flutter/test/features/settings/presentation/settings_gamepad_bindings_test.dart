import 'dart:async';

import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/application/client_gamepad_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import '../../../support/map_test_fixture.dart';
import '../../../support/recording_game_audio.dart';

void main() {
  for (final (locale, none, assigned, stick) in const [
    (Locale('en'), 'Unassigned', 'Assigned to:', 'Left stick X'),
    (Locale('pl'), 'Bez przypisania', 'Przypisano do:', 'Lewy drążek X'),
    (Locale('fr'), 'Non affecté', 'Affecté à :', 'Stick gauche, axe X'),
    (Locale('de'), 'Nicht belegt', 'Belegt mit:', 'Linker Stick X'),
    (Locale('es'), 'Sin asignar', 'Asignado a:', 'Palanca izquierda X'),
    (Locale('nl'), 'Niet toegewezen', 'Toegewezen aan:', 'Linkerstick X'),
  ]) {
    testWidgets(
      'edits and resets bindings with visible displaced actions in $locale',
      (tester) async {
        final h = await _Harness.mount(tester, locale: locale);
        expect(h.fieldText('button-cancel'), contains('B / Back'));
        await h.open(tester, 'button-confirm');
        expect(find.textContaining(assigned), findsWidgets);
        await tester.tap(find.text('B').last);
        await tester.pumpAndSettle();
        expect(
          h.settings.settings.gamepad.bindings.buttonsFor(
            GamepadButtonAction.confirm,
          ),
          [GamepadButtonControl.b],
        );
        expect(h.fieldText('button-cancel'), contains('Back'));
        expect(h.fieldText('button-confirm'), contains('B'));
        await h.open(tester, 'button-cancel');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('gamepad-binding-unassigned')),
          -250,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(none).last);
        await tester.pumpAndSettle();
        expect(
          h.settings.settings.gamepad.bindings.buttonsFor(
            GamepadButtonAction.cancel,
          ),
          isEmpty,
        );
        expect(h.fieldText('button-cancel'), contains(none));
        await h.open(tester, 'axis-cameraX');
        await tester.tap(find.text(stick).last);
        await tester.pumpAndSettle();
        expect(
          h.settings.settings.gamepad.bindings.axisFor(
            GamepadAxisAction.cursorX,
          ),
          isNull,
        );
        expect(h.fieldText('axis-cursorX'), contains(none));
        final reset = find.byKey(const ValueKey('gamepad-reset-bindings'));
        await tester.ensureVisible(reset);
        await tester.pumpAndSettle();
        await tester.tap(reset);
        await tester.pumpAndSettle();
        expect(
          h.settings.settings.gamepad,
          const ClientGamepadSettings(
            deadzone: 0.4,
            cameraSensitivity: 0.8,
            invertCameraY: true,
          ),
        );
        expect(h.fieldText('button-cancel'), contains('B / Back'));
        expect(tester.takeException(), isNull);
        await h.unmount(tester);
      },
    );
  }

  testWidgets('gamepad opens, traverses and closes only the binding popup', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    await h.open(tester, 'button-confirm');
    await h.press(tester, GamepadButton.b, hold: true);
    expect(find.text('Settings'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Assigned to: Cancel'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    await h.release(tester, GamepadButton.b);
    await h.press(tester, GamepadButton.a, hold: true);
    expect(find.text('Assigned to: Cancel'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.settings.settings.gamepad.bindings, GamepadBindings.defaults);
    await h.release(tester, GamepadButton.a);
    await h.press(tester, GamepadButton.dpadDown);
    await h.press(tester, GamepadButton.a);
    expect(
      h.settings.settings.gamepad.bindings.buttonsFor(
        GamepadButtonAction.confirm,
      ),
      [GamepadButtonControl.b],
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Assigned to: Cancel'), findsNothing);
    expect(tester.takeException(), isNull);
    await h.unmount(tester);
  });

  testWidgets('gamepad scrolls through the full physical button list', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    await h.open(tester, 'button-confirm');
    for (var step = 0; step < 17; step++) {
      await h.press(tester, GamepadButton.dpadDown);
    }
    expect(find.text('Touchpad').last.hitTestable(), findsOneWidget);
    await h.press(tester, GamepadButton.a);
    expect(
      h.settings.settings.gamepad.bindings.buttonsFor(
        GamepadButtonAction.confirm,
      ),
      [GamepadButtonControl.touchpad],
    );
    expect(find.text('Settings'), findsOneWidget);
    await h.unmount(tester);
  });

  for (final locale in const [
    Locale('pl'),
    Locale('fr'),
    Locale('de'),
    Locale('es'),
    Locale('nl'),
  ]) {
    testWidgets(
      '$locale bindings and picker fit a narrow viewport with larger text',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final h = await _Harness.mount(
          tester,
          locale: locale,
          size: const Size(390, 844),
        );
        await h.open(tester, 'button-primaryAction');
        expect(tester.takeException(), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await h.open(tester, 'axis-cameraY');
        expect(tester.takeException(), isNull);
        await h.unmount(tester);
      },
    );
  }

  testWidgets('keyboard escape closes the picker without changing bindings', (
    tester,
  ) async {
    final h = await _Harness.mount(tester);
    await h.open(tester, 'axis-cameraY');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(h.settings.settings.gamepad.bindings, GamepadBindings.defaults);
    await h.unmount(tester);
  });
}

final class _Harness {
  final settings = ClientSettingsController.ephemeral();
  final events = StreamController<NormalizedGamepadEvent>(sync: true);
  final audio = RecordingGameAudio();
  late final GamepadMapInputSource input;

  static Future<_Harness> mount(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(900, 1000),
  }) async {
    final h = _Harness();
    h.input = GamepadMapInputSource(events: h.events.stream);
    addTearDown(h.events.close);
    await h.settings.update(
      h.settings.settings.copyWith(
        gamepad: const ClientGamepadSettings(
          deadzone: 0.4,
          cameraSensitivity: 0.8,
          invertCameraY: true,
        ),
      ),
    );
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      AonwApp(
        mapController: MapPresentationController(
          capabilities: testGameSessionCapabilities(
            FakeGameSession.success(testMapScene()),
          ),
        ),
        mapInputSource: h.input,
        settingsController: h.settings,
        audio: h.audio,
        locale: locale,
        initialRoute: AonwRoute.settings,
      ),
    );
    await tester.pumpAndSettle();
    final section = find.byKey(const PageStorageKey('gamepad-settings'));
    await tester.ensureVisible(section);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: section,
        matching: find.text(lookupAonwLocalizations(locale).gamepadSettings),
      ),
    );
    await tester.pumpAndSettle();
    return h;
  }

  Finder field(String name) => find.byKey(ValueKey('gamepad-$name'));
  List<String?> fieldText(String name) => find
      .descendant(of: field(name), matching: find.byType(Text))
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .toList();

  Future<void> open(WidgetTester tester, String name) async {
    await tester.ensureVisible(field(name));
    await tester.pumpAndSettle();
    await tester.tap(field(name));
    await tester.pumpAndSettle();
  }

  void emit(GamepadButton button, double value) => events.add(
    NormalizedGamepadEvent(
      gamepadId: 'bindings-pad',
      timestamp: 1,
      button: button,
      value: value,
      rawEvent: GamepadEvent(
        gamepadId: 'bindings-pad',
        timestamp: 1,
        type: KeyType.button,
        key: button.name,
        value: value,
      ),
    ),
  );

  Future<void> press(
    WidgetTester tester,
    GamepadButton button, {
    bool hold = false,
  }) async {
    emit(button, 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    if (!hold) await release(tester, button);
  }

  Future<void> release(WidgetTester tester, GamepadButton button) async {
    emit(button, 0);
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}
