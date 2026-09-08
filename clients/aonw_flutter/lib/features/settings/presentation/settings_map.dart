part of 'settings_screen.dart';

final class _MapAppearanceSettings extends StatelessWidget {
  const _MapAppearanceSettings({
    required this.settings,
    required this.onChanged,
  });

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      children: [
        _PreferredMapViewSetting(settings: settings, onChanged: onChanged),
        const SizedBox(height: AonwSpacing.md),
        _MapSetting(
          key: const ValueKey('map-grid-setting'),
          title: l10n.mapGrid,
          description: l10n.mapGridDescription,
          value: settings.showMapGrid,
          onChanged: (value) =>
              onChanged(settings.copyWith(showMapGrid: value)),
        ),
        _MapSetting(
          key: const ValueKey('map-elevation-walls-setting'),
          title: l10n.mapElevationWalls,
          description: l10n.mapElevationWallsDescription,
          value: settings.showMapElevationWalls,
          onChanged: (value) =>
              onChanged(settings.copyWith(showMapElevationWalls: value)),
        ),
      ],
    );
  }
}

final class _MapMarkingsSettings extends StatelessWidget {
  const _MapMarkingsSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      children: [
        _MapSetting(
          key: const ValueKey('map-resource-icons-setting'),
          title: l10n.mapResourceIcons,
          description: l10n.mapResourceIconsDescription,
          value: settings.showMapResourceIcons,
          onChanged: (value) =>
              onChanged(settings.copyWith(showMapResourceIcons: value)),
        ),
        _MapSetting(
          key: const ValueKey('map-height-badges-setting'),
          title: l10n.mapHeightBadges,
          description: l10n.mapHeightBadgesDescription,
          value: settings.showMapHeightBadges,
          onChanged: (value) =>
              onChanged(settings.copyWith(showMapHeightBadges: value)),
        ),
        _MapSetting(
          key: const ValueKey('map-terrain-icons-setting'),
          title: l10n.mapTerrainIcons,
          description: l10n.mapTerrainIconsDescription,
          value: settings.showMapTerrainIcons,
          onChanged: (value) =>
              onChanged(settings.copyWith(showMapTerrainIcons: value)),
        ),
      ],
    );
  }
}

final class _PreferredMapViewSetting extends StatelessWidget {
  const _PreferredMapViewSetting({
    required this.settings,
    required this.onChanged,
  });

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.preferredMapViewMode),
        Text(
          l10n.preferredMapViewModeDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<MapViewMode>(
            key: const ValueKey('preferred-map-view-setting'),
            value: settings.preferredMapViewMode,
            isExpanded: true,
            itemHeight: null,
            items: [
              for (final mode in MapViewMode.values)
                DropdownMenuItem(
                  value: mode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AonwSpacing.sm,
                    ),
                    child: Text(
                      mode == MapViewMode.graphic
                          ? l10n.mapViewModeGraphic
                          : l10n.mapViewModeTiles,
                    ),
                  ),
                ),
            ],
            onChanged: context.withGameSoundValue((mode) {
              if (mode != null) {
                onChanged(settings.copyWith(preferredMapViewMode: mode));
              }
            }),
          ),
        ),
      ],
    );
  }
}
