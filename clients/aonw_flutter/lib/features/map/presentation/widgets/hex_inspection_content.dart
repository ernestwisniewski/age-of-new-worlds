import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../read_model/hex_inspection_view.dart';
import '../../read_model/map_scene.dart';
import 'hex_inspection_components.dart';
import 'hex_inspection_improvements.dart';

final class HexInspectionContent extends StatelessWidget {
  const HexInspectionContent({
    required this.view,
    required this.scene,
    super.key,
  });

  final HexInspectionView view;
  final MapScene scene;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.hexInspectionRecommendation(view.recommendation.name),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        HexInspectionSection(
          title: l10n.hexInspectionText('description'),
          children: [
            Text(
              '${l10n.hexInspectionDescription(view.kind.name)} '
              '${l10n.hexInspectionRecommendationDetail(view.recommendation.name)}',
            ),
            const SizedBox(height: 6),
            HexInspectionYield(value: view.yieldValue),
            if (view.hasRiver) Text(l10n.hexInspectionText('riverBonus')),
            if (view.yieldValue.defense > 0)
              Text(l10n.hexInspectionText('defenseBonus')),
            Text('${l10n.hexInspectionText('height')}: ${view.height}'),
          ],
        ),
        HexInspectionSection(
          title: l10n.hexInspectionText('terrain'),
          children: [
            Text(
              view.terrainTags
                  .map((value) => l10n.hexInspectionTerrain(value.name))
                  .join(' + '),
            ),
          ],
        ),
        HexInspectionSection(
          title: l10n.hexInspectionText('resources'),
          children: [
            Text(
              view.resources.isEmpty
                  ? l10n.hexInspectionText('none')
                  : view.resources
                        .map((value) => l10n.presentationName(value.name))
                        .join(' + '),
            ),
          ],
        ),
        ..._objectives(l10n),
        HexInspectionImprovements(view: view, player: scene.player),
      ],
    );
  }

  List<Widget> _objectives(AonwLocalizations l10n) => [
    for (final objective in scene.map.objectives)
      if (objective.coordinate == view.coordinate)
        HexInspectionSection(
          title: l10n.hexInspectionText('objective'),
          children: [
            Text(l10n.objectiveType(objective.type.name)),
            Text(
              l10n.objectiveDetails(
                objective.coordinate.col,
                objective.coordinate.row,
                objective.requiredHoldTurns,
                objective.victoryPoints,
                objective.goldPerTurn,
              ),
            ),
          ],
        ),
  ];
}
