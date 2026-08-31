import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_pending_action.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

final class AonwPlayerStrategicResourceAmount {
  const AonwPlayerStrategicResourceAmount({
    required this.resource,
    required this.amount,
  });

  factory AonwPlayerStrategicResourceAmount.fromJson(Object? source) {
    final value = readObject(source, 'player strategic resource amount');
    requireKeys(value, const {
      'resource',
      'amount',
    }, 'player strategic resource amount');
    return AonwPlayerStrategicResourceAmount(
      resource: AonwResourceType.fromJson(value['resource']),
      amount: readInt(value['amount'], 'player strategic resource amount'),
    );
  }

  final AonwResourceType resource;
  final int amount;
}

final class AonwPlayerStrategicResourceSource {
  const AonwPlayerStrategicResourceSource({
    required this.cityId,
    required this.coordinate,
    required this.resource,
    required this.improvement,
    required this.amountPerTurn,
  });

  factory AonwPlayerStrategicResourceSource.fromJson(Object? source) {
    final value = readObject(source, 'player strategic resource source');
    requireKeys(value, const {
      'cityId',
      'coordinate',
      'resource',
      'improvement',
      'amountPerTurn',
    }, 'player strategic resource source');
    return AonwPlayerStrategicResourceSource(
      cityId: readString(value['cityId'], 'resource source city id'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      resource: AonwResourceType.fromJson(value['resource']),
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
      amountPerTurn: readInt(
        value['amountPerTurn'],
        'resource source amount per turn',
      ),
    );
  }

  final String cityId;
  final AonwCoordinate coordinate;
  final AonwResourceType resource;
  final AonwFieldImprovementKind improvement;
  final int amountPerTurn;
}

final class AonwPlayerEconomyView {
  AonwPlayerEconomyView({
    required this.gold,
    required this.warWeariness,
    required this.stabilityNet,
    required List<AonwPlayerStrategicResourceAmount> strategicResourceStockpile,
    required List<AonwPlayerStrategicResourceAmount> strategicResourceOutput,
    required List<AonwPlayerStrategicResourceSource> strategicResourceSources,
  }) : strategicResourceStockpile = List.unmodifiable(
         strategicResourceStockpile,
       ),
       strategicResourceOutput = List.unmodifiable(strategicResourceOutput),
       strategicResourceSources = List.unmodifiable(strategicResourceSources);

  factory AonwPlayerEconomyView.empty() => AonwPlayerEconomyView(
    gold: 0,
    warWeariness: 0,
    stabilityNet: 0,
    strategicResourceStockpile: const [],
    strategicResourceOutput: const [],
    strategicResourceSources: const [],
  );

  factory AonwPlayerEconomyView.fromJson(Object? source) {
    final value = readObject(source, 'player economy view');
    requireKeys(value, const {
      'gold',
      'warWeariness',
      'stabilityNet',
      'strategicResourceStockpile',
      'strategicResourceOutput',
      'strategicResourceSources',
    }, 'player economy view');
    return AonwPlayerEconomyView(
      gold: readInt(value['gold'], 'player gold'),
      warWeariness: readInt(value['warWeariness'], 'player war weariness'),
      stabilityNet: readInt(value['stabilityNet'], 'player stability'),
      strategicResourceStockpile: _economyViews(
        value['strategicResourceStockpile'],
        'player strategic resource stockpile',
        AonwPlayerStrategicResourceAmount.fromJson,
      ),
      strategicResourceOutput: _economyViews(
        value['strategicResourceOutput'],
        'player strategic resource output',
        AonwPlayerStrategicResourceAmount.fromJson,
      ),
      strategicResourceSources: _economyViews(
        value['strategicResourceSources'],
        'player strategic resource sources',
        AonwPlayerStrategicResourceSource.fromJson,
      ),
    );
  }

  final int gold;
  final int warWeariness;
  final int stabilityNet;
  final List<AonwPlayerStrategicResourceAmount> strategicResourceStockpile;
  final List<AonwPlayerStrategicResourceAmount> strategicResourceOutput;
  final List<AonwPlayerStrategicResourceSource> strategicResourceSources;
}

List<T> _economyViews<T>(
  Object? value,
  String label,
  T Function(Object? value) parse,
) => readList(value, label, (item, _) => parse(item));
