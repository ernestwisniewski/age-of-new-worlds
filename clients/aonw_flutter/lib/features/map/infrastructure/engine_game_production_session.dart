part of 'engine_game_session_gateway.dart';

final class _EngineGameProductionSession implements ProductionSessionPort {
  const _EngineGameProductionSession(this._owner);

  final EngineGameSessionGateway _owner;

  @override
  Future<
    ({ProductionOptionsView options, StrategicResourceProjectionView resources})
  >
  productionOverview({required int expectedRevision, required String cityId}) =>
      _owner._serialize(
        () => _owner._productionGateway.overview(
          readContext: _owner._context,
          expectedRevision: expectedRevision,
          cityId: cityId,
          send: _owner._send,
        ),
      );

  @override
  Future<ProductionCommandResultView> executeProductionAction({
    required int expectedRevision,
    required ProductionActionView action,
  }) => _owner._serialize(
    () => _owner._productionGateway.execute(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      action: action,
      send: _owner._send,
      applyPatch: _owner._applyCommandPatch,
    ),
  );
}
