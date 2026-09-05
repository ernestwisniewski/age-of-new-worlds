import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_menu_adjustable.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../application/client_settings.dart';
import 'client_settings_controller.dart';

final class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});

  final ClientSettingsController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.aonwL10n.settingsTitle)),
    body: SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) => _SettingsForm(
          settings: controller.settings,
          onChanged: (settings) => unawaited(controller.update(settings)),
          onReset: () => unawaited(controller.reset()),
        ),
      ),
    ),
  );
}

final class _SettingsForm extends StatelessWidget {
  const _SettingsForm({
    required this.settings,
    required this.onChanged,
    required this.onReset,
  });

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return ListView(
      padding: const EdgeInsets.all(AonwSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsSection(
                  title: l10n.audioSettings,
                  child: _AudioSettings(
                    settings: settings,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(height: AonwSpacing.md),
                _SettingsSection(
                  title: l10n.cameraSettings,
                  child: _CameraSettings(
                    settings: settings,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(height: AonwSpacing.md),
                _SettingsSection(
                  title: l10n.mapSettings,
                  child: _MapSettings(settings: settings, onChanged: onChanged),
                ),
                const SizedBox(height: AonwSpacing.md),
                _SettingsSection(
                  title: l10n.accessibilitySettings,
                  child: _AccessibilitySettings(
                    settings: settings,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(height: AonwSpacing.lg),
                OutlinedButton.icon(
                  key: const ValueKey('reset-settings'),
                  onPressed: onReset,
                  icon: const Icon(Icons.restore),
                  label: Text(l10n.resetSettings),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _MapSettings extends StatelessWidget {
  const _MapSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      children: [
        _MapSetting(
          key: const ValueKey('map-grid-setting'),
          title: l10n.mapGrid,
          description: l10n.mapGridDescription,
          value: settings.showMapGrid,
          onChanged: (value) =>
              onChanged(settings.copyWith(showMapGrid: value)),
        ),
        _MapSetting(
          key: const ValueKey('map-resource-icons-setting'),
          title: l10n.mapResourceIcons,
          description: l10n.mapResourceIconsDescription,
          value: settings.showMapResourceIcons,
          onChanged: (value) =>
              onChanged(settings.copyWith(showMapResourceIcons: value)),
        ),
        _MapSetting(
          key: const ValueKey('map-terrain-icons-setting'),
          title: l10n.mapTerrainIcons,
          description: l10n.mapTerrainIconsDescription,
          value: settings.showMapTerrainIcons,
          onChanged: (value) =>
              onChanged(settings.copyWith(showMapTerrainIcons: value)),
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

final class _MapSetting extends StatelessWidget {
  const _MapSetting({
    required super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(description),
    value: value,
    onChanged: onChanged,
  );
}

final class _AudioSettings extends StatelessWidget {
  const _AudioSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) => _LabeledSlider(
    key: const ValueKey('master-volume-setting'),
    label: context.aonwL10n.masterVolume,
    value: settings.masterVolume,
    minimum: 0,
    maximum: 1,
    divisions: 20,
    valueLabel: '${(settings.masterVolume * 100).round()}%',
    onChanged: (value) => onChanged(settings.copyWith(masterVolume: value)),
  );
}

final class _CameraSettings extends StatelessWidget {
  const _CameraSettings({required this.settings, required this.onChanged});

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _LabeledSlider(
        key: const ValueKey('camera-sensitivity-setting'),
        label: context.aonwL10n.cameraSensitivity,
        value: settings.cameraSensitivity,
        minimum: 0.5,
        maximum: 2,
        divisions: 6,
        valueLabel: '${settings.cameraSensitivity}×',
        onChanged: (value) =>
            onChanged(settings.copyWith(cameraSensitivity: value)),
      ),
      SwitchListTile.adaptive(
        key: const ValueKey('smooth-camera-movement-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.aonwL10n.smoothCameraMovement),
        value: settings.smoothCameraMovement,
        onChanged: (value) =>
            onChanged(settings.copyWith(smoothCameraMovement: value)),
      ),
    ],
  );
}

final class _AccessibilitySettings extends StatelessWidget {
  const _AccessibilitySettings({
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
        SwitchListTile.adaptive(
          key: const ValueKey('reduced-motion-setting'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.reducedMotion),
          subtitle: Text(l10n.reducedMotionDescription),
          value: settings.reducedMotion,
          onChanged: (value) =>
              onChanged(settings.copyWith(reducedMotion: value)),
        ),
        SwitchListTile.adaptive(
          key: const ValueKey('high-contrast-setting'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.highContrast),
          subtitle: Text(l10n.highContrastDescription),
          value: settings.highContrast,
          onChanged: (value) =>
              onChanged(settings.copyWith(highContrast: value)),
        ),
      ],
    );
  }
}

final class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => AonwPanel(
    maxWidth: 720,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AonwSpacing.md),
        child,
      ],
    ),
  );
}

final class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required super.key,
    required this.label,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double minimum;
  final double maximum;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label · $valueLabel'),
      AonwMenuAdjustable(
        onAdjust: _adjust,
        child: Slider(
          value: value,
          min: minimum,
          max: maximum,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ),
    ],
  );

  void _adjust(int delta) {
    final step = (maximum - minimum) / divisions;
    onChanged((value + step * delta).clamp(minimum, maximum));
  }
}
