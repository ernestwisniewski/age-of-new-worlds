part of 'engine_game_session_gateway.dart';

extension _EngineGameSessionClose on EngineGameSessionGateway {
  Future<void> _closeSession() async {
    _loadGeneration += 1;
    _sessionGeneration += 1;
    final session = _session;
    _session = null;
    _scene = null;
    _map = null;
    _player = null;
    _cache = null;
    _actorPlayerId = null;
    _replayEntryCount = null;
    _replayPosition = null;
    await _requestTail;
    if (session != null) await session.close();
  }
}
