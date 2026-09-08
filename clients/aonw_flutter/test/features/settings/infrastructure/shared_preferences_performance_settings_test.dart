import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/client_preferences_fixture.dart';

void main() {
  test('performance indicators persist independently and reset', () async {
    final preferences = MemoryClientPreferences();
    final store = SharedPreferencesClientSettingsStore(
      preferences: preferences,
    );
    expect((await store.load()).performance, const ClientPerformanceSettings());
    for (final fps in [false, true]) {
      for (final zoom in [false, true]) {
        final settings = ClientSettings.defaults.copyWith(
          performance: ClientPerformanceSettings(
            showFps: fps,
            showMapZoom: zoom,
          ),
          highContrast: true,
        );
        await store.save(settings);
        final restored = await SharedPreferencesClientSettingsStore(
          preferences: preferences,
        ).load();
        expect(restored, settings);
        expect(restored.hashCode, settings.hashCode);
        expect(preferences.values['aonw.settings.performance.showFps'], fps);
        expect(
          preferences.values['aonw.settings.performance.showMapZoom'],
          zoom,
        );
      }
    }
    await store.save(ClientSettings.defaults);
    expect(await store.load(), ClientSettings.defaults);
  });
}
