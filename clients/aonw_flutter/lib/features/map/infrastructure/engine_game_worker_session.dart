part of 'engine_game_session_gateway.dart';

final class _EngineGameWorkerSession implements WorkerSessionPort {
  const _EngineGameWorkerSession(this._owner);

  final EngineGameSessionGateway _owner;

  @override
  Future<WorkerOptionsView> workerOptions({
    required int expectedRevision,
    required String unitId,
  }) => _owner._serialize(
    () => _owner._workerGateway.options(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      unitId: unitId,
      send: _owner._send,
    ),
  );

  @override
  Future<WorkerCommandResultView> executeWorkerAction({
    required int expectedRevision,
    required WorkerActionView action,
  }) => _owner._serialize(
    () => _owner._workerGateway.execute(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      action: action,
      send: _owner._send,
      applyPatch: _owner._applyCommandPatch,
    ),
  );
}
