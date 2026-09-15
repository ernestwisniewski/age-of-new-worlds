import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_victory_view.dart';

import '../../../support/map_test_fixture.dart';

PlayerMapView resourcePlayerFixture({
  TreasuryWarningView warning = TreasuryWarningView.none,
  List<MapResource> shortages = const [],
  PlayerVictoryView? victory,
}) {
  final source = testMapScene().player;
  return PlayerMapView(
    actorPlayerId: source.actorPlayerId,
    stamp: source.stamp,
    turnMode: source.turnMode,
    participants: source.participants,
    fog: source.fog,
    turnView: source.turnView,
    diplomacy: source.diplomacy,
    victory: victory ?? source.victory,
    units: source.units,
    cities: source.cities,
    economy: PlayerEconomyView(
      strategicResourceInventory: PlayerStrategicResourceInventoryView.empty(),
      strategicResourceShortages: shortages,
      gold: 123,
      warWeariness: 0,
      stabilityNet: 0,
      strategicResourceStockpile: const [],
      strategicResourceOutput: const [],
      strategicResourceSources: const [],
      forecast: PlayerEconomyForecastView(
        treasuryWarning: warning,
        treasury: 123,
        cityIncome: 3,
        projectIncome: 4,
        grossIncome: 999,
        netPerTurn: -77,
        citySources: const [
          PlayerGoldIncomeSourceView(cityId: 'city', amount: 3),
        ],
        projectSources: const [
          PlayerGoldIncomeSourceView(cityId: 'city', amount: 4),
        ],
        upkeep: PlayerUnitUpkeepView(
          upkeepBearingUnitCount: 7,
          freeUnitCount: 2,
          paidUnitCount: 5,
          total: 32,
          nextWorkerUpkeep: 4,
          sources: const [],
        ),
        stability: source.economy.forecast.stability,
      ),
    ),
    research: PlayerResearchSummaryView(
      dominantEra: PlayerTechnologyEraView.foundation,
      activeTechnologyId: 'agriculture',
      activeProgress: 7,
      activeEffectiveCost: 31,
      scienceOverflow: 19,
      sciencePerTurn: 11,
      scienceByCityId: const {'city': 6},
      scienceSources: const [
        PlayerScienceYieldSourceView(
          cityId: 'city',
          amount: 6,
          kind: PlayerScienceYieldSourceKindView.cityScience,
        ),
      ],
    ),
  );
}

PlayerVictoryView resourceVictoryFixture(VictoryStatusView status) =>
    PlayerVictoryView(
      status: status,
      conquestEnabled: true,
      dominationEnabled: true,
      dominationRequiredControlPercent: 60,
      dominationRequiredHoldTurns: 5,
      culturalEnabled: true,
      culturalRequiredArtifacts: 6,
      culturalRequiredHoldTurns: 5,
      scoreFallbackEnabled: true,
      turnLimit: 20,
      remainingTurns: 3,
      scoreByPlayerId: const {'player-1': 40},
      domination: const [
        DominationVictoryProgressView(
          playerId: 'player-1',
          controlledPassableHexes: 54,
          totalPassableHexes: 100,
          holdTurns: 0,
        ),
      ],
      ownCultural: const CulturalVictoryProgressView(
        uniqueStoredArtifacts: 2,
        holdTurns: 0,
      ),
      mapObjectives: const [],
    );
