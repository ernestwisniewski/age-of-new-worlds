import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/client_preferences_fixture.dart';

void main() {
  test(
    'preferred map view persists and missing or unknown values use graphic mode',
    () async {
      final preferences = MemoryClientPreferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      expect((await store.load()).preferredMapViewMode, MapViewMode.graphic);
      preferences.values['aonw.settings.preferredMapViewMode'] = 'unknown';
      expect((await store.load()).preferredMapViewMode, MapViewMode.graphic);
      for (final mode in MapViewMode.values) {
        final settings = ClientSettings.defaults.copyWith(
          preferredMapViewMode: mode,
          highContrast: true,
        );
        await store.save(settings);
        final loaded = await SharedPreferencesClientSettingsStore(
          preferences: preferences,
        ).load();
        expect(loaded, settings);
        expect(loaded.hashCode, settings.hashCode);
        expect(
          preferences.values['aonw.settings.preferredMapViewMode'],
          mode.name,
        );
      }
      await store.save(
        ClientSettings.defaults.copyWith(
          preferredMapViewMode: MapViewMode.tile,
        ),
      );
      await store.save(ClientSettings.defaults);
      expect(await store.load(), ClientSettings.defaults);
    },
  );
}
