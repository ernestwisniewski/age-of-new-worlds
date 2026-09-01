import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../map/read_model/map_view.dart';
import '../application/city_state.dart';
import '../read_model/city_view.dart';
import 'city_copy.dart';

final class CityPanel extends StatelessWidget {
  const CityPanel({
    required this.state,
    required this.city,
    required this.onToggleFoundingHex,
    required this.onConfirmFounding,
    required this.onCancelFounding,
    required this.onStartManagement,
    required this.onCancelManagement,
    this.enabled = true,
    super.key,
  });

  final CityState state;
  final CityView? city;
  final ValueChanged<MapHexCoordinate> onToggleFoundingHex;
  final VoidCallback onConfirmFounding;
  final VoidCallback onCancelFounding;
  final ValueChanged<CityManagementMode> onStartManagement;
  final VoidCallback onCancelManagement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final copy = CityCopy.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: copy.text(CityText.title),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AonwSpacing.sm),
              Text(
                city?.name ?? copy.text(CityText.foundingTitle),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (city case final city?) _CitySummary(city: city),
              if (state.loading)
                AonwProgressIndicator(
                  semanticLabel: copy.text(CityText.loading),
                  compact: true,
                ),
              if (state.foundingOptions case final options?)
                _FoundingEditor(
                  state: state,
                  options: options,
                  onToggle: onToggleFoundingHex,
                  onConfirm: onConfirmFounding,
                  onCancel: onCancelFounding,
                ),
              if (state.inspection case final inspection?)
                _OwnedCityInspection(
                  state: state,
                  inspection: inspection,
                  enabled: enabled && !state.commandPending,
                  onStartManagement: onStartManagement,
                  onCancelManagement: onCancelManagement,
                ),
              if (state.commandPending)
                AonwProgressIndicator(
                  semanticLabel: copy.text(CityText.executing),
                  compact: true,
                ),
              if (state.failure case final failure?)
                Text(
                  copy.failure(failure),
                  key: const ValueKey('city-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _CitySummary extends StatelessWidget {
  const _CitySummary({required this.city});

  final CityView city;

  @override
  Widget build(BuildContext context) {
    final copy = CityCopy.of(context);
    final details = city.ownedDetails;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${copy.text(CityText.owner)}: ${city.ownerPlayerId}'),
        if (city.hitPoints case final hitPoints?)
          Text('${copy.text(CityText.health)}: $hitPoints'),
        if (details != null) ...[
          Text('${copy.text(CityText.population)}: ${details.population}'),
          Text(
            '${copy.text(CityText.territory)}: '
            '${city.visibleControlledHexes.length}/${details.maxHexes}',
          ),
        ],
      ],
    );
  }
}

final class _FoundingEditor extends StatelessWidget {
  const _FoundingEditor({
    required this.state,
    required this.options,
    required this.onToggle,
    required this.onConfirm,
    required this.onCancel,
  });

  final CityState state;
  final CityFoundingOptionsView options;
  final ValueChanged<MapHexCoordinate> onToggle;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final copy = CityCopy.of(context);
    final choices = <MapHexCoordinate>{
      ...options.selectedControlledHexes,
      ...options.availableControlledHexes,
    }.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${copy.text(CityText.foundingSelection)}: '
          '${state.foundingSelection.length}/'
          '${options.requiredControlledHexes}',
        ),
        Wrap(
          spacing: AonwSpacing.xs,
          runSpacing: AonwSpacing.xs,
          children: [
            for (final coordinate in choices)
              FilterChip(
                label: Text('${coordinate.col}, ${coordinate.row}'),
                selected: state.foundingSelection.contains(coordinate),
                onSelected: state.commandPending
                    ? null
                    : (_) => onToggle(coordinate),
              ),
          ],
        ),
        Wrap(
          spacing: AonwSpacing.xs,
          runSpacing: AonwSpacing.xs,
          children: [
            FilledButton.icon(
              key: const ValueKey('confirm-city-founding'),
              onPressed:
                  !state.commandPending &&
                      state.foundingSelection.length ==
                          options.requiredControlledHexes
                  ? onConfirm
                  : null,
              icon: const Icon(Icons.location_city),
              label: Text(copy.text(CityText.foundingConfirm)),
            ),
            OutlinedButton.icon(
              key: const ValueKey('cancel-city-founding'),
              onPressed: state.commandPending ? null : onCancel,
              icon: const Icon(Icons.close),
              label: Text(copy.text(CityText.foundingCancel)),
            ),
          ],
        ),
      ],
    );
  }
}

final class _OwnedCityInspection extends StatelessWidget {
  const _OwnedCityInspection({
    required this.state,
    required this.inspection,
    required this.enabled,
    required this.onStartManagement,
    required this.onCancelManagement,
  });

  final CityState state;
  final CityInspectionView inspection;
  final bool enabled;
  final ValueChanged<CityManagementMode> onStartManagement;
  final VoidCallback onCancelManagement;

  @override
  Widget build(BuildContext context) {
    final copy = CityCopy.of(context);
    final worked = inspection.workedHexes;
    final cityYield = inspection.cityYield.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${copy.text(CityText.cityYield)}: '
          '${copy.text(CityText.food)} ${cityYield.food}, '
          '${copy.text(CityText.production)} ${cityYield.production}, '
          '${copy.text(CityText.gold)} ${cityYield.gold}, '
          '${copy.text(CityText.defense)} ${cityYield.defense}',
        ),
        Text(
          '${copy.text(CityText.workedHexes)}: '
          '${worked.selectedHexes.length}/${worked.limit}',
        ),
        _CityManagementControls(
          mode: state.managementMode,
          expansionAvailable: inspection.expansion.candidates.isNotEmpty,
          enabled: enabled,
          onStart: onStartManagement,
          onCancel: onCancelManagement,
        ),
      ],
    );
  }
}

final class _CityManagementControls extends StatelessWidget {
  const _CityManagementControls({
    required this.mode,
    required this.expansionAvailable,
    required this.enabled,
    required this.onStart,
    required this.onCancel,
  });

  final CityManagementMode? mode;
  final bool expansionAvailable;
  final bool enabled;
  final ValueChanged<CityManagementMode> onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final copy = CityCopy.of(context);
    final activeMode = mode;
    if (activeMode != null) {
      final hint = activeMode == CityManagementMode.workedHexes
          ? CityText.workedHexHint
          : CityText.expansionHint;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.text(hint)),
          OutlinedButton.icon(
            key: const ValueKey('cancel-city-management'),
            onPressed: enabled ? onCancel : null,
            icon: const Icon(Icons.close),
            label: Text(copy.text(CityText.managementCancel)),
          ),
        ],
      );
    }
    return Wrap(
      spacing: AonwSpacing.xs,
      runSpacing: AonwSpacing.xs,
      children: [
        FilledButton.icon(
          key: const ValueKey('start-worked-hex-management'),
          onPressed: enabled
              ? () => onStart(CityManagementMode.workedHexes)
              : null,
          icon: const Icon(Icons.grid_view),
          label: Text(copy.text(CityText.workedHexSelect)),
        ),
        OutlinedButton.icon(
          key: const ValueKey('start-expansion-management'),
          onPressed: enabled && expansionAvailable
              ? () => onStart(CityManagementMode.expansion)
              : null,
          icon: const Icon(Icons.open_in_full),
          label: Text(copy.text(CityText.expansionSelect)),
        ),
      ],
    );
  }
}
