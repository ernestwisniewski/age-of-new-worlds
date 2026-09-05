import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../settings/application/client_audio_settings.dart';
import '../application/game_audio_port.dart';
import 'audio_asset_catalog.dart';
import 'audio_playback_device.dart';

part 'game_audio_loop.dart';
part 'game_audio_effects.dart';

typedef GameAudioErrorReporter =
    void Function(String operation, Object error, StackTrace stack);

final class GameAudioRuntime implements GameAudioPort {
  GameAudioRuntime({
    required AudioPlaybackDevice device,
    Random? random,
    GameAudioErrorReporter? reportError,
  }) : _device = device,
       _reportError = reportError ?? _reportAudioError {
    _music = _AudioLoop(
      this,
      name: 'music',
      assets: [...AudioAssetCatalog.music]..shuffle(random ?? Random()),
      volume: () => _musicVolume,
    );
    _nature = _AudioLoop(
      this,
      name: 'nature',
      assets: AudioAssetCatalog.nature,
      volume: () => _natureVolume,
    );
    _effects = _AudioEffects(this);
  }

  final AudioPlaybackDevice _device;
  final GameAudioErrorReporter _reportError;
  final _reported = <String>{};
  late final _AudioLoop _music;
  late final _AudioLoop _nature;
  late final _AudioEffects _effects;
  var _settings = const ClientAudioSettings();
  var _active = false;
  var _mapActive = false;
  var _disposed = false;
  var _soundGeneration = 0;
  Future<void> _tail = Future.value();
  Future<void>? _disposal;

  double get _musicVolume => !_disposed && _active && _settings.musicEnabled
      ? _settings.musicVolume
      : 0;
  double get _natureVolume =>
      !_disposed && _active && _mapActive && _settings.natureEnabled
      ? _settings.natureVolume
      : 0;
  double get _soundVolume => !_disposed && _active && _settings.soundsEnabled
      ? _settings.soundVolume
      : 0;

  @visibleForTesting
  String? get debugMusicAsset => _music.runningAsset;
  @visibleForTesting
  String? get debugNatureAsset => _nature.runningAsset;
  @visibleForTesting
  int get debugActiveEffectCount => _effects.activeCount;
  @visibleForTesting
  Future<void> get debugSettled => _tail;

  @override
  Future<void> configure(
    ClientAudioSettings settings, {
    required bool active,
    required bool mapActive,
  }) {
    if (_disposed) return Future.value();
    final soundsWereAudible = _soundVolume > 0;
    _settings = settings;
    _active = active;
    _mapActive = mapActive;
    if (soundsWereAudible && _soundVolume <= 0) _soundGeneration++;
    return _enqueue('configure audio', _synchronize);
  }

  Future<void> _synchronize() async {
    if (_disposed) return;
    await _perform(
      'configure focus',
      () => _device.configureFocus(musicAudible: _musicVolume > 0),
    );
    await _perform('configure music', _music.synchronize);
    await _perform('configure nature', _nature.synchronize);
    await _perform('configure effects', _effects.synchronize);
  }

  @override
  Future<void> play(GameSoundCue cue) {
    if (_soundVolume <= 0) return Future.value();
    final generation = _soundGeneration;
    return _enqueue('play ${cue.name}', () => _effects.play(cue, generation));
  }

  Future<void> _enqueue(String operation, Future<void> Function() action) {
    final pending = _tail.then((_) => _perform(operation, action));
    _tail = pending.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return pending;
  }

  Future<void> _perform(
    String operation,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      _reported.remove(operation);
    } catch (error, stack) {
      if (_reported.add(operation)) _reportError(operation, error, stack);
    }
  }

  @override
  Future<void> dispose() {
    if (_disposal case final pending?) return pending;
    _disposed = true;
    return _disposal = _enqueue('dispose audio', () async {
      try {
        await Future.wait([
          _music.dispose(),
          _nature.dispose(),
          _effects.dispose(),
        ]);
      } finally {
        await _device.dispose();
      }
    });
  }
}

void _reportAudioError(String operation, Object error, StackTrace stack) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'AoNW audio',
      context: ErrorDescription('while attempting to $operation'),
    ),
  );
}
