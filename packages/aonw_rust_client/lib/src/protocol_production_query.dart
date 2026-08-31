part of 'protocol_query.dart';

final class AonwProductionOptionsResult extends AonwQueryResult {
  AonwProductionOptionsResult({
    required this.stamp,
    required this.cityId,
    required this.currentTarget,
    required this.investedProduction,
    required this.productionOverflow,
    required List<AonwProductionOption> buildings,
    required List<AonwUnitProductionOption> units,
    required List<AonwProductionOption> projects,
    required List<AonwProductionOption> wonders,
    required List<AonwCitySpecializationOption> specializations,
  }) : buildings = List.unmodifiable(buildings),
       units = List.unmodifiable(units),
       projects = List.unmodifiable(projects),
       wonders = List.unmodifiable(wonders),
       specializations = List.unmodifiable(specializations);

  factory AonwProductionOptionsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'cityId',
      'currentTarget',
      'investedProduction',
      'productionOverflow',
      'buildings',
      'units',
      'projects',
      'wonders',
      'specializations',
    }, 'production options');
    return AonwProductionOptionsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      cityId: readString(value['cityId'], 'production city id'),
      currentTarget: value['currentTarget'] == null
          ? null
          : AonwCityProductionTarget.fromJson(value['currentTarget']),
      investedProduction: readInt(
        value['investedProduction'],
        'invested production',
      ),
      productionOverflow: readInt(
        value['productionOverflow'],
        'production overflow',
      ),
      buildings: _productionOptions(value['buildings'], 'building options'),
      units: readList(
        value['units'],
        'unit production options',
        (item, _) => AonwUnitProductionOption.fromJson(item),
      ),
      projects: _productionOptions(value['projects'], 'project options'),
      wonders: _productionOptions(value['wonders'], 'wonder options'),
      specializations: readList(
        value['specializations'],
        'city specialization options',
        (item, _) => AonwCitySpecializationOption.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String cityId;
  final AonwCityProductionTarget? currentTarget;
  final int investedProduction;
  final int productionOverflow;
  final List<AonwProductionOption> buildings;
  final List<AonwUnitProductionOption> units;
  final List<AonwProductionOption> projects;
  final List<AonwProductionOption> wonders;
  final List<AonwCitySpecializationOption> specializations;
}

final class AonwProductionOption {
  const AonwProductionOption({
    required this.target,
    required this.cost,
    required this.rejection,
  });

  factory AonwProductionOption.fromJson(Object? source) {
    final value = readObject(source, 'production option');
    requireKeys(value, const {
      'target',
      'cost',
      'rejection',
    }, 'production option');
    return AonwProductionOption(
      target: AonwCityProductionTarget.fromJson(value['target']),
      cost: readInt(value['cost'], 'production cost'),
      rejection: value['rejection'] == null
          ? null
          : AonwCommandRejectionCode.fromWire(
              readString(value['rejection'], 'production blocker'),
            ),
    );
  }

  final AonwCityProductionTarget target;
  final int cost;
  final AonwCommandRejectionCode? rejection;
}

final class AonwUnitProductionOption {
  AonwUnitProductionOption({
    required this.option,
    required List<Map<AonwResourceType, int>> resourceOptions,
    required List<int> affordableResourceOptionIndices,
  }) : resourceOptions = List.unmodifiable(resourceOptions),
       affordableResourceOptionIndices = List.unmodifiable(
         affordableResourceOptionIndices,
       );

  factory AonwUnitProductionOption.fromJson(Object? source) {
    final value = readObject(source, 'unit production option');
    requireKeys(value, const {
      'option',
      'resourceOptions',
      'affordableResourceOptionIndices',
    }, 'unit production option');
    return AonwUnitProductionOption(
      option: AonwProductionOption.fromJson(value['option']),
      resourceOptions: readList(
        value['resourceOptions'],
        'unit production resource options',
        (item, _) => _resourceStockpile(item),
      ),
      affordableResourceOptionIndices: readList(
        value['affordableResourceOptionIndices'],
        'affordable resource option indices',
        (item, _) => readUnsigned(item, 'affordable resource option index'),
      ),
    );
  }

