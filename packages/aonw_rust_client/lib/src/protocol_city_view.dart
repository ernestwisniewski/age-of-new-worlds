import 'package:aonw_rust_client/src/protocol_coordinate.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

final class AonwCityFoundingDraft {
  const AonwCityFoundingDraft({
    required this.founderUnitId,
    required this.center,
    required this.controlledHexes,
  });

  factory AonwCityFoundingDraft.fromJson(Object? source) {
    final value = readObject(source, 'city founding draft');
    requireKeys(value, const {
      'founderUnitId',
      'center',
      'controlledHexes',
    }, 'city founding draft');
    return AonwCityFoundingDraft(
      founderUnitId: readString(value['founderUnitId'], 'founder unit id'),
      center: AonwCoordinate.fromJson(value['center']),
      controlledHexes: _coordinates(
        value['controlledHexes'],
        'controlled hexes',
      ),
    );
  }

  final String founderUnitId;
  final AonwCoordinate center;
  final List<AonwCoordinate> controlledHexes;
}

enum AonwCitySpecialization {
  growth,
  industry,
  commerce,
  science,
  military;

  factory AonwCitySpecialization.fromJson(Object? source) =>
      _enumValue(source, values, 'city specialization');
}

enum AonwWonderType {
  greatLibrary,
  hangingGardens,
  greatWall,
  petra,
  centralBank,
  imperialUniversity,
  grandCathedral,
  motherFactory,
  nationalObservatory,
  svalbardSeedVault,
  grandExposition;

  factory AonwWonderType.fromJson(Object? source) =>
      _enumValue(source, values, 'wonder type');
}

enum AonwCityProjectType {
  wealth,
  research;

  factory AonwCityProjectType.fromJson(Object? source) =>
      _enumValue(source, values, 'city project type');
}

enum AonwCityBuildingType {
  granary,
  waterMill,
  workshop,
  storehouse,
  housing,
  merchantHall,
  stonemason,
  barracks,
  marketplace,
  port,
  aqueduct,
  forge,
  stable,
  bank,
  buildersGuild,
  factory,
  lighthouse,
  trainingGrounds,
  townHall,
  monument,
  archive,
  academy,
  university,
  observatory,
  laboratory,
  reactor,
  courthouse,
  court,
  governorsOffice,
  surveyorsOffice,
  planningOffice,
  apothecary,
  publicBaths,
  hospital,
  ministries,
  walls,
  armory,
  siegeWorkshop,
  citadel,
  warCollege,
  conscriptionOffice,
  borderFort,
  airfield,
  artisansGuild,
  masterWorkshop,
  steelworks,
  railDepot,
  powerPlant,
  assemblyPlant,
  refinery,
  mapRoom,
  shipyard,
  dryDock,
  navalAcademy,
  harborCustoms,
  museum,
  parliament,
  broadcastTower,
  worldFairGrounds;

  factory AonwCityBuildingType.fromJson(Object? source) =>
      _enumValue(source, values, 'city building type');
}

enum AonwCityProductionTargetKind { building, unit, project, wonder }

final class AonwCityProductionTarget {
  const AonwCityProductionTarget._({
    required this.kind,
    this.buildingType,
    this.unitType,
    this.projectType,
    this.wonderType,
  });

  factory AonwCityProductionTarget.fromJson(Object? source) {
    final value = readObject(source, 'city production target');
    final kind = _enumValue(
      value['kind'],
      AonwCityProductionTargetKind.values,
      'city production target kind',
    );
    return switch (kind) {
      AonwCityProductionTargetKind.building => _buildingTarget(value),
      AonwCityProductionTargetKind.unit => _unitTarget(value),
      AonwCityProductionTargetKind.project => _projectTarget(value),
      AonwCityProductionTargetKind.wonder => _wonderTarget(value),
    };
  }

  final AonwCityProductionTargetKind kind;
  final AonwCityBuildingType? buildingType;
  final AonwUnitKind? unitType;
  final AonwCityProjectType? projectType;
  final AonwWonderType? wonderType;

  static AonwCityProductionTarget _buildingTarget(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'buildingType'}, 'building target');
    return AonwCityProductionTarget._(
      kind: AonwCityProductionTargetKind.building,
      buildingType: AonwCityBuildingType.fromJson(value['buildingType']),
    );
  }

  static AonwCityProductionTarget _unitTarget(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'unitType'}, 'unit target');
    return AonwCityProductionTarget._(
      kind: AonwCityProductionTargetKind.unit,
      unitType: AonwUnitKind.fromJson(value['unitType']),
    );
  }

  static AonwCityProductionTarget _projectTarget(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'projectType'}, 'project target');
    return AonwCityProductionTarget._(
      kind: AonwCityProductionTargetKind.project,
      projectType: AonwCityProjectType.fromJson(value['projectType']),
    );
  }

  static AonwCityProductionTarget _wonderTarget(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'wonderType'}, 'wonder target');
    return AonwCityProductionTarget._(
      kind: AonwCityProductionTargetKind.wonder,
      wonderType: AonwWonderType.fromJson(value['wonderType']),
    );
  }
}

final class AonwCityProductionQueue {
  const AonwCityProductionQueue({
    required this.target,
    required this.investedProduction,
    required this.resourceAllocation,
  });

