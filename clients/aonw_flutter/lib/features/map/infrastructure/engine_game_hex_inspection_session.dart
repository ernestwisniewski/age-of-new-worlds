part of 'engine_game_session_gateway.dart';

final class _EngineGameHexInspectionSession
    implements HexInspectionSessionPort {
  const _EngineGameHexInspectionSession(this._owner);
  final EngineGameSessionGateway _owner;

  @override
  Future<HexInspectionView> inspectHex({
    required int expectedRevision,
    required MapHexCoordinate coordinate,
  }) => _owner._serialize(
    () => const EngineHexInspectionGateway().inspect(
      readContext: _owner._context,
      expectedRevision: expectedRevision,
      coordinate: coordinate,
      send: _owner._send,
    ),
  );
}
