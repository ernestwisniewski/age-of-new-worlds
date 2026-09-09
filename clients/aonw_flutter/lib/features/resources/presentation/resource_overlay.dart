import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../../map/read_model/player_map_view.dart';
import 'resource_details.dart';
import 'resource_strip.dart';

final class ResourceOverlay extends StatelessWidget {
  const ResourceOverlay({
    required this.player,
    required this.open,
    required this.onOpen,
    required this.onClose,
    super.key,
  });
  final PlayerMapView player;
  final ResourcePopup? open;
  final ValueChanged<ResourcePopup>? onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (open != null)
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('resource-dismiss'),
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            excludeFromSemantics: true,
          ),
        ),
      Positioned(
        top: MediaQuery.paddingOf(context).top + 6,
        left: 8,
        right: 8,
        child: Align(
          alignment: Alignment.topRight,
          child: ResourceStrip(player: player, open: open, onOpen: onOpen),
        ),
      ),
      if (open case final kind?)
        Positioned(
          top: MediaQuery.paddingOf(context).top + 62,
          right: 12,
          bottom: MediaQuery.paddingOf(context).bottom + 12,
          width: math.min(480, MediaQuery.sizeOf(context).width - 24),
          child: Align(
            alignment: Alignment.topRight,
            child: MapGamepadRegion(
              section: MapHudSection.topResources,
              priority: MapGamepadPriority.popup,
              onCancel: onClose,
              scrollBeforeFocus: true,
              child: _ResourcePanel(
                player: player,
                kind: kind,
                onClose: onClose,
              ),
            ),
          ),
        ),
    ],
  );
}

final class _ResourcePanel extends StatelessWidget {
  const _ResourcePanel({
    required this.player,
    required this.kind,
    required this.onClose,
  });
  final PlayerMapView player;
  final ResourcePopup kind;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final details = resourceDetails(player, kind, l10n);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: AonwHudSurface(
        key: ValueKey('resource-details-${kind.name}'),
        elevation: AonwHudElevation.floating,
        semanticLabel: l10n.resourceText(kind.name),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.resourceText(kind.name),
                    style: Theme.of(context).textTheme.titleLarge,
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
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (details.isEmpty) Text(l10n.resourceText('empty')),
                    for (final detail in details) _detailRow(detail),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ResourceDetail detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: Text(detail.label)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            detail.value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontFeatures: AonwTypography.tabularFigures),
          ),
        ),
      ],
    ),
  );
}
