part of 'load_game_screen.dart';

final class _LoadFailureMessages extends StatelessWidget {
  const _LoadFailureMessages({
    required this.onlineFailureCode,
    required this.resumeFailure,
    required this.replayFailure,
    required this.transferAction,
    required this.transferResult,
  });

  final String? onlineFailureCode;
  final LocalResumeFailureViewCode? resumeFailure;
  final ReplayFailureViewCode? replayFailure;
  final _LocalSaveTransferAction? transferAction;
  final LocalSaveTransferResultView? transferResult;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _TransferMessage(action: transferAction, result: transferResult),
      if (onlineFailureCode case final code?) ...[
        const SizedBox(height: AonwSpacing.md),
        _FailureMessage(
          key: const ValueKey('online-resume-failure'),
          message: context.aonwL10n.multiplayerFailure(code),
        ),
      ],
      if (resumeFailure case final failure?) ...[
        const SizedBox(height: AonwSpacing.md),
        _FailureMessage(
          key: const ValueKey('resume-failure'),
          message: context.aonwL10n.resumeFailure(failure.name),
        ),
      ],
      if (replayFailure case final failure?) ...[
        const SizedBox(height: AonwSpacing.md),
        _FailureMessage(
          key: const ValueKey('replay-failure'),
          message: context.aonwL10n.replayFailure(failure.name),
        ),
      ],
    ],
  );
}

final class _TransferMessage extends StatelessWidget {
  const _TransferMessage({required this.action, required this.result});

  final _LocalSaveTransferAction? action;
  final LocalSaveTransferResultView? result;

  @override
  Widget build(BuildContext context) {
    final current = result;
    if (current == null ||
        current.status == LocalSaveTransferStatusView.cancelled) {
      return const SizedBox.shrink();
    }
    final failure = current.failure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AonwSpacing.md),
        child: _FailureMessage(
          key: const ValueKey('save-transfer-failure'),
          message: context.aonwL10n.saveTransferFailure(failure.name),
        ),
      );
    }
    final mapName = context.aonwL10n.localScenarioName(current.scenario!.name);
    final message = action == _LocalSaveTransferAction.importSave
        ? context.aonwL10n.saveImportCompleted(mapName)
        : context.aonwL10n.saveExportCompleted(mapName);
    return Padding(
      padding: const EdgeInsets.only(top: AonwSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          key: const ValueKey('save-transfer-success'),
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

final class _ImportAction extends StatelessWidget {
  const _ImportAction({
    required this.onPressed,
    required this.enabled,
    required this.active,
  });

  final VoidCallback? onPressed;
  final bool enabled;
  final bool active;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: onPressed == null ? context.aonwL10n.saveTransferUnavailable : '',
    child: OutlinedButton.icon(
      key: const ValueKey('import-save'),
      onPressed: enabled ? onPressed : null,
      icon: _ProgressIcon(active: active, fallback: Icons.file_upload_outlined),
      label: Text(context.aonwL10n.importSave),
    ),
  );
}

final class _EmptySaves extends StatelessWidget {
  const _EmptySaves({required this.onStartSinglePlayer});

  final VoidCallback onStartSinglePlayer;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(Icons.folder_off_outlined, size: 42),
      const SizedBox(height: AonwSpacing.md),
      Text(context.aonwL10n.loadGameEmpty),
      const SizedBox(height: AonwSpacing.lg),
      FilledButton.icon(
        key: const ValueKey('empty-start-single-player'),
        onPressed: onStartSinglePlayer,
        icon: const Icon(Icons.add),
        label: Text(context.aonwL10n.singlePlayer),
      ),
    ],
  );
}

final class _FailureMessage extends StatelessWidget {
  const _FailureMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
