part of 'research_discovery_overlay.dart';

final class _DiscoveryPanel extends StatelessWidget {
  const _DiscoveryPanel({
    required this.technology,
    required this.playerName,
    required this.option,
    required this.suppress,
    required this.onSuppress,
    required this.onDismiss,
    required this.onMinimize,
  });

  final TechnologyIdView technology;
  final String playerName;
  final ResearchOptionView? option;
  final bool suppress;
  final ValueChanged<bool> onSuppress;
  final VoidCallback onDismiss;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final copy = ResearchCopy.of(context);
    return AonwPanel(
      key: const ValueKey('research-discovery-panel'),
      maxWidth: 520,
      semanticLabel: l10n.researchDiscoveryTitle,
      liveRegion: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: AonwSpacing.md),
            Text(
              copy.technology(technology),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(playerName),
            const SizedBox(height: AonwSpacing.md),
            Text(copy.description(technology)),
            if (option case final details? when details.unlocks.isNotEmpty) ...[
              const SizedBox(height: AonwSpacing.md),
              Text(
                copy.text(ResearchText.unlocks),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final unlock in details.unlocks) Text(copy.unlock(unlock)),
            ],
            const SizedBox(height: AonwSpacing.md),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.researchDiscoverySuppress),
              value: suppress,
              onChanged: (value) => onSuppress(value ?? false),
            ),
            FilledButton(
              autofocus: true,
              onPressed: onDismiss,
              child: Text(l10n.researchDiscoveryContinue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = context.aonwL10n;
    return Row(
      children: [
        AonwSpriteThumbnail(
          frame: SpriteFrameId('technology.${technology.name}'),
        ),
        const SizedBox(width: AonwSpacing.md),
        Expanded(
          child: Text(
            l10n.researchDiscoveryTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: onMinimize,
          tooltip: l10n.researchDiscoveryMinimize,
          icon: const Icon(Icons.minimize),
        ),
      ],
    );
  }
}