  factory AonwCityProductionQueue.fromJson(Object? source) {
    final value = readObject(source, 'city production queue');
    requireKeys(value, const {
      'target',
      'investedProduction',
      'resourceAllocation',
    }, 'city production queue');
    final allocation = readObject(
      value['resourceAllocation'],
      'production resource allocation',
    );
    return AonwCityProductionQueue(
      target: AonwCityProductionTarget.fromJson(value['target']),
      investedProduction: readUnsigned(
        value['investedProduction'],
        'invested production',
      ),
      resourceAllocation: Map.unmodifiable({
        for (final entry in allocation.entries)
          AonwResourceType.fromJson(entry.key): readUnsigned(
            entry.value,
            'allocated resource amount',
          ),
      }),
    );
  }

  final AonwCityProductionTarget target;
  final int investedProduction;
  final Map<AonwResourceType, int> resourceAllocation;
}

final class AonwOwnedCityDetails {
  const AonwOwnedCityDetails({
    required this.population,
    required this.workedHexes,
    required this.preferredExpansionHex,
    this.storedFood = 0,
    this.maxHexes = 0,
    this.territoryRadius = 0,
    this.buildings = const [],
    this.wonders = const [],
    this.productionQueue,
    this.productionOverflow = 0,
    this.specialization,
  });

  factory AonwOwnedCityDetails.fromJson(Object? source) {
    final value = readObject(source, 'owned city details');
    requireKeys(value, const {
      'population',
      'storedFood',
      'maxHexes',
      'territoryRadius',
      'workedHexes',
      'buildings',
      'wonders',
      'productionQueue',
      'productionOverflow',
      'specialization',
      'preferredExpansionHex',
    }, 'owned city details');
    return AonwOwnedCityDetails(
      population: readInt(value['population'], 'city population'),
      storedFood: readUnsigned(value['storedFood'], 'stored city food'),
      maxHexes: readUnsigned(value['maxHexes'], 'city territory capacity'),
      territoryRadius: readUnsigned(
        value['territoryRadius'],
        'city territory radius',
      ),
      workedHexes: _coordinates(value['workedHexes'], 'worked hexes'),
      buildings: readList(
        value['buildings'],
        'city buildings',
        (item, _) => AonwCityBuildingType.fromJson(item),
      ),
      wonders: readList(
        value['wonders'],
        'city wonders',
        (item, _) => AonwWonderType.fromJson(item),
      ),
      productionQueue: value['productionQueue'] == null
          ? null
          : AonwCityProductionQueue.fromJson(value['productionQueue']),
      productionOverflow: readUnsigned(
        value['productionOverflow'],
        'city production overflow',
      ),
      specialization: value['specialization'] == null
          ? null
          : AonwCitySpecialization.fromJson(value['specialization']),
      preferredExpansionHex: value['preferredExpansionHex'] == null
          ? null
          : AonwCoordinate.fromJson(value['preferredExpansionHex']),
    );
  }

  final int population;
  final int storedFood;
  final int maxHexes;
  final int territoryRadius;
  final List<AonwCoordinate> workedHexes;
  final List<AonwCityBuildingType> buildings;
  final List<AonwWonderType> wonders;
  final AonwCityProductionQueue? productionQueue;
  final int productionOverflow;
  final AonwCitySpecialization? specialization;
  final AonwCoordinate? preferredExpansionHex;
}

final class AonwPlayerCityView {
  const AonwPlayerCityView({
    required this.id,
    required this.ownerPlayerId,
    required this.name,
    required this.center,
    required this.visibleControlledHexes,
    required this.ownedDetails,
    this.hitPoints,
  });

  factory AonwPlayerCityView.fromJson(Object? source) {
    final value = readObject(source, 'player city view');
    requireKeys(value, const {
      'id',
      'ownerPlayerId',
      'name',
      'center',
      'visibleControlledHexes',
      'hitPoints',
      'ownedDetails',
    }, 'player city view');
    return AonwPlayerCityView(
      id: readString(value['id'], 'city id'),
      ownerPlayerId: readString(value['ownerPlayerId'], 'city owner'),
      name: readString(value['name'], 'city name'),
      center: AonwCoordinate.fromJson(value['center']),
      visibleControlledHexes: _coordinates(
        value['visibleControlledHexes'],
        'visible controlled hexes',
      ),
      ownedDetails: value['ownedDetails'] == null
          ? null
          : AonwOwnedCityDetails.fromJson(value['ownedDetails']),
      hitPoints: value['hitPoints'] == null
          ? null
          : readUnsigned(value['hitPoints'], 'city hit points'),
    );
  }

  final String id;
  final String ownerPlayerId;
  final String name;
  final AonwCoordinate center;
  final List<AonwCoordinate> visibleControlledHexes;
  final AonwOwnedCityDetails? ownedDetails;
  final int? hitPoints;
}

List<AonwCoordinate> _coordinates(Object? value, String label) =>
    readList(value, label, (item, _) => AonwCoordinate.fromJson(item));

T _enumValue<T extends Enum>(Object? source, List<T> values, String label) {
  final wire = readString(source, label);
  return values.firstWhere(
    (value) => value.name == wire,
    orElse: () => throw FormatException('Unknown AoNW $label $wire.'),
  );
}
