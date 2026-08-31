part of 'protocol_query.dart';

enum AonwTechnologyAvailability {
  unlocked,
  active,
  available,
  lockedByPrerequisites,
  lockedByTechnology;

  factory AonwTechnologyAvailability.fromJson(Object? source) {
    final wire = readString(source, 'technology availability');
    return values.firstWhere(
      (value) => value.name == wire,
      orElse: () =>
          throw FormatException('Unknown AoNW technology availability $wire.'),
    );
  }
}

sealed class AonwTechnologyUnlock {
  const AonwTechnologyUnlock();

  factory AonwTechnologyUnlock.fromJson(Object? source) {
    final value = readObject(source, 'technology unlock');
    return switch (value['kind']) {
      'building' => AonwTechnologyBuildingUnlock.fromJson(value),
      'improvement' => AonwTechnologyImprovementUnlock.fromJson(value),
      'resourceVisibility' => AonwTechnologyResourceVisibilityUnlock.fromJson(
        value,
      ),
      'unit' => AonwTechnologyUnitUnlock.fromJson(value),
      'wonder' => AonwTechnologyWonderUnlock.fromJson(value),
      final Object? kind => throw FormatException(
        'Unknown AoNW technology unlock $kind.',
      ),
    };
  }
}

final class AonwTechnologyBuildingUnlock extends AonwTechnologyUnlock {
  const AonwTechnologyBuildingUnlock(this.building);

  factory AonwTechnologyBuildingUnlock.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'buildingType'}, 'building unlock');
    return AonwTechnologyBuildingUnlock(
      AonwCityBuildingType.fromJson(value['buildingType']),
    );
  }

  final AonwCityBuildingType building;
}

final class AonwTechnologyImprovementUnlock extends AonwTechnologyUnlock {
  const AonwTechnologyImprovementUnlock(this.improvement);

  factory AonwTechnologyImprovementUnlock.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'improvement'}, 'improvement unlock');
    return AonwTechnologyImprovementUnlock(
      AonwFieldImprovementKind.fromJson(value['improvement']),
    );
  }

  final AonwFieldImprovementKind improvement;
}

final class AonwTechnologyResourceVisibilityUnlock
    extends AonwTechnologyUnlock {
  const AonwTechnologyResourceVisibilityUnlock(this.resource);

  factory AonwTechnologyResourceVisibilityUnlock.fromJson(
    Map<String, Object?> value,
  ) {
    requireKeys(value, const {
      'kind',
      'resource',
    }, 'resource visibility unlock');
    return AonwTechnologyResourceVisibilityUnlock(
      AonwResourceType.fromJson(value['resource']),
    );
  }

  final AonwResourceType resource;
}

final class AonwTechnologyUnitUnlock extends AonwTechnologyUnlock {
  const AonwTechnologyUnitUnlock(this.unit);

  factory AonwTechnologyUnitUnlock.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'unitType'}, 'unit unlock');
    return AonwTechnologyUnitUnlock(AonwUnitKind.fromJson(value['unitType']));
  }

  final AonwUnitKind unit;
}

final class AonwTechnologyWonderUnlock extends AonwTechnologyUnlock {
  const AonwTechnologyWonderUnlock(this.wonder);

  factory AonwTechnologyWonderUnlock.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'wonderType'}, 'wonder unlock');
    return AonwTechnologyWonderUnlock(
      AonwWonderType.fromJson(value['wonderType']),
    );
  }

  final AonwWonderType wonder;
}

final class AonwResearchOption {
  AonwResearchOption({
    required this.technology,
    required this.availability,
    required this.effectiveCost,
    required this.progress,
    required this.boostDiscountBasisPoints,
    required List<AonwTechnologyId> prerequisites,
    required List<AonwTechnologyId> blockedBy,
    required List<AonwTechnologyUnlock> unlocks,
  }) : prerequisites = List.unmodifiable(prerequisites),
       blockedBy = List.unmodifiable(blockedBy),
       unlocks = List.unmodifiable(unlocks);

  factory AonwResearchOption.fromJson(Object? source) {
    final value = readObject(source, 'research option');
    requireKeys(value, const {
      'technologyId',
      'availability',
      'effectiveCost',
      'progress',
      'boostDiscountBasisPoints',
      'prerequisites',
      'blockedBy',
      'unlocks',
    }, 'research option');
    return AonwResearchOption(
      technology: AonwTechnologyId.fromJson(value['technologyId']),
      availability: AonwTechnologyAvailability.fromJson(value['availability']),
      effectiveCost: readUnsigned(
        value['effectiveCost'],
        'effective research cost',
      ),
      progress: readInt(value['progress'], 'research progress'),
      boostDiscountBasisPoints: readUnsigned(
        value['boostDiscountBasisPoints'],
        'research boost discount',
      ),
      prerequisites: readList(
        value['prerequisites'],
        'research prerequisites',
        (item, _) => AonwTechnologyId.fromJson(item),
      ),
      blockedBy: readList(
        value['blockedBy'],
        'research blockers',
        (item, _) => AonwTechnologyId.fromJson(item),
      ),
      unlocks: readList(
        value['unlocks'],
        'research unlocks',
        (item, _) => AonwTechnologyUnlock.fromJson(item),
      ),
    );
  }

  final AonwTechnologyId technology;
  final AonwTechnologyAvailability availability;
  final int effectiveCost;
  final int progress;
  final int boostDiscountBasisPoints;
  final List<AonwTechnologyId> prerequisites;
  final List<AonwTechnologyId> blockedBy;
  final List<AonwTechnologyUnlock> unlocks;
}

final class AonwResearchOptionsResult extends AonwQueryResult {
  AonwResearchOptionsResult({
    required this.stamp,
    required this.playerId,
    required this.activeTechnology,
    required this.scienceOverflow,
    required this.scienceYield,
    required List<AonwResearchOption> options,
  }) : options = List.unmodifiable(options);

  factory AonwResearchOptionsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'playerId',
      'activeTechnologyId',
      'scienceOverflow',
      'scienceYield',
      'options',
    }, 'research options');
    return AonwResearchOptionsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      playerId: readString(value['playerId'], 'research player id'),
      activeTechnology: value['activeTechnologyId'] == null
          ? null
          : AonwTechnologyId.fromJson(value['activeTechnologyId']),
      scienceOverflow: readInt(value['scienceOverflow'], 'science overflow'),
      scienceYield: AonwScienceYieldBreakdown.fromJson(value['scienceYield']),
      options: readList(
        value['options'],
        'research options',
        (item, _) => AonwResearchOption.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String playerId;
  final AonwTechnologyId? activeTechnology;
  final int scienceOverflow;
  final AonwScienceYieldBreakdown scienceYield;
  final List<AonwResearchOption> options;
}
