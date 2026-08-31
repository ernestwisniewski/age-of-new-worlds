part of 'rust_game_session_gateway.dart';

final class _RustGameWorkerSession implements WorkerSessionPort {
  const _RustGameWorkerSession(this._owner);

  final RustGameSessionGateway _owner;

  @override
  Future<WorkerOptionsView> workerOptions({
    required int expectedRevision,
    required String unitId,
  }) => _owner._serialize(
    () => _owner._workerGateway.options(
      context: _owner._context(),
      expectedRevision: expectedRevision,
      unitId: unitId,
      send: RustGameSessionGateway._send,
    ),
  );

  @override
  Future<WorkerCommandResultView> executeWorkerAction({
    required int expectedRevision,
    required WorkerActionView action,
  }) => _owner._serialize(
    () => _owner._workerGateway.execute(
      context: _owner._context(),
      expectedRevision: expectedRevision,
      action: action,
      send: RustGameSessionGateway._send,
      applyPatch: _owner._applyCommandPatch,
    ),
  );
}
