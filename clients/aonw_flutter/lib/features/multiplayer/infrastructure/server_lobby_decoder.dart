import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;

import '../read_model/multiplayer_view.dart';

MultiplayerMatchView decodeServerMatch(server.GameMatchView value) {
  final phase = _decodeMatchPhase(value.state);
  _validateMatchIdentity(value);
  _validateMatchLifecycle(value, phase);
  _validateMatchOffsets(value);
  return MultiplayerMatchView(
    matchId: value.matchId,
    mapId: value.mapId,
    mapHash: value.mapHash,
    rulesetId: value.rulesetId,
    rulesetHash: value.rulesetHash,
    phase: phase,
    hostPlayerId: value.hostPlayerId,
    startedAt: value.startedAt?.toUtc(),
    revision: value.revision,
    eventOffset: value.eventOffset,
  );
}

MultiplayerMatchPhase _decodeMatchPhase(String value) => switch (value) {
  'lobby' => MultiplayerMatchPhase.lobby,
  'running' => MultiplayerMatchPhase.running,
  'finished' => MultiplayerMatchPhase.finished,
  'abandoned' => MultiplayerMatchPhase.abandoned,
  _ => throw const FormatException('The server returned an invalid match.'),
};

void _validateMatchIdentity(server.GameMatchView value) {
  if (value.matchId.isEmpty ||
      value.mapId.isEmpty ||
      value.mapHash.isEmpty ||
      value.rulesetId.isEmpty ||
      value.rulesetHash.isEmpty ||
      (value.hostPlayerId?.isEmpty ?? false)) {
    throw const FormatException('The server returned an invalid match.');
  }
}

void _validateMatchLifecycle(
  server.GameMatchView value,
  MultiplayerMatchPhase phase,
) {
  final waiting = phase == MultiplayerMatchPhase.lobby;
  if (waiting && (value.hostPlayerId == null || value.startedAt != null)) {
    throw const FormatException('The server returned an invalid match.');
  }
  if (!waiting && value.startedAt == null) {
    if (phase == MultiplayerMatchPhase.abandoned) return;
    throw const FormatException('The server returned an invalid match.');
  }
}

void _validateMatchOffsets(server.GameMatchView value) {
  if (value.revision < 0 || value.eventOffset < 0) {
    throw const FormatException('The server returned an invalid match.');
  }
}

MultiplayerMatchLobbyView decodeServerLobby(server.GameLobbyView value) {
  final match = decodeServerMatch(value.match);
  final seen = <String>{};
  final participants = [
    for (final participant in value.participants)
      _decodeLobbyParticipant(participant, seen),
  ];
  _validateLobbyRoster(match, participants);
  _validateCanStart(match, participants, value.canStart);
  return MultiplayerMatchLobbyView(
    match: match,
    participants: List.unmodifiable(participants),
    canStart: value.canStart,
  );
}

MultiplayerLobbyParticipantView _decodeLobbyParticipant(
  server.GameLobbyParticipantView value,
  Set<String> seen,
) {
  _validateLobbyParticipantIdentity(value);
  if (!seen.add(value.playerId) ||
      (value.isCurrentUser && !value.isClaimed) ||
      (value.kind == 'ai' && !value.isReady) ||
      (value.isConnected && (!value.isClaimed || value.kind != 'human'))) {
    throw const FormatException('The server returned an invalid lobby.');
  }
  return MultiplayerLobbyParticipantView(
    playerId: value.playerId,
    name: value.name,
    kind: value.kind,
    country: value.country,
    colorValue: value.colorValue,
    isHost: value.isHost,
    isClaimed: value.isClaimed,
    isConnected: value.isConnected,
    isReady: value.isReady,
    isCurrentUser: value.isCurrentUser,
  );
}

void _validateLobbyParticipantIdentity(server.GameLobbyParticipantView value) {
  if (value.playerId.isEmpty || value.name.isEmpty) {
    throw const FormatException('The server returned an invalid lobby.');
  }
  if (!AonwPlayerCountry.values.any(
        (country) => country.name == value.country,
      ) ||
      value.colorValue < 0 ||
      value.colorValue > 0xffffffff) {
    throw const FormatException(
      'The server returned an invalid lobby identity.',
    );
  }
  if (value.kind != 'human' && value.kind != 'ai') {
    throw const FormatException('The server returned an invalid lobby.');
  }
}

void _validateLobbyRoster(
  MultiplayerMatchView match,
  List<MultiplayerLobbyParticipantView> participants,
) {
  final current = participants.where((value) => value.isCurrentUser).toList();
  final hosts = participants.where((value) => value.isHost).toList();
  if (participants.isEmpty || current.length != 1 || hosts.length != 1) {
    throw const FormatException('The server returned an invalid lobby.');
  }
  if (hosts.single.playerId != match.hostPlayerId) {
    throw const FormatException('The server returned an invalid lobby.');
  }
}

void _validateCanStart(
  MultiplayerMatchView match,
  List<MultiplayerLobbyParticipantView> participants,
  bool canStart,
) {
  final current = participants.singleWhere((value) => value.isCurrentUser);
  final humans = participants.where((value) => value.kind == 'human');
  final expected =
      match.phase == MultiplayerMatchPhase.lobby &&
      current.isHost &&
      humans.every(
        (value) => value.isClaimed && value.isConnected && value.isReady,
      );
  if (canStart != expected) {
    throw const FormatException('The server returned an invalid lobby.');
  }
}
