part of 'turn_hud.dart';

final class _TurnNavigationActions extends StatelessWidget {
  const _TurnNavigationActions({
    required this.enabled,
    required this.onNavigate,
  });

  final bool enabled;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        key: const ValueKey('previous-turn-action'),
        tooltip: context.aonwL10n.gamepadActionPrevious,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: enabled ? () => onNavigate(-1) : null,
        icon: const Icon(Icons.chevron_left),
      ),
      IconButton(
        key: const ValueKey('next-turn-action'),
        tooltip: context.aonwL10n.gamepadActionNext,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: enabled ? () => onNavigate(1) : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}
