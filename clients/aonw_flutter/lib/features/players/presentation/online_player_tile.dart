part of 'player_rail.dart';

double playerRailWidth(Size size, {required bool online}) =>
    online &&
        size.width >= 620 &&
        !(size.height < 520 && size.width > size.height)
    ? 140
    : 48;

final class _OnlinePlayerTile extends StatelessWidget {
  const _OnlinePlayerTile({
    required this.player,
    required this.participant,
    required this.selected,
    required this.compact,
    required this.onTap,
  });
  final PlayerMapView player;
  final MatchParticipantView participant;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final own = participant.id == player.actorPlayerId;
    final name = participant.name.trim();
    final status = playerStatus(player, participant.id, context.aonwL10n);
    return Tooltip(
      message: '$name · $status',
      child: Semantics(
        label: '$name · $status',
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('player-avatar-${participant.id}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(compact ? 8 : 999),
            child: SizedBox(
              height: 48,
              child: Center(
                child: Container(
                  key: ValueKey('online-player-tile-${participant.id}'),
                  width: compact ? 40 : 140,
                  height: compact ? 40 : 32,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 9),
                  decoration: _decoration(own),
                  child: _content(own, name),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(bool own, String name) {
    final relation = player.diplomacy.relationWith(participant.id);
    final label = Text(
      compact
          ? (name.isEmpty ? '?' : name.characters.first.toUpperCase())
          : name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: compact ? TextAlign.center : TextAlign.start,
      style: AonwTextStyles.toolbarLabel.copyWith(fontSize: compact ? 12 : 10),
    );
    if (compact) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: label),
          Positioned(right: -5, bottom: -2, child: _status(own)),
          if (!own && relation != null)
            Positioned(
              left: -5,
              top: -2,
              child: _AvatarBadge(color: _relationColor(relation.status)),
            ),
        ],
      );
    }
    return Row(
      children: [
        _AvatarBadge(color: Color(participant.colorValue)),
        const SizedBox(width: 7),
        Expanded(child: label),
        if (!own && relation != null)
          _AvatarBadge(color: _relationColor(relation.status)),
        const SizedBox(width: 5),
        _status(own),
      ],
    );
  }

  Widget _status(bool own) => Icon(
    own
        ? (player.turnView.ownSubmitted
              ? Icons.check_circle
              : Icons.circle_outlined)
        : Icons.lock_outline,
    size: 12,
    color: own && player.turnView.ownSubmitted
        ? AonwColorTokens.success
        : AonwColorTokens.textSecondary,
  );

  BoxDecoration _decoration(bool own) => BoxDecoration(
    borderRadius: BorderRadius.circular(compact ? 8 : 999),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AonwColorTokens.surface, AonwColorTokens.surfaceDeep],
    ),
    border: Border.all(
      color: selected
          ? AonwColorTokens.brand
          : AonwColorTokens.brand.withAlpha(70),
    ),
    boxShadow: own
        ? const [BoxShadow(color: Color(0x5AB47A4E), blurRadius: 16)]
        : null,
  );
}
