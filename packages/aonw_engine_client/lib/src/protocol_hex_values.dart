import 'package:aonw_engine_client/src/protocol_json.dart';

enum AonwHexAssessmentKind {
  idealCitySite,
  goodCitySite,
  fertileField,
  fertilePlains,
  richPlain,
  strategicBorderland,
  strategicField,
  defensivePosition,
  fertileForest,
  forestBackline,
  forestForge,
  wildLand,
  richWilds,
  exoticBackline,
  difficultStrategicTerrain,
  highGround,
  riverHills,
  industrialStronghold,
  richHills,
  barrenLand,
  oasis,
  tradeOasis,
  desertDeposits,
  harshLand,
  coldPastures,
  resourceOutpost,
  hostileLand,
  arcticDeposits,
  coast,
  fishingCoast,
  richCoast,
  riverPort,
  regionalPortHeart,
  openSea,
  naturalBarrier,
  promisingLand,
  weakLand,
  ordinaryLand,
  mapTile;

  factory AonwHexAssessmentKind.fromJson(Object? value) =>
      _hexEnumValue(values, value, 'HexAssessmentKind');
}

enum AonwHexRecommendation {
  foundCity,
  defendHere,
  exploitEconomy,
  avoid,
  neutral;

  factory AonwHexRecommendation.fromJson(Object? value) =>
      _hexEnumValue(values, value, 'HexRecommendation');
}

enum AonwHexAssessmentTag {
  city,
  defense,
  trade,
  fertile,
  production,
  hostile,
  strategic,
  water;

  factory AonwHexAssessmentTag.fromJson(Object? value) =>
      _hexEnumValue(values, value, 'HexAssessmentTag');
}

sealed class AonwHexImprovementAccess {
  const AonwHexImprovementAccess();

  factory AonwHexImprovementAccess.fromJson(Object? source) {
    final value = readObject(source, 'hex improvement access');
    if (value['kind'] == 'controlledCity') {
      requireKeys(value, const {'kind', 'cityId'}, 'hex improvement access');
      return AonwHexControlledCity(readString(value['cityId'], 'city id'));
    }
    requireKeys(value, const {'kind'}, 'hex improvement access');
    return switch (value['kind']) {
      'outsideControlledCity' => const AonwHexOutsideControlledCity(),
      'cityCenter' => const AonwHexCityCenter(),
      'alreadyImproved' => const AonwHexAlreadyImproved(),
      final Object? kind => throw FormatException(
        'Unknown AoNW hex improvement access $kind.',
      ),
    };
  }
}

final class AonwHexOutsideControlledCity extends AonwHexImprovementAccess {
  const AonwHexOutsideControlledCity();
}

final class AonwHexCityCenter extends AonwHexImprovementAccess {
  const AonwHexCityCenter();
}

final class AonwHexAlreadyImproved extends AonwHexImprovementAccess {
  const AonwHexAlreadyImproved();
}

final class AonwHexControlledCity extends AonwHexImprovementAccess {
  const AonwHexControlledCity(this.cityId);
  final String cityId;
}

T _hexEnumValue<T extends Enum>(List<T> values, Object? source, String label) {
  final wire = readString(source, label);
  return values.firstWhere(
    (value) => value.name == wire,
    orElse: () => throw FormatException('Unknown AoNW $label $wire.'),
  );
}
