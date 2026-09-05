import '../../settings/application/client_audio_settings.dart';

enum GameSoundCue {
  uiPanelOpen,
  uiPanelClose,
  menuClick,
  menuBack,
  mapTileSelect,
  movePreview,
  moveConfirm,
  attack,
  city,
  newTurn,
  technology,
  walk,
}

abstract interface class GameAudioPort {
  Future<void> configure(
    ClientAudioSettings settings, {
    required bool active,
    required bool mapActive,
  });

  Future<void> play(GameSoundCue cue);

  Future<void> dispose();
}
