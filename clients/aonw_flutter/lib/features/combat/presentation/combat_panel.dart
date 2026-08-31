import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../l10n/l10n.dart';
import '../application/combat_state.dart';
import '../read_model/combat_view.dart';
import 'combat_failure_messages.dart';

final class CombatPanel extends StatelessWidget {
  const CombatPanel({
    required this.state,
    required this.onConfirm,
    required this.onCityConquestAction,
    super.key,
  });

  final CombatState state;
  final VoidCallback onConfirm;
  final ValueChanged<CityConquestActionView> onCityConquestAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AonwSpacing.md),
        Text(
          l10n.turnText('combatTitle'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        AnimatedSwitcher(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 160),
          child: _content(context),
        ),
        if (state.failure case final failure?) ...[
          const SizedBox(height: AonwSpacing.sm),
          Text(
            combatFailureMessage(l10n, failure),
            key: const ValueKey('combat-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.aonwL10n;
    if (state.loading) {
      return Padding(
        key: const ValueKey('combat-loading'),
        padding: const EdgeInsets.only(top: AonwSpacing.xs),
        child: AonwProgressIndicator(
          semanticLabel: l10n.turnText('combatLoading'),
          compact: true,
        ),
      );
    }
    final execution = state.lastExecution;
    if (execution != null) {
      return _CombatResult(
        key: const ValueKey('combat-result'),
        value: execution,
      );
    }
    final preview = state.preview;
    if (preview == null) return const SizedBox.shrink();
    return _CombatPreview(
      key: const ValueKey('combat-preview'),
      state: state,
      preview: preview,
      onConfirm: onConfirm,
      onCityConquestAction: onCityConquestAction,
    );
  }
}

final class _CombatPreview extends StatelessWidget {
  const _CombatPreview({
    required this.state,
    required this.preview,
    required this.onConfirm,
    required this.onCityConquestAction,
    super.key,
  });

  final CombatState state;
  final CombatPreviewView preview;
  final VoidCallback onConfirm;
  final ValueChanged<CityConquestActionView> onCityConquestAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final retaliation = preview.retaliationDamageMin == null
        ? l10n.turnText('combatNone')
        : '${preview.retaliationDamageMin}–${preview.retaliationDamageMax}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AonwSpacing.xs),
        Text('${l10n.turnText('combatTarget')}: ${preview.target.id}'),
        Text('${l10n.turnText('combatDistance')}: ${preview.distance}'),
        Text(
          '${l10n.turnText('combatOutgoing')}: '
          '${preview.outgoingDamageMin}–${preview.outgoingDamageMax}',
        ),
        Text('${l10n.turnText('combatRetaliation')}: $retaliation'),
        if (preview.target.kind == CombatTargetKindView.city) ...[
          const SizedBox(height: AonwSpacing.xs),
          SegmentedButton<CityConquestActionView>(
            segments: [
              ButtonSegment(
                value: CityConquestActionView.capture,
                label: Text(l10n.turnText('combatCapture')),
              ),
              ButtonSegment(
                value: CityConquestActionView.destroy,
                label: Text(l10n.turnText('combatDestroy')),
              ),
            ],
            selected: {state.cityConquestAction},
            onSelectionChanged: state.commandPending
                ? null
                : (values) => onCityConquestAction(values.single),
          ),
        ],
        const SizedBox(height: AonwSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('confirm-combat'),
          onPressed: state.commandPending ? null : onConfirm,
          icon: const Icon(Icons.flash_on_outlined),
          label: Text(l10n.turnText('combatConfirm')),
        ),
        if (state.commandPending) ...[
          const SizedBox(height: AonwSpacing.sm),
          AonwProgressIndicator(
            semanticLabel: l10n.turnText('combatExecuting'),
            compact: true,
          ),
        ],
      ],
    );
  }
}

final class _CombatResult extends StatelessWidget {
  const _CombatResult({required this.value, super.key});

  final CombatExecutionView value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final outcome = value.outcome;
    return Semantics(
      key: const ValueKey('combat-result-semantics'),
      liveRegion: true,
      label: l10n.turnText('combatResolved'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AonwSpacing.xs),
          Text(l10n.turnText('combatResolved')),
          Text(
            '${l10n.turnText('combatOutgoing')}: '
            '${outcome.outgoingDamage}; '
            '${l10n.turnText('combatRetaliation')}: '
            '${outcome.retaliationDamage}',
          ),
          Text(
            '${l10n.turnText('combatAttackerHp')}: '
            '${outcome.attackerHitPoints}; '
            '${l10n.turnText('combatDefenderHp')}: '
            '${outcome.defenderHitPoints}',
          ),
          for (final event in value.events)
            Text(
              l10n.turnText('combatEvent${_upperFirst(event.name)}'),
              key: ValueKey(('combat-event', value.revision, event.index)),
            ),
        ],
      ),
    );
  }
}

String _upperFirst(String value) =>
    '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
