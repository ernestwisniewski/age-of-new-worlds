import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('preserves city identities and exact production outcomes', () {
    final founded =
        _event({
              'type': 'cityFounded',
              'cityId': 'new-city',
              'ownerPlayerId': 'owner',
            })
            as AonwCityFoundedEvent;
    expect((founded.cityId, founded.ownerPlayerId), ('new-city', 'owner'));
    final building =
        _event({
              'type': 'cityBuiltBuilding',
              'cityId': 'city',
              'buildingType': 'granary',
            })
            as AonwCityBuiltBuildingEvent;
    expect(
      (building.cityId, building.buildingType),
      ('city', AonwCityBuildingType.granary),
    );
    final produced =
        _event({
              'type': 'cityProducedUnit',
              'cityId': 'city',
              'unitType': 'worker',
              'producedUnitId': 'spawned-worker',
            })
            as AonwCityProducedUnitEvent;
    expect(
      (produced.cityId, produced.unitType, produced.producedUnitId),
      ('city', AonwUnitKind.worker, 'spawned-worker'),
    );
    final wonder =
        _event({
              'type': 'cityBuiltWonder',
              'cityId': 'city',
              'ownerPlayerId': 'owner',
              'wonderType': 'greatLibrary',
            })
            as AonwCityBuiltWonderEvent;
    expect(
      (wonder.cityId, wonder.ownerPlayerId, wonder.wonderType),
      ('city', 'owner', AonwWonderType.greatLibrary),
    );
    final refund =
        _event({
              'type': 'wonderProductionRefunded',
              'cityId': 'other-city',
              'ownerPlayerId': 'owner',
              'wonderType': 'greatLibrary',
              'refundedProduction': 37,
            })
            as AonwWonderProductionRefundedEvent;
    expect(
      (
        refund.cityId,
        refund.ownerPlayerId,
        refund.wonderType,
        refund.refundedProduction,
      ),
      ('other-city', 'owner', AonwWonderType.greatLibrary, 37),
    );
    final claimed =
        _event({
              'type': 'cityClaimedHex',
              'cityId': 'city',
              'col': 12,
              'row': 9,
            })
            as AonwCityClaimedHexEvent;
    expect(
      (claimed.cityId, claimed.coordinate.col, claimed.coordinate.row),
      ('city', 12, 9),
    );
  });

  test(
    'preserves the completed technology and authoritative science amount',
    () {
      final researched =
          _event({
                'type': 'technologyResearched',
                'playerId': 'researcher',
                'technologyId': 'navigation',
              })
              as AonwTechnologyResearchedEvent;
      expect(
        (researched.playerId, researched.technology),
        ('researcher', AonwTechnologyId.navigation),
      );
      final points =
          _event({
                'type': 'researchPointsGained',
                'playerId': 'researcher',
                'points': 19,
              })
              as AonwResearchPointsGainedEvent;
      expect((points.playerId, points.points), ('researcher', 19));
    },
  );

  test('preserves artifact ownership anchors and the nullable source unit', () {
    const common = {
      'artifactId': 'artifact',
      'ownerPlayerId': 'owner',
      'unitId': 'excavator',
      'coordinate': {'col': 4, 'row': 7},
    };
    final excavated =
        _event({'type': 'artifactExcavationStarted', ...common})
            as AonwArtifactExcavationStartedEvent;
    expect(
      (
        excavated.artifactId,
        excavated.ownerPlayerId,
        excavated.unitId,
        excavated.coordinate.col,
        excavated.coordinate.row,
      ),
      ('artifact', 'owner', 'excavator', 4, 7),
    );
    final carried =
        _event({'type': 'artifactCarried', ...common})
            as AonwArtifactCarriedEvent;
    expect(
      (
        carried.artifactId,
        carried.ownerPlayerId,
        carried.unitId,
        carried.coordinate.col,
        carried.coordinate.row,
      ),
      ('artifact', 'owner', 'excavator', 4, 7),
    );
    for (final source in ['excavator', null]) {
      final stored =
          _event({
                'type': 'artifactStored',
                'artifactId': 'artifact',
                'ownerPlayerId': 'owner',
                'sourceUnitId': source,
                'cityId': 'storehouse',
                'coordinate': {'col': 6, 'row': 8},
              })
              as AonwArtifactStoredEvent;
      expect(
        (
          stored.artifactId,
          stored.ownerPlayerId,
          stored.sourceUnitId,
          stored.cityId,
          stored.coordinate.col,
          stored.coordinate.row,
        ),
        ('artifact', 'owner', source, 'storehouse', 6, 8),
      );
    }
  });

  test(
    'distinguishes a completed improvement from a road at the exact target',
    () {
      for (final completion in [
        {'type': 'fieldImprovement', 'improvement': 'farm'},
        {'type': 'road'},
      ]) {
        final completed =
            _event({
                  'type': 'workerCompletedJob',
                  'unitId': 'builder',
                  'target': {'col': 3, 'row': 2},
                  'completion': completion,
                })
                as AonwWorkerCompletedJobEvent;
        expect(
          (completed.unitId, completed.target.col, completed.target.row),
          ('builder', 3, 2),
        );
        if (completion['type'] == 'road') {
          expect(completed.completion, isA<AonwRoadCompletion>());
        } else {
          expect(
            (completed.completion as AonwFieldImprovementCompletion)
                .improvement,
            AonwFieldImprovementKind.farm,
          );
        }
      }
    },
  );

  test('rejects unknown nested completion and catalog values', () {
    const worker = {
      'type': 'workerCompletedJob',
      'unitId': 'builder',
      'target': {'col': 3, 'row': 2},
    };
    for (final invalid in [
      {'type': 'futureCompletion'},
      {'type': 'road', 'improvement': 'farm'},
      {'type': 'fieldImprovement', 'improvement': 'futureImprovement'},
    ]) {
      expect(
        () => AonwClientEvent.fromJson({...worker, 'completion': invalid}),
        throwsFormatException,
      );
    }
    expect(
      () => AonwClientEvent.fromJson({
        'type': 'technologyResearched',
        'playerId': 'owner',
        'technologyId': 'futureTechnology',
      }),
      throwsFormatException,
    );
    expect(
      () => AonwClientEvent.fromJson({
        'type': 'cityProducedUnit',
        'cityId': 'city',
        'unitType': 'futureUnit',
        'producedUnitId': 'unit',
      }),
      throwsFormatException,
    );
  });
}

// Every preserved event retains the same strict field-set contract.
AonwClientEvent _event(Map<String, Object?> value) {
  final event = AonwClientEvent.fromJson(value);
  expect(event.kind.name, value['type']);
  expect(
    () => AonwClientEvent.fromJson({...value, 'extra': true}),
    throwsFormatException,
  );
  for (final key in value.keys) {
    expect(
      () => AonwClientEvent.fromJson({...value}..remove(key)),
      throwsFormatException,
      reason: '${value['type']} requires $key',
    );
  }
  return event;
}
