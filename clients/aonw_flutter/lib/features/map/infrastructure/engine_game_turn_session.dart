part of 'engine_game_session_gateway.dart';

final class _EngineGameTurnSession implements TurnSessionPort {
  const _EngineGameTurnSession(this._owner);
  final EngineGameSessionGateway _owner;

  @override
  Future<PendingTurnActionsView> pendingTurnActions({
    required int expectedRevision,
  }) => _owner._serialize(
    () => const EnginePendingTurnActionsGateway().query(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      send: _owner._send,
    ),
  );

  @override
  Future<TurnCommandResultView> endTurn({required int expectedRevision}) =>
      _owner._serialize(
        () => _owner._turnGateway.execute(
          readContext: _owner._context,
          expectedRevision: expectedRevision,
          send: _owner._send,
          applyPatch: _owner._applyCommandPatch,
        ),
      );
}
