enum HexAssessmentKindView {
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
  mapTile,
}

enum HexRecommendationView {
  foundCity,
  defendHere,
  exploitEconomy,
  avoid,
  neutral,
}

enum HexAssessmentTagView {
  city,
  defense,
  trade,
  fertile,
  production,
  hostile,
  strategic,
  water,
}

sealed class HexImprovementAccessView {
  const HexImprovementAccessView();
}

final class HexOutsideControlledCityView extends HexImprovementAccessView {
  const HexOutsideControlledCityView();
}

final class HexCityCenterView extends HexImprovementAccessView {
  const HexCityCenterView();
}

final class HexAlreadyImprovedView extends HexImprovementAccessView {
  const HexAlreadyImprovedView();
}

final class HexControlledCityView extends HexImprovementAccessView {
  const HexControlledCityView(this.cityId);
  final String cityId;
}
