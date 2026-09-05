import 'package:flutter/widgets.dart';

import '../../audio/presentation/game_audio_actions.dart';
import '../read_model/map_feedback_view.dart';

extension MapAudio on BuildContext {
  void playMapSound(MapSoundKindView sound) => playGameSound(switch (sound) {
    MapSoundKindView.city => GameSoundCue.city,
    MapSoundKindView.combat => GameSoundCue.attack,
    MapSoundKindView.movement => GameSoundCue.walk,
  });
}
