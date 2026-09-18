import 'package:flutter/material.dart';

import '../read_model/production_details_view.dart';
import '../read_model/production_view.dart';
import 'production_detail_copy.dart';
import 'production_detail_widgets.dart';

final class ProductionDetailRequirements extends StatelessWidget {
  const ProductionDetailRequirements({
    required this.option,
    this.requirements = const [],
    this.extra = const [],
    super.key,
  });
  final ProductionOptionView option;
  final List<ProductionRequirementStatusView> requirements;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionDetailCopy.of(context);
    final technology = option.availability.requiredTechnology;
    return ProductionDetailSection(
      title: copy.l10n.technologyDetailsPrerequisites,
      children: [
        if (technology != null)
          ProductionDetailLine(
            copy.l10n.buildingDetailsRequirementTechnology(
              copy.l10n.technologyName(technology.name),
            ),
            met: option.availability.technologyUnlocked,
          ),
        for (final item in requirements)
          ProductionDetailLine(
            copy.requirement(item.requirement),
            met: item.met,
          ),
        ...extra,
        if (technology == null && requirements.isEmpty && extra.isEmpty)
          ProductionDetailLine(copy.l10n.buildingDetailsNoRequirements),
      ],
    );
  }
}
