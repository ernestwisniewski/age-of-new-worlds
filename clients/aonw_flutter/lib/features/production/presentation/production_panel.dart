import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../map/read_model/map_view.dart';
import '../application/production_state.dart';
import '../read_model/production_view.dart';
import 'production_copy.dart';

final class ProductionPanel extends StatelessWidget {
  const ProductionPanel({
    required this.state,
    required this.onAction,
    this.enabled = true,
    super.key,
  });

  final ProductionState state;
  final ValueChanged<ProductionActionView> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    final acceptsInput = enabled && !state.loading && !state.commandPending;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AonwSpacing.md),
          Text(
            copy.text(ProductionText.title),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (state.loading)
            AonwProgressIndicator(
              semanticLabel: copy.text(ProductionText.loading),
              compact: true,
            )
          else if (state.options case final options?) ...[
            _ProductionSummary(options: options),
            if (state.resources case final resources?)
              _ResourceSummary(resources: resources),
            _ProductionActions(
              options: options,
              enabled: acceptsInput,
              onAction: onAction,
            ),
          ],
          if (state.commandPending)
            AonwProgressIndicator(
              semanticLabel: copy.text(ProductionText.executing),
              compact: true,
            ),
          if (state.failure case final failure?)
            Text(
              copy.failure(failure),
              key: const ValueKey('production-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

final class _ProductionSummary extends StatelessWidget {
  const _ProductionSummary({required this.options});

  final ProductionOptionsView options;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    final target = options.currentTarget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${copy.text(ProductionText.current)}: '
          '${target == null ? '—' : copy.target(target)}',
        ),
        Text(
          '${copy.text(ProductionText.invested)}: '
          '${options.investedProduction} · '
          '${copy.text(ProductionText.overflow)}: '
          '${options.productionOverflow}',
        ),
      ],
    );
  }
}

final class _ResourceSummary extends StatelessWidget {
  const _ResourceSummary({required this.resources});

  final StrategicResourceProjectionView resources;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    final value = resources.output.isEmpty
        ? '—'
        : resources.output
              .map((item) => '${copy.resource(item.resource)} ${item.amount}')
              .join(', ');
    return Semantics(
      label: copy.text(ProductionText.resources),
      value: value,
      child: Text('${copy.text(ProductionText.resources)}: $value'),
    );
  }
}

final class _ProductionActions extends StatelessWidget {
  const _ProductionActions({
    required this.options,
    required this.enabled,
    required this.onAction,
  });

  final ProductionOptionsView options;
  final bool enabled;
  final ValueChanged<ProductionActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    var order = 30.0;
    Widget button({
      required ProductionActionView action,
      required String label,
      ProductionRejectionCodeView? blocker,
    }) {
      final reason = copy.rejection(blocker);
      final semanticLabel = reason == null ? label : '$label. $reason';
      return FocusTraversalOrder(
        order: NumericFocusOrder(order++),
        child: Semantics(
          label: semanticLabel,
          button: true,
          enabled: enabled && blocker == null,
          child: OutlinedButton(
            key: ValueKey(('production-action', action.runtimeType, label)),
            onPressed: enabled && blocker == null
                ? () => onAction(action)
                : null,
            child: Text(reason == null ? label : '$label · $reason'),
          ),
        ),
      );
    }

    final sections = <Widget>[];
    void section(String title, List<Widget> children) {
      if (children.isEmpty) return;
      sections.add(Text(title, style: Theme.of(context).textTheme.labelMedium));
      sections.add(
        Wrap(
          spacing: AonwSpacing.xs,
          runSpacing: AonwSpacing.xs,
          children: children,
        ),
      );
    }

    section(copy.text(ProductionText.buildings), [
      for (final option in options.buildings)
        button(
          action: StartBuildingActionView(
            cityId: options.cityId,
            building: (option.target as BuildingProductionTargetView).building,
          ),
          label: _optionLabel(copy, option),
          blocker: option.blocker,
        ),
    ]);
    section(copy.text(ProductionText.units), [
      for (final option in options.units)
        ..._unitButtons(
          copy: copy,
          cityId: options.cityId,
          option: option,
          button: button,
        ),
    ]);
    section(copy.text(ProductionText.projects), [
      for (final option in options.projects)
        button(
          action: StartCityProjectActionView(
            cityId: options.cityId,
            project: (option.target as ProjectProductionTargetView).project,
          ),
          label: _optionLabel(copy, option),
          blocker: option.blocker,
        ),
    ]);
    section(copy.text(ProductionText.wonders), [
      for (final option in options.wonders)
        button(
          action: StartWonderActionView(
            cityId: options.cityId,
            wonder: (option.target as WonderProductionTargetView).wonder,
          ),
          label: _optionLabel(copy, option),
          blocker: option.blocker,
        ),
    ]);
    section(copy.text(ProductionText.specializations), [
      for (final option in options.specializations)
        button(
          action: SetCitySpecializationActionView(
            cityId: options.cityId,
            specialization: option.specialization,
          ),
          label:
              '${copy.cityContent(option.specialization)} · '
              '${copy.text(ProductionText.requires)} '
              '${copy.cityContent(option.requiredBuilding)}',
          blocker: option.blocker,
        ),
    ]);
    if (options.currentTarget != null) {
      sections.add(
        button(
          action: RushProductionActionView(cityId: options.cityId),
          label: copy.text(ProductionText.rush),
        ),
      );
    }
    return sections.isEmpty
        ? Text(copy.text(ProductionText.empty))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections,
          );
  }
}

List<Widget> _unitButtons({
  required ProductionCopy copy,
  required String cityId,
  required UnitProductionOptionView option,
  required Widget Function({
    required ProductionActionView action,
    required String label,
    ProductionRejectionCodeView? blocker,
  })
  button,
}) {
  final target = option.option.target as UnitProductionTargetView;
  if (option.resourceOptions.isEmpty) {
    return [
      button(
        action: StartUnitProductionActionView(
          cityId: cityId,
          unit: target.unit,
          resourceOptionIndex: null,
        ),
        label: _optionLabel(copy, option.option),
        blocker: option.option.blocker,
      ),
    ];
  }
  return [
    for (var index = 0; index < option.resourceOptions.length; index++)
      button(
        action: StartUnitProductionActionView(
          cityId: cityId,
          unit: target.unit,
          resourceOptionIndex: index,
        ),
        label:
            '${_optionLabel(copy, option.option)} · '
            '${_stockpile(copy, option.resourceOptions[index])}',
        blocker:
            option.option.blocker ??
            (option.affordableResourceOptionIndices.contains(index)
                ? null
                : ProductionRejectionCodeView
                      .unitProductionMissingStrategicResource),
      ),
  ];
}

String _optionLabel(ProductionCopy copy, ProductionOptionView option) =>
    '${copy.target(option.target)} · ${copy.text(ProductionText.cost)} '
    '${option.cost}';

String _stockpile(ProductionCopy copy, Map<MapResource, int> value) => value
    .entries
    .map((entry) => '${copy.resource(entry.key)} ${entry.value}')
    .join(' + ');
