part of 'local_handoff_overlay.dart';

final class _LocalHandoffIdentity extends StatelessWidget {
  const _LocalHandoffIdentity({
    required this.playerName,
    required this.colorValue,
    required this.turnNumber,
  });

  final String playerName;
  final int? colorValue;
  final int? turnNumber;

  @override
  Widget build(BuildContext context) {
    final color = colorValue == null
        ? AonwColorTokens.brand
        : Color(colorValue!);
    final initial = playerName.characters.firstOrNull?.toUpperCase() ?? '?';
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            key: const ValueKey('handoff-player-avatar'),
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: color,
              shape: CircleBorder(
                side: BorderSide(
                  color: Color.lerp(color, Colors.white, .45)!,
                  width: 3,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: color.withAlpha(160),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Text(
              initial,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: foreground,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AonwSpacing.lg),
        Text(
          playerName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (turnNumber case final turn?) ...[
          const SizedBox(height: AonwSpacing.sm),
          Text(context.aonwL10n.multiplayerTurn(turn)),
        ],
      ],
    );
  }
}
