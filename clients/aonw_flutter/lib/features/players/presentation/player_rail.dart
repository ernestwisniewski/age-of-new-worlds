import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../diplomacy/read_model/diplomacy_view.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../../map/read_model/player_map_view.dart';
import 'player_status.dart';

part 'player_avatar_badges.dart';
part 'online_player_tile.dart';

final class PlayerRail extends StatelessWidget {
  const PlayerRail({
    required this.player,
    required this.selectedId,
    required this.onSelect,
    this.online = false,
    super.key,
  });
  final PlayerMapView player;
  final String? selectedId;
  final ValueChanged<String>? onSelect;
  final bool online;

  @override
  Widget build(BuildContext context) => MapGamepadRegion(
    section: MapHudSection.rightPlayers,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final participant in player.participants)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: online
                  ? _OnlinePlayerTile(
                      player: player,
                      participant: participant,
                      selected: selectedId == participant.id,
                      compact:
                          playerRailWidth(
                            MediaQuery.sizeOf(context),
                            online: true,
                          ) ==
                          48,
                      onTap: onSelect == null
                          ? null
                          : () => onSelect!(participant.id),
                    )
                  : _Avatar(
                      player: player,
                      participant: participant,
                      selected: selectedId == participant.id,
                      onTap: onSelect == null
                          ? null
                          : () => onSelect!(participant.id),
                    ),
            ),
        ],
      ),
    ),
  );
}

final class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.player,
    required this.participant,
    required this.selected,
    required this.onTap,
  });
  final PlayerMapView player;
  final MatchParticipantView participant;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final own = participant.id == player.actorPlayerId;
    final l10n = context.aonwL10n;
    final status = playerStatus(player, participant.id, l10n);
    final name = participant.name.trim();
    return Tooltip(
      message: '$name · $status',
      child: Semantics(
        label:
            '$name · ${l10n.countryName(participant.country.name)} · $status',
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('player-avatar-${participant.id}'),
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: _visual(own)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _visual(bool own) {
    final size = own ? 44.0 : 34.0;
    final name = participant.name.trim();
    final submitted = own && player.turnView.ownSubmitted;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: _decoration(own),
          alignment: Alignment.center,
          child: submitted
              ? const Icon(Icons.check_circle, color: Colors.white, size: 20)
              : Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: own ? 18 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        ..._badges(own, submitted),
      ],
    );
  }

  List<Widget> _badges(bool own, bool submitted) => [
    if (own && !submitted && !player.turnView.outcome.isTerminal)
      Positioned(
        bottom: 0,
        right: 0,
        child: _AvatarBadge(
          color: Color.lerp(Color(participant.colorValue), Colors.white, 0.45)!,
        ),
      ),
    if (!own)
      if (player.diplomacy.relationWith(participant.id) case final relation?)
        Positioned(
          top: -1,
          left: -1,
          child: _AvatarBadge(color: _relationColor(relation.status)),
        ),
  ];

  BoxDecoration _decoration(bool own) => BoxDecoration(
    shape: BoxShape.circle,
    color: Color(participant.colorValue).withValues(alpha: own ? 1 : 0.72),
    border: Border.all(
      color: selected || own
          ? AonwColorTokens.brand
          : AonwColorTokens.brand.withAlpha(70),
      width: selected || own ? 2.5 : 1.5,
    ),
    boxShadow: own
        ? const [
            BoxShadow(
              color: Color(0x5AB47A4E),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ]
        : null,
  );
}
