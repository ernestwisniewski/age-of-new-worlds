import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../read_model/production_view.dart';
import 'production_copy.dart';
import 'production_target_artwork.dart';

final class ProductionChoiceCard extends StatelessWidget {
  const ProductionChoiceCard({
    required this.option,
    required this.active,
    required this.onProduce,
    this.onDetails,
    this.resourceCost,
    this.blocker,
    super.key,
  });

  final ProductionOptionView option;
  final bool active;
  final VoidCallback? onProduce;
  final VoidCallback? onDetails;
  final String? resourceCost;
  final ProductionRejectionCodeView? blocker;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final copy = ProductionCopy.of(context);
      final wide =
          constraints.maxWidth >= 520 &&
          MediaQuery.textScalerOf(context).scale(14) <= 20;
      return Container(
        margin: const EdgeInsets.only(bottom: AonwSpacing.sm),
        padding: const EdgeInsets.all(AonwSpacing.sm),
        decoration: BoxDecoration(
          color: active
              ? AonwColorTokens.brandDark.withAlpha(70)
              : AonwColorTokens.background.withAlpha(150),
          border: Border.all(
            color: active
                ? AonwColorTokens.brand
                : AonwColorTokens.chipSurfaceDim,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductionTargetArtwork(target: option.target),
            const SizedBox(width: AonwSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.target(option.target),
                    style: AonwTextStyles.bodyStrong,
                  ),
                  const SizedBox(height: AonwSpacing.xs),
                  _metadata(copy),
                  if (!wide) _actions(copy),
                ],
              ),
            ),
            if (wide) ...[
              const SizedBox(width: AonwSpacing.sm),
              _actions(copy),
            ],
          ],
        ),
      );
    },
  );

  Widget _metadata(ProductionCopy copy) {
    final reason = copy.rejection(blocker ?? option.blocker);
    final requirement = copy.technologyRequirement(option.availability);
    final target = option.target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (target is ProjectProductionTargetView)
          Text(
            copy.output(target, option.forecast.projectOutput!),
            style: AonwTextStyles.bodySmall,
          )
        else
          Text(
            '${copy.text(ProductionText.cost)} ${option.cost} · ${copy.estimate(option.forecast)}',
            style: AonwTextStyles.bodySmall,
          ),
        if (resourceCost case final cost?)
          Text(cost, style: AonwTextStyles.bodySmall),
        if (requirement != null)
          Text(requirement, style: AonwTextStyles.bodySmall),
        if (reason != null) Text(reason, style: AonwTextStyles.bodySmall),
      ],
    );
  }

  Widget _produce(ProductionCopy copy) => Padding(
    padding: const EdgeInsets.only(top: AonwSpacing.xs),
    child: FilledButton(
      onPressed: onProduce,
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      child: Text(
        copy.text(active ? ProductionText.inProgress : ProductionText.produce),
        semanticsLabel:
            '${copy.target(option.target)}. ${copy.text(active ? ProductionText.inProgress : ProductionText.produce)}',
      ),
    ),
  );

  Widget _actions(ProductionCopy copy) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (onDetails != null)
        IconButton(
          tooltip:
              '${copy.text(ProductionText.details)}: ${copy.target(option.target)}',
          onPressed: onDetails,
          icon: const Icon(Icons.help_outline),
        ),
      _produce(copy),
    ],
  );
}
