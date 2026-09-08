import 'dart:convert';

import '../application/gamepad_bindings.dart';

abstract final class GamepadBindingsCodec {
  static String encode(GamepadBindings bindings) => jsonEncode({
    'version': 1,
    'buttons': {
      for (final entry in bindings.buttons.entries)
        entry.key.name: entry.value.name,
    },
    'axes': {
      for (final entry in bindings.axes.entries)
        entry.key.name: entry.value.name,
    },
  });

  static GamepadBindings decode(String? encoded) {
    if (encoded == null) return GamepadBindings.defaults;
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, dynamic> || value['version'] != 1) {
        return GamepadBindings.defaults;
      }
      return GamepadBindings(
        buttons: _decodeMap(
          value['buttons'],
          GamepadButtonControl.values,
          GamepadButtonAction.values,
        ),
        axes: _decodeMap(
          value['axes'],
          GamepadAxisControl.values,
          GamepadAxisAction.values,
        ),
      );
    } on FormatException {
      return GamepadBindings.defaults;
    } on ArgumentError {
      return GamepadBindings.defaults;
    }
  }
}

Map<K, V> _decodeMap<K extends Enum, V extends Enum>(
  Object? value,
  List<K> keys,
  List<V> values,
) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid bindings.');
  }
  return {
    for (final entry in value.entries)
      _enumValue(keys, entry.key): _enumValue(values, entry.value),
  };
}

T _enumValue<T extends Enum>(List<T> values, Object? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw const FormatException('Unknown gamepad control or action.');
}
