part of 'aonw_flame_game.dart';

extension AonwFlameGameDisplay on AonwFlameGame {
  void setCityPlanning(CityPlanningView? planning) {
    if (!_disposed && world.applyCityPlanning(planning)) {
      _requestInputFrame();
    }
  }

  void setMapDisplayOptions(MapDisplayOptions options) {
    if (!_disposed && world.applyMapDisplayOptions(options)) {
      _requestInputFrame();
    }
  }
}
