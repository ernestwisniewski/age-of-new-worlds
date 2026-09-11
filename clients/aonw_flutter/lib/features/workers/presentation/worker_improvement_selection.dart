part of 'worker_panel.dart';

final class _WorkerImprovementSelection extends StatelessWidget {
  const _WorkerImprovementSelection({
    required this.state,
    this.readOnly = false,
    required this.options,
    required this.enabled,
    required this.onOpenChanged,
    required this.onPreview,
    required this.onAction,
  });

  final bool readOnly;
  final WorkerState state;
  final WorkerOptionsView options;
  final bool enabled;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<FieldImprovementKind> onPreview;
  final ValueChanged<WorkerActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final copy = WorkerCopy.of(context);
    return CallbackShortcuts(
      bindings: {
        if (enabled && state.actionsOpen)
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              onOpenChanged(false),
      },
      child: Wrap(
        spacing: AonwSpacing.xs,
        runSpacing: AonwSpacing.xs,
        children: [_toggle(copy), if (state.actionsOpen) ..._choices(copy)],
      ),
    );
  }

  Widget _toggle(WorkerCopy copy) => OutlinedButton.icon(
    key: const ValueKey('worker-actions-toggle'),
    onPressed: enabled ? () => onOpenChanged(!state.actionsOpen) : null,
    icon: Icon(state.actionsOpen ? Icons.close : Icons.handyman_outlined),
    label: Text(
      copy.text(
        state.actionsOpen ? WorkerText.closeActions : WorkerText.openActions,
      ),
    ),
  );

  List<Widget> _choices(WorkerCopy copy) => [
    for (final option in options.improvements)
      ChoiceChip(
        label: Text(
          '${copy.text(WorkerText.selectImprovement)} '
          '${copy.improvement(option.improvement.name)} (${option.buildTurns})',
        ),
        selected: state.previewedImprovement == option.improvement,
        onSelected: enabled ? (_) => onPreview(option.improvement) : null,
      ),
    if (state.previewedImprovement case final kind?) _confirm(copy, kind),
  ];

  Widget _confirm(
    WorkerCopy copy,
    FieldImprovementKind kind,
  ) => OutlinedButton.icon(
    key: const ValueKey('worker-improvement-confirm'),
    onPressed: enabled && !readOnly
        ? () => onAction(
            ConfirmWorkerImprovementActionView(
              unitId: options.unitId,
              improvement: kind,
            ),
          )
        : null,
    icon: const Icon(Icons.check_circle_outline),
    label: Text(
      '${copy.text(WorkerText.confirmImprovement)} · ${copy.improvement(kind.name)}',
    ),
  );
}
