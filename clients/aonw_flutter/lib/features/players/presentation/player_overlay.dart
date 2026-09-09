import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../../map/read_model/player_map_view.dart';
import 'player_rail.dart';
import 'player_status.dart';

final class PlayerOverlay extends StatelessWidget {
  const PlayerOverlay({
    required this.player,
    required this.selectedId,
    required this.onSelect,
    required this.onClose,
    this.onDiplomacy,
    super.key,
  });
  final PlayerMapView player;
  final String? selectedId;
  final ValueChanged<String>? onSelect;
  final VoidCallback onClose;
  final ValueChanged<String>? onDiplomacy;

  @override
  Widget build(BuildContext context) {
    final selected = player.participants
        .where((p) => p.id == selectedId)
        .firstOrNull;
    return Stack(
      children: [
        if (selected != null)
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('player-dismiss'),
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: onClose,
            ),
          ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 70,
          right: 8,
          bottom: MediaQuery.paddingOf(context).bottom + 112,
          child: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 48,
              child: PlayerRail(
                player: player,
                selectedId: selectedId,
                onSelect: onSelect,
              ),
            ),
          ),
        ),
        if (selected != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 70,
            right: 64,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            width: math.max(
              0,
              math.min(380, MediaQuery.sizeOf(context).width - 76),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: MapGamepadRegion(
                section: MapHudSection.rightPlayers,
                priority: MapGamepadPriority.popup,
                onCancel: onClose,
                scrollBeforeFocus: true,
                child: _PlayerDetails(
                  player: player,
                  participant: selected,
                  onClose: onClose,
                  onDiplomacy: onDiplomacy,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _PlayerDetails extends StatelessWidget {
  const _PlayerDetails({
    required this.player,
    required this.participant,
    required this.onClose,
    this.onDiplomacy,
  });
  final PlayerMapView player;
  final MatchParticipantView participant;
  final VoidCallback onClose;
  final ValueChanged<String>? onDiplomacy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: AonwHudSurface(
        key: ValueKey('player-details-${participant.id}'),
        elevation: AonwHudElevation.floating,
        semanticLabel: participant.name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    participant.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  key: const ValueKey('close-player-details'),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _details(l10n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _details(AonwLocalizations l10n) {
    final relation = player.diplomacy.relationWith(participant.id);
    return [
      Text(l10n.countryName(participant.country.name)),
      Text(l10n.participantControlName(participant.kind.name)),
      const SizedBox(height: 12),
      Text(playerStatus(player, participant.id, l10n)),
      if (participant.id != player.actorPlayerId)
        Text(
          relation == null
              ? l10n.playerText('noContact')
              : l10n.presentationName(relation.status.name),
        ),
      if (onDiplomacy != null &&
          relation != null &&
          participant.id != player.actorPlayerId)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton(
            key: const ValueKey('player-open-diplomacy'),
            onPressed: () => onDiplomacy!(participant.id),
            child: Text(l10n.diplomacyText('open')),
          ),
        ),
      const SizedBox(height: 12),
      Text(l10n.turnModeName(player.turnMode.name)),
      Text(
        '${l10n.resourceText('submitted')}: '
        '${player.turnView.submittedCount} / ${player.turnView.requiredSubmissionCount}',
      ),
    ];
  }
}
