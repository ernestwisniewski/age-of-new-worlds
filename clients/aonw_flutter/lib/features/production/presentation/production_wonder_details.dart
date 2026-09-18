import 'package:flutter/material.dart';

import '../read_model/production_details_view.dart';
import '../read_model/production_view.dart';
import 'production_detail_copy.dart';
import 'production_detail_requirements.dart';
import 'production_detail_widgets.dart';

final class ProductionWonderDetails extends StatelessWidget {
  const ProductionWonderDetails({
    required this.option,
    required this.effects,
    super.key,
  });
  final ProductionOptionView option;
  final WonderProductionDetailsView effects;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionDetailCopy.of(context);
    final standing = copy.wonderStanding(effects);
    final completion = copy.wonderCompletion(effects);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductionDetailRequirements(
          option: option,
          requirements: effects.requirements,
        ),
        ProductionDetailSection(
          title: copy.l10n.wonderDetailsStandingEffects,
          children: [
            for (final line
                in standing.isEmpty
                    ? [copy.l10n.wonderDetailsNoStandingEffects]
                    : standing)
              ProductionDetailLine(line),
          ],
        ),
        ProductionDetailSection(
          title: copy.l10n.wonderDetailsCompletionEffects,
          children: [
            for (final line
                in completion.isEmpty
                    ? [copy.l10n.wonderDetailsNoCompletionEffects]
                    : completion)
              ProductionDetailLine(line),
          ],
        ),
      ],
    );
  }
}
