import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_menu_adjustable.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../audio/presentation/game_audio_actions.dart';
import '../../map/read_model/map_view_mode.dart';
import '../application/client_settings.dart';
import '../application/window_settings.dart';
import 'client_settings_controller.dart';
import 'window_settings_controller.dart';
import 'window_settings_host.dart';

part 'settings_map.dart';
part 'settings_movement_camera.dart';
part 'settings_animations.dart';
part 'settings_ai.dart';
part 'settings_audio.dart';
part 'settings_automation.dart';
part 'settings_performance.dart';
part 'settings_gamepad.dart';
part 'settings_keyboard.dart';
part 'settings_text_scale.dart';
part 'settings_language.dart';
part 'settings_window.dart';
part 'settings_gamepad_bindings.dart';
part 'settings_gamepad_labels.dart';

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
          onReset: () => _reset(context),
        ),
      ),
    ),
  );

  void _reset(BuildContext context) {
    unawaited(controller.reset());
    unawaited(WindowSettingsScope.of(context)?.reset());
  }
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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AonwSpacing.lg),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _sections(context),
          ),
        ),
      ),
    ],
  );

  List<Widget> _sections(BuildContext context) {
    final l10n = context.aonwL10n;
    return [
      ..._accessibilitySections(context),
      _SettingsSection(
        title: l10n.mapAppearanceSettings,
        child: _MapAppearanceSettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _SettingsSection(
        title: l10n.mapMarkingsSettings,
        child: _MapMarkingsSettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _SettingsSection(
        title: l10n.cameraSettings,
        child: _CameraSettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _SettingsSection(
        title: l10n.animationSettings,
        child: _AnimationSettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _SettingsSection(
        title: l10n.automationSettings,
        child: _AutomationSettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _SettingsSection(
        title: l10n.audioSettings,
        child: _AudioSettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _SettingsSection(
        title: l10n.aiSettings,
        child: _AiSettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _SettingsSection(
        title: l10n.performanceSettings,
        child: _PerformanceSettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _GamepadSettings(settings: settings, onChanged: onChanged),
      const SizedBox(height: AonwSpacing.md),
      const _KeyboardSettings(),
      const SizedBox(height: AonwSpacing.lg),
      OutlinedButton.icon(
        key: const ValueKey('reset-settings'),
        onPressed: context.withGameSound(onReset),
        icon: const Icon(Icons.restore),
        label: Text(l10n.resetSettings),
      ),
    ];
  }

  List<Widget> _accessibilitySections(BuildContext context) {
    final l10n = context.aonwL10n;
    return [
      _SettingsSection(
        title: l10n.accessibilitySettings,
        child: _AccessibilitySettings(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      _SettingsSection(
        title: l10n.languageSettings,
        child: _LanguageSetting(settings: settings, onChanged: onChanged),
      ),
      const SizedBox(height: AonwSpacing.md),
      const _WindowSettings(),
    ];
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
    onChanged: context.withGameSoundValue(onChanged),
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
        onChanged: context.withGameSoundValue(
          (value) => onChanged(settings.copyWith(smoothCameraMovement: value)),
        ),
      ),
      SwitchListTile.adaptive(
        key: const ValueKey('cinematic-camera-setting'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.aonwL10n.cinematicCamera),
        value: settings.cinematicCamera,
        onChanged: context.withGameSoundValue(
          (value) => onChanged(settings.copyWith(cinematicCamera: value)),
        ),
      ),
      _MovementCameraSettings(settings: settings, onChanged: onChanged),
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
        _TextScaleSetting(settings: settings, onChanged: onChanged),
        const SizedBox(height: AonwSpacing.md),
        SwitchListTile.adaptive(
          key: const ValueKey('reduced-motion-setting'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.reducedMotion),
          subtitle: Text(l10n.reducedMotionDescription),
          value: settings.reducedMotion,
          onChanged: context.withGameSoundValue(
            (value) => onChanged(settings.copyWith(reducedMotion: value)),
          ),
        ),
        SwitchListTile.adaptive(
          key: const ValueKey('high-contrast-setting'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.highContrast),
          subtitle: Text(l10n.highContrastDescription),
          value: settings.highContrast,
          onChanged: context.withGameSoundValue(
            (value) => onChanged(settings.copyWith(highContrast: value)),
          ),
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
