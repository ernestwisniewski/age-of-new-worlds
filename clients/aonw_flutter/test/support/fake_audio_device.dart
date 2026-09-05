import 'dart:async';

import 'package:aonw_flutter/features/audio/infrastructure/audio_playback_device.dart';

final class FakeAudioDevice implements AudioPlaybackDevice {
  final voices = <FakeAudioVoice>[];
  final focus = <bool>[];
  final failedAssets = <String>{};
  Future<void>? preparationGate;
  final preparationStarted = Completer<void>();
  bool disposed = false;
  bool failNextResume = false;

  @override
  Future<void> configureFocus({required bool musicAudible}) async {
    focus.add(musicAudible);
  }

  @override
  Future<AudioPlaybackVoice> createVoice() async {
    if (disposed) throw StateError('Device is disposed.');
    final voice = FakeAudioVoice(this);
    voices.add(voice);
    return voice;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    for (final voice in voices) {
      await voice.dispose();
    }
  }
}

final class FakeAudioVoice implements AudioPlaybackVoice {
  FakeAudioVoice(this.device);

  final FakeAudioDevice device;
  final _completion = StreamController<void>.broadcast(sync: true);
  String? asset;
  double volume = 1;
  int starts = 0;
  bool playing = false;
  bool disposed = false;
  bool failStop = false;

  @override
  Stream<void> get completed => _completion.stream;

  @override
  Future<void> prepare(String value) async {
    playing = false;
    asset = value;
    if (!device.preparationStarted.isCompleted) {
      device.preparationStarted.complete();
    }
    await device.preparationGate;
    if (device.failedAssets.contains(value)) {
      throw StateError('Cannot prepare $value');
    }
  }

  @override
  Future<void> setVolume(double value) async => volume = value;

  @override
  Future<void> resume() async {
    if (device.failNextResume) {
      device.failNextResume = false;
      throw StateError('Cannot resume the voice.');
    }
    if (disposed) throw StateError('Voice is disposed.');
    starts++;
    playing = true;
  }

  void complete() {
    playing = false;
    _completion.add(null);
  }

  @override
  Future<void> stop() async {
    if (failStop) throw StateError('Cannot stop the voice.');
    playing = false;
  }

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    playing = false;
    await _completion.close();
  }
}
