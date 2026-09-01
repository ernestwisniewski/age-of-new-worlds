import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('serializes every current city query and command exactly', () {
    expect(
      _request(
        AonwCityRequest.foundingOptions(
          expectedRevision: 7,
          founderUnitId: 'founder',
        ),
      ),
      _query('cityFoundingOptions', 7, {'founderUnitId': 'founder'}),
    );
    expect(
      _request(
        AonwCityRequest.workedHexOptions(expectedRevision: 7, cityId: 'city'),
      ),
      _query('cityWorkedHexOptions', 7, {'cityId': 'city'}),
    );
    expect(
      _request(
        AonwCityRequest.expansionOptions(expectedRevision: 7, cityId: 'city'),
      ),
      _query('cityExpansionOptions', 7, {'cityId': 'city'}),
    );
    expect(
      _request(AonwCityRequest.cityYield(expectedRevision: 7, cityId: 'city')),
      _query('cityYield', 7, {'cityId': 'city'}),
    );
    expect(
      _request(
        AonwCityRequest.found(
          expectedRevision: 7,
          founderUnitId: 'founder',
          controlledHexes: const [AonwCoordinate(col: 1, row: 2)],
        ),
      ),
      _command('foundCity', 7, {
        'founderUnitId': 'founder',
        'controlledHexes': [
          {'col': 1, 'row': 2},
        ],
      }),
    );
    expect(
      _request(
        AonwCityRequest.toggleWorkedHex(
          expectedRevision: 7,
          cityId: 'city',
          targetCol: 2,
          targetRow: 3,
        ),
      ),
      _command('toggleWorkedHex', 7, {
        'cityId': 'city',
        'target': {'col': 2, 'row': 3},
      }),
    );
    expect(
      _request(
        AonwCityRequest.selectExpansionHex(
          expectedRevision: 7,
          cityId: 'city',
          targetCol: 3,
          targetRow: 4,
        ),
      ),
      _command('selectCityExpansionHex', 7, {
        'cityId': 'city',
        'target': {'col': 3, 'row': 4},
      }),
    );
  });

  test('parses complete engine-owned city query projections', () {
    final founding =
        AonwQueryResult.fromJson({
              'type': 'cityFoundingOptions',
              'stamp': _stamp,
              'founderUnitId': 'founder',
              'center': {'col': 1, 'row': 1},
              'selectedControlledHexes': [
                {'col': 1, 'row': 2},
              ],
              'availableControlledHexes': [
                {'col': 2, 'row': 1},
              ],
              'rankedAvailableControlledHexes': [
                {'col': 2, 'row': 1},
              ],
              'requiredControlledHexes': 2,
              'maximumRadius': 3,
            })
            as AonwCityFoundingOptionsResult;
    expect(founding.requiredControlledHexes, 2);
    expect(founding.availableControlledHexes.single.col, 2);
    expect(founding.rankedAvailableControlledHexes.single.col, 2);

    final worked =
        AonwQueryResult.fromJson({
              'type': 'cityWorkedHexOptions',
              'stamp': _stamp,
              'cityId': 'city',
              'center': {'col': 1, 'row': 1},
              'controlledHexes': [
                {'col': 1, 'row': 2},
              ],
              'availableHexes': [
                {'col': 1, 'row': 2},
              ],
              'selectedHexes': <Object?>[],
              'effectiveHexes': [
                {'col': 1, 'row': 2},
              ],
              'limit': 1,
            })
            as AonwCityWorkedHexOptionsResult;
    expect(worked.effectiveHexes, hasLength(1));
    expect(worked.limit, 1);

    final expansion =
        AonwQueryResult.fromJson({
              'type': 'cityExpansionOptions',
              'stamp': _stamp,
              'cityId': 'city',
              'controlledHexes': [
                {'col': 1, 'row': 2},
              ],
              'preferredHex': null,
              'candidates': [
                {
                  'coordinate': {'col': 2, 'row': 2},
                  'score': -1,
                  'distance': 2,
                  'tileYield': _yield,
                },
              ],
            })
            as AonwCityExpansionOptionsResult;
    expect(expansion.candidates.single.score, -1);
    expect(expansion.candidates.single.tileYield.production, 3);

    final cityYield =
        AonwQueryResult.fromJson({
              'type': 'cityYield',
              'stamp': _stamp,
              'cityId': 'city',
              'contributions': [
                {
                  'kind': 'center',
                  'coordinate': {'col': 1, 'row': 1},
                  'value': _yield,
                },
              ],
              'total': _yield,
            })
            as AonwCityYieldResult;
    expect(cityYield.total.production, 3);
    expect(
      cityYield.contributions.single.kind,
      AonwCityYieldContributionKind.center,
    );
  });

  test('city query projections reject unknown or incomplete values', () {
    expect(
      () => AonwCityExpansionCandidate.fromJson({
        'coordinate': {'col': 1, 'row': 1},
        'score': 2,
      }),
      throwsFormatException,
    );
    expect(
      () => AonwCityYieldContribution.fromJson({
        'kind': 'hiddenRule',
        'coordinate': {'col': 1, 'row': 1},
        'value': _yield,
      }),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _request(AonwClientRequest request) =>
    (jsonDecode(request.toJson()) as Map<String, Object?>)['request']!
        as Map<String, Object?>;

Map<String, Object?> _query(
  String type,
  int expectedRevision,
  Map<String, Object?> fields,
) => {
  'type': 'query',
  'query': {'type': type, 'expectedRevision': expectedRevision, ...fields},
};

Map<String, Object?> _command(
  String type,
  int expectedRevision,
  Map<String, Object?> fields,
) => {
  'type': 'dispatch',
  'command': {'type': type, 'expectedRevision': expectedRevision, ...fields},
};

const _stamp = <String, Object?>{
  'revision': 7,
  'stateDigest':
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  'mapHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  'rulesetHash':
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
};

const _yield = <String, Object?>{
  'food': 2,
  'production': 3,
  'gold': 1,
  'defense': 0,
};
