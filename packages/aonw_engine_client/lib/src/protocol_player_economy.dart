import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_economy_forecast.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_pending_action.dart';
import 'package:aonw_engine_client/src/protocol_resource_inventory.dart';
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
    required this.strategicResourceInventory,
    required this.gold,
    required List<AonwResourceType> strategicResourceShortages,
    required this.warWeariness,
    required this.stabilityNet,
    required List<AonwPlayerStrategicResourceAmount> strategicResourceStockpile,
    required List<AonwPlayerStrategicResourceAmount> strategicResourceOutput,
    required List<AonwPlayerStrategicResourceSource> strategicResourceSources,
    required this.forecast,
  }) : strategicResourceShortages = List.unmodifiable(
         strategicResourceShortages,
       ),
       strategicResourceStockpile = List.unmodifiable(
         strategicResourceStockpile,
       ),
       strategicResourceOutput = List.unmodifiable(strategicResourceOutput),
       strategicResourceSources = List.unmodifiable(strategicResourceSources);

  factory AonwPlayerEconomyView.empty() => AonwPlayerEconomyView(
    strategicResourceInventory: AonwStrategicResourceInventory.empty(),
    gold: 0,
    strategicResourceShortages: const [],
    warWeariness: 0,
    stabilityNet: 0,
    strategicResourceStockpile: const [],
    strategicResourceOutput: const [],
    strategicResourceSources: const [],
    forecast: AonwEconomyForecast.empty(),
  );

  factory AonwPlayerEconomyView.fromJson(Object? source) {
    final value = readObject(source, 'player economy view');
    requireKeys(value, const {
      'gold',
      'strategicResourceInventory',
      'strategicResourceShortages',
      'warWeariness',
      'stabilityNet',
      'strategicResourceStockpile',
      'strategicResourceOutput',
      'strategicResourceSources',
      'forecast',
    }, 'player economy view');
    return AonwPlayerEconomyView(
      strategicResourceInventory: AonwStrategicResourceInventory.fromJson(
        value['strategicResourceInventory'],
      ),
      gold: readInt(value['gold'], 'player gold'),
      strategicResourceShortages: readList(
        value['strategicResourceShortages'],
        'strategic resource shortages',
        (item, _) => AonwResourceType.fromJson(item),
      ),
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
      forecast: AonwEconomyForecast.fromJson(value['forecast']),
    );
  }

  final int gold;
  final AonwStrategicResourceInventory strategicResourceInventory;
  final List<AonwResourceType> strategicResourceShortages;
  final int warWeariness;
  final int stabilityNet;
  final List<AonwPlayerStrategicResourceAmount> strategicResourceStockpile;
  final List<AonwPlayerStrategicResourceAmount> strategicResourceOutput;
  final List<AonwPlayerStrategicResourceSource> strategicResourceSources;
  final AonwEconomyForecast forecast;
}

List<T> _economyViews<T>(
  Object? value,
  String label,
  T Function(Object? value) parse,
) => readList(value, label, (item, _) => parse(item));
