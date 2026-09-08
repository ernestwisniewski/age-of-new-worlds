import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/client_preferences_fixture.dart';

void main() {
  test(
    'AI battery saver persists, reloads and resets without changing other settings',
    () async {
      final preferences = MemoryClientPreferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      expect((await store.load()).ai, const ClientAiSettings());
      for (final enabled in [true, false]) {
        final settings = ClientSettings.defaults.copyWith(
          ai: const ClientAiSettings().copyWith(batterySaver: enabled),
          highContrast: true,
        );
        await store.save(settings);
        final loaded = await SharedPreferencesClientSettingsStore(
          preferences: preferences,
        ).load();
        expect(loaded, settings);
        expect(loaded.hashCode, settings.hashCode);
        expect(preferences.values['aonw.settings.ai.batterySaver'], enabled);
      }
      await store.save(
        ClientSettings.defaults.copyWith(
          ai: const ClientAiSettings(batterySaver: true),
        ),
      );
      await store.save(ClientSettings.defaults);
      expect(await store.load(), ClientSettings.defaults);
    },
  );
}
