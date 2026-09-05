import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'missing animation keys retain defaults for existing installations',
    () async {
      final preferences = _Preferences();
      preferences.values['aonw.settings.masterVolume'] = 0.25;
      final settings = await SharedPreferencesClientSettingsStore(
        preferences: preferences,
      ).load();
      expect(settings, ClientSettings.defaults.copyWith(masterVolume: 0.25));
      expect(settings.showUnitMovementAnimations, isTrue);
      expect(settings.showCombatAnimations, isTrue);
      expect(settings.showUnitIdleAnimations, isTrue);
    },
  );

  test('persists idle separately from motion and accessibility', () async {
    final preferences = _Preferences();
    final store = SharedPreferencesClientSettingsStore(
      preferences: preferences,
    );
    for (final idle in [false, true]) {
      final settings = ClientSettings.defaults.copyWith(
        showUnitIdleAnimations: idle,
        showUnitMovementAnimations: false,
        reducedMotion: true,
      );
      await store.save(settings);
      expect(preferences.values['aonw.settings.showUnitIdleAnimations'], idle);
      final loaded = await SharedPreferencesClientSettingsStore(
        preferences: preferences,
      ).load();
      expect(loaded, settings);
      expect(loaded.hashCode, settings.hashCode);
      expect(loaded, isNot(settings.copyWith(showUnitIdleAnimations: !idle)));
    }
    await store.save(ClientSettings.defaults);
    expect(await store.load(), ClientSettings.defaults);
  });

  test(
    'persists independent animation choices across store recreation and reset',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      for (final movement in [false, true]) {
        for (final combat in [false, true]) {
          final settings = ClientSettings.defaults.copyWith(
            showUnitMovementAnimations: movement,
            showCombatAnimations: combat,
            reducedMotion: true,
            followOwnUnitMovement: true,
          );
          await store.save(settings);
          final loaded = await SharedPreferencesClientSettingsStore(
            preferences: preferences,
          ).load();
          expect(loaded.showUnitMovementAnimations, movement);
          expect(loaded.showCombatAnimations, combat);
          expect(loaded, settings);
          expect(loaded.hashCode, settings.hashCode);
        }
      }
      await store.save(ClientSettings.defaults);
      expect(await store.load(), ClientSettings.defaults);
    },
  );
}

final class _Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, Object>{};

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<double?> getDouble(String key) async => values[key] as double?;

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    values[key] = value;
  }
}
