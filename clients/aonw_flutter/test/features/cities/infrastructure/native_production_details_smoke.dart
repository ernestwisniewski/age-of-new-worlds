part of 'native_city_smoke_test.dart';

Future<void> _inspectProductionDetails(
  AonwEngineSession session,
  String cityId,
  int revision,
  AonwProductionOption building,
) async {
  final snapshot = (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
  final targets = [
    building.target,
    const AonwCityProductionTarget.unit(AonwUnitKind.warrior),
    const AonwCityProductionTarget.wonder(AonwWonderType.greatLibrary),
  ];
  for (final target in targets) {
    final details = await _query<AonwProductionDetailsResult>(
      session,
      AonwProductionRequest.details(
        expectedRevision: revision,
        cityId: cityId,
        target: target,
      ),
    );
    expect(details.cityId, cityId);
    expect(details.stamp.stateDigest, snapshot.stamp.stateDigest);
    expect(details.option.target.toJson(), target.toJson());
    if (target.kind == AonwCityProductionTargetKind.building) {
      expect(details.option.cost, building.cost);
      expect(details.effects, isA<AonwBuildingProductionDetails>());
    } else if (target.kind == AonwCityProductionTargetKind.unit) {
      expect(
        (details.effects as AonwUnitProductionDetails).maximumMovementUnits,
        greaterThan(0),
      );
    } else {
      expect(
        (details.effects as AonwWonderProductionDetails)
            .grantsFreeActiveTechnology,
        isTrue,
      );
    }
  }
  final ranks = await _query<AonwProductionBuildingRanksResult>(
    session,
    AonwProductionRequest.buildingRanks(
      expectedRevision: revision,
      cityId: cityId,
    ),
  );
  expect(ranks.buildings, hasLength(AonwCityBuildingType.values.length));
  expect(ranks.stamp.stateDigest, snapshot.stamp.stateDigest);
  final after = (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
  expect(after.stamp.stateDigest, snapshot.stamp.stateDigest);
}

Future<void> _assertForeignProductionDetails(
  AonwEngineSession session,
  String cityId,
  int revision,
) async {
  for (final request in [
    AonwProductionRequest.details(
      expectedRevision: revision,
      cityId: cityId,
      target: const AonwCityProductionTarget.building(
        AonwCityBuildingType.workshop,
      ),
    ),
    AonwProductionRequest.buildingRanks(
      expectedRevision: revision,
      cityId: cityId,
    ),
  ]) {
    expect((await session.send(request)).error?.code, 'city_not_controlled');
  }
}
