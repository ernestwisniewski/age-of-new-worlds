part of 'rust_game_session_gateway.dart';

final class _RustGameProductionSession implements ProductionSessionPort {
  const _RustGameProductionSession(this._owner);

  final RustGameSessionGateway _owner;

  @override
  Future<
    ({ProductionOptionsView options, StrategicResourceProjectionView resources})
  >
  productionOverview({required int expectedRevision, required String cityId}) =>
      _owner._serialize(
        () => _owner._productionGateway.overview(
          context: _owner._context(),
          expectedRevision: expectedRevision,
          cityId: cityId,
          send: RustGameSessionGateway._send,
        ),
      );

  @override
  Future<ProductionCommandResultView> executeProductionAction({
    required int expectedRevision,
    required ProductionActionView action,
  }) => _owner._serialize(
    () => _owner._productionGateway.execute(
      context: _owner._context(),
      expectedRevision: expectedRevision,
      action: action,
      send: RustGameSessionGateway._send,
      applyPatch: _owner._applyCommandPatch,
    ),
  );
}
