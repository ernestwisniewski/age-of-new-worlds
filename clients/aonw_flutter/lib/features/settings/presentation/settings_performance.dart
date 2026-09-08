part of 'settings_screen.dart';

final class _PerformanceSettings extends StatelessWidget {
  const _PerformanceSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      children: [
        _MapSetting(
          key: const ValueKey('show-fps-setting'),
          title: l10n.showFps,
          description: l10n.showFpsDescription,
          value: settings.performance.showFps,
          onChanged: (value) => onChanged(
            settings.copyWith(
              performance: settings.performance.copyWith(showFps: value),
            ),
          ),
        ),
        _MapSetting(
          key: const ValueKey('show-map-zoom-setting'),
          title: l10n.showMapZoom,
          description: l10n.showMapZoomDescription,
          value: settings.performance.showMapZoom,
          onChanged: (value) => onChanged(
            settings.copyWith(
              performance: settings.performance.copyWith(showMapZoom: value),
            ),
          ),
        ),
      ],
    );
  }
}
