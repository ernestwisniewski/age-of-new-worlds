import 'package:aonw_engine_client/src/protocol_json.dart';

enum AonwTechnologyId {
  agriculture,
  woodworking,
  mining,
  animalHusbandry,
  hunting,
  fishing,
  craftsmanship,
  trade,
  storage,
  waterEngineering,
  stoneworking,
  militaryOrganization,
  advancedTrade,
  construction,
  navigation,
  irrigation,
  banking,
  engineering,
  metallurgy,
  horsebackRiding,
  ironWorking,
  coalMining,
  machinery,
  administration,
  logistics,
  shipbuilding,
  tactics,
  economy,
  urbanization,
  fortifications,
  strategy,
  specialization,
  writing,
  mathematics,
  medicine,
  civilService,
  siegecraft,
  cartography,
  guilds,
  law,
  education,
  urbanPlanning,
  navalDoctrine,
  steel,
  bureaucracy,
  nationalism,
  scientificMethod,
  steamPower,
  electricity,
  combustion,
  flight,
  massProduction,
  radio,
  nuclearPhysics;

  factory AonwTechnologyId.fromJson(Object? source) {
    final wire = readString(source, 'technology id');
    return values.firstWhere(
      (value) => value.name == wire,
      orElse: () => throw FormatException('Unknown AoNW technology $wire.'),
    );
  }
}

enum AonwScienceYieldSourceKind {
  cityScience,
  cityResearchProject,
  worldArtifact,
  worldWonder;

  factory AonwScienceYieldSourceKind.fromJson(Object? source) {
    final wire = readString(source, 'science yield source kind');
    return values.firstWhere(
      (value) => value.name == wire,
      orElse: () => throw FormatException(
        'Unknown AoNW science yield source kind $wire.',
      ),
    );
  }
}

final class AonwScienceYieldSource {
  const AonwScienceYieldSource({
    required this.cityId,
    required this.amount,
    required this.kind,
  });

  factory AonwScienceYieldSource.fromJson(Object? source) {
    final value = readObject(source, 'science yield source');
    requireKeys(value, const {'cityId', 'amount', 'kind'}, 'science source');
    return AonwScienceYieldSource(
      cityId: readString(value['cityId'], 'science source city id'),
      amount: readInt(value['amount'], 'science source amount'),
      kind: AonwScienceYieldSourceKind.fromJson(value['kind']),
    );
  }

  final String cityId;
  final int amount;
  final AonwScienceYieldSourceKind kind;
}

final class AonwScienceYieldBreakdown {
  AonwScienceYieldBreakdown({
    required this.total,
    required Map<String, int> byCityId,
    required List<AonwScienceYieldSource> sources,
  }) : byCityId = Map.unmodifiable(byCityId),
       sources = List.unmodifiable(sources);

  factory AonwScienceYieldBreakdown.fromJson(Object? source) {
    final value = readObject(source, 'science yield breakdown');
    requireKeys(value, const {
      'total',
      'byCityId',
      'sources',
    }, 'science yield breakdown');
    return AonwScienceYieldBreakdown(
      total: readInt(value['total'], 'total science yield'),
      byCityId: readStringIntMap(value['byCityId'], 'science by city'),
      sources: readList(
        value['sources'],
        'science yield sources',
        (item, _) => AonwScienceYieldSource.fromJson(item),
      ),
    );
  }

  final int total;
  final Map<String, int> byCityId;
  final List<AonwScienceYieldSource> sources;
}
