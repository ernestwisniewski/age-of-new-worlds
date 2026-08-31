import 'package:aonw_server/src/game/service/game_match_service.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Authenticated endpoint for Rust-authoritative multiplayer.
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

  Future<GameCommandOutcome> submitTurn(
    Session session,
    GameSubmitTurnRequest request,
  ) => _service.submitTurn(session, request);

  Future<GameResync> resync(Session session, String matchId) =>
      _service.resync(session, matchId);
}
