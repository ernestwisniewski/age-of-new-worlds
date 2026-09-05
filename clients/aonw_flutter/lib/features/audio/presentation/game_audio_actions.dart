import 'package:flutter/widgets.dart';

import '../application/game_audio_port.dart';
import 'game_audio_scope.dart';

export '../application/game_audio_port.dart' show GameSoundCue;

extension GameAudioActions on BuildContext {
  void playGameSound(GameSoundCue cue) {
    if (!mounted) return;
    getInheritedWidgetOfExactType<GameAudioScope>()?.session.play(cue);
  }

  VoidCallback? withGameSound(
    VoidCallback? action, {
    GameSoundCue cue = GameSoundCue.menuClick,
  }) {
    if (action == null) return null;
    return () {
      playGameSound(cue);
      action();
    };
  }

  ValueChanged<T>? withGameSoundValue<T>(
    ValueChanged<T>? action, {
    GameSoundCue cue = GameSoundCue.menuClick,
  }) {
    if (action == null) return null;
    return (value) {
      playGameSound(cue);
      action(value);
    };
  }
}
