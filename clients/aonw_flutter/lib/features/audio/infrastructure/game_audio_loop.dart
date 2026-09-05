part of 'game_audio_runtime.dart';

final class _AudioLoop {
  _AudioLoop(
    this.owner, {
    required this.name,
    required this.assets,
    required this.volume,
  });

  final GameAudioRuntime owner;
  final String name;
  final List<String> assets;
  final double Function() volume;
  AudioPlaybackVoice? _voice;
  StreamSubscription<void>? _completion;
  var _running = false;
  var _index = 0;
  var _generation = 0;

  String? get runningAsset => _running ? assets[_index] : null;

  Future<void> synchronize() async {
    if (volume() <= 0) {
      await _stop();
      return;
    }
    final voice = _voice ??= await owner._device.createVoice();
    try {
      await voice.setVolume(volume());
      if (_running) return;
      await voice.prepare(assets[_index]);
      if (volume() <= 0) return;
      await voice.setVolume(volume());
      final generation = ++_generation;
      await _completion?.cancel();
      _completion = voice.completed.listen((_) {
        unawaited(
          owner._enqueue('advance $name', () async {
            if (generation != _generation || !_running || volume() <= 0) return;
            _running = false;
            _index = (_index + 1) % assets.length;
            await synchronize();
          }),
        );
      });
      await voice.resume();
      _running = true;
      if (volume() <= 0) await _stop();
    } on Object {
      await dispose();
      rethrow;
    }
  }

  Future<void> _stop() async {
    _running = false;
    _generation++;
    await _completion?.cancel();
    _completion = null;
    try {
      await _voice?.stop();
    } on Object {
      await dispose();
      rethrow;
    }
  }

  Future<void> dispose() async {
    _running = false;
    _generation++;
    final voice = _voice;
    _voice = null;
    try {
      await _completion?.cancel();
      _completion = null;
    } finally {
      await voice?.dispose();
    }
  }
}
