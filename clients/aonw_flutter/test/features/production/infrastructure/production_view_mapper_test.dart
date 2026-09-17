import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/infrastructure/production_view_mapper.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = ProductionViewMapper();

  test('maps exact production choices and strategic resource projection', () {
    final city = testCityView();
    final scene = testMapScene(cities: [city]);

    final options = mapper.options(
      _options(),
      map: scene.map,
      player: scene.player,
      cityId: city.id,
      expectedRevision: 0,
    );
    final resources = mapper.resources(
      _resources(),
      map: scene.map,
      player: scene.player,
      expectedRevision: 0,
    );

    expect(options.currentTarget, isA<ProjectProductionTargetView>());
    expect(options.investedProduction, 4);
    expect(options.productionOverflow, 1);
    expect(options.buildings.single.cost, 15);
    expect(options.buildings.single.forecast.estimatedTurns, 4);
    expect(
      options.buildings.single.availability.requiredTechnology?.name,
      'craftsmanship',
    );
    expect(options.buildings.single.availability.technologyUnlocked, isTrue);
    expect(options.buildings.single.availability.completedInCity, isFalse);
    expect(options.projects.single.forecast.projectOutput, 1);
    expect(options.projects.single.forecast.estimatedTurns, isNull);
    expect(
      options.rushQuote.blocker,
      ProductionRejectionCodeView.projectCannotBeRushed,
    );
    expect(options.units.single.option.target, isA<UnitProductionTargetView>());
    expect(
      (options.units.single.option.target as UnitProductionTargetView).unit,
      VisibleUnitKind.tank,
    );
    expect(options.units.single.resourceOptions.single, {MapResource.oil: 2});
    expect(options.units.single.affordableResourceOptionIndices, {0});
    expect(resources.output.single.amount, 2);
    expect(resources.sources.single.coordinate, city.center);
    expect(resources.sources.single.improvement, 'mine');
  });

  test(
    'rejects unlocked or completed status that contradicts command availability',
    () {
      final scene = testMapScene(cities: [testCityView()]);
      for (final value in [
        const AonwProductionAvailability(
          requiredTechnology: AonwTechnologyId.craftsmanship,
          technologyUnlocked: false,
          completedInCity: false,
        ),
        const AonwProductionAvailability(
          requiredTechnology: null,
          technologyUnlocked: true,
          completedInCity: true,
        ),
      ]) {
        expect(
          () => mapper.options(
            _options(availability: value),
            map: scene.map,
            player: scene.player,
            cityId: 'preview-city',
            expectedRevision: 0,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('fails closed on stale, malformed, or unrelated engine choices', () {
    final city = testCityView();
    final scene = testMapScene(cities: [city]);

    expect(
      () => mapper.options(
        _options(revision: 1),
        map: scene.map,
        player: scene.player,
        cityId: city.id,
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.options(
        _options(affordableIndices: const [1]),
        map: scene.map,
        player: scene.player,
        cityId: city.id,
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.options(
        _options(buildingRejection: AonwCommandRejectionCode.workerNotFound),
        map: scene.map,
        player: scene.player,
        cityId: city.id,
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.command(
        _rejected(AonwCommandRejectionCode.workerNotFound),
        map: scene.map,
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('rejects incoherent project forecasts and rush availability', () {
    final scene = testMapScene(cities: [testCityView()]);
    for (final value in [
      _options(
        projectForecast: const AonwProductionForecast(
          investedProduction: 4,
          productionPerTurn: 3,
          estimatedTurns: 2,
          projectOutput: 1,
          spawnBlocked: false,
        ),
      ),
      _options(
        projectForecast: const AonwProductionForecast(
          investedProduction: 8,
          productionPerTurn: 3,
          estimatedTurns: null,
          projectOutput: 1,
          spawnBlocked: false,
        ),
      ),
      _options(
        projectForecast: const AonwProductionForecast(
          investedProduction: 4,
          productionPerTurn: 3,
          estimatedTurns: null,
          projectOutput: 1,
          spawnBlocked: true,
        ),
      ),
      _options(
        rushQuote: const AonwProductionRushQuote(
          production: 3,
          goldCost: 6,
          rejection: null,
        ),
      ),
      _options(
        rushQuote: const AonwProductionRushQuote(
          production: 0,
          goldCost: 0,
          rejection: AonwCommandRejectionCode.workerNotFound,
        ),
      ),
    ]) {
      expect(
        () => mapper.options(
          value,
          map: scene.map,
          player: scene.player,
          cityId: 'preview-city',
          expectedRevision: 0,
        ),
        throwsFormatException,
      );
    }
  });
}

AonwProductionOptionsResult _options({
  int revision = 0,
  List<int> affordableIndices = const [0],
  AonwCommandRejectionCode? buildingRejection,
  AonwProductionForecast? projectForecast,
  AonwProductionAvailability? availability,
  AonwProductionRushQuote? rushQuote,
}) => AonwProductionOptionsResult(
  stamp: _stamp(revision: revision),
  cityId: 'preview-city',
  currentTarget: _target('project', 'projectType', 'research'),
  investedProduction: 4,
  productionOverflow: 1,
  rushQuote:
      rushQuote ??
      const AonwProductionRushQuote(
        production: 0,
        goldCost: 0,
        rejection: AonwCommandRejectionCode.projectCannotBeRushed,
      ),
  buildings: [
    AonwProductionOption(
      availability:
          availability ??
          const AonwProductionAvailability(
            requiredTechnology: AonwTechnologyId.craftsmanship,
            technologyUnlocked: true,
            completedInCity: false,
          ),
      target: _target('building', 'buildingType', 'workshop'),
      cost: 15,
      forecast: const AonwProductionForecast(
        investedProduction: 4,
        productionPerTurn: 3,
        estimatedTurns: 4,
        projectOutput: null,
        spawnBlocked: false,
      ),
      rejection: buildingRejection,
    ),
  ],
  units: [
    AonwUnitProductionOption(
      option: AonwProductionOption(
        availability: AonwProductionAvailability(
          requiredTechnology: null,
          technologyUnlocked: true,
          completedInCity: false,
        ),
        target: _target('unit', 'unitType', 'tank'),
        cost: 32,
        forecast: const AonwProductionForecast(
          investedProduction: 4,
          productionPerTurn: 3,
          estimatedTurns: 10,
          projectOutput: null,
          spawnBlocked: false,
        ),
        rejection: null,
      ),
      resourceOptions: const [
        <AonwResourceType, int>{AonwResourceType.oil: 2},
      ],
      affordableResourceOptionIndices: affordableIndices,
    ),
  ],
  projects: [
    AonwProductionOption(
      availability: AonwProductionAvailability(
        requiredTechnology: null,
        technologyUnlocked: true,
        completedInCity: false,
      ),
      target: _target('project', 'projectType', 'research'),
      cost: 0,
      forecast:
          projectForecast ??
          const AonwProductionForecast(
            investedProduction: 4,
            productionPerTurn: 3,
            estimatedTurns: null,
            projectOutput: 1,
            spawnBlocked: false,
          ),
      rejection: null,
    ),
  ],
  wonders: [
    AonwProductionOption(
      availability: AonwProductionAvailability(
        requiredTechnology: null,
        technologyUnlocked: true,
        completedInCity: false,
      ),
      target: _target('wonder', 'wonderType', 'greatLibrary'),
      cost: 25,
      forecast: const AonwProductionForecast(
        investedProduction: 4,
        productionPerTurn: 3,
        estimatedTurns: 7,
        projectOutput: null,
        spawnBlocked: false,
      ),
      rejection: null,
    ),
  ],
  specializations: const [
    AonwCitySpecializationOption(
      specialization: AonwCitySpecialization.industry,
      requiredBuilding: AonwCityBuildingType.workshop,
      rejection: null,
    ),
  ],
);

AonwStrategicResourceProjectionResult _resources() =>
    AonwStrategicResourceProjectionResult(
      stamp: _stamp(),
      playerId: 'preview-player',
      output: const [
        AonwStrategicResourceAmount(resource: AonwResourceType.oil, amount: 2),
      ],
      sources: const [
        AonwStrategicResourceSource(
          cityId: 'preview-city',
          coordinate: AonwCoordinate(col: 1, row: 1),
          resource: AonwResourceType.oil,
          improvement: AonwFieldImprovementKind.mine,
          amountPerTurn: 2,
        ),
      ],
    );

AonwCityProductionTarget _target(String kind, String key, String value) =>
    AonwCityProductionTarget.fromJson({'kind': kind, key: value});

AonwCommandResult _rejected(AonwCommandRejectionCode code) => AonwCommandResult(
  stamp: _stamp(),
  outcome: AonwCommandRejected(code),
  events: const [],
  evidence: null,
  viewPatch: const AonwPlayerViewPatch(
    fromRevision: 0,
    toRevision: 0,
    turn: 1,
    turnMode: AonwTurnMode.sequential,
    turnLifecycle: null,
    outcome: null,
    upsertedUnits: [],
    removedUnitIds: [],
    upsertedCities: [],
    removedCityIds: [],
    upsertedArtifacts: [],
    removedArtifactIds: [],
    upsertedFieldImprovements: [],
    removedFieldImprovementCoordinates: [],
    upsertedRoads: [],
    removedRoadCoordinates: [],
    pendingAction: null,
    cityFoundingDraft: null,
    diplomacy: null,
  ),
);

AonwSessionStamp _stamp({int revision = 0}) => AonwSessionStamp(
  revision: revision,
  stateDigest: 'b' * 64,
  mapHash: 'a' * 64,
  rulesetHash: 'c' * 64,
);
