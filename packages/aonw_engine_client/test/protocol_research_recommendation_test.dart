import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test(
    'recommendation rejects missing unknown and invalid nullable details',
    () {
      final source = _entry();
      expect(
        AonwResearchRecommendation.fromJson(source).turnsRemaining,
        isNull,
      );
      for (final key in source.keys) {
        final missing = {...source}..remove(key);
        expect(
          () => AonwResearchRecommendation.fromJson(missing),
          throwsFormatException,
        );
      }
      for (final patch in [
        {'extra': true},
        {'score': '10'},
        {'technologyId': 'future'},
        {'turnsRemaining': -1},
        {'turnsRemaining': 0},
        {'turnsRemaining': 0x100000000},
        {
          'reasons': ['boost', 'boost'],
        },
        {
          'reasons': ['unknown'],
        },
        {'reasons': List.filled(6, 'boost')},
      ]) {
        expect(
          () => AonwResearchRecommendation.fromJson({...source, ...patch}),
          throwsFormatException,
        );
      }
    },
  );
  test('research result requires bounded distinct ordered recommendations', () {
    final source = _query();
    expect(
      AonwResearchOptionsResult.fromJson(source).recommendations,
      hasLength(1),
    );
    for (final entries in [
      null,
      List.filled(4, _entry()),
      [_entry(), _entry()],
      [
        _entry(),
        {..._entry(), 'technologyId': 'mining', 'score': 20},
      ],
    ]) {
      expect(
        () => AonwResearchOptionsResult.fromJson({
          ...source,
          'recommendations': entries,
        }),
        throwsFormatException,
      );
    }
    source.remove('recommendations');
    expect(
      () => AonwResearchOptionsResult.fromJson(source),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _entry() => {
  'technologyId': 'agriculture',
  'score': 10,
  'turnsRemaining': null,
  'reasons': ['workerYields'],
};
Map<String, Object?> _query() => {
  'type': 'researchOptions',
  'stamp': {
    'revision': 0,
    'stateDigest': 'd',
    'mapHash': 'm',
    'rulesetHash': 'r',
  },
  'playerId': 'player',
  'activeTechnologyId': null,
  'scienceOverflow': 0,
  'scienceYield': {
    'total': 0,
    'byCityId': <String, int>{},
    'sources': <Object?>[],
  },
  'options': <Object?>[],
  'recommendations': [_entry()],
};
