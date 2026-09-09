import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../../map/read_model/player_map_view.dart';
import 'resource_pill.dart';
import 'resource_popup.dart';

export 'resource_popup.dart';

final class ResourceStrip extends StatelessWidget {
  const ResourceStrip({
    required this.player,
    required this.open,
    required this.onOpen,
    super.key,
  });
  final PlayerMapView player;
  final ResourcePopup? open;
  final ValueChanged<ResourcePopup>? onOpen;

  @override
  Widget build(BuildContext context) => MapGamepadRegion(
    section: MapHudSection.topResources,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in ResourcePopup.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ResourcePill(
                key: ValueKey('resource-${kind.name}'),
                label: context.aonwL10n.resourceText(kind.name),
                value: _value(kind),
                delta: kind == ResourcePopup.gold
                    ? signedResourceAmount(player.economy.forecast.netPerTurn)
                    : null,
                icon: kind,
                color: _color(kind),
                active: open == kind,
                onPressed: onOpen == null ? null : () => onOpen!(kind),
              ),
            ),
        ],
      ),
    ),
  );

  String _value(ResourcePopup kind) => switch (kind) {
    ResourcePopup.gold => '${player.economy.gold}',
    ResourcePopup.science => signedResourceAmount(
      player.research.sciencePerTurn,
    ),
    ResourcePopup.stability => signedResourceAmount(
      player.economy.forecast.stability.effectiveNet,
    ),
    ResourcePopup.resources =>
      '${player.economy.strategicResourceStockpile.where((value) => value.amount > 0).length}/${player.economy.strategicResourceStockpile.length}',
    ResourcePopup.turn => '${player.turnView.number}',
    ResourcePopup.victory =>
      '${player.victory.scoreByPlayerId[player.actorPlayerId] ?? 0}',
  };

  Color _color(ResourcePopup kind) => switch (kind) {
    ResourcePopup.science => AonwColorTokens.scienceAccent,
    ResourcePopup.resources => AonwColorTokens.resourcesAccent,
    ResourcePopup.stability => switch (player.economy.forecast.stability.band) {
      PlayerStabilityBandView.content => AonwColorTokens.success,
      PlayerStabilityBandView.stable => AonwColorTokens.brandLight,
      PlayerStabilityBandView.strained => AonwColorTokens.warning,
      PlayerStabilityBandView.unrest => AonwColorTokens.danger,
    },
    _ => AonwColorTokens.brandLight,
  };
}

String signedResourceAmount(int value) => value > 0 ? '+$value' : '$value';
