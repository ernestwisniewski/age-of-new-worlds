import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/pending_turn_actions_view.dart';

final class PendingTurnActionsViewMapper {
  const PendingTurnActionsViewMapper();

  PendingTurnActionsView fromWire(
    AonwPendingTurnActionsResult wire, {
    required MapView map,
    required PlayerMapView player,
    required int expectedRevision,
  }) {
    final stamp = wire.stamp;
    final current = player.stamp;
    if (expectedRevision != current.revision ||
        stamp.revision != expectedRevision ||
        (stamp.stateDigest, stamp.mapHash, stamp.rulesetHash) !=
            (current.stateDigest, current.mapHash, current.rulesetHash) ||
        stamp.mapHash != map.contentHash) {
      throw const FormatException(
        'Pending turn actions state identity is stale.',
      );
    }
    final identities = <String>{};
    final actions = <PendingTurnActionView>[];
    for (final action in wire.actions) {
      final identity = switch (action) {
        AonwPendingUnitTurnAction(:final unitId) => 'unit:$unitId',
        AonwPendingCityProductionTurnAction(:final cityId) => 'city:$cityId',
        AonwPendingResearchTurnAction() => 'research',
      };
      if (!identities.add(identity)) {
        throw const FormatException(
          'Pending turn actions contain duplicate targets.',
        );
      }
      actions.add(_action(action, map, player));
    }
    return PendingTurnActionsView(
      stamp: SessionStampView(
        revision: stamp.revision,
        stateDigest: stamp.stateDigest,
        mapHash: stamp.mapHash,
        rulesetHash: stamp.rulesetHash,
      ),
      actorPlayerId: player.actorPlayerId,
      canActivate: wire.canActivate,
      actions: actions,
    );
  }
}

PendingTurnActionView _action(
  AonwPendingTurnAction value,
  MapView map,
  PlayerMapView player,
) => switch (value) {
  AonwPendingUnitTurnAction() => _unit(value, map, player),
  AonwPendingCityProductionTurnAction() => _city(value, map, player),
  AonwPendingResearchTurnAction() => const PendingResearchTurnActionView(),
};

PendingUnitTurnActionView _unit(
  AonwPendingUnitTurnAction value,
  MapView map,
  PlayerMapView player,
) {
  final position = (col: value.coordinate.col, row: value.coordinate.row);
  final unit = player.controlledUnitById(value.unitId);
  if (unit == null ||
      unit.coordinate != position ||
      map.tileAt(position) == null) {
    throw const FormatException(
      'Pending turn action references an absent or foreign unit.',
    );
  }
  return PendingUnitTurnActionView(unitId: value.unitId, coordinate: position);
}

PendingCityProductionTurnActionView _city(
  AonwPendingCityProductionTurnAction value,
  MapView map,
  PlayerMapView player,
) {
  final position = (col: value.coordinate.col, row: value.coordinate.row);
  final city = player.cityById(value.cityId);
  if (city == null ||
      city.ownerPlayerId != player.actorPlayerId ||
      city.center != position ||
      map.tileAt(position) == null) {
    throw const FormatException(
      'Pending turn action references an absent or foreign city.',
    );
  }
  return PendingCityProductionTurnActionView(
    cityId: value.cityId,
    coordinate: position,
  );
}
