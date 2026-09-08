import 'package:aonw_flutter/app/navigation/aonw_menu_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_map_input_source.dart';

void main() {
  testWidgets(
    'disabled gamepad leaves keyboard active and primes held input on enabling',
    (tester) async {
      final settings = ClientSettingsController.ephemeral();
      final input = TestMapInputSource();
      final focus = FocusNode();
      addTearDown(settings.dispose);
      addTearDown(input.close);
      addTearDown(focus.dispose);
      var activations = 0;
      await settings.update(
        settings.settings.copyWith(
          gamepad: settings.settings.gamepad.copyWith(enabled: false),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ClientSettingsScope(
            controller: settings,
            child: AonwMenuNavigation(
              input: input.continuousInputs,
              child: Scaffold(
                body: FilledButton(
                  focusNode: focus,
                  onPressed: () => activations++,
                  child: const Text('Action'),
                ),
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      input.addContinuous(const MapGamepadInput(activate: true));
      await tester.pumpAndSettle();
      expect(activations, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(activations, 1);
      await settings.update(
        settings.settings.copyWith(
          gamepad: settings.settings.gamepad.copyWith(enabled: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(activations, 1);
      input.addContinuous(MapGamepadInput.idle);
      await tester.pump();
      input.addContinuous(const MapGamepadInput(activate: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(activations, 2);
      input.addContinuous(MapGamepadInput.idle);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('menu traversal respects stored deadzone', (tester) async {
    final settings = ClientSettingsController.ephemeral();
    final input = TestMapInputSource();
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(settings.dispose);
    addTearDown(input.close);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await settings.update(
      settings.settings.copyWith(
        gamepad: settings.settings.gamepad.copyWith(deadzone: 0.5),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ClientSettingsScope(
          controller: settings,
          child: AonwMenuNavigation(
            input: input.continuousInputs,
            child: Scaffold(
              body: Column(
                children: [
                  FilledButton(
                    focusNode: first,
                    onPressed: () {},
                    child: const Text('First'),
                  ),
                  FilledButton(
                    focusNode: second,
                    onPressed: () {},
                    child: const Text('Second'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    first.requestFocus();
    await tester.pumpAndSettle();
    input.addContinuous(const MapGamepadInput(cursorY: -0.4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(first.hasFocus, isTrue);
    input.addContinuous(const MapGamepadInput(cursorY: -0.75));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(second.hasFocus, isTrue);
    input.addContinuous(MapGamepadInput.idle);
    await tester.pumpAndSettle();
  });
}
