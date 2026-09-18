import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../application/production_inspection_state.dart';
import '../read_model/production_details_view.dart';
import '../read_model/production_view.dart';
import 'production_building_details.dart';
import 'production_copy.dart';
import 'production_target_artwork.dart';
import 'production_unit_details.dart';
import 'production_wonder_details.dart';

final class ProductionTargetDetails extends StatelessWidget {
  const ProductionTargetDetails({
    required this.inspection,
    required this.onClose,
    required this.onRetry,
    super.key,
  });

  final ProductionInspectionState inspection;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    return MapGamepadRegion(
      section: MapHudSection.selectionActions,
      priority: MapGamepadPriority.modal,
      onCancel: onClose,
      scrollBeforeFocus: true,
      child: Stack(
        children: [
          ModalBarrier(color: Colors.black54, onDismiss: onClose),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                ),
                child: AonwHudSurface(
                  key: const ValueKey('production-target-details'),
                  elevation: AonwHudElevation.modal,
                  background: AonwColorTokens.background,
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AonwRadii.panel),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _header(context, copy),
                        Flexible(
                          child: SingleChildScrollView(
                            key: const ValueKey('production-details-scroll'),
                            padding: const EdgeInsets.all(AonwSpacing.md),
                            child: _body(context, copy),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, ProductionCopy copy) => ColoredBox(
    color: AonwColorTokens.chipSurface,
    child: Padding(
      padding: const EdgeInsets.all(AonwSpacing.sm),
      child: Row(
        children: [
          ProductionTargetArtwork(target: inspection.target, size: 56),
          const SizedBox(width: AonwSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.target(inspection.target),
                  style: AonwTextStyles.screenTitle,
                ),
                const Divider(color: AonwColorTokens.brand, height: 12),
                Text(
                  copy.text(ProductionText.details),
                  style: AonwTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('close-production-details'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );

  Widget _body(BuildContext context, ProductionCopy copy) {
    final currentOption = inspection.details?.option;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(copy.description(inspection.target), style: AonwTextStyles.body),
        const SizedBox(height: AonwSpacing.md),
        if (currentOption != null) _facts(copy, currentOption),
        if (inspection.loading)
          AonwProgressIndicator(
            semanticLabel: copy.text(ProductionText.loading),
            compact: true,
          ),
        if (inspection.failure case final failure?) ...[
          Text(copy.failure(failure), style: AonwTextStyles.body),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.aonwL10n.retry),
          ),
        ],
        if (inspection.details case final details?) _effects(details),
      ],
    );
  }

  Widget _facts(ProductionCopy copy, ProductionOptionView value) {
    final reason = copy.rejection(value.blocker);
    return Wrap(
      spacing: AonwSpacing.sm,
      runSpacing: AonwSpacing.sm,
      children: [
        _fact('${copy.text(ProductionText.cost)}: ${value.cost}'),
        _fact(copy.progress(value.forecast.investedProduction, value.cost)),
        _fact(copy.rate(value.forecast.productionPerTurn)),
        _fact(copy.estimate(value.forecast)),
        if (value.availability.completedInCity)
          _fact(copy.text(ProductionText.completed))
        else if (reason != null)
          _fact(reason),
      ],
    );
  }

  Widget _fact(String text) => DecoratedBox(
    decoration: BoxDecoration(
      color: AonwColorTokens.chipSurface,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(text, style: AonwTextStyles.bodySmall),
    ),
  );

  Widget _effects(ProductionDetailsView value) => switch (value.effects) {
    final BuildingProductionDetailsView effects => ProductionBuildingDetails(
      option: value.option,
      effects: effects,
    ),
    final UnitProductionDetailsView effects => ProductionUnitDetails(
      option: value.option,
      effects: effects,
    ),
    final WonderProductionDetailsView effects => ProductionWonderDetails(
      option: value.option,
      effects: effects,
    ),
    ProjectProductionDetailsView() => const SizedBox.shrink(),
  };
}
