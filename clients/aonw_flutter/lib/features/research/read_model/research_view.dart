import '../../map/read_model/player_map_view.dart';

enum TechnologyIdView {
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
  nuclearPhysics,
}

enum TechnologyAvailabilityView {
  unlocked,
  active,
  available,
  lockedByPrerequisites,
  lockedByTechnology,
}

enum TechnologyUnlockKindView {
  building,
  improvement,
  resourceVisibility,
  unit,
  wonder,
}

final class TechnologyUnlockView {
  const TechnologyUnlockView({required this.kind, required this.target});

  final TechnologyUnlockKindView kind;
  final String target;
}

enum ScienceYieldSourceKindView {
  cityScience,
  cityResearchProject,
  worldArtifact,
  worldWonder,
}

final class ScienceYieldSourceView {
  const ScienceYieldSourceView({
    required this.cityId,
    required this.amount,
    required this.kind,
  });

  final String cityId;
  final int amount;
  final ScienceYieldSourceKindView kind;
}

final class ScienceYieldBreakdownView {
  ScienceYieldBreakdownView({
    required this.total,
    required Map<String, int> byCityId,
    required List<ScienceYieldSourceView> sources,
  }) : byCityId = Map.unmodifiable(byCityId),
       sources = List.unmodifiable(sources);

  final int total;
  final Map<String, int> byCityId;
  final List<ScienceYieldSourceView> sources;
}

final class ResearchOptionView {
  ResearchOptionView({
    required this.technology,
    required this.availability,
    required this.effectiveCost,
    required this.progress,
    required this.boostDiscountBasisPoints,
    required List<TechnologyIdView> prerequisites,
    required List<TechnologyIdView> blockedBy,
    required List<TechnologyUnlockView> unlocks,
  }) : prerequisites = List.unmodifiable(prerequisites),
       blockedBy = List.unmodifiable(blockedBy),
       unlocks = List.unmodifiable(unlocks);

  final TechnologyIdView technology;
  final TechnologyAvailabilityView availability;
  final int effectiveCost;
  final int progress;
  final int boostDiscountBasisPoints;
  final List<TechnologyIdView> prerequisites;
  final List<TechnologyIdView> blockedBy;
  final List<TechnologyUnlockView> unlocks;
}

final class ResearchOptionsView {
  ResearchOptionsView({
    required this.stamp,
    required this.playerId,
    required this.activeTechnology,
    required this.scienceOverflow,
    required this.scienceYield,
    required List<ResearchOptionView> options,
  }) : options = List.unmodifiable(options);

  final SessionStampView stamp;
  final String playerId;
  final TechnologyIdView? activeTechnology;
  final int scienceOverflow;
  final ScienceYieldBreakdownView scienceYield;
  final List<ResearchOptionView> options;
}

final class SelectTechnologyActionView {
  const SelectTechnologyActionView(this.technology);

  final TechnologyIdView technology;
}

enum ResearchRejectionCodeView {
  staleRevision,
  technologyPlayerNotControlled,
  technologyNotAvailable,
  stateRevisionOverflow,
}
