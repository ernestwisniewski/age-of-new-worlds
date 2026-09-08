import 'package:aonw_flutter/design_system/widgets/aonw_menu_adjustable.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('pl')]) {
    testWidgets('gamepad section is collapsed and retains edits in $locale', (
      tester,
    ) async {
      final controller = ClientSettingsController.ephemeral();
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: locale,
          home: SettingsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      final section = find.byKey(const PageStorageKey('gamepad-settings'));
      final toggle = find.byKey(const ValueKey('gamepad-enabled-setting'));
      expect(toggle, findsNothing);
      await tester.ensureVisible(section);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: section, matching: find.text('Gamepad')),
      );
      await tester.pumpAndSettle();
      expect(toggle, findsOneWidget);
      final deadzone = _slider('deadzone');
      final sensitivity = _slider('camera-sensitivity');
      tester.widget<Slider>(deadzone).onChanged!(0.5);
      await tester.pumpAndSettle();
      tester.widget<Slider>(sensitivity).onChanged!(0.2);
      await tester.pumpAndSettle();
      final invert = find.byKey(
        const ValueKey('gamepad-invert-camera-y-setting'),
      );
      await tester.ensureVisible(invert);
      await tester.pumpAndSettle();
      await tester.tap(invert);
      await tester.pumpAndSettle();
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(deadzone, findsNothing);
      expect(
        controller.settings.gamepad,
        const ClientGamepadSettings(
          enabled: false,
          deadzone: 0.5,
          cameraSensitivity: 0.2,
          invertCameraY: true,
        ),
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      Actions.invoke(
        tester.element(sensitivity),
        const AonwMenuAdjustIntent(-1),
      );
      await tester.pumpAndSettle();
      expect(controller.settings.gamepad.cameraSensitivity, 0.2);
      expect(controller.settings.cameraSensitivity, 1);
      await controller.reset();
      await tester.pumpAndSettle();
      expect(controller.settings, ClientSettings.defaults);
      expect(tester.widget<Slider>(deadzone).value, 0.24);
      expect(tester.takeException(), isNull);
    });
  }
}

Finder _slider(String name) => find.descendant(
  of: find.byKey(ValueKey('gamepad-$name-setting')),
  matching: find.byType(Slider),
);
