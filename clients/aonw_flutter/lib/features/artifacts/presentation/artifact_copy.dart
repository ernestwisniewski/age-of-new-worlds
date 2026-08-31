import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';
import '../../map/read_model/player_map_view.dart';
import '../application/artifact_state.dart';
import '../read_model/artifact_view.dart';

enum ArtifactText {
  title,
  executing,
  startExcavation,
  storeInCity,
  trade,
  targetPlayer,
  offeredGold,
  onMap,
  carried,
  stored,
  excavation,
  turnsRemaining,
}

final class ArtifactCopy {
  const ArtifactCopy._(this._l10n);

  factory ArtifactCopy.of(BuildContext context) =>
      ArtifactCopy._(context.aonwL10n);

  final AonwLocalizations _l10n;

  String text(ArtifactText key) => _l10n.artifactText(key.name);

  String artifactName(WorldArtifactKindView kind) =>
      _l10n.artifactName(kind.name);

  String location(ArtifactLocationView location, PlayerMapView player) =>
      switch (location) {
        MapArtifactLocationView(:final coordinate) => _l10n.artifactOnMap(
          coordinate.col,
          coordinate.row,
        ),
        CarriedArtifactLocationView(:final unitId) => _l10n.artifactCarriedBy(
          _unitName(player, unitId),
        ),
        StoredArtifactLocationView(:final cityId) => _l10n.artifactStoredIn(
          player.cityById(cityId)?.name ?? cityId,
        ),
        ExcavationArtifactLocationView(
          :final coordinate,
          :final remainingTurns,
        ) =>
          _l10n.artifactExcavationAt(
            coordinate.col,
            coordinate.row,
            remainingTurns,
          ),
      };

  String _unitName(PlayerMapView player, String unitId) {
    final unit = player.controlledUnitById(unitId);
    return unit == null ? unitId : _l10n.presentationName(unit.kind.name);
  }

  String failure(ArtifactFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _l10n.artifactFailure(key);
  }
}
