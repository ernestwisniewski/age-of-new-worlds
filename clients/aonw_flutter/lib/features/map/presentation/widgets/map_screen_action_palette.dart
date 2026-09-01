part of 'map_screen.dart';

extension _MapScreenActionPalette on _MapScreenState {
  void _handleActionPaletteIntent(MapActionPaletteIntent intent) {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) return;
    if (widget.controller.networkConnection.blocksGameplay) return;
    final state = widget.controller.state;
    if (state is! GameSessionReady || state.localHandoff.blocksGameplay) return;
    switch (intent) {
      case ConfirmMapMovePaletteIntent():
        widget.controller.confirmMove();
      case PreviewWorkerImprovementPaletteIntent(
        :final unitId,
        :final improvement,
      ):
        widget.controller.executeWorkerAction(
          SelectWorkerImprovementActionView(
            unitId: unitId,
            improvement: improvement,
          ),
        );
      case ConfirmWorkerImprovementPaletteIntent(
        :final unitId,
        :final improvement,
      ):
        widget.controller.executeWorkerAction(
          ConfirmWorkerImprovementActionView(
            unitId: unitId,
            improvement: improvement,
          ),
        );
    }
  }
}
