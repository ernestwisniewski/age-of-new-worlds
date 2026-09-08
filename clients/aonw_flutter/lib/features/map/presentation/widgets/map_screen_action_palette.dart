part of 'map_screen.dart';

extension _MapScreenActionPalette on _MapScreenState {
  void _handleActionPaletteIntent(MapActionPaletteIntent intent) {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) return;
    if (widget.controller.networkConnection.blocksGameplay) return;
    final state = widget.controller.state;
    if (state is! GameSessionReady || state.localHandoff.blocksGameplay) return;
    switch (intent) {
      case CancelWorkerSelectionPaletteIntent(:final unitId):
        _cancelWorkerPalette(state, unitId);
      case ConfirmMapMovePaletteIntent():
        widget.controller.confirmMove();
      case PreviewWorkerImprovementPaletteIntent(
        :final unitId,
        :final improvement,
      ):
        widget.controller.previewWorkerImprovement(unitId, improvement);
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

  void _cancelWorkerPalette(GameSessionReady state, String unitId) {
    if (state.interaction.worker?.unitId == unitId) {
      widget.controller.setWorkerActionsOpen(false);
    }
  }
}
