part of 'map_screen.dart';

final class _SaveAction extends StatelessWidget {
  const _SaveAction({
    required this.localSave,
    required this.localAiTurn,
    required this.localHandoff,
    required this.onSave,
  });

  final LocalSaveState localSave;
  final LocalAiTurnState localAiTurn;
  final LocalHandoffState localHandoff;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final failure = localSave.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AonwHudIconButton(
          key: const ValueKey('save-game'),
          tooltip: localSave.inFlight
              ? context.aonwL10n.savingGame
              : context.aonwL10n.saveGame,
          onPressed:
              localSave.inFlight ||
                  localAiTurn.blocksGameplay ||
                  localHandoff.blocksGameplay
              ? null
              : onSave,
          icon: Icon(
            localSave.inFlight ? Icons.hourglass_top : Icons.save_outlined,
          ),
        ),
        if (localSave.phase == LocalSavePhase.saved)
          _SaveMessage(message: context.aonwL10n.gameSaved),
        if (failure != null)
          _SaveMessage(
            message: context.aonwL10n.saveFailure(failure.name),
            error: true,
          ),
      ],
    );
  }
}

final class _SaveMessage extends StatelessWidget {
  const _SaveMessage({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AonwPanel(
      padding: const EdgeInsets.all(AonwSpacing.xs),
      child: Text(
        message,
        key: const ValueKey('save-status'),
        style: error
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      ),
    ),
  );
}
