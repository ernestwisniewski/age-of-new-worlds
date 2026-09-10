import 'dart:convert';

import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Match history', (sessionBuilder, endpoints) {
    test(
      'paginates completed memberships without granting gameplay access',
      () async {
        final database = sessionBuilder.build();
        await _seedHistory(database);
        final owner = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'history-owner',
            const {},
          ),
        );
        final stranger = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'history-stranger',
            const {},
          ),
        );
        final first = await endpoints.game.matchHistory(owner);
        expect(first.entries, hasLength(50));
        expect(first.nextBeforeParticipantId, isNotNull);
        final second = await endpoints.game.matchHistory(
          owner,
          beforeParticipantId: first.nextBeforeParticipantId,
        );
        expect(second.entries, hasLength(2));
        expect(second.nextBeforeParticipantId, isNull);
        final entries = [...first.entries, ...second.entries];
        expect(
          entries.map((entry) => entry.match.matchId).toSet(),
          hasLength(52),
        );
        expect(
          entries.every((entry) => entry.match.state == 'finished'),
          isTrue,
        );
        expect(entries.where((entry) => entry.resignedAt != null), isNotEmpty);
        expect(entries.where((entry) => entry.kickedAt != null), isNotEmpty);
        expect(entries.every((entry) => entry.playerId == 'player-1'), isTrue);
        expect(entries.every((entry) => entry.turn == 12), isTrue);
        expect(entries.every((entry) => !entry.replayAvailable), isTrue);
        final serialized = jsonEncode(first.toJson());
        for (final privateField in [
          'canonicalStateJson',
          'mapDocument',
          'userIdentifier',
          'kickReason',
          'private-history-sentinel',
        ]) {
          expect(serialized, isNot(contains(privateField)));
        }
        expect((await endpoints.game.matchHistory(stranger)).entries, isEmpty);
        final resigned = entries.firstWhere(
          (entry) => entry.resignedAt != null,
        );
        await expectLater(
          endpoints.game.resync(owner, resigned.match.matchId),
          throwsA(
            isA<GameException>().having(
              (error) => error.code,
              'code',
              'not_participant',
            ),
          ),
        );
        await expectLater(
          endpoints.game.matchHistory(owner, beforeParticipantId: 0),
          throwsA(
            isA<GameException>().having(
              (error) => error.code,
              'code',
              'invalid_history_cursor',
            ),
          ),
        );
      },
    );
  }, rollbackDatabase: RollbackDatabase.afterEach);
}

Future<void> _seedHistory(Session session) async {
  final now = DateTime.utc(2026, 9, 12);
  // More active memberships than the page size must not hide completed games.
  final matches = await GameMatch.db.insert(session, [
    for (var index = 0; index < 153; index++)
      GameMatch(
        publicId: 'history-match-$index',
        mapId: 'history-map',
        mapHash: 'a' * 64,
        rulesetId: 'history-rules',
        rulesetHash: 'b' * 64,
        mapDocument: 'private-history-sentinel',
        canonicalStateJson: 'private-history-sentinel',
        state: index < 52 || index == 152 ? 'finished' : 'running',
        turn: 12,
        startedAt: now.subtract(const Duration(days: 1)),
        endedAt: index < 52 || index == 152 ? now : null,
        outcomeCondition: 'resignation',
        winnerPlayerId: 'player-2',
        revision: 100,
        eventOffset: 200,
        createdAt: now,
        updatedAt: now,
      ),
  ]);
  await GameParticipant.db.insert(session, [
    for (var index = 0; index < matches.length; index++)
      GameParticipant(
        matchId: matches[index].id!,
        userIdentifier: index == 152 ? 'other-owner' : 'history-owner',
        playerId: 'player-1',
        joinedAt: now,
        resignedAt: index % 3 == 1 ? now : null,
        kickedAt: index % 3 == 2 ? now : null,
        kickReason: 'private-history-sentinel',
      ),
  ]);
}
