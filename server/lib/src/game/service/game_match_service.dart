import 'dart:convert';

import 'package:aonw_server/src/game/native/game_native_runtime.dart';
import 'package:aonw_server/src/game/service/game_turn_timeout_policy.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server_native/aonw_server_native.dart';
import 'package:serverpod/serverpod.dart';

part 'game_match_service_commands.dart';
part 'game_match_service_creation.dart';
part 'game_match_service_lifecycle.dart';
part 'game_match_service_membership.dart';
part 'game_match_service_queries.dart';
part 'game_match_service_support.dart';
part 'game_match_service_system.dart';
part 'game_match_service_timeout.dart';

const _maximumIdentifierLength = 128;
const _maximumContentDocumentBytes = 16 * 1024 * 1024;
const _maximumIdentityDocumentBytes = 2 * 1024 * 1024;
const _maximumCommandDocumentBytes = 64 * 1024;
const _maximumQueryDocumentBytes = 64 * 1024;

/// Transactional application service for engine-authoritative matches.
final class GameMatchService {
  GameMatchService({GameNativeRuntime? nativeRuntime})
    : _native = nativeRuntime ?? aonwGameNativeRuntime;

  final GameNativeRuntime _native;

  Future<GameMatchView> createMatch(
    Session session,
    GameCreateMatchRequest request,
  ) => _createMatch(this, session, request);

  Future<GameResync> joinMatch(Session session, GameJoinMatchRequest request) =>
      _joinMatch(session, request);

  Future<List<GameMatchView>> listMatches(Session session) =>
      _listMatches(session);

  Future<GameLobbyView> lobby(Session session, String matchId) =>
      _lobby(session, matchId);

  Future<GameLobbyView> setReady(Session session, String matchId, bool ready) =>
      _setReady(session, matchId, ready);

  Future<GameLobbyView> startMatch(Session session, String matchId) =>
      _startMatch(session, matchId);

  Future<GameMatchView> leaveLobby(Session session, String matchId) =>
      _leaveLobby(session, matchId);

  Future<GameCommandOutcome> submitTurn(
    Session session,
    GameSubmitTurnRequest request,
  ) => _submitTurn(this, session, request);

  Future<GameCommandOutcome> applyCommand(
    Session session,
    GamePlayerCommandRequest request,
  ) => _applyCommand(this, session, request);

  Future<GameCommandOutcome> kickParticipant(
    Session session,
    GameKickParticipantRequest request,
  ) => _kickParticipant(this, session, request);

  Future<GameCommandOutcome> resignMatch(
    Session session,
    GameResignMatchRequest request,
  ) => _resignMatch(this, session, request);

  Future<bool> finalizeTimedOutTurn(
    Session session, {
    required String matchId,
    required DateTime now,
  }) => _finalizeTimedOutTurn(this, session, matchId: matchId, now: now);

  Future<GamePlayerQueryOutcome> query(
    Session session,
    GamePlayerQueryRequest request,
  ) => _query(this, session, request);

  Future<GameResync> resync(Session session, String matchId) =>
      _resync(session, matchId);
}
