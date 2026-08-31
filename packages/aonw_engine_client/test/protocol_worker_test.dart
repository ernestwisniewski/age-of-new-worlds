import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('serializes every current worker query and command exactly', () {
    expect(
      _request(AonwWorkerRequest.options(expectedRevision: 8, unitId: 'w1')),
      _query('workerOptions', 8, 'w1'),
    );
    expect(
      _request(
        AonwWorkerRequest.selectImprovement(
          expectedRevision: 8,
          unitId: 'w1',
          improvement: AonwFieldImprovementKind.farm,
        ),
      ),
      _command('selectWorkerImprovement', 8, 'w1', {'improvement': 'farm'}),
    );
    expect(
      _request(
        AonwWorkerRequest.confirmImprovement(
          expectedRevision: 8,
          unitId: 'w1',
          improvement: AonwFieldImprovementKind.farm,
        ),
      ),
      _command('confirmWorkerImprovement', 8, 'w1', {'improvement': 'farm'}),
    );
    expect(
      _request(AonwWorkerRequest.cancelJob(expectedRevision: 8, unitId: 'w1')),
      _command('cancelWorkerJob', 8, 'w1'),
    );
    expect(
      _request(
        AonwWorkerRequest.assignToHex(expectedRevision: 8, unitId: 'w1'),
      ),
      _command('assignWorkerToHex', 8, 'w1'),
    );
    expect(
      _request(
        AonwWorkerRequest.cancelAssignment(expectedRevision: 8, unitId: 'w1'),
      ),
      _command('cancelWorkerAssignment', 8, 'w1'),
    );
    expect(
      _request(AonwWorkerRequest.buildRoad(expectedRevision: 8, unitId: 'w1')),
      _command('buildRoad', 8, 'w1'),
    );
    expect(
      _request(AonwWorkerRequest.automate(expectedRevision: 8, unitId: 'w1')),
      _command('automateWorker', 8, 'w1'),
    );
  });

  test('parses complete engine-owned worker options', () {
    final result =
        AonwQueryResult.fromJson({
              'type': 'workerOptions',
              'stamp': _stamp,
              'unitId': 'w1',
              'coordinate': {'col': 1, 'row': 2},
              'improvements': [
                {'improvement': 'farm', 'buildTurns': 3},
              ],
              'canAssign': false,
              'canBuildRoad': true,
              'automation': {
                'target': {'col': 1, 'row': 2},
                'action': {'type': 'improve', 'improvement': 'farm'},
                'movementCostUnits': 0,
                'metrics': {
                  'tilesExamined': 3,
                  'legalityEvaluations': 57,
                  'routesPlanned': 2,
                },
              },
            })
            as AonwWorkerOptionsResult;

    expect(result.unitId, 'w1');
    expect((result.coordinate.col, result.coordinate.row), (1, 2));
    expect(
      result.improvements.single.improvement,
      AonwFieldImprovementKind.farm,
    );
    expect(result.improvements.single.buildTurns, 3);
    expect(result.canBuildRoad, isTrue);
    expect(result.automation!.metrics.legalityEvaluations, 57);
  });

  test('worker options reject incomplete and unknown values', () {
    expect(
      () => AonwWorkerImprovementOption.fromJson({'improvement': 'farm'}),
      throwsFormatException,
    );
    expect(
      () => AonwQueryResult.fromJson({
        'type': 'workerOptions',
        'stamp': _stamp,
        'unitId': 'w1',
        'coordinate': {'col': 1, 'row': 2},
        'improvements': const <Object?>[],
        'canAssign': false,
        'canBuildRoad': false,
        'automation': null,
        'clientFallback': true,
      }),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _request(AonwClientRequest request) =>
    (jsonDecode(request.toJson()) as Map<String, Object?>)['request']!
        as Map<String, Object?>;

Map<String, Object?> _query(String type, int revision, String unitId) => {
  'type': 'query',
  'query': {'type': type, 'expectedRevision': revision, 'unitId': unitId},
};

Map<String, Object?> _command(
  String type,
  int revision,
  String unitId, [
  Map<String, Object?> fields = const {},
]) => {
  'type': 'dispatch',
  'command': {
    'type': type,
    'expectedRevision': revision,
    'unitId': unitId,
    ...fields,
  },
};

const _stamp = <String, Object?>{
  'revision': 8,
  'stateDigest':
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  'mapHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  'rulesetHash':
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
};
