import 'dart:async';

import 'package:flutter/services.dart';

final class ControlledSpriteBundle extends AssetBundle {
  final _gates = <String, AssetReadGate>{};
  final reads = <String, int>{};
  final failOnce = <String>{};

  AssetReadGate pause(String key) => _gates[key] = AssetReadGate();

  Future<void> _beforeRead(String key) async {
    reads.update(key, (count) => count + 1, ifAbsent: () => 1);
    final gate = _gates.remove(key);
    if (gate != null) {
      gate.started.complete();
      await gate.released.future;
    }
    if (failOnce.remove(key)) throw StateError('Asset unavailable: $key');
  }

  @override
  Future<ByteData> load(String key) async {
    await _beforeRead(key);
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    await _beforeRead(key);
    return rootBundle.loadString(key, cache: cache);
  }
}

final class AssetReadGate {
  final started = Completer<void>();
  final released = Completer<void>();
}
