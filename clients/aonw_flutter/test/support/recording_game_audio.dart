import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/settings/application/client_audio_settings.dart';

export 'package:aonw_flutter/features/audio/application/game_audio_port.dart'
    show GameSoundCue;

final class RecordingGameAudio implements GameAudioPort {
  final cues = <GameSoundCue>[];

  @override
  Future<void> configure(
    ClientAudioSettings settings, {
    required bool active,
    required bool mapActive,
  }) async {}

  @override
  Future<void> play(GameSoundCue cue) async => cues.add(cue);

  @override
  Future<void> dispose() async {}
}
