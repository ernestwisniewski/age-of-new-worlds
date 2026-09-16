import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../l10n/l10n.dart';
import '../../diplomacy/read_model/diplomacy_view.dart';
import '../../map/read_model/player_map_view.dart';
import 'resource_icon.dart';
import 'resource_strip.dart';

part 'strategic_resource_cards.dart';
part 'strategic_resource_sections.dart';
part 'strategic_resource_trade.dart';

final class StrategicResourcePanel extends StatelessWidget {
  const StrategicResourcePanel({
    required this.player,
    required this.onClose,
    this.onCity,
    this.onTradePartner,
    super.key,
  });

  final PlayerMapView player;
  final VoidCallback onClose;
  final ValueChanged<String>? onCity;
  final ValueChanged<String>? onTradePartner;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
    child: Listener(
      behavior: HitTestBehavior.opaque,
      child: AonwHudSurface(
        key: const ValueKey('resource-details-resources'),
        elevation: AonwHudElevation.raised,
        semanticLabel: context.aonwL10n.resourceInventoryText('title'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InventoryHeader(player: player, onClose: onClose),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                key: const ValueKey('strategic-inventory-scroll'),
                child: _InventoryOverview(
                  player: player,
                  onCity: onCity,
                  onTradePartner: onTradePartner,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({required this.player, required this.onClose});

  final PlayerMapView player;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final attention = player.economy.strategicResourceInventory.attentionCount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, right: 10),
          child: ResourceIcon(
            kind: ResourcePopup.resources,
            color: AonwColorTokens.brandLight,
            size: 28,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.resourceInventoryText('title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                attention == 0
                    ? l10n.resourceInventoryText('healthy')
                    : l10n.resourceInventoryAttention(attention),
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('close-resource-details'),
          autofocus: true,
          tooltip: l10n.resourceText('close'),
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

final class _InventoryOverview extends StatelessWidget {
  const _InventoryOverview({
    required this.player,
    this.onCity,
    this.onTradePartner,
  });

  final PlayerMapView player;
  final ValueChanged<String>? onCity;
  final ValueChanged<String>? onTradePartner;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (player.economy.strategicResourceInventory.attentionCount > 0)
        _InventoryAlerts(player: player),
      _InventoryCards(inventory: player.economy.strategicResourceInventory),
      _InventoryAllocations(player: player, onCity: onCity),
      _InventorySources(player: player, onCity: onCity),
      _InventoryAgreements(player: player),
      _InventoryPartners(player: player, onTradePartner: onTradePartner),
    ],
  );
}

final class _InventorySection extends StatelessWidget {
  const _InventorySection({
    required this.name,
    required this.child,
    this.accent = AonwColorTokens.brand,
  });

  final String name;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: AonwHudSurface(
      key: ValueKey('strategic-inventory-$name'),
      elevation: AonwHudElevation.flat,
      accent: accent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              context.aonwL10n.resourceInventoryText(name),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: accent),
            ),
          ),
          const Divider(),
          child,
        ],
      ),
    ),
  );
}

String _cityLabel(PlayerMapView player, String id, AonwLocalizations l10n) =>
    player.cities.where((city) => city.id == id).firstOrNull?.name ??
    l10n.cityText('title');
