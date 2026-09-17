import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../application/production_state.dart';
import '../read_model/production_view.dart';
import 'production_active_banner.dart';
import 'production_catalog.dart';
import 'production_copy.dart';

final class ProductionPanel extends StatelessWidget {
  const ProductionPanel({
    required this.state,
    required this.onAction,
    this.enabled = true,
    this.treasury,
    this.cityName,
    this.onClose,
    super.key,
  });

  final ProductionState state;
  final ValueChanged<ProductionActionView> onAction;
  final bool enabled;
  final int? treasury;
  final String? cityName;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final copy = ProductionCopy.of(context);
      final compact =
          constraints.maxHeight < 600 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      return FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, copy),
            if (state.loading)
              AonwProgressIndicator(
                semanticLabel: copy.text(ProductionText.loading),
                compact: true,
              )
            else if (state.options case final options?)
              ..._content(options, compact),
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
    },
  );

  Widget _header(BuildContext context, ProductionCopy copy) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.text(ProductionText.title),
              style: AonwTextStyles.screenTitle,
            ),
            if (cityName case final name?)
              Text(name, style: AonwTextStyles.cardTitle),
          ],
        ),
      ),
      if (onClose != null)
        IconButton(
          key: const ValueKey('close-production'),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: state.commandPending ? null : onClose,
          icon: const Icon(Icons.close),
        ),
    ],
  );

  List<Widget> _content(ProductionOptionsView options, bool compact) {
    final acceptsInput = enabled && !state.commandPending;
    final overview = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProductionActiveBanner(
          options: options,
          enabled: acceptsInput,
          onAction: onAction,
          treasury: treasury,
        ),
        if (state.resources case final resources?)
          _ResourceSummary(resources: resources),
      ],
    );
    return [
      if (!compact) overview,
      Expanded(
        child: ProductionCatalog(
          key: ValueKey(options.cityId),
          header: compact ? overview : null,
          options: options,
          enabled: acceptsInput,
          onAction: onAction,
        ),
      ),
    ];
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
