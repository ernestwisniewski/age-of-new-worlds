import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';

final class PendingTurnActionsView {
  PendingTurnActionsView({
    required this.stamp,
    required this.actorPlayerId,
    required this.canActivate,
    required List<PendingTurnActionView> actions,
  }) : actions = List.unmodifiable(actions);

  final SessionStampView stamp;
  final String actorPlayerId;
  final bool canActivate;
  final List<PendingTurnActionView> actions;
}

sealed class PendingTurnActionView {
  const PendingTurnActionView();
}

final class PendingUnitTurnActionView extends PendingTurnActionView {
  const PendingUnitTurnActionView({
    required this.unitId,
    required this.coordinate,
  });
  final String unitId;
  final MapHexCoordinate coordinate;
}

final class PendingCityProductionTurnActionView extends PendingTurnActionView {
  const PendingCityProductionTurnActionView({
    required this.cityId,
    required this.coordinate,
  });
  final String cityId;
  final MapHexCoordinate coordinate;
}

final class PendingResearchTurnActionView extends PendingTurnActionView {
  const PendingResearchTurnActionView();
}
