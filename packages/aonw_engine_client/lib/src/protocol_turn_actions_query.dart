part of 'protocol_query.dart';

final class AonwPendingTurnActionsResult extends AonwQueryResult {
  AonwPendingTurnActionsResult({
    required this.stamp,
    required this.canActivate,
    required List<AonwPendingTurnAction> actions,
  }) : actions = List.unmodifiable(actions);

  factory AonwPendingTurnActionsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'canActivate',
      'actions',
    }, 'pending turn actions');
    return AonwPendingTurnActionsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      canActivate: readBool(value['canActivate'], 'turn actions availability'),
      actions: readList(
        value['actions'],
        'pending turn actions',
        (item, _) => AonwPendingTurnAction.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final bool canActivate;
  final List<AonwPendingTurnAction> actions;
}

sealed class AonwPendingTurnAction {
  const AonwPendingTurnAction();

  factory AonwPendingTurnAction.fromJson(Object? source) {
    final value = readObject(source, 'pending turn action');
    final type = readString(value['type'], 'pending turn action type');
    switch (type) {
      case 'unit':
        requireKeys(value, const {
          'type',
          'unitId',
          'coordinate',
        }, 'unit turn action');
        return AonwPendingUnitTurnAction(
          unitId: readString(value['unitId'], 'turn action unit id'),
          coordinate: AonwCoordinate.fromJson(value['coordinate']),
        );
      case 'cityProduction':
        requireKeys(value, const {
          'type',
          'cityId',
          'coordinate',
        }, 'city turn action');
        return AonwPendingCityProductionTurnAction(
          cityId: readString(value['cityId'], 'turn action city id'),
          coordinate: AonwCoordinate.fromJson(value['coordinate']),
        );
      case 'research':
        requireKeys(value, const {'type'}, 'research turn action');
        return const AonwPendingResearchTurnAction();
      default:
        throw FormatException('Unknown AoNW pending turn action $type.');
    }
  }
}

final class AonwPendingUnitTurnAction extends AonwPendingTurnAction {
  const AonwPendingUnitTurnAction({
    required this.unitId,
    required this.coordinate,
  });
  final String unitId;
  final AonwCoordinate coordinate;
}

final class AonwPendingCityProductionTurnAction extends AonwPendingTurnAction {
  const AonwPendingCityProductionTurnAction({
    required this.cityId,
    required this.coordinate,
  });
  final String cityId;
  final AonwCoordinate coordinate;
}

final class AonwPendingResearchTurnAction extends AonwPendingTurnAction {
  const AonwPendingResearchTurnAction();
}
