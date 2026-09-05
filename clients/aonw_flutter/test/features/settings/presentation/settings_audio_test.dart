import 'package:aonw_flutter/design_system/widgets/aonw_menu_adjustable.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('pl')]) {
    testWidgets('edits and retains each audio channel in $locale', (
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
      for (final name in ['sound', 'music', 'nature']) {
        final toggle = find.byKey(ValueKey('$name-enabled-setting'));
        final volume = find.byKey(ValueKey('$name-volume-setting'));
        final slider = find.descendant(
          of: volume,
          matching: find.byType(Slider),
        );
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        tester.widget<Slider>(slider).onChanged!(0.65);
        await tester.pumpAndSettle();
        final before = controller.settings.audio;
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(volume, findsNothing);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(slider).value, 0.65);
        expect(controller.settings.audio, before);
      }
      expect(
        controller.settings.audio,
        const ClientAudioSettings(
          soundVolume: 0.65,
          musicVolume: 0.65,
          natureVolume: 0.65,
        ),
      );
      await controller.reset();
      await tester.pumpAndSettle();
      expect(controller.settings.audio, const ClientAudioSettings());
    });
  }

  testWidgets('gamepad volume adjustment preserves channel bounds', (
    tester,
  ) async {
    final controller = ClientSettingsController.ephemeral();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      LocalizedTestApp(home: SettingsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    final slider = find.descendant(
      of: find.byKey(const ValueKey('sound-volume-setting')),
      matching: find.byType(Slider),
    );
    for (final delta in [-1, -1, -1, -1, -1, -1]) {
      Actions.invoke(tester.element(slider), AonwMenuAdjustIntent(delta));
      await tester.pumpAndSettle();
    }
    expect(controller.settings.audio.soundVolume, 0);
    for (var step = 0; step < 21; step++) {
      Actions.invoke(tester.element(slider), const AonwMenuAdjustIntent(1));
      await tester.pumpAndSettle();
    }
    expect(controller.settings.audio.soundVolume, 1);
    expect(controller.settings.audio.musicVolume, 0.2);
    expect(controller.settings.audio.natureVolume, 0.4);
  });
}
