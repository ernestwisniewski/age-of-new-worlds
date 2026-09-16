import 'package:aonw_flutter/features/multiplayer/infrastructure/server_lobby_decoder.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'claimed ready seats remain offline until an authoritative connection',
    () {
      final value = _lobby();
      var decoded = decodeServerLobby(value);
      expect(decoded.currentParticipant.isClaimed, isTrue);
      expect(decoded.currentParticipant.isReady, isTrue);
      expect(decoded.currentParticipant.isConnected, isFalse);
      expect(decoded.canStart, isFalse);
      value.participants.single.isConnected = true;
      value.canStart = true;
      decoded = decodeServerLobby(value);
      expect(decoded.currentParticipant.isConnected, isTrue);
      expect(decoded.canStart, isTrue);
    },
  );

  test('rejects start permission while a ready human is disconnected', () {
    final value = _lobby()..canStart = true;
    expect(() => decodeServerLobby(value), throwsFormatException);
  });

  test('rejects live presence on an unclaimed or computer seat', () {
    final value = _lobby();
    value.participants.single
      ..isConnected = true
      ..isClaimed = false;
    expect(() => decodeServerLobby(value), throwsFormatException);
    value.participants.single
      ..isClaimed = true
      ..kind = 'ai';
    expect(() => decodeServerLobby(value), throwsFormatException);
  });

  test('presence is required by the generated wire decoder', () {
    final json = _lobby().participants.single.toJson()..remove('isConnected');
    expect(
      () => server.GameLobbyParticipantView.fromJson(json),
      throwsA(isA<server.DeserializationTypeNotFoundException>()),
    );
  });
}

server.GameLobbyView _lobby() => server.GameLobbyView(
  match: server.GameMatchView(
    matchId: 'match-1',
    mapId: 'map-1',
    mapHash: 'map-hash',
    rulesetId: 'ruleset-1',
    rulesetHash: 'ruleset-hash',
    state: 'lobby',
    hostPlayerId: 'player-1',
    revision: 0,
    eventOffset: 0,
  ),
  participants: [
    server.GameLobbyParticipantView(
      playerId: 'player-1',
      name: 'Player one',
      kind: 'human',
      country: 'poland',
      colorValue: 0xff8b2424,
      isHost: true,
      isClaimed: true,
      isConnected: false,
      isReady: true,
      isCurrentUser: true,
    ),
  ],
  canStart: false,
);
