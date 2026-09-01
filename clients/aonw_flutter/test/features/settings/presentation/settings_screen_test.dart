import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('edits and resets audio, camera and accessibility', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    final controller = ClientSettingsController(store: store);
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(home: SettingsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Accessibility'), findsOneWidget);

    tester
        .widget<Slider>(
          find.descendant(
            of: find.byKey(const ValueKey('master-volume-setting')),
            matching: find.byType(Slider),
          ),
        )
        .onChanged!(0.25);
    await tester.pumpAndSettle();
    tester
        .widget<Slider>(
          find.descendant(
            of: find.byKey(const ValueKey('camera-sensitivity-setting')),
            matching: find.byType(Slider),
          ),
        )
        .onChanged!(1.5);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reduced-motion-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('high-contrast-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-elevation-walls-setting')));
    await tester.pumpAndSettle();

    expect(store.settings.masterVolume, 0.25);
    expect(store.settings.cameraSensitivity, 1.5);
    expect(store.settings.reducedMotion, isTrue);
    expect(store.settings.highContrast, isTrue);
    expect(store.settings.showMapElevationWalls, isTrue);

    await tester.tap(find.byKey(const ValueKey('reset-settings')));
    await tester.pumpAndSettle();
    expect(store.settings, ClientSettings.defaults);
  });
}

final class _MemorySettingsStore implements ClientSettingsStore {
  var settings = ClientSettings.defaults;

  @override
  Future<ClientSettings> load() async => settings;

  @override
  Future<void> save(ClientSettings settings) async {
    this.settings = settings;
  }
}
