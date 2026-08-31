import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/infrastructure/production_view_mapper.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
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
}

AonwProductionOptionsResult _options({
  int revision = 0,
  List<int> affordableIndices = const [0],
  AonwCommandRejectionCode? buildingRejection,
}) => AonwProductionOptionsResult(
  stamp: _stamp(revision: revision),
  cityId: 'preview-city',
  currentTarget: _target('project', 'projectType', 'research'),
  investedProduction: 4,
  productionOverflow: 1,
  buildings: [
    AonwProductionOption(
      target: _target('building', 'buildingType', 'workshop'),
      cost: 15,
      rejection: buildingRejection,
    ),
  ],
  units: [
    AonwUnitProductionOption(
      option: AonwProductionOption(
        target: _target('unit', 'unitType', 'tank'),
        cost: 32,
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
      target: _target('project', 'projectType', 'research'),
      cost: 0,
      rejection: null,
    ),
  ],
  wonders: [
    AonwProductionOption(
      target: _target('wonder', 'wonderType', 'greatLibrary'),
      cost: 25,
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
