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
    required this.onAction,
    this.enabled = true,
    super.key,
  });

  final CityState state;
  final CityView? city;
  final ValueChanged<MapHexCoordinate> onToggleFoundingHex;
  final VoidCallback onConfirmFounding;
  final ValueChanged<CityActionView> onAction;
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
                ),
              if (state.inspection case final inspection?)
                _OwnedCityInspection(
                  inspection: inspection,
                  enabled: enabled && !state.commandPending,
                  onAction: onAction,
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
  });

  final CityState state;
  final CityFoundingOptionsView options;
  final ValueChanged<MapHexCoordinate> onToggle;
  final VoidCallback onConfirm;

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
      ],
    );
  }
}

final class _OwnedCityInspection extends StatelessWidget {
  const _OwnedCityInspection({
    required this.inspection,
    required this.enabled,
    required this.onAction,
  });

  final CityInspectionView inspection;
  final bool enabled;
  final ValueChanged<CityActionView> onAction;

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
        Wrap(
          spacing: AonwSpacing.xs,
          runSpacing: AonwSpacing.xs,
          children: [
            for (final coordinate in worked.availableHexes)
              FilterChip(
                label: Text('${coordinate.col}, ${coordinate.row}'),
                selected: worked.selectedHexes.contains(coordinate),
                onSelected: enabled
                    ? (_) => onAction(
                        ToggleWorkedHexActionView(
                          cityId: worked.cityId,
                          target: coordinate,
                        ),
                      )
                    : null,
              ),
          ],
        ),
        Text(copy.text(CityText.expansion)),
        Wrap(
          spacing: AonwSpacing.xs,
          runSpacing: AonwSpacing.xs,
          children: [
            for (final candidate in inspection.expansion.candidates)
              ChoiceChip(
                label: Text(
                  '${candidate.coordinate.col}, ${candidate.coordinate.row} '
                  '(${candidate.score})',
                ),
                selected:
                    inspection.expansion.preferredHex == candidate.coordinate,
                onSelected: enabled
                    ? (_) => onAction(
                        SelectCityExpansionActionView(
                          cityId: inspection.expansion.cityId,
                          target: candidate.coordinate,
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}
