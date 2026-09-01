import 'dart:convert';

import 'package:aonw_server/src/game/native/game_native_runtime.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server_native/aonw_server_native.dart';
import 'package:serverpod/serverpod.dart';

part 'game_match_service_commands.dart';
part 'game_match_service_creation.dart';
part 'game_match_service_membership.dart';
part 'game_match_service_support.dart';

const _maximumIdentifierLength = 128;
const _maximumContentDocumentBytes = 16 * 1024 * 1024;
const _maximumIdentityDocumentBytes = 2 * 1024 * 1024;
const _maximumCommandDocumentBytes = 64 * 1024;

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

  Future<GameCommandOutcome> submitTurn(
    Session session,
    GameSubmitTurnRequest request,
  ) => _submitTurn(this, session, request);

  Future<GameCommandOutcome> applyCommand(
    Session session,
    GamePlayerCommandRequest request,
  ) => _applyCommand(this, session, request);

  Future<GameResync> resync(Session session, String matchId) =>
      _resync(session, matchId);
}
