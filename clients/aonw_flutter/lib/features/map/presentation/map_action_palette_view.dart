import '../../../l10n/generated/aonw_localizations.dart';
import '../../workers/read_model/worker_view.dart';
import '../application/map_interaction_state.dart';
import '../read_model/map_view.dart';
import '../read_model/pending_action_view.dart';
import '../read_model/player_map_view.dart';

sealed class MapActionPaletteView {
  const MapActionPaletteView({required this.coordinate, required this.enabled});

  final MapHexCoordinate coordinate;
  final bool enabled;
}

final class MapMovePreviewPillView extends MapActionPaletteView {
  const MapMovePreviewPillView({
    required super.coordinate,
    required super.enabled,
    required this.label,
    required this.warning,
  });

  final String label;
  final bool warning;
}

final class MapWorkerImprovementOptionView {
  const MapWorkerImprovementOptionView({
    required this.improvement,
    required this.label,
    required this.turnLabel,
  });

  final FieldImprovementKind improvement;
  final String label;
  final String turnLabel;
}

final class MapWorkerActionPaletteView extends MapActionPaletteView {
  MapWorkerActionPaletteView({
    required super.coordinate,
    required super.enabled,
    required this.unitId,
    required List<MapWorkerImprovementOptionView> options,
    required this.previewedImprovement,
    required this.confirmLabel,
  }) : options = List.unmodifiable(options);

  final String unitId;
  final List<MapWorkerImprovementOptionView> options;
  final FieldImprovementKind? previewedImprovement;
  final String confirmLabel;
}

MapActionPaletteView? buildMapActionPaletteView({
  required MapInteractionState interaction,
  required PlayerMapView player,
  required AonwLocalizations l10n,
}) {
  if (interaction.city?.founderUnitId != null) return null;
  final worker = _buildWorkerPalette(interaction, player, l10n);
  return worker ?? _buildMovePalette(interaction, l10n);
}

MapWorkerActionPaletteView? _buildWorkerPalette(
  MapInteractionState interaction,
  PlayerMapView player,
  AonwLocalizations l10n,
) {
  final pendingAction = player.pendingAction;
  final worker = interaction.worker;
  final workerOptions = worker?.options;
  if (pendingAction is PendingWorkerActionSelectionView &&
      workerOptions != null &&
      worker != null &&
      workerOptions.unitId == pendingAction.unitId &&
      worker.unitId == pendingAction.unitId &&
      workerOptions.improvements.isNotEmpty) {
    final previewed = pendingAction.improvement;
    final previewedLabel = previewed == null
        ? null
        : l10n.presentationName(previewed.name);
    return MapWorkerActionPaletteView(
      coordinate: workerOptions.coordinate,
      enabled: !worker.loading && !worker.commandPending,
      unitId: workerOptions.unitId,
      options: _localizedWorkerOptions(workerOptions.improvements, l10n),
      previewedImprovement: previewed,
      confirmLabel: _workerConfirmLabel(previewedLabel, l10n),
    );
  }

  return null;
}

List<MapWorkerImprovementOptionView> _localizedWorkerOptions(
  Iterable<WorkerImprovementOptionView> options,
  AonwLocalizations l10n,
) => [
  for (final option in options)
    MapWorkerImprovementOptionView(
      improvement: option.improvement,
      label: l10n.presentationName(option.improvement.name),
      turnLabel: l10n.moveTurnCost(option.buildTurns),
    ),
];

String _workerConfirmLabel(String? previewedLabel, AonwLocalizations l10n) =>
    previewedLabel == null
    ? l10n.workerText('selectImprovement')
    : '${l10n.workerText('confirmImprovement')} · $previewedLabel';

MapMovePreviewPillView? _buildMovePalette(
  MapInteractionState interaction,
  AonwLocalizations l10n,
) {
  final route = interaction.route;
  if (route == null) return null;
  return MapMovePreviewPillView(
    coordinate: route.destination,
    enabled: !_hasPendingCommand(interaction),
    label: l10n.confirmMoveWithCost(l10n.moveTurnCost(route.estimatedTurns)),
    warning: route.estimatedTurns > 1,
  );
}

bool _hasPendingCommand(MapInteractionState interaction) =>
    interaction.movementPending ||
    (interaction.actionDeck?.commandPending ?? false) ||
    (interaction.unitLogistics?.commandPending ?? false) ||
    (interaction.worker?.commandPending ?? false) ||
    (interaction.production?.commandPending ?? false) ||
    (interaction.artifact?.commandPending ?? false);
