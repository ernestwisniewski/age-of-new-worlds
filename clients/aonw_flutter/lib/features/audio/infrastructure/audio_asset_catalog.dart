import '../application/game_audio_port.dart';

abstract final class AudioAssetCatalog {
  static const effects = <GameSoundCue, String>{
    GameSoundCue.uiPanelOpen: 'assets/audio/ui_panel_open.wav',
    GameSoundCue.uiPanelClose: 'assets/audio/menu_back.wav',
    GameSoundCue.menuClick: 'assets/audio/menu_click.wav',
    GameSoundCue.menuBack: 'assets/audio/menu_back.wav',
    GameSoundCue.mapTileSelect: 'assets/audio/map_tile_select.wav',
    GameSoundCue.movePreview: 'assets/audio/map_tile_select.wav',
    GameSoundCue.moveConfirm: 'assets/audio/move_confirm.wav',
    GameSoundCue.attack: 'assets/audio/attack.wav',
    GameSoundCue.city: 'assets/audio/city.wav',
    GameSoundCue.newTurn: 'assets/audio/new_turn.wav',
    GameSoundCue.technology: 'assets/audio/technology.wav',
    GameSoundCue.walk: 'assets/audio/walk.wav',
  };

  static const music = [
    'assets/audio/music/korona1.mp3',
    'assets/audio/music/korona2.mp3',
    'assets/audio/music/kroniki1.mp3',
    'assets/audio/music/kroniki2.mp3',
    'assets/audio/music/oddech1.mp3',
    'assets/audio/music/oddech2.mp3',
    'assets/audio/music/szepty1.mp3',
    'assets/audio/music/szepty2.mp3',
  ];

  static const nature = [
    'assets/audio/nature/656124__itsthegoodstuff__nature-ambiance.mp3',
  ];

  static Set<String> get assets => {...effects.values, ...music, ...nature};
}
