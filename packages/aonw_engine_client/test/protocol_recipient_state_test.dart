import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('game outcome is strict, typed, and immutable', () {
    final outcome = AonwGameOutcome.fromJson({
      'condition': 'score',
      'winnerPlayerId': 'player-1',
      'scoreByPlayerId': {'player-1': 17, 'player-2': -3},
    });

    expect(outcome.condition, AonwGameOutcomeCondition.score);
    expect(outcome.winnerPlayerId, 'player-1');
    expect(outcome.scoreByPlayerId, {'player-1': 17, 'player-2': -3});
    expect(
      () => outcome.scoreByPlayerId['player-3'] = 1,
      throwsUnsupportedError,
    );
    expect(
      () => AonwGameOutcome.fromJson({
        'condition': 'futureOutcome',
        'winnerPlayerId': null,
        'scoreByPlayerId': const <String, int>{},
      }),
      throwsFormatException,
    );
  });

  test('artifact parser covers every current recipient-safe location', () {
    final locations = <Map<String, Object?>, Type>{
      {
        'kind': 'map',
        'coordinate': {'col': 1, 'row': 2},
      }: AonwMapArtifactLocation,
      {'kind': 'carried', 'unitId': 'unit-1'}: AonwCarriedArtifactLocation,
      {'kind': 'stored', 'cityId': 'city-1'}: AonwStoredArtifactLocation,
      {
        'kind': 'excavation',
        'unitId': 'unit-1',
        'coordinate': {'col': 1, 'row': 2},
        'remainingTurns': 3,
      }: AonwExcavationArtifactLocation,
    };

    for (final MapEntry(key: source, value: expectedType)
        in locations.entries) {
      final artifact = AonwPlayerArtifactView.fromJson({
        'id': 'artifact-1',
        'type': 'heroSword',
        'location': source,
      });
      expect(artifact.type, AonwWorldArtifactType.heroSword);
      expect(artifact.location.runtimeType, expectedType);
    }
    expect(
      () => AonwPlayerArtifactLocation.fromJson(const {'kind': 'unknown'}),
      throwsFormatException,
    );
  });

  test(
    'diplomacy parser keeps the complete recipient-safe projection typed',
    () {
      final diplomacy = AonwPlayerDiplomacyView.fromJson({
        'relations': [
          {
            'counterpartPlayerId': 'player-2',
            'status': 'truce',
            'relationScore': -7,
            'statusExpiresOnTurn': 12,
            'lastChangedTurn': 4,
            'lastChangeReason': 'proposalAccepted',
          },
        ],
        'proposals': [
          {
            'id': 'proposal-1',
            'fromPlayerId': 'player-1',
            'toPlayerId': 'player-2',
            'kind': 'friendship',
            'createdTurn': 4,
            'expiresOnTurn': 8,
            'goldPayment': 0,
          },
        ],
        'messages': [
          {
            'id': 'message-1',
            'fromPlayerId': 'player-2',
            'toPlayerId': 'player-1',
            'topic': 'avoidEscalation',
            'category': 'warning',
            'createdTurn': 5,
            'expiresOnTurn': 7,
            'response': 'conciliatory',
            'respondedTurn': 6,
            'relationScoreDelta': 2,
            'relationScoreAfter': -5,
            'promiseDueTurn': 10,
            'promiseBroken': false,
          },
        ],
        'resourceTradeAgreements': [
          {
            'id': 'trade-1',
            'exporterPlayerId': 'player-1',
            'importerPlayerId': 'player-2',
            'resource': 'iron',
            'goldPerTurn': 3,
            'remainingTurns': 5,
            'amountPerTurn': 1,
            'exchangeGroupId': null,
          },
        ],
      });

      expect(
        diplomacy.relations.single.status,
        AonwDiplomaticRelationStatus.truce,
      );
      expect(
        diplomacy.proposals.single.kind,
        AonwDiplomaticProposalKind.friendship,
      );
      expect(
        diplomacy.messages.single.topic,
        AonwDiplomaticMessageTopic.avoidEscalation,
      );
      expect(
        diplomacy.resourceTradeAgreements.single.resource,
        AonwResourceType.iron,
      );
    },
  );
}
