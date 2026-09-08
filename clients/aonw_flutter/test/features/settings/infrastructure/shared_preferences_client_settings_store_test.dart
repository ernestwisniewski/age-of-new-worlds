import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/infrastructure/shared_preferences_client_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'language survives restart and returning to system persists explicitly',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      for (final language in [
        ClientLanguage.polish,
        ClientLanguage.english,
        ClientLanguage.system,
      ]) {
        final settings = ClientSettings.defaults.copyWith(
          language: language,
          textScale: ClientTextScale.large,
        );
        await store.save(settings);
        final restored = await SharedPreferencesClientSettingsStore(
          preferences: preferences,
        ).load();
        expect(restored, settings);
        expect(restored.hashCode, settings.hashCode);
        expect(
          preferences.values['aonw.settings.language'],
          language.storageValue,
        );
      }
      await store.save(ClientSettings.defaults);
      expect(await store.load(), ClientSettings.defaults);
    },
  );

  test('missing or unsupported language follows the system', () async {
    final preferences = _Preferences();
    final store = SharedPreferencesClientSettingsStore(
      preferences: preferences,
    );
    expect((await store.load()).language, ClientLanguage.system);
    preferences.values['aonw.settings.language'] = 'unknown';
    preferences.values['aonw.settings.highContrast'] = true;
    final restored = await store.load();
    expect(restored.language, ClientLanguage.system);
    expect(restored.highContrast, isTrue);
  });

  test(
    'text size survives restart and resets without changing other options',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      for (final scale in ClientTextScale.values) {
        final settings = ClientSettings.defaults.copyWith(
          textScale: scale,
          highContrast: true,
          cameraSensitivity: 1.5,
        );
        await store.save(settings);
        final restored = await SharedPreferencesClientSettingsStore(
          preferences: preferences,
        ).load();
        expect(restored, settings);
        expect(restored.hashCode, settings.hashCode);
        expect(restored.textScale, scale);
      }
      await store.save(ClientSettings.defaults);
      expect(await store.load(), ClientSettings.defaults);
    },
  );

  test(
    'unknown or absent text size uses standard while retaining preferences',
    () async {
      final preferences = _Preferences();
      preferences.values['aonw.settings.highContrast'] = true;
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      expect((await store.load()).textScale, ClientTextScale.standard);
      preferences.values['aonw.settings.textScale'] = 'unsupported';
      final restored = await store.load();
      expect(restored.textScale, ClientTextScale.standard);
      expect(restored.highContrast, isTrue);
    },
  );

  test(
    'persisted reassignment retains displaced and explicitly unbound actions',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      final bindings = GamepadBindings.defaults
          .bindButton(GamepadButtonAction.confirm, GamepadButtonControl.start)
          .bindButton(GamepadButtonAction.cancel, null)
          .bindAxis(GamepadAxisAction.cameraX, GamepadAxisControl.leftStickX);
      final settings = ClientSettings.defaults.copyWith(
        gamepad: ClientGamepadSettings(bindings: bindings, deadzone: 0.5),
      );
      await store.save(settings);
      final restored = await SharedPreferencesClientSettingsStore(
        preferences: preferences,
      ).load();
      expect(restored, settings);
      expect(
        restored.gamepad.bindings.buttonsFor(GamepadButtonAction.primaryAction),
        isEmpty,
      );
      expect(
        restored.gamepad.bindings.buttonsFor(GamepadButtonAction.cancel),
        isEmpty,
      );
      expect(
        restored.gamepad.bindings.axisFor(GamepadAxisAction.cursorX),
        isNull,
      );
      await store.save(
        restored.copyWith(
          gamepad: restored.gamepad.copyWith(
            bindings: GamepadBindings.defaults,
          ),
        ),
      );
      expect(
        (await store.load()).gamepad,
        const ClientGamepadSettings(deadzone: 0.5),
      );
    },
  );

  test(
    'gamepad defaults are independent of existing camera preferences',
    () async {
      final preferences = _Preferences();
      preferences.values['aonw.settings.cameraSensitivity'] = 1.5;
      final loaded = await SharedPreferencesClientSettingsStore(
        preferences: preferences,
      ).load();
      expect(loaded.gamepad, const ClientGamepadSettings());
      expect(loaded.cameraSensitivity, 1.5);
    },
  );

  test(
    'round trips gamepad options, retains disabled values and resets',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      for (final enabled in [true, false]) {
        final settings = ClientSettings.defaults.copyWith(
          cameraSensitivity: 1.5,
          gamepad: ClientGamepadSettings(
            enabled: enabled,
            deadzone: 0.5,
            cameraSensitivity: 0.2,
            invertCameraY: true,
          ),
        );
        await store.save(settings);
        final loaded = await store.load();
        expect(loaded, settings);
        expect(loaded.hashCode, settings.hashCode);
        expect(loaded, isNot(ClientSettings.defaults));
      }
      await store.save(ClientSettings.defaults);
      expect(await store.load(), ClientSettings.defaults);
    },
  );

  test('invalid gamepad ranges fall back independently', () async {
    final preferences = _Preferences();
    preferences.values['aonw.settings.gamepad.enabled'] = false;
    preferences.values['aonw.settings.gamepad.invertCameraY'] = true;
    for (final invalid in [double.nan, double.infinity, -1.0, 3.0]) {
      preferences.values['aonw.settings.gamepad.deadzone'] = invalid;
      preferences.values['aonw.settings.gamepad.cameraSensitivity'] = invalid;
      final loaded = await SharedPreferencesClientSettingsStore(
        preferences: preferences,
      ).load();
      expect(
        loaded.gamepad,
        const ClientGamepadSettings(enabled: false, invertCameraY: true),
      );
    }
    preferences.values['aonw.settings.gamepad.deadzone'] = 0.6;
    preferences.values['aonw.settings.gamepad.cameraSensitivity'] = 0.2;
    final loaded = await SharedPreferencesClientSettingsStore(
      preferences: preferences,
    ).load();
    expect(loaded.gamepad.deadzone, 0.6);
    expect(loaded.gamepad.cameraSensitivity, 0.2);
  });

  test(
    'uses three audio defaults when channel preferences are absent',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      expect((await store.load()).audio, const ClientAudioSettings());
      const defaults = ClientAudioSettings();
      expect(defaults.soundVolume, 0.25);
      expect(defaults.musicVolume, 0.2);
      expect(defaults.natureVolume, 0.4);
      expect(defaults.soundsEnabled, isTrue);
      expect(defaults.musicEnabled, isTrue);
      expect(defaults.natureEnabled, isTrue);
    },
  );

  test(
    'persists independent channel switches and their retained volumes',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      for (final flags in [
        (false, true, true),
        (true, false, true),
        (true, true, false),
        (false, false, false),
      ]) {
        final audio = ClientAudioSettings(
          soundsEnabled: flags.$1,
          musicEnabled: flags.$2,
          natureEnabled: flags.$3,
          soundVolume: 0,
          musicVolume: 0.55,
          natureVolume: 1,
        );
        final settings = ClientSettings.defaults.copyWith(audio: audio);
        await store.save(settings);
        final restored = await SharedPreferencesClientSettingsStore(
          preferences: preferences,
        ).load();
        expect(restored, settings);
        expect(restored.hashCode, settings.hashCode);
        expect(restored, isNot(ClientSettings.defaults));
      }
      await store.save(ClientSettings.defaults);
      expect(await store.load(), ClientSettings.defaults);
    },
  );

  test(
    'invalid volumes fall back independently without changing switches',
    () async {
      final preferences = _Preferences();
      preferences.values['aonw.settings.audio.musicEnabled'] = false;
      for (final invalid in [double.nan, double.infinity, -0.1, 1.1]) {
        for (final name in ['soundVolume', 'musicVolume', 'natureVolume']) {
          preferences.values['aonw.settings.audio.$name'] = invalid;
        }
        final restored = await SharedPreferencesClientSettingsStore(
          preferences: preferences,
        ).load();
        expect(restored.audio, const ClientAudioSettings(musicEnabled: false));
      }
      preferences.values['aonw.settings.audio.soundVolume'] = 0.75;
      final restored = await SharedPreferencesClientSettingsStore(
        preferences: preferences,
      ).load();
      expect(
        restored.audio,
        const ClientAudioSettings(soundVolume: 0.75, musicEnabled: false),
      );
    },
  );

  test(
    'missing animation keys retain defaults for existing installations',
    () async {
      final preferences = _Preferences();
      preferences.values['aonw.settings.cameraSensitivity'] = 1.5;
      final settings = await SharedPreferencesClientSettingsStore(
        preferences: preferences,
      ).load();
      expect(
        settings,
        ClientSettings.defaults.copyWith(cameraSensitivity: 1.5),
      );
      expect(settings.showUnitMovementAnimations, isTrue);
      expect(settings.showCombatAnimations, isTrue);
      expect(settings.showUnitIdleAnimations, isTrue);
      expect(settings.showRouteAnimations, isTrue);
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
    'persists route animation independently across recreation and reset',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesClientSettingsStore(
        preferences: preferences,
      );
      for (final enabled in [false, true]) {
        final settings = ClientSettings.defaults.copyWith(
          showRouteAnimations: enabled,
          showUnitMovementAnimations: false,
          showUnitIdleAnimations: false,
          reducedMotion: true,
        );
        await store.save(settings);
        expect(
          preferences.values['aonw.settings.showRouteAnimations'],
          enabled,
        );
        final loaded = await SharedPreferencesClientSettingsStore(
          preferences: preferences,
        ).load();
        expect(loaded, settings);
        expect(loaded.hashCode, settings.hashCode);
        expect(loaded, isNot(settings.copyWith(showRouteAnimations: !enabled)));
      }
      await store.save(ClientSettings.defaults);
      expect(await store.load(), ClientSettings.defaults);
    },
  );

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
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

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
