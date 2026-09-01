import 'package:aonw_engine_client/src/protocol_city_view.dart';
import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_evidence.dart';
import 'package:aonw_engine_client/src/protocol_execution.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_pending_action.dart';
import 'package:aonw_engine_client/src/protocol_player_view.dart';
import 'package:aonw_engine_client/src/protocol_research_values.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

part 'protocol_city_query.dart';
part 'protocol_production_query.dart';
part 'protocol_research_query.dart';
part 'protocol_worker_query.dart';

sealed class AonwQueryResult {
  const AonwQueryResult();

  factory AonwQueryResult.fromJson(Object? source) {
    final value = readObject(source, 'query result');
    return switch (value['type']) {
      'reachable' => AonwReachableResult.fromJson(value),
      'routePlan' => AonwRoutePlanResult.fromJson(value),
      'unitLogisticsOptions' => AonwUnitLogisticsOptionsResult.fromJson(value),
      'combatPreview' => AonwCombatPreviewResult.fromJson(value),
      'cityFoundingOptions' => AonwCityFoundingOptionsResult.fromJson(value),
      'cityWorkedHexOptions' => AonwCityWorkedHexOptionsResult.fromJson(value),
      'cityExpansionOptions' => AonwCityExpansionOptionsResult.fromJson(value),
      'cityYield' => AonwCityYieldResult.fromJson(value),
      'strategicResourceProjection' =>
        AonwStrategicResourceProjectionResult.fromJson(value),
      'productionOptions' => AonwProductionOptionsResult.fromJson(value),
      'researchOptions' => AonwResearchOptionsResult.fromJson(value),
      'workerOptions' => AonwWorkerOptionsResult.fromJson(value),
      final Object? type => throw FormatException(
        'Unknown AoNW query result $type.',
      ),
    };
  }
}

final class AonwCombatPreviewResult extends AonwQueryResult {
  const AonwCombatPreviewResult({required this.stamp, required this.preview});

  factory AonwCombatPreviewResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'preview',
    }, 'combat preview result');
    return AonwCombatPreviewResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      preview: AonwCombatPreview.fromJson(value['preview']),
    );
  }

  final AonwSessionStamp stamp;
  final AonwCombatPreview preview;
}

final class AonwUnitLogisticsOptionsResult extends AonwQueryResult {
  AonwUnitLogisticsOptionsResult({
    required this.stamp,
    required this.unitId,
    required this.autoExplore,
    required List<AonwMerchantDestinationOption> merchantRouteDestinations,
    required List<AonwMerchantDestinationOption> merchantTravelDestinations,
    required List<AonwDetachmentOption> detachments,
  }) : merchantRouteDestinations = List.unmodifiable(merchantRouteDestinations),
       merchantTravelDestinations = List.unmodifiable(
         merchantTravelDestinations,
       ),
       detachments = List.unmodifiable(detachments);

  factory AonwUnitLogisticsOptionsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'unitId',
      'autoExplore',
      'merchantRouteDestinations',
      'merchantTravelDestinations',
      'detachments',
    }, 'unit logistics options');
    return AonwUnitLogisticsOptionsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      unitId: readString(value['unitId'], 'logistics unit id'),
      autoExplore: value['autoExplore'] == null
          ? null
          : AonwAutoExploreOption.fromJson(value['autoExplore']),
      merchantRouteDestinations: readList(
        value['merchantRouteDestinations'],
        'merchant route destinations',
        (item, _) => AonwMerchantDestinationOption.fromJson(item),
      ),
      merchantTravelDestinations: readList(
        value['merchantTravelDestinations'],
        'merchant travel destinations',
        (item, _) => AonwMerchantDestinationOption.fromJson(item),
      ),
      detachments: readList(
        value['detachments'],
        'detachment options',
        (item, _) => AonwDetachmentOption.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String unitId;
  final AonwAutoExploreOption? autoExplore;
  final List<AonwMerchantDestinationOption> merchantRouteDestinations;
  final List<AonwMerchantDestinationOption> merchantTravelDestinations;
  final List<AonwDetachmentOption> detachments;
}

final class AonwAutoExploreOption {
  const AonwAutoExploreOption({
    required this.target,
    required this.totalCostUnits,
    required this.searchMetrics,
  });

  factory AonwAutoExploreOption.fromJson(Object? source) {
    final value = readObject(source, 'auto explore option');
    requireKeys(value, const {
      'target',
      'totalCostUnits',
      'searchMetrics',
    }, 'auto explore option');
    return AonwAutoExploreOption(
      target: AonwCoordinate.fromJson(value['target']),
      totalCostUnits: readUnsigned(
        value['totalCostUnits'],
        'auto explore route cost',
      ),
      searchMetrics: AonwMovementSearchMetrics.fromJson(value['searchMetrics']),
    );
  }

