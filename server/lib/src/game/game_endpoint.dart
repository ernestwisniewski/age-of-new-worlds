import 'package:aonw_server/src/game/service/game_match_service.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Authenticated endpoint for engine-authoritative multiplayer.
final class GameEndpoint extends Endpoint {
  GameEndpoint({GameMatchService? service})
    : _service = service ?? GameMatchService();

  final GameMatchService _service;

  @override
  bool get requireLogin => true;

  Future<GameMatchView> createMatch(
    Session session,
    GameCreateMatchRequest request,
  ) => _service.createMatch(session, request);

  Future<GameResync> joinMatch(Session session, GameJoinMatchRequest request) =>
      _service.joinMatch(session, request);

  Future<List<GameMatchView>> listMatches(Session session) =>
      _service.listMatches(session);

  Future<GameLobbyView> lobby(Session session, String matchId) =>
      _service.lobby(session, matchId);

  Future<GameLobbyView> setReady(Session session, String matchId, bool ready) =>
      _service.setReady(session, matchId, ready);

  Future<GameLobbyView> startMatch(Session session, String matchId) =>
      _service.startMatch(session, matchId);

  Future<GameCommandOutcome> submitTurn(
    Session session,
    GameSubmitTurnRequest request,
  ) => _service.submitTurn(session, request);

  Future<GameCommandOutcome> applyCommand(
    Session session,
    GamePlayerCommandRequest request,
  ) => _service.applyCommand(session, request);

  Future<GamePlayerQueryOutcome> query(
    Session session,
    GamePlayerQueryRequest request,
  ) => _service.query(session, request);

  Future<GameResync> resync(Session session, String matchId) =>
      _service.resync(session, matchId);
}
