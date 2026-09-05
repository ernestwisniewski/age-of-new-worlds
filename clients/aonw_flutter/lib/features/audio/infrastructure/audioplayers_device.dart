import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_playback_device.dart';

final class AudioplayersDevice implements AudioPlaybackDevice {
  final _cache = AudioCache();
  final _voices = <_AudioplayersVoice>{};
  AudioContext? _context;
  var _disposed = false;

  @visibleForTesting
  int get debugVoiceCount => _voices.length;

  @visibleForTesting
  int get debugCachedAssetCount => _cache.loadedFiles.length;

  @visibleForTesting
  Future<List<Duration?>> debugPositions() => Future.wait([
    for (final voice in _voices) voice.player.getCurrentPosition(),
  ]);

  @override
  Future<void> configureFocus({required bool musicAudible}) async {
    final context = AudioContextConfig(
      focus: musicAudible
          ? AudioContextConfigFocus.gain
          : AudioContextConfigFocus.mixWithOthers,
    ).build();
    if (_disposed || _context == context) return;
    await AudioPlayer.global.setAudioContext(context);
    for (final voice in _voices) {
      await voice.player.setAudioContext(context);
    }
    _context = context;
  }

  @override
  Future<AudioPlaybackVoice> createVoice() async {
    if (_disposed) throw StateError('Audio device is disposed.');
    final player = AudioPlayer()..audioCache = _cache;
    final voice = _AudioplayersVoice(player, onDisposed: _voices.remove);
    _voices.add(voice);
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      if (_context case final context?) await player.setAudioContext(context);
      return voice;
    } on Object {
      await voice.dispose();
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await Future.wait([
        for (final voice in _voices.toList()) voice.dispose(),
      ]);
    } finally {
      await _cache.clearAll();
    }
  }
}

final class _AudioplayersVoice implements AudioPlaybackVoice {
  _AudioplayersVoice(this.player, {required this.onDisposed});

  final AudioPlayer player;
  final void Function(_AudioplayersVoice voice) onDisposed;
  var _disposed = false;

  @override
  Stream<void> get completed => player.onPlayerComplete;

  @override
  Future<void> prepare(String asset) async {
    await player.stop();
    await player.setSource(AssetSource(asset.substring('assets/'.length)));
  }

  @override
  Future<void> setVolume(double volume) => player.setVolume(volume);

  @override
  Future<void> resume() => player.resume();

  @override
  Future<void> stop() => player.stop();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await player.dispose();
    } finally {
      onDisposed(this);
    }
  }
}