  final AonwCoordinate target;
  final int totalCostUnits;
  final AonwMovementSearchMetrics searchMetrics;
}

final class AonwMovementSearchMetrics {
  const AonwMovementSearchMetrics({
    required this.frontierPops,
    required this.expandedTiles,
    required this.examinedEdges,
    required this.heapPushes,
    required this.routeRecords,
  });

  factory AonwMovementSearchMetrics.fromJson(Object? source) {
    final value = readObject(source, 'movement search metrics');
    requireKeys(value, const {
      'frontierPops',
      'expandedTiles',
      'examinedEdges',
      'heapPushes',
      'routeRecords',
    }, 'movement search metrics');
    return AonwMovementSearchMetrics(
      frontierPops: readUnsigned(value['frontierPops'], 'frontier pops'),
      expandedTiles: readUnsigned(value['expandedTiles'], 'expanded tiles'),
      examinedEdges: readUnsigned(value['examinedEdges'], 'examined edges'),
      heapPushes: readUnsigned(value['heapPushes'], 'heap pushes'),
      routeRecords: readUnsigned(value['routeRecords'], 'route records'),
    );
  }

  final int frontierPops;
  final int expandedTiles;
  final int examinedEdges;
  final int heapPushes;
  final int routeRecords;
}

final class AonwMerchantDestinationOption {
  const AonwMerchantDestinationOption({
    required this.cityId,
    required this.totalCostUnits,
  });

  factory AonwMerchantDestinationOption.fromJson(Object? source) {
    final value = readObject(source, 'merchant destination');
    requireKeys(value, const {
      'cityId',
      'totalCostUnits',
    }, 'merchant destination');
    return AonwMerchantDestinationOption(
      cityId: readString(value['cityId'], 'merchant destination city id'),
      totalCostUnits: readUnsigned(
        value['totalCostUnits'],
        'merchant route cost',
      ),
    );
  }

  final String cityId;
  final int totalCostUnits;
}

final class AonwDetachmentOption {
  const AonwDetachmentOption({
    required this.troopKind,
    required this.destination,
  });

  factory AonwDetachmentOption.fromJson(Object? source) {
    final value = readObject(source, 'detachment option');
    requireKeys(value, const {'troopKind', 'destination'}, 'detachment option');
    return AonwDetachmentOption(
      troopKind: AonwTroopKind.fromJson(value['troopKind']),
      destination: AonwCoordinate.fromJson(value['destination']),
    );
  }

  final AonwTroopKind troopKind;
  final AonwCoordinate destination;
}

final class AonwReachableResult extends AonwQueryResult {
  const AonwReachableResult({
    required this.stamp,
    required this.unitId,
    required this.availableMovementUnits,
    required this.tiles,
  });

  factory AonwReachableResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'unitId',
      'availableMovementUnits',
      'tiles',
    }, 'reachable result');
    return AonwReachableResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      unitId: readString(value['unitId'], 'reachable unit id'),
      availableMovementUnits: readUnsigned(
        value['availableMovementUnits'],
        'available movement',
      ),
      tiles: readList(
        value['tiles'],
        'reachable tiles',
        (item, _) => AonwReachableTile.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String unitId;
  final int availableMovementUnits;
  final List<AonwReachableTile> tiles;
}

final class AonwRoutePlanResult extends AonwQueryResult {
  const AonwRoutePlanResult({
    required this.stamp,
    required this.unitId,
    required this.target,
    required this.destination,
    required this.totalCostUnits,
    required this.availableMovementUnits,
    required this.remainingMovementUnits,
    required this.estimatedTurns,
    required this.steps,
  });

  factory AonwRoutePlanResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'unitId',
      'target',
      'destination',
      'totalCostUnits',
      'availableMovementUnits',
      'remainingMovementUnits',
      'estimatedTurns',
      'steps',
    }, 'route plan result');
    return AonwRoutePlanResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      unitId: readString(value['unitId'], 'route unit id'),
      target: AonwCoordinate.fromJson(value['target']),
      destination: AonwCoordinate.fromJson(value['destination']),
      totalCostUnits: readUnsigned(value['totalCostUnits'], 'route total cost'),
      availableMovementUnits: readUnsigned(
        value['availableMovementUnits'],
        'available movement',
      ),
      remainingMovementUnits: readUnsigned(
        value['remainingMovementUnits'],
        'remaining movement',
      ),
      estimatedTurns: readUnsigned(
        value['estimatedTurns'],
        'estimated route turns',
      ),
      steps: readList(
        value['steps'],
        'route steps',
        (item, _) => AonwMovementStep.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String unitId;
  final AonwCoordinate target;
  final AonwCoordinate destination;
  final int totalCostUnits;
  final int availableMovementUnits;
  final int remainingMovementUnits;
  final int estimatedTurns;
  final List<AonwMovementStep> steps;
}
