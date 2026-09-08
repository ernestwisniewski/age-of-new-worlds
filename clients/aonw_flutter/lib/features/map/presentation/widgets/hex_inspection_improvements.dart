import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../read_model/hex_inspection_view.dart';
import '../../read_model/player_map_view.dart';
import 'hex_inspection_components.dart';

final class HexInspectionImprovements extends StatelessWidget {
  const HexInspectionImprovements({
    required this.view,
    required this.player,
    super.key,
  });
  final HexInspectionView view;
  final PlayerMapView player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return HexInspectionSection(
      title: l10n.hexInspectionText('improvements'),
      children: [
        Text(_access(l10n)),
        if (view.improvements.isEmpty)
          Text(l10n.hexInspectionText('noImprovements')),
        for (final option in view.improvements) _Improvement(option: option),
      ],
    );
  }

  String _access(AonwLocalizations l10n) => switch (view.improvementAccess) {
    HexOutsideControlledCityView() => l10n.hexInspectionText('outsideCity'),
    HexCityCenterView() => l10n.hexInspectionText('cityCenter'),
    HexAlreadyImprovedView() => l10n.hexInspectionText('alreadyImproved'),
    HexControlledCityView(:final cityId) => l10n.hexInspectionCity(
      player.cityById(cityId)?.name ?? cityId,
    ),
  };
}

final class _Improvement extends StatelessWidget {
  const _Improvement({required this.option});
  final HexImprovementOptionView option;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final technology = option.requiredTechnology;
    final available = option.technologyUnlocked;
    final color = available
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Padding(
      key: ValueKey(('hex-inspection-improvement', option.kind)),
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.presentationName(option.kind.name),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            technology == null
                ? l10n.hexInspectionText('fromStart')
                : '${l10n.technologyName(technology.name)} — '
                      '${l10n.hexInspectionText(available ? 'unlocked' : 'locked')}',
            style: TextStyle(color: color),
          ),
          HexInspectionYield(value: option.yieldDelta),
          Text(l10n.hexInspectionBuildTurns(option.buildTurns)),
        ],
      ),
    );
  }
}