  final AonwProductionOption option;
  final List<Map<AonwResourceType, int>> resourceOptions;
  final List<int> affordableResourceOptionIndices;
}

final class AonwCitySpecializationOption {
  const AonwCitySpecializationOption({
    required this.specialization,
    required this.requiredBuilding,
    required this.rejection,
  });

  factory AonwCitySpecializationOption.fromJson(Object? source) {
    final value = readObject(source, 'city specialization option');
    requireKeys(value, const {
      'specialization',
      'requiredBuilding',
      'rejection',
    }, 'city specialization option');
    return AonwCitySpecializationOption(
      specialization: AonwCitySpecialization.fromJson(value['specialization']),
      requiredBuilding: AonwCityBuildingType.fromJson(
        value['requiredBuilding'],
      ),
      rejection: value['rejection'] == null
          ? null
          : AonwCommandRejectionCode.fromWire(
              readString(value['rejection'], 'specialization blocker'),
            ),
    );
  }

  final AonwCitySpecialization specialization;
  final AonwCityBuildingType requiredBuilding;
  final AonwCommandRejectionCode? rejection;
}

final class AonwStrategicResourceProjectionResult extends AonwQueryResult {
  AonwStrategicResourceProjectionResult({
    required this.stamp,
    required this.playerId,
    required List<AonwStrategicResourceAmount> output,
    required List<AonwStrategicResourceSource> sources,
  }) : output = List.unmodifiable(output),
       sources = List.unmodifiable(sources);

  factory AonwStrategicResourceProjectionResult.fromJson(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {
      'type',
      'stamp',
      'playerId',
      'output',
      'sources',
    }, 'strategic resource projection');
    return AonwStrategicResourceProjectionResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      playerId: readString(value['playerId'], 'resource projection player id'),
      output: readList(
        value['output'],
        'strategic resource output',
        (item, _) => AonwStrategicResourceAmount.fromJson(item),
      ),
      sources: readList(
        value['sources'],
        'strategic resource sources',
        (item, _) => AonwStrategicResourceSource.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String playerId;
  final List<AonwStrategicResourceAmount> output;
  final List<AonwStrategicResourceSource> sources;
}

final class AonwStrategicResourceAmount {
  const AonwStrategicResourceAmount({
    required this.resource,
    required this.amount,
  });

  factory AonwStrategicResourceAmount.fromJson(Object? source) {
    final value = readObject(source, 'strategic resource amount');
    requireKeys(value, const {
      'resource',
      'amount',
    }, 'strategic resource amount');
    return AonwStrategicResourceAmount(
      resource: AonwResourceType.fromJson(value['resource']),
      amount: readInt(value['amount'], 'strategic resource amount'),
    );
  }

  final AonwResourceType resource;
  final int amount;
}

final class AonwStrategicResourceSource {
  const AonwStrategicResourceSource({
    required this.cityId,
    required this.coordinate,
    required this.resource,
    required this.improvement,
    required this.amountPerTurn,
  });

  factory AonwStrategicResourceSource.fromJson(Object? source) {
    final value = readObject(source, 'strategic resource source');
    requireKeys(value, const {
      'cityId',
      'coordinate',
      'resource',
      'improvement',
      'amountPerTurn',
    }, 'strategic resource source');
    return AonwStrategicResourceSource(
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

List<AonwProductionOption> _productionOptions(Object? source, String label) =>
    readList(source, label, (item, _) => AonwProductionOption.fromJson(item));

Map<AonwResourceType, int> _resourceStockpile(Object? source) {
  final value = readObject(source, 'strategic resource stockpile');
  return Map.unmodifiable({
    for (final entry in value.entries)
      AonwResourceType.fromJson(entry.key): readUnsigned(
        entry.value,
        'strategic resource stockpile amount',
      ),
  });
}
