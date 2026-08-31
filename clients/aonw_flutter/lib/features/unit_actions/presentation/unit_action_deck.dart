import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../features/logistics/application/unit_logistics_state.dart';
import '../../../features/logistics/presentation/unit_logistics_failure_messages.dart';
import '../../../features/logistics/read_model/unit_logistics_view.dart';
import '../../../l10n/l10n.dart';
import '../application/action_deck_state.dart';
import '../read_model/unit_action_view.dart';
import 'unit_action_failure_messages.dart';

final class UnitActionDeck extends StatelessWidget {
  const UnitActionDeck({
    required this.state,
    required this.logistics,
    required this.onAction,
    required this.onLogisticsAction,
    this.enabled = true,
    super.key,
  });

  final ActionDeckViewState state;
  final UnitLogisticsState? logistics;
  final ValueChanged<UnitActionKindView> onAction;
  final ValueChanged<UnitLogisticsActionView> onLogisticsAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final acceptsInput =
        enabled &&
        !state.commandPending &&
        !(logistics?.commandPending ?? false);
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AonwSpacing.sm),
          Text(
            l10n.unitActionLabel('title'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AonwSpacing.xs),
          Wrap(
            spacing: AonwSpacing.xs,
            runSpacing: AonwSpacing.xs,
            children: _actionButtons(l10n, acceptsInput, onAction),
          ),
          if (state.commandPending) ...[
            const SizedBox(height: AonwSpacing.sm),
            AonwProgressIndicator(
              semanticLabel: l10n.unitActionLabel('executing'),
              compact: true,
            ),
          ],
          if (state.failure case final failure?) ...[
            const SizedBox(height: AonwSpacing.sm),
            Text(
              unitActionFailureMessage(l10n, failure),
              key: const ValueKey('unit-action-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (logistics case final logistics?)
            _UnitLogisticsDeck(
              state: logistics,
              enabled: enabled && !state.commandPending,
              onAction: onLogisticsAction,
            ),
        ],
      ),
    );
  }
}

final class _UnitLogisticsDeck extends StatelessWidget {
  const _UnitLogisticsDeck({
    required this.state,
    required this.enabled,
    required this.onAction,
  });

  final UnitLogisticsState state;
  final bool enabled;
  final ValueChanged<UnitLogisticsActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final options = state.options;
    final acceptsInput = enabled && !state.commandPending;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AonwSpacing.md),
        Text(
          l10n.unitActionLabel('logisticsTitle'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (state.loading) ...[
          const SizedBox(height: AonwSpacing.xs),
          AonwProgressIndicator(
            semanticLabel: l10n.unitActionLabel('logisticsLoading'),
            compact: true,
          ),
        ] else if (options != null) ...[
          const SizedBox(height: AonwSpacing.xs),
          if (options.isEmpty)
            Text(l10n.unitActionLabel('logisticsEmpty'))
          else
            Wrap(
              spacing: AonwSpacing.xs,
              runSpacing: AonwSpacing.xs,
              children: _logisticsButtons(
                l10n,
                options,
                acceptsInput,
                onAction,
              ),
            ),
        ],
        if (state.commandPending) ...[
          const SizedBox(height: AonwSpacing.sm),
          AonwProgressIndicator(
            semanticLabel: l10n.unitActionLabel('executing'),
            compact: true,
          ),
        ],
        if (state.failure case final failure?) ...[
          const SizedBox(height: AonwSpacing.sm),
          Text(
            unitLogisticsFailureMessage(l10n, failure),
            key: const ValueKey('unit-logistics-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

List<Widget> _logisticsButtons(
  AonwLocalizations l10n,
  UnitLogisticsOptionsView options,
  bool enabled,
  ValueChanged<UnitLogisticsActionView> onAction,
) {
  final buttons = <Widget>[];
  var order = 10.0;
  void add(UnitLogisticsActionView action, String label, IconData icon) {
    buttons.add(
      FocusTraversalOrder(
        order: NumericFocusOrder(order++),
        child: OutlinedButton.icon(
          key: ValueKey(('unit-logistics', action.labelKey, label)),
          onPressed: enabled ? () => onAction(action) : null,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  if (options.autoExplore case final option?) {
    add(
      AutoExploreActionView(unitId: options.unitId),
      '${l10n.unitActionLabel('autoExplore')} · ${option.totalCostUnits}',
      Icons.explore_outlined,
    );
  }
  for (final option in options.merchantRouteDestinations) {
    add(
      AssignMerchantRouteActionView(
        unitId: options.unitId,
        destinationCityId: option.cityId,
      ),
      '${l10n.unitActionLabel('merchantRoute')} · ${option.cityId} '
      '(${option.totalCostUnits})',
      Icons.currency_exchange,
    );
  }
  for (final option in options.merchantTravelDestinations) {
    add(
      MoveMerchantToCityActionView(
        unitId: options.unitId,
        destinationCityId: option.cityId,
      ),
      '${l10n.unitActionLabel('merchantTravel')} · ${option.cityId} '
      '(${option.totalCostUnits})',
      Icons.storefront_outlined,
    );
  }
  for (final option in options.detachments) {
    add(
      DetachTroopActionView(
        unitId: options.unitId,
        troopKind: option.troopKind,
      ),
      '${l10n.unitActionLabel('detachTroop')} · '
      '${l10n.presentationName(option.troopKind.name)}',
      Icons.call_split,
    );
  }
  return buttons;
}

List<Widget> _actionButtons(
  AonwLocalizations l10n,
  bool enabled,
  ValueChanged<UnitActionKindView> onAction,
) => [
  _ActionButton(
    order: 1,
    action: UnitActionKindView.fortify,
    label: l10n.unitActionLabel('fortify'),
    icon: Icons.shield_outlined,
    enabled: enabled,
    onAction: onAction,
  ),
  _ActionButton(
    order: 2,
    action: UnitActionKindView.skip,
    label: l10n.unitActionLabel('skip'),
    icon: Icons.skip_next,
    enabled: enabled,
    onAction: onAction,
  ),
  _ActionButton(
    order: 3,
    action: UnitActionKindView.cancel,
    label: l10n.unitActionLabel('cancel'),
    icon: Icons.cancel_outlined,
    enabled: enabled,
    onAction: onAction,
  ),
];

final class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.order,
    required this.action,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onAction,
  });

  final double order;
  final UnitActionKindView action;
  final String label;
  final IconData icon;
  final bool enabled;
  final ValueChanged<UnitActionKindView> onAction;

  @override
  Widget build(BuildContext context) => FocusTraversalOrder(
    order: NumericFocusOrder(order),
    child: OutlinedButton.icon(
      key: ValueKey(('unit-action', action.name)),
      onPressed: enabled ? () => onAction(action) : null,
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}
