import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../read_model/production_view.dart';
import 'production_copy.dart';

final class ProductionActiveBanner extends StatelessWidget {
  const ProductionActiveBanner({
    required this.options,
    required this.enabled,
    required this.onAction,
    this.treasury,
    super.key,
  });

  final ProductionOptionsView options;
  final bool enabled;
  final ValueChanged<ProductionActionView> onAction;
  final int? treasury;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    final current = options.currentOption;
    return Container(
      key: const ValueKey('production-active-banner'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
      padding: const EdgeInsets.all(AonwSpacing.md),
      decoration: BoxDecoration(
        color: AonwColorTokens.surface,
        border: Border.all(color: AonwColorTokens.brandDark),
        borderRadius: BorderRadius.circular(AonwRadii.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            copy.text(ProductionText.current),
            style: AonwTextStyles.sectionHeader,
          ),
          const SizedBox(height: AonwSpacing.xs),
          if (current == null)
            Text(copy.text(ProductionText.choose), style: AonwTextStyles.body)
          else ...[
            Text(copy.target(current.target), style: AonwTextStyles.cardTitle),
            const SizedBox(height: AonwSpacing.sm),
            _ActiveProgress(option: current),
            if (current.target is! ProjectProductionTargetView)
              _RushAction(
                options: options,
                enabled: enabled,
                onAction: onAction,
              ),
          ],
          if (options.productionOverflow > 0)
            Text(
              '${copy.text(ProductionText.overflow)}: ${options.productionOverflow}',
              style: AonwTextStyles.bodySmall,
            ),
          if (treasury case final gold?)
            Text(copy.treasury(gold), style: AonwTextStyles.bodySmall),
        ],
      ),
    );
  }
}

final class _ActiveProgress extends StatelessWidget {
  const _ActiveProgress({required this.option});

  final ProductionOptionView option;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    final forecast = option.forecast;
    final progress = copy.progress(forecast.investedProduction, option.cost);
    final project = option.target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(copy.estimate(forecast), style: AonwTextStyles.bodyStrong),
        if (project is ProjectProductionTargetView)
          Text(
            copy.output(project, forecast.projectOutput!),
            style: AonwTextStyles.body,
          )
        else ...[
          const SizedBox(height: AonwSpacing.sm),
          LinearProgressIndicator(
            value: (forecast.investedProduction / option.cost).clamp(0.0, 1.0),
            color: AonwColorTokens.brand,
            backgroundColor: AonwColorTokens.chipSurface,
            semanticsLabel: '${copy.target(option.target)}. $progress',
          ),
          const SizedBox(height: AonwSpacing.xs),
          Text(progress, style: AonwTextStyles.bodySmall),
        ],
        Text(
          copy.rate(forecast.productionPerTurn),
          style: AonwTextStyles.bodySmall,
        ),
      ],
    );
  }
}

final class _RushAction extends StatelessWidget {
  const _RushAction({
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
    final quote = options.rushQuote;
    final blocker = copy.rejection(quote.blocker);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(20),
            child: OutlinedButton.icon(
              key: const ValueKey('production-rush'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: enabled && quote.blocker == null
                  ? () => onAction(
                      RushProductionActionView(cityId: options.cityId),
                    )
                  : null,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                quote.production > 0
                    ? copy.rush(quote.production, quote.goldCost)
                    : copy.text(ProductionText.rush),
              ),
            ),
          ),
          if (blocker != null) Text(blocker, style: AonwTextStyles.bodySmall),
        ],
      ),
    );
  }
}
