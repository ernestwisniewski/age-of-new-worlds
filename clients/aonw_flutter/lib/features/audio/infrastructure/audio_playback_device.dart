abstract interface class AudioPlaybackDevice {
  Future<void> configureFocus({required bool musicAudible});
  Future<AudioPlaybackVoice> createVoice();
  Future<void> dispose();
}

abstract interface class AudioPlaybackVoice {
  Stream<void> get completed;
  Future<void> prepare(String asset);
  Future<void> setVolume(double volume);
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}
