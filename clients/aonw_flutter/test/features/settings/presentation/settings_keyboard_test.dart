import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  for (final locale in ['en', 'pl']) {
    testWidgets(
      'keyboard help starts collapsed and scales on mobile in $locale',
      (tester) async {
        final controller = ClientSettingsController.ephemeral();
        addTearDown(controller.dispose);
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: Locale(locale),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SettingsScreen(controller: controller),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final section = find.byKey(const PageStorageKey('keyboard-settings'));
        await Scrollable.ensureVisible(tester.element(section), alignment: 0.5);
        await tester.pumpAndSettle();
        expect(find.text('[ / ]'), findsNothing);
        await tester.tap(find.text(locale == 'pl' ? 'Klawiatura' : 'Keyboard'));
        await tester.pumpAndSettle();
        for (final label in [
          'Enter',
          'M',
          'I',
          'R',
          '[ / ]',
          locale == 'pl' ? 'Spacja' : 'Space',
          'Esc',
          'Tab / Shift + Tab',
        ]) {
          final text = find.text(label);
          expect(text, findsOneWidget);
          await Scrollable.ensureVisible(tester.element(text), alignment: 0.5);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
