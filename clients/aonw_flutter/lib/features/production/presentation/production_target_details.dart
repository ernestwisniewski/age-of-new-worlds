import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../read_model/production_view.dart';
import 'production_copy.dart';
import 'production_target_artwork.dart';

final class ProductionTargetDetails extends StatelessWidget {
  const ProductionTargetDetails({
    required this.option,
    required this.onClose,
    super.key,
  });

  final ProductionOptionView option;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    return MapGamepadRegion(
      section: MapHudSection.selectionActions,
      priority: MapGamepadPriority.modal,
      onCancel: onClose,
      scrollBeforeFocus: true,
      child: ColoredBox(
        key: const ValueKey('production-target-details'),
        color: AonwColorTokens.background,
        child: Column(
          children: [
            _header(context, copy),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('production-details-scroll'),
                padding: const EdgeInsets.all(AonwSpacing.sm),
                child: _description(copy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ProductionCopy copy) => Row(
    children: [
      IconButton(
        key: const ValueKey('close-production-details'),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onClose,
        icon: const Icon(Icons.arrow_back),
      ),
      Expanded(
        child: Text(
          copy.text(ProductionText.details),
          style: AonwTextStyles.screenTitle,
        ),
      ),
    ],
  );

  Widget _description(ProductionCopy copy) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(child: ProductionTargetArtwork(target: option.target, size: 120)),
      Text(copy.target(option.target), style: AonwTextStyles.cardTitle),
      const SizedBox(height: AonwSpacing.sm),
      Text(copy.description(option.target), style: AonwTextStyles.body),
      const SizedBox(height: AonwSpacing.lg),
      _facts(copy),
    ],
  );

  Widget _facts(ProductionCopy copy) {
    final requirement = copy.unlockingTechnology(option.availability);
    final reason = copy.rejection(option.blocker);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${copy.text(ProductionText.cost)}: ${option.cost}',
          style: AonwTextStyles.bodyStrong,
        ),
        Text(
          copy.rate(option.forecast.productionPerTurn),
          style: AonwTextStyles.body,
        ),
        Text(copy.estimate(option.forecast), style: AonwTextStyles.body),
        if (requirement != null) Text(requirement, style: AonwTextStyles.body),
        if (option.availability.completedInCity)
          Text(
            copy.text(ProductionText.completed),
            style: AonwTextStyles.bodyStrong,
          )
        else if (reason != null)
          Text(reason, style: AonwTextStyles.body),
      ],
    );
  }
}
