part of 'map_screen.dart';

extension _MapScreenScene on _MapScreenState {
  void _synchronizeFlameScene() {
    switch (widget.controller.state) {
      case GameSessionReady(:final scene, :final interaction):
        _flameGame.sceneSink.replaceScene(
          MapRenderSnapshot(
            map: scene.map,
            interaction: interaction,
            reference: scene.reference,
            player: scene.player,
            feedbackLabels: switch (_localizations) {
              final l10n? => buildMapFeedbackLabels(
                scene.player.recentFeedback,
                l10n,
              ),
              null => const MapFeedbackLabels.empty(),
            },
            actionPalette: switch (_localizations) {
              final l10n? => buildMapActionPaletteView(
                interaction: interaction,
                player: scene.player,
                l10n: l10n,
              ),
              null => null,
            },
          ),
        );
      case GameSessionLoading() || GameSessionFailure():
        _flameGame.sceneSink.clearScene();
    }
  }

  void _synchronizeFlameCursor() {
    _flameGame.sceneSink.replaceCursor(widget.controller.cursor.value);
  }
}
