part of 'player_rail.dart';

final class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: AonwColorTokens.surfaceDeep, width: 2),
    ),
  );
}

Color _relationColor(DiplomaticRelationStatusView status) => switch (status) {
  DiplomaticRelationStatusView.friendly => AonwColorTokens.success,
  DiplomaticRelationStatusView.hostile => AonwColorTokens.warning,
  DiplomaticRelationStatusView.truce => AonwColorTokens.info,
  DiplomaticRelationStatusView.war => AonwColorTokens.danger,
  DiplomaticRelationStatusView.neutral => AonwColorTokens.textTertiary,
};
