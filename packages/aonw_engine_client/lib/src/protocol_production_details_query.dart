part of 'protocol_query.dart';

sealed class AonwProductionTargetEffects {
  const AonwProductionTargetEffects();

  factory AonwProductionTargetEffects.fromJson(Object? source) {
    final value = readObject(source, 'production effects');
    final kind = readString(value['kind'], 'production effects kind');
    if (kind == 'project') {
      requireKeys(value, const {'kind'}, 'project effects');
      return const AonwProjectProductionDetails();
    }
    requireKeys(value, const {'kind', 'details'}, 'production effects');
    return switch (kind) {
      'building' => AonwBuildingProductionDetails.fromJson(value['details']),
      'unit' => AonwUnitProductionDetails.fromJson(value['details']),
      'wonder' => AonwWonderProductionDetails.fromJson(value['details']),
      _ => throw FormatException('Unknown production effects $kind.'),
    };
  }
}

final class AonwProjectProductionDetails extends AonwProductionTargetEffects {
  const AonwProjectProductionDetails();
}

final class AonwProductionCityOutput {
  const AonwProductionCityOutput({
    required this.grossYield,
    required this.foodDeposit,
    required this.production,
    required this.gold,
    required this.science,
    required this.maxControlledHexes,
  });

  factory AonwProductionCityOutput.fromJson(Object? source) {
    final value = readObject(source, 'AonwProductionCityOutput');
    requireKeys(value, const {
      'grossYield',
      'foodDeposit',
      'production',
      'gold',
      'science',
      'maxControlledHexes',
    }, 'AonwProductionCityOutput');
    return AonwProductionCityOutput(
      grossYield: AonwYieldValue.fromJson(value['grossYield']),
      foodDeposit: readInt(value['foodDeposit'], 'foodDeposit'),
      production: readInt(value['production'], 'production'),
      gold: readInt(value['gold'], 'gold'),
      science: readInt(value['science'], 'science'),
      maxControlledHexes: readInt(
        value['maxControlledHexes'],
        'maxControlledHexes',
      ),
    );
  }

  final AonwYieldValue grossYield;
  final int foodDeposit;
  final int production;
  final int gold;
  final int science;
  final int maxControlledHexes;
}

final class AonwProductionRequirementStatus {
  const AonwProductionRequirementStatus({
    required this.requirement,
    required this.met,
  });

  factory AonwProductionRequirementStatus.fromJson(Object? source) {
    final value = readObject(source, 'AonwProductionRequirementStatus');
    requireKeys(value, const {
      'requirement',
      'met',
    }, 'AonwProductionRequirementStatus');
    return AonwProductionRequirementStatus(
      requirement: AonwProductionRequirement.fromJson(value['requirement']),
      met: readBool(value['met'], 'met'),
    );
  }

  final AonwProductionRequirement requirement;
  final bool met;
}

enum AonwProductionRequirementKind {
  coastalAccess,
  resourceAny,
  adjacentRiver,
  adjacentMountain,
  hostTerrainAny;

  factory AonwProductionRequirementKind.fromJson(Object? value) {
    final name = readString(value, 'production requirement');
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    throw FormatException('Unknown production requirement $name.');
  }
}

final class AonwProductionRequirement {
  AonwProductionRequirement({
    required this.kind,
    List<AonwMapResource> resources = const [],
    List<AonwMapTerrain> terrains = const [],
  }) : resources = List.unmodifiable(resources),
       terrains = List.unmodifiable(terrains);

  factory AonwProductionRequirement.fromJson(Object? source) {
    final value = readObject(source, 'production requirement');
    final kind = AonwProductionRequirementKind.fromJson(value['kind']);
    final resource = kind == AonwProductionRequirementKind.resourceAny;
    final terrain = kind == AonwProductionRequirementKind.hostTerrainAny;
    requireKeys(value, {
      'kind',
      if (resource) 'resources',
      if (terrain) 'terrains',
    }, 'production requirement');
    return AonwProductionRequirement(
      kind: kind,
      resources: resource
          ? readList(
              value['resources'],
              'requirement resources',
              (item, _) => AonwMapResource.fromJson(item),
            )
          : const [],
      terrains: terrain
          ? readList(
              value['terrains'],
              'requirement terrains',
              (item, _) => AonwMapTerrain.fromJson(item),
            )
          : const [],
    );
  }

  final AonwProductionRequirementKind kind;
  final List<AonwMapResource> resources;
  final List<AonwMapTerrain> terrains;
}

final class AonwProductionDetailsResult extends AonwQueryResult {
  const AonwProductionDetailsResult({
    required this.stamp,
    required this.cityId,
    required this.option,
    required this.effects,
  });

  factory AonwProductionDetailsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'cityId',
      'option',
      'effects',
    }, 'production details');
    return AonwProductionDetailsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      cityId: readString(value['cityId'], 'production details city'),
      option: AonwProductionOption.fromJson(value['option']),
      effects: AonwProductionTargetEffects.fromJson(value['effects']),
    );
  }

  final AonwSessionStamp stamp;
  final String cityId;
  final AonwProductionOption option;
  final AonwProductionTargetEffects effects;
}
