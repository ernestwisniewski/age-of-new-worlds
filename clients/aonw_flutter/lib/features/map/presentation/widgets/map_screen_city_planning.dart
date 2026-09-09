part of 'map_screen.dart';

extension _MapScreenCityPlanning on _MapScreenState {
  void _synchronizeCityPlanning() {
    final state = widget.controller.state;
    _cityPlanning.synchronize(
      session: widget.controller.cityPlanningSession,
      player:
          state is GameSessionReady &&
              !state.localHandoff.blocksGameplay &&
              !state.localAiTurn.blocksGameplay &&
              !widget.controller.networkConnection.blocksGameplay
          ? state.scene.player
          : null,
      enabled: _planningEnabled,
      epoch: widget.controller,
    );
  }
}
