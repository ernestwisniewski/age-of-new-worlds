part of 'game_audio_runtime.dart';

final class _AudioEffects {
  _AudioEffects(this.owner);

  static const _preloadedPerAsset = 2;
  static const _maximumPerAsset = 6;
  final GameAudioRuntime owner;
  final _pools = <String, List<_EffectVoice>>{};

  int get activeCount =>
      _pools.values.expand((pool) => pool).where((slot) => slot.active).length;

  Future<void> synchronize() async {
    for (final entry in _pools.entries.toList()) {
      for (final slot in entry.value.toList()) {
        await owner._perform(
          'configure effect ${entry.key}',
          () => _updateSlot(entry.value, slot),
        );
      }
    }
    for (final asset in AudioAssetCatalog.effects.values.toSet()) {
      await owner._perform('prepare effect $asset', () async {
        final pool = _pools.putIfAbsent(asset, () => []);
        while (pool.length < _preloadedPerAsset && owner._soundVolume > 0) {
          pool.add(await _create(asset));
        }
      });
    }
  }

  Future<void> _updateSlot(List<_EffectVoice> pool, _EffectVoice slot) async {
    try {
      if (owner._soundVolume <= 0) {
        slot.active = false;
        await slot.voice.stop();
      } else {
        await slot.voice.setVolume(owner._soundVolume);
      }
    } on Object {
      pool.remove(slot);
      await slot.dispose();
      rethrow;
    }
  }

  Future<_EffectVoice> _create(String asset) async {
    final voice = await owner._device.createVoice();
    try {
      await voice.prepare(asset);
      return _EffectVoice(voice);
    } on Object {
      await voice.dispose();
      rethrow;
    }
  }

  bool _canPlay(int generation) =>
      owner._soundVolume > 0 && generation == owner._soundGeneration;

  Future<void> play(GameSoundCue cue, int generation) async {
    if (!_canPlay(generation)) return;
    final asset = AudioAssetCatalog.effects[cue]!;
    final pool = _pools.putIfAbsent(asset, () => []);
    var slot = pool.where((entry) => !entry.active).firstOrNull;
    if (slot == null) {
      if (pool.length >= _maximumPerAsset) return;
      slot = await _create(asset);
      pool.add(slot);
    }
    if (!_canPlay(generation)) return;
    slot.active = true;
    try {
      await slot.voice.setVolume(owner._soundVolume);
      if (!_canPlay(generation)) {
        slot.active = false;
        return;
      }
      await slot.voice.resume();
      if (!_canPlay(generation)) {
        slot.active = false;
        await slot.voice.stop();
      }
    } on Object {
      pool.remove(slot);
      await slot.dispose();
      rethrow;
    }
  }

  Future<void> dispose() async {
    final voices = _pools.values.expand((pool) => pool).toList();
    _pools.clear();
    await Future.wait([for (final slot in voices) slot.dispose()]);
  }
}

final class _EffectVoice {
  _EffectVoice(this.voice) {
    _completion = voice.completed.listen((_) => active = false);
  }

  final AudioPlaybackVoice voice;
  late final StreamSubscription<void> _completion;
  bool active = false;

  Future<void> dispose() async {
    active = false;
    try {
      await _completion.cancel();
    } finally {
      await voice.dispose();
    }
  }
}
