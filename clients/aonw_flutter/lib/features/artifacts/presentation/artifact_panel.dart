import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../cities/read_model/city_view.dart';
import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../application/artifact_state.dart';
import '../read_model/artifact_view.dart';
import 'artifact_copy.dart';

final class ArtifactPanel extends StatelessWidget {
  const ArtifactPanel({
    required this.state,
    required this.player,
    required this.coordinate,
    required this.unit,
    required this.city,
    required this.onAction,
    this.enabled = true,
    super.key,
  });

  final ArtifactState state;
  final PlayerMapView player;
  final MapHexCoordinate coordinate;
  final VisibleUnitView? unit;
  final CityView? city;
  final ValueChanged<ArtifactActionView> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final copy = ArtifactCopy.of(context);
    final artifacts = player.artifactsAt(coordinate).toList(growable: false);
    final acceptsInput = enabled && !state.commandPending;
    final mapArtifact = artifacts
        .where((artifact) => artifact.location is MapArtifactLocationView)
        .firstOrNull;
    final carriedArtifact = unit?.carriedArtifactId == null
        ? null
        : player.artifactById(unit!.carriedArtifactId!);
    final storedArtifacts = artifacts
        .where((artifact) => artifact.location is StoredArtifactLocationView)
        .toList(growable: false);
    if (artifacts.isEmpty && state.failure == null) {
      return const SizedBox.shrink();
    }
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        key: const ValueKey('artifact-panel'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AonwSpacing.md),
          Text(
            copy.text(ArtifactText.title),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          for (final artifact in artifacts)
            Padding(
              padding: const EdgeInsets.only(top: AonwSpacing.xs),
              child: Semantics(
                label: copy.artifactName(artifact.kind),
                value: copy.location(artifact.location, player),
                child: Text(
                  '${copy.artifactName(artifact.kind)} · '
                  '${copy.location(artifact.location, player)}',
                ),
              ),
            ),
          if (mapArtifact != null && unit != null)
            OutlinedButton.icon(
              key: const ValueKey('start-artifact-excavation'),
              onPressed: acceptsInput
                  ? () => onAction(
                      StartArtifactExcavationActionView(unitId: unit!.id),
                    )
                  : null,
              icon: const Icon(Icons.architecture),
              label: Text(copy.text(ArtifactText.startExcavation)),
            ),
          if (carriedArtifact != null && city?.ownedDetails != null)
            OutlinedButton.icon(
              key: const ValueKey('store-artifact-in-city'),
              onPressed: acceptsInput
                  ? () => onAction(
                      StoreArtifactInCityActionView(
                        unitId: unit!.id,
                        cityId: city!.id,
                      ),
                    )
                  : null,
              icon: const Icon(Icons.inventory_2),
              label: Text(copy.text(ArtifactText.storeInCity)),
            ),
          for (final artifact in storedArtifacts)
            _ArtifactTradeEditor(
              key: ValueKey(('artifact-trade', artifact.id)),
              artifact: artifact,
              counterpartPlayerIds: player.diplomaticCounterpartPlayerIds,
              enabled: acceptsInput && city?.ownedDetails != null,
              onAction: onAction,
            ),
          if (state.commandPending)
            AonwProgressIndicator(
              semanticLabel: copy.text(ArtifactText.executing),
              compact: true,
            ),
          if (state.failure case final failure?)
            Text(
              copy.failure(failure),
              key: const ValueKey('artifact-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

final class _ArtifactTradeEditor extends StatefulWidget {
  const _ArtifactTradeEditor({
    required this.artifact,
    required this.counterpartPlayerIds,
    required this.enabled,
    required this.onAction,
    super.key,
  });

  final WorldArtifactView artifact;
  final List<String> counterpartPlayerIds;
  final bool enabled;
  final ValueChanged<ArtifactActionView> onAction;

  @override
  State<_ArtifactTradeEditor> createState() => _ArtifactTradeEditorState();
}

final class _ArtifactTradeEditorState extends State<_ArtifactTradeEditor> {
  late final TextEditingController _goldController;
  String? _targetPlayerId;

  @override
  void initState() {
    super.initState();
    _goldController = TextEditingController(text: '0');
    _targetPlayerId = widget.counterpartPlayerIds.firstOrNull;
  }

  @override
  void didUpdateWidget(covariant _ArtifactTradeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.counterpartPlayerIds.contains(_targetPlayerId)) {
      _targetPlayerId = widget.counterpartPlayerIds.firstOrNull;
    }
  }

  @override
  void dispose() {
    _goldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = ArtifactCopy.of(context);
    final canTrade = widget.enabled && _targetPlayerId != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(('artifact-trade-target', widget.artifact.id)),
          initialValue: _targetPlayerId,
          decoration: InputDecoration(
            labelText: copy.text(ArtifactText.targetPlayer),
          ),
          items: [
            for (final playerId in widget.counterpartPlayerIds)
              DropdownMenuItem(value: playerId, child: Text(playerId)),
          ],
          onChanged: widget.enabled
              ? (value) => setState(() => _targetPlayerId = value)
              : null,
        ),
        TextField(
          key: ValueKey(('artifact-trade-gold', widget.artifact.id)),
          controller: _goldController,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: copy.text(ArtifactText.offeredGold),
          ),
        ),
        OutlinedButton.icon(
          key: ValueKey(('trade-artifact', widget.artifact.id)),
          onPressed: canTrade ? _trade : null,
          icon: const Icon(Icons.swap_horiz),
          label: Text(copy.text(ArtifactText.trade)),
        ),
      ],
    );
  }

  void _trade() {
    final target = _targetPlayerId;
    final gold = int.tryParse(_goldController.text);
    if (target == null || gold == null || gold < 0) return;
    widget.onAction(
      TradeArtifactActionView(
        targetPlayerId: target,
        offeredArtifactId: widget.artifact.id,
        offeredGold: gold,
      ),
    );
  }
}
