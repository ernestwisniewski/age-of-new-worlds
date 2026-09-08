import 'package:aonw_flutter/features/settings/application/window_settings.dart';
import 'package:aonw_flutter/features/settings/infrastructure/shared_preferences_window_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'window modes survive store recreation and reset is persisted',
    () async {
      final preferences = _Preferences();
      final store = SharedPreferencesWindowSettingsStore(
        preferences: preferences,
      );
      for (final mode in [WindowMode.windowed, WindowMode.fullscreen]) {
        await store.save(mode);
        expect(
          await SharedPreferencesWindowSettingsStore(
            preferences: preferences,
          ).load(),
          mode,
        );
        expect(preferences.values['aonw.settings.windowMode'], mode.name);
        expect(preferences.values['aonw.settings.language'], 'pl');
      }
    },
  );

  test('missing and unknown preferences default to fullscreen', () async {
    final preferences = _Preferences();
    final store = SharedPreferencesWindowSettingsStore(
      preferences: preferences,
    );
    expect(await store.load(), WindowMode.fullscreen);
    preferences.values['aonw.settings.windowMode'] = 'unknown';
    expect(await store.load(), WindowMode.fullscreen);
  });

  test(
    'write failure is propagated so the coordinator can restore the window',
    () async {
      final preferences = _Preferences(failWrite: true);
      final store = SharedPreferencesWindowSettingsStore(
        preferences: preferences,
      );
      await expectLater(store.save(WindowMode.windowed), throwsStateError);
      expect(
        preferences.values.containsKey('aonw.settings.windowMode'),
        isFalse,
      );
    },
  );
}

final class _Preferences extends Fake implements SharedPreferencesAsync {
  _Preferences({this.failWrite = false});

  final values = <String, String>{'aonw.settings.language': 'pl'};
  final bool failWrite;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    if (failWrite) throw StateError('write failure');
    values[key] = value;
  }
}
